#!/usr/bin/env python
r"""depthAgg -- depth aggregate compute
"""
import sys
import pathlib
from collections import OrderedDict

from dask import dataframe as dd
from plumbum import cli, colors
import pandas as pd

def aggregate(
        input,
        index_col,
        cnprefix,
        threads,
        memthread,
        out,
        ):
    # 1. init
    input_header = {0: index_col, 1: 'ref_pos', 2: 'reads_count'}
    ## read all align mpileup
    input_fp = pathlib.Path(input)
    try:
        input_df = dd.read_csv(input_fp, sep='\t', header=None, blocksize=memthread)
        input_df = input_df.rename(columns=input_header)
    except:
        input_df = None

    ## set output file
    out_fp = pathlib.Path(out)

    if input_df is None:
        out_cols = OrderedDict((
            (index_col, str),
            (cnprefix + '_ref_covlen', int),
            (cnprefix + '_reads_basenum', int),
            ))
        result = pd.DataFrame(columns=out_cols)
    else:
        # 2. set task
        task = input_df.groupby(index_col).\
                agg({'ref_pos': 'count', 'reads_count': 'sum'})

        # 3. compute
        result = task.compute(scheduler='processes', num_workers=threads)

        # 4. rename
        result = result.rename(columns={'ref_pos': cnprefix + '_ref_covlen',
                                        'reads_count': cnprefix + '_reads_basenum'})

    # 4. output
    result.to_csv(out_fp.with_suffix('.csv'))

    return 0


class Main(cli.Application):
    VERSION = "0.1.0"
    COLOR_USAGE = colors.blue & colors.bold
    DESCRIPTION = colors.white | "-- rpdseq-origin depthAgg"
    USAGE = """
python depthAgg.py --in /path/to/depthfile --out /path/to/output_prefix
    """

    input       = cli.SwitchAttr("--in", str,
                                 mandatory = True,
                                 help = "samtools depth file path")

    index_col   = cli.SwitchAttr("-R", str,
                                 default = "ref_name",
                                 help = "set the index colname")

    cnprefix    = cli.SwitchAttr("--cnpx", str,
                                 mandatory = True,
                                 help = "output colnames prefix")

    threads     = cli.SwitchAttr("--threads", int,
                                 default = 4,
                                 help = "ncpus to process compute task")

    memthread   = cli.SwitchAttr("-M", int,
                                 default = 1e6,
                                 help = "chuncksize per threads")

    out         = cli.SwitchAttr("--out", str,
                                 mandatory = True,
                                 help = "aggregate csv file output prefix")

    def main(self):
        retcode = aggregate(
                self.input,
                self.index_col,
                self.cnprefix,
                self.threads,
                self.memthread,
                self.out,
                )
        sys.exit(retcode)

if __name__ == "__main__":
    Main.run()
