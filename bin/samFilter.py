#!/usr/bin/env python
r"""samFilter -- filter alignment, design for bwa-mem
"""

from plumbum import cli, colors
import pathlib
import pysam
import sys
from collections import Counter
from operator import methodcaller
import re


cH = methodcaller('get', 'H', 0)
cS = methodcaller('get', 'S', 0)
cI = methodcaller('get', 'I', 0)
cD = methodcaller('get', 'D', 0)
cM = methodcaller('get', 'M', 0)
sNM = methodcaller('get_tag', 'NM', 0)

#print (cigarstring())

#print (cM)

def get_pe(
        obj
        ):
    while True:
        try:
            yield (next(obj), next(obj))
        except:
            break


def check(
        segment,
        indel,
        lims,
        match,
        ):
    count = Counter(segment.cigarstring)
    cMap = segment.cigarstring
    mm = re.findall(r'(\d+)M',cMap)
    mc = 0
    for i in mm:
        a=int(i)
        mc += a
    cLims = (mc - sNM(segment))/mc
#    print(cLims)

#    print (mm)
#    if cM(count)  > 89:
#        return 1
########################################    
    if mc < match:
        return 0
    elif cI(count) + cD(count) > indel:
        return 0
    elif cLims < lims:
        return 0
    else:
        return 1
########################################


def main(
        input,
        read_type,
        indel,
        lims,
        match,
        out,
        threads,
        ):
    in_fp = pathlib.Path(input)
    out_fp = pathlib.Path(out)

    with pysam.AlignmentFile(in_fp, threads=threads) as samfh:
        with pysam.AlignmentFile(out_fp.with_suffix('.bam'),
                                 'wb',
                                 header=samfh.header,
                                 threads=threads,
                                 duplicate_filehandle=False) as outfh:
            if read_type == 'se':
                for segment in samfh:
                    # Hard clip or Soft clip only exists one and one end
                    if check(segment, indel, lims, match) == 1:
                        outfh.write(segment)
            elif read_type == "pe":
                for align1, align2 in get_pe(samfh):
                    pass1 = check(align1, indel, lims, match)
                    pass2 = check(align2, indel, lims, match)
                    if pass1 + pass2 == 2:
                        outfh.write(align1)
                        outfh.write(align2)
            else:
                return 1

    return 0


class Main(cli.Application):
    VERSION = "0.1.0"
    COLOR_USAGE = colors.blue & colors.bold
    DESCRIPTION = colors.white | "-- filter alignments, for bwa-mem"
    USAGE = """
samFilter.py --in /path/to/bwa-mem.bam --out /path/to/pass.bam
    """

    # get params value
    ## normal flag & kwargs
    input       = cli.SwitchAttr("--in", str,
                                 mandatory = True,
                                 help = "the input file path")

    out         = cli.SwitchAttr("--out", str,
                                 mandatory = True,
                                 help = "the output file path")

    read_type   = cli.SwitchAttr("--rt", str,
                                 default = 'se',
                                 help = "the read type, se or pe")

    indel       = cli.SwitchAttr("--indel", int,
                                 default = 1,
                                 help = "how many in/del parts allowed")

    lims        = cli.SwitchAttr("--lims", float,
                                 default = 0.95,
                                 help = "how many mismatch base num allowed")
    match       = cli.SwitchAttr("--match", int,
                                 default = 90,
                                 help = "how many match base num allowed")
    threads     = cli.SwitchAttr(["-p", "--threads"], int,
                                 default = 1,
                                 help = "num of compressing/decompressing threads")

    def main(self):
        retcode = main(
                self.input,
                self.read_type,
                self.indel,
                self.lims,
                self.match,
                self.out,
                self.threads,
                )
        sys.exit(retcode)

if __name__ == "__main__":
    Main.run()
