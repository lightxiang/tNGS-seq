#!/usr/bin/env python
r"""get_score -- get score from table and do normalization
"""

from plumbum import cli, colors
from pathlib import Path
import pandas as pd
import sys
from ruamel import yaml


def StrOfSize(
        size,
        carry = 1000,
        ):
    '''
    递归实现，精确为最大单位值 + 小数点后三位
    默认进位为1000
    '''
    def strofsize(integer, remainder, level):
        if integer >= carry:
            remainder = integer % carry
            integer //= carry
            level += 1
            return strofsize(integer, remainder, level)
        else:
            return integer, remainder, level
    units = ['', 'K', 'M', 'G', 'T', 'P']
    integer, remainder, level = strofsize(int(size), 0, 0)
    if level+1 > len(units):
        level = -1
    return ( '{}.{:>01d}{}'.format(integer, remainder, units[level]) )


def reshape(
        df,
        vcol,
        ):
    collect = dict()
    for i in df.to_dict('record'):
        try:
            collect[i['sample_id']][i['Item_id']] = i[vcol]
        except:
            collect[i['sample_id']] = dict()
            collect[i['sample_id']]['sample_id'] = i['sample_id']
            collect[i['sample_id']][i['Item_id']] = i[vcol]
    return pd.DataFrame.from_records(list(collect.values())).fillna(0)


def main(
        indir,
        ends,
        outpf,
        sp,
        sc,
        fastp=None,
        norm=None,
        normv=None,
        host=None,
        rrna=None,
        ):
    # 1. init
    indir_fp = Path(indir)
    outpf_fp = Path(outpf)
    sp_fp = Path(sp)
    sc_fp = Path(sc)
    ## read target species config
    with sp_fp.open('r') as spfh:
        sp_cfg = yaml.safe_load(spfh)
    ## read target score config
    with sc_fp.open('r') as scfh:
        sc_cfg = yaml.safe_load(scfh)

    target_sp = pd.DataFrame({'Item_id': list(sp_cfg['target'].keys())})
    merged = pd.DataFrame()


    ## calc norm factor
    if norm is not None and fastp is not None:
        fastp_fp = Path(fastp)
        fastp_df = pd.read_csv(fastp_fp)
        fastp_df = fastp_df.assign(norm_factor=lambda x: normv / x[norm])

    if host is not None:
        host_fp = Path(host)
        host_df = pd.read_csv(host_fp)

    if rrna is not None:
        rrna_fp = Path(rrna)
        rrna_df = pd.read_csv(rrna_fp)

    sample_list = {'sample_id': [], 'sample_name': [], 'library_id': [], 'batch_id': []}

    ## read input tables and concat them
    for i in indir_fp.iterdir():
        if i.name.endswith(ends):
            # process
            library_id, batch_id, _ = i.name.split('-', 2)
            sample_id = library_id + '-' + batch_id
            sample_name = library_id.split('_', 1)[0]
            sample_list['sample_id'].append(sample_id)
            sample_list['sample_name'].append(sample_name)
            sample_list['library_id'].append(library_id)
            sample_list['batch_id'].append(batch_id)
            dfnow = pd.read_csv(i)
            dfnow = dfnow.assign(sample_id=lambda x: sample_id)
            dfnow = pd.merge(target_sp, dfnow, on='Item_id', how='left')
            if norm is not None and fastp is not None:
                ### 在这里处理标准化计算
                norm_factor = float(fastp_df[fastp_df['sample_id'] == sample_id]['norm_factor'])
                for score in sc_cfg['target']:
                    dfnow = dfnow.assign(**{score + '_norm' : lambda x : x[score] * norm_factor}).round(3)
            merged = pd.concat([merged, dfnow], ignore_index=True)
        else:
            pass

    sample_list_df = pd.DataFrame(sample_list)
    # add basic summary
    if fastp is not None:
        sample_list_df = pd.merge(sample_list_df, fastp_df[['sample_id', norm]], on='sample_id', how='left')
    if host is not None:
        sample_list_df = pd.merge(sample_list_df, host_df, on=['library_id', 'batch_id'], how='left')
    if rrna is not None:
        sample_list_df = pd.merge(sample_list_df, rrna_df, on=['library_id', 'batch_id'], how='left')

    # 2. get score
    for score in sc_cfg['target']:
        score_df = reshape(merged[['sample_id', 'Item_id', score]], score)
        score_df = pd.merge(sample_list_df, score_df, on='sample_id', how='left').fillna(0)
        score_df.to_csv(outpf_fp.with_suffix('.' + score + '.csv'), index=False)
        score_df.rename(columns=sp_cfg['target']).to_excel(outpf_fp.with_suffix('.' + score + '.xlsx'), index=False)

        if norm is not None and fastp is not None:
            norm_score_df = reshape(merged[['sample_id', 'Item_id', score + '_norm']], score + '_norm')
            norm_score_df = pd.merge(sample_list_df, norm_score_df, on='sample_id', how='left').fillna(0)
            norm_score_df.to_csv(outpf_fp.with_suffix('.' + score + '-normby-' + norm + '-' + StrOfSize(normv) + '.csv'), index=False)
            norm_score_df.rename(columns=sp_cfg['target']).to_excel(outpf_fp.with_suffix('.' + score + '-normby-' + norm + '-' + StrOfSize(normv) + '.xlsx'), index=False)

    return 0



class Main(cli.Application):
    VERSION = "0.1.0"
    COLOR_USAGE = colors.blue & colors.bold
    DESCRIPTION = colors.white | "-- get score from table and do normalization"
    USAGE = """
get_score.py --in /path/to/infiles_dir --out /path/to/outfile_prefix
    """

    # get params value
    ## normal flag & kwargs
    indir   = cli.SwitchAttr("--in", str,
                             mandatory = True,
                             help = "the input files dir(csv)")

    ends    = cli.SwitchAttr("--ends", str,
                             mandatory = True,
                             help = "file ends with this identical string")

    outpf   = cli.SwitchAttr("--out", str,
                             mandatory = True,
                             help = "the output file path")

    sp      = cli.SwitchAttr("--sp", str,
                             mandatory = True,
                             help = "the target species yaml")

    sc      = cli.SwitchAttr("--sc", str,
                             mandatory = True,
                             help = "the target scores yaml")

    ## others arguments
    fastp   = cli.SwitchAttr("--fastp", str,
                             default = None,
                             help = "merge table with fastp(csv)")

    norm    = cli.SwitchAttr("--norm", str,
                             default = None,
                             help = "do normalization, if yes, the norm value is a colname")

    normv   = cli.SwitchAttr("--nv", int,
                             default = 10e6,
                             help = "when norm have been used, this param will be valid")

    host    = cli.SwitchAttr("--host", str,
                             default = None,
                             help = "merge table with host_ratio(csv)")

    rrna    = cli.SwitchAttr("--rrna", str,
                             default = None,
                             help = "merge table with rRNA_ratio(csv)")

    def main(self):
        retcode = main(
                self.indir,
                self.ends,
                self.outpf,
                self.sp,
                self.sc,
                self.fastp,
                self.norm,
                self.normv,
                self.host,
                self.rrna,
                )
        sys.exit(retcode)

if __name__ == "__main__":
    Main.run()
