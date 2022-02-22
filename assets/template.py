#!/usr/bin/env python
r"""template -- calculate, and generate item table from unit table
"""
import sys
import json
import pathlib

import numpy as np
from pprint import pprint
from collections import OrderedDict
from plumbum import cli, colors
from sqlalchemy import create_engine
import pandas as pd
import dask.dataframe as dd

# descript the inputs and outputs
input_dtypes = OrderedDict((
    ('Unit_id',                   np.str),
    ('Type',                      np.str),
    ('Taxonomy_id',               np.int32),
    ('Parent_id',                 np.str),
    ('Genome',                    np.int8),
    ('Genome_size',               np.int64),
    ('GC_content',                np.float16),
    ('L_name',                    np.str),
    ('C_name_g',                  np.str),
    ('C_name_s',                  np.str),
    ('Filter_flag',               np.str),
    ('Filter_region',             np.str),
    ('Source',                    np.str),
    ('Genome_info',               np.str),
    ('align_reads_count',         np.int64),
    ('align_reads_basenum',       np.int64),
    ('align_mean_depth',          np.float64),
    ('align_ref_covlen',          np.int64),
    ('align_ref_coverage',        np.float16),
    ('uniq_reads_count',          np.int64),
    ('uniq_reads_basenum',        np.int64),
    ('uniq_mean_depth',           np.float64),
    ('uniq_ref_covlen',           np.int64),
    ('uniq_ref_coverage',         np.float16),
#    ('align_infer_reads_basenum', np.int64),
    ('filter_reason',             np.str),
    ))

out_dtypes =  OrderedDict((
    ('Item_id',                   np.str),
    ('Type',                      np.str),
    ('Taxonomy_id',               np.int32),
    ('Genome',                    np.int8),
    ('Genome_size',               np.int64),
    ('GC_content',                np.float16),
    ('L_name',                    np.str),
    ('C_name_g',                  np.str),
    ('C_name_s',                  np.str),
    ('Alias',                     np.str),
    ('Abbr',                      np.str),
    ('Encyclo',                   np.str),
    ('System_background',         np.str),
    ('Attention_species',         np.str),
    ('Common_commensal',          np.str),
    ('Common_pollutionsource',    np.str),
    ('Unexplained_source',        np.str),
    ('align_reads_count',         np.int64),
    ('align_reads_pct',           np.float32),
    ('align_ref_covlen',          np.float64),
    ('align_ref_coverage',        np.float16),
    ('uniq_reads_count',          np.int64),
    ('uniq_reads_pct',            np.float32),
    ('uniq_ref_covlen',           np.float64),
    ('uniq_ref_coverage',         np.float16),
    ('RPM',                       np.float64),
    # ('align_infer_reads_basenum', np.int64),
    # ('align_infer_ref_covlen',    np.float64),
    # ('align_infer_ref_coverage',  np.float64),
    # ('CBPM',                      np.float64),
    # ('abundance',                 np.float64),
    # ('rel_abundance',             np.float16),
    ))

# deprecated
# def infer_ref_covlen(
        # i,
        # prefix
        # ):
    # reads_basenum = prefix + '_reads_basenum'
    # infer_covlen = 0
    # for r in range(i[reads_basenum]):
        # infer_covlen = infer_covlen - infer_covlen / i['Genome_size'] + 1
    # return infer_covlen

