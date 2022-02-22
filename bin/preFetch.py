#!/usr/bin/env python
r"""preFetch -- prefetch data, and generate data_ready and traits
"""

import sys
import json
from pathlib import Path

import pandas as pd
from plumbum import cli, colors


# design.csv maybe like this:
#
# library_id,batch_id,read1,read2,libprepkit,sample_type
#
# assign create two columns: sample_id and sample_name
# sample_id = library_id + '-' + batch_id
# sample_name = library_id.str.replace
# set_index('sample_id')
#
## mandatory outputs
# name.csv
# sample_id,sample_name,library_id,batch_id
#
# data.csv
# sample_id,read1,read2
#
## accroding to other columns
# libprepkit.csv
# sample_id,libprepkit
#
# sample_type.csv
# sample_id,sample_type


def search_path(
        indir_fp,
        library_id,
        ):
    datas_fp = sorted(indir_fp.glob(library_id + '*' + '.fq.gz'))
    if len(datas_fp) == 2:
        read1 = datas_fp[0].as_posix()
        read2 = datas_fp[1].as_posix()
        return (read1, read2)
    elif len(datas_fp) == 1:
        read1 = datas_fp[0].as_posix()
        return (read1, '-')
    else:
        return ('-', '-')


def fetch_data(
        obj,
        seqd,
        rawd,
        ):
    (read1, read2) = ('-', '-')

    try:
        read1_fp = Path(obj['read1'])
        if read1_fp.is_file():
            read1 = read1_fp.as_posix()
            try:
                read2_fp = Path(obj['read2'])
                if read2_fp.is_file():
                    read2 = read2_fp.as_posix()
            except:
                pass
    except:
        pass

    if read1 == '-':
        try:
            _, machine_id, _ = obj['batch_id'].split('_', 2)
        except:
            machine_id = None

        if machine_id is not None and seqd is not None:
            seqd_fp = Path(seqd)
            dir_fp = seqd_fp / machine_id / obj['batch_id'] / 'Data/Intensities/BaseCalls'
            read1, read2 = search_path(dir_fp, obj['library_id'])

    if read1 == '-' and rawd is not None:
            rawd_fp = Path(rawd)
            dir_fp = rawd_fp / obj['batch_id']
            read1, read2 = search_path(dir_fp, obj['library_id'])

    return (read1, read2)


def main(
        input,
        out,
        seqdata,
        rawdata,
        ):
    in_fp = Path(input)
    out_fp = Path(out)

    design = pd.read_csv(in_fp)
    design = design.drop_duplicates()
    pat = r"(?P<name>[A-Za-z0-9]+)_(?P<suffix>\w+)"
    repl = lambda m: m.group('name')
    design = design.assign(sample_id=lambda x: x['library_id'] + '-' + x['batch_id'],
                           sample_name=lambda x: x['library_id'].str.replace(pat=pat, repl=repl))
    design = design.set_index('sample_id')
    design[['read1', 'read2']] = design.apply(fetch_data,
                                              args=(seqdata, rawdata),
                                              axis=1,
                                              result_type='expand')

    # failed.csv
    design[design['read1'] == '-'].to_csv(out_fp/'failed.csv')

    design_pass = design[design['read1'] != '-']
    # name.csv
    design_pass[['sample_name', 'library_id', 'batch_id']].to_csv(out_fp/'name.csv')
    # data.csv
    design_pass[['read1', 'read2']].to_csv(out_fp/'data.csv')

    # other columns seperated table output
    full_columns = design_pass.columns.to_list()
    except_columns = ['sample_name', 'library_id', 'batch_id', 'read1', 'read2']
    other_columns = list(set(full_columns) - set(except_columns))
    for i in other_columns:
        design_pass[i].to_csv((out_fp/i).with_suffix('.csv'))

    return 0

class Main(cli.Application):
    VERSION = "0.1.0"
    COLOR_USAGE = colors.blue & colors.bold
    DESCRIPTION = colors.white | "-- prefetch data, and generate data_ready and traits"
    USAGE = """
preFetch.py -i /path/to/input.csv -o /path/to/outprefix --sd /path/to/SeqData --rd /path/to/RawData
    """

    # get params value
    ## normal flag & kwargs
    input   = cli.SwitchAttr("-i", str,
                             mandatory = True,
                             help = "the input file path")

    out     = cli.SwitchAttr("-o", str,
                             mandatory = True,
                             help = "the output files dir")

    seqdata = cli.SwitchAttr("--sd", str,
                             default = None,
                             help = "how many clip parts allowed")

    rawdata = cli.SwitchAttr("--rd", str,
                             default = None,
                             help = "how many in/del parts allowed")

    def main(self):
        retcode = main(
                self.input,
                self.out,
                self.seqdata,
                self.rawdata,
                )
        sys.exit(retcode)

if __name__ == "__main__":
    Main.run()