def unit2item(
        db,
        fastp,
        libsize,
        input,
        bs,
        threads,
        out,
        ):

    out_fp = pathlib.Path(out)
    # init input first, if it is empty, then output expected_header csv file
    input_fp = pathlib.Path(input)
    unitstat = dd.read_csv(input_fp, blocksize=bs)
    if (len(unitstat.index) == 0):
        out_df = pd.DataFrame(columns=out_dtypes)
        out_df.to_csv(out_fp.with_suffix('.csv'), index=False)
        return 0

    # input is not empty
    # 1. init other file
    db_conn = create_engine(f'sqlite:///{db}?mode=ro', echo=False)
    pd_item = pd.read_sql_table('item', con=db_conn)
    del db_conn
    item = dd.from_pandas(pd_item, npartitions=threads)

    fastp_fp = pathlib.Path(fastp)
    with fastp_fp.open() as infh:
        fastp_obj = json.load(infh)

    libsize_fp = pathlib.Path(libsize)
    with libsize_fp.open() as infh:
        libsize_obj = json.load(infh)

    # 2. compute
    # sums = unitstat[['Parent_id', 'align_reads_count', 'uniq_reads_count', 'align_infer_reads_basenum']]\
    sums = unitstat[['Parent_id', 'align_reads_count', 'align_ref_covlen',
                     'uniq_reads_count', 'uniq_ref_covlen', 'Genome_size']]\
            .rename(columns={'Parent_id': 'Item_id',
                             'Genome_size': 'eff_genome_size',
                             'align_ref_covlen': 'eff_align_ref_covlen',
                             'uniq_ref_covlen': 'eff_uniq_ref_covlen'})\
            .groupby(['Item_id'])\
            .sum()\
            .compute(scheduler="processes", num_workers=threads)

    dd_sums = dd.from_pandas(sums, npartitions=threads)

    merged = item.set_index('Item_id')\
                 .join(dd_sums, how='inner')\
                 .compute(scheduler="processes", num_workers=threads)

    # merged['align_infer_ref_covlen'] = dd.from_pandas(merged.sample(frac=1.0)[['Genome_size', 'align_infer_reads_basenum']],
                                                      # chunksize=2, sort=False)\
                                         # .apply(infer_ref_covlen,
                                                # args=('align_infer',),
                                                # meta=pd.DataFrame,
                                                # axis=1)\
                                         # .compute(scheduler="processes",
                                                  # num_workers=threads)

    merged = dd.from_pandas(merged, npartitions=threads)\
            .assign(align_ref_coverage=lambda x: x['eff_align_ref_covlen'] / x['eff_genome_size'],
                    uniq_ref_coverage=lambda x: x['eff_uniq_ref_covlen'] / x['eff_genome_size'])\
            .compute(scheduler="processes", num_workers=threads)

    sum_of_align_reads_count = sum(merged['align_reads_count'].to_list())

    merged = dd.from_pandas(merged, npartitions=threads)\
            .assign(align_reads_pct=lambda x: x['align_reads_count'] * 100 / sum_of_align_reads_count,
                    align_ref_covlen=lambda x: x['align_ref_coverage'] * x['Genome_size'],
                    uniq_reads_pct=lambda x: x['uniq_reads_count'] * 100 / sum_of_align_reads_count,
                    uniq_ref_covlen=lambda x: x['uniq_ref_coverage'] * x['Genome_size'],
                    RPM=lambda x: x['align_reads_count'] * 1e6 / libsize_obj['libsize']
                    )\
            .compute(scheduler="processes", num_workers=threads)

    # merged = merged.drop(merged.filter(regex='eff_', axis=1), axis=1)
    # because use to_csv(columns=out_dtypes), drop is unnecessary
    # these formulas are deprecated
    # align_infer_ref_coverage=lambda x: x['align_infer_ref_covlen']/x['Genome_size'],
    # CBPM=lambda x: x['align_infer_reads_basenum'] * 1e6 / fastp_obj['summary']['after_filtering']['total_bases'],
    # abundance=lambda x: x['align_infer_reads_basenum']/x['Genome_size']

    # sum_of_abundance = sum(merged['abundance'].to_list())

    # merged = dd.from_pandas(merged, npartitions=threads)\
               # .assign(rel_abundance=lambda x: x['abundance']/sum_of_abundance)\
               # .compute(scheduler="processes", num_workers=threads)
    # merged = merged.sort_values(by=['relative_abundance'], ascending=False, ignore_index=True)

    # 4. output
    merged.reset_index().to_csv(out_fp.with_suffix('.csv'), columns=out_dtypes, index=False)
    return 0


class Main(cli.Application):
    VERSION = "0.2.0"
    COLOR_USAGE = colors.blue & colors.bold
    DESCRIPTION = colors.white | """
-- rpdseq-reborn unit2item
"""
    USAGE = """
python unit2item.py subcommand --kwargs
"""
    def main(self, *args):
        if args:
            print("Unknown command {0!r}".format(args[0]))
            return 1
        if not self.nested_command:
            print("No command given")
            return 1

@Main.subcommand("run")
class Run(cli.Application):
    """run table computation"""
    COLOR_USAGE = colors.blue & colors.bold
    USAGE = """
python unit2item.py run --in /path/to/unitstat.csv --out /path/to/itemstat_prefix
    """
    ## arguments
    db      = cli.SwitchAttr("--db", str,
                             mandatory = True,
                             help = "the Clinical_Microbe.db sqlite db file path")

    fastp   = cli.SwitchAttr("--fastp", str,
                             mandatory = True,
                             help = "QC fastp summary json file, deprecated")

    libsize = cli.SwitchAttr("--libsize", str,
                             mandatory = True,
                             help = "libsize json file")

    input   = cli.SwitchAttr("--in", str,
                             mandatory = True,
                             help = "input unitstat file path")

    bs      = cli.SwitchAttr("--bs", int,
                             default = 32e6,
                             help = "dask process blocksize")

    threads = cli.SwitchAttr("--threads", int,
                             default = 4,
                             help = "dask compute threads")

    out     = cli.SwitchAttr("--out", str,
                             mandatory = True,
                             help = "output prefix of itemstat file")

    def main(self):
        retcode = unit2item(
                self.db,
                self.fastp,
                self.libsize,
                self.input,
                self.bs,
                self.threads,
                self.out,
                )
        sys.exit(0)


@Main.subcommand("schema")
class Schema(cli.Application):
    """show schemas of inputs and outputs"""
    def main(self):
        print("====================SHOW SCHEMAS====================")
        print("input:")
        pprint(input_dtypes)
        print("out:")
        pprint(out_dtypes)
        print("====================OVER SCHEMAS====================")
        return 0

if __name__ == "__main__":
    Main.run()
