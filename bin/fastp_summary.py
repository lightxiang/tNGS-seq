#!/usr/bin/env python

import sys
from pathlib import Path
from plumbum import cli
from ruamel import yaml
import json
from jsonpath_ng.ext import arithmetic, parse
import pandas as pd

def build_parser(jpath):
    tokens = jpath.split(' ')
    if len(tokens) == 3:
        left, op, right = tokens
        return arithmetic.Operation(parse(left), op, parse(right))
    else:
        return parse(jpath)


class Main(cli.Application):
    indir = cli.SwitchAttr(['-i'],
                            str,
                            mandatory=True,
                            help='input json files dir')

    config = cli.SwitchAttr(['-c'],
                            str,
                            mandatory=True,
                            help='schema config file')

    outdir = cli.SwitchAttr(['-o'],
                            str,
                            mandatory=True,
                            help='output processed files dir')

    def main(self):
        indir_fp = Path(self.indir).resolve()
        config_fp = Path(self.config).resolve()
        outdir_fp = Path(self.outdir).resolve()

        with config_fp.open() as instream:
            config = yaml.safe_load(instream)

        schema_parser = dict()
        result_busket = dict()
        for schema_name, columns in config.items():
            result_busket[schema_name] = list()
            schema_parser[schema_name] = {colname: {'parser': build_parser(attrs['path']), 'format': attrs['format']} for colname, attrs in columns.items()}

        for infile in indir_fp.iterdir():
            if infile.as_posix().endswith('.json'):
                with infile.open() as instream:
                    content = json.load(instream)
                    for schema_name, columns in schema_parser.items():
                        values = dict()
                        values['sample_id'] = infile.with_suffix('').name
                        values.update({colname : attrs['format'].format(attrs['parser'].find(content)[0].value) for colname, attrs in columns.items()})
                        result_busket[schema_name].append(values)

        for schema_name in config.keys():
#            with (outdir_fp/schema_name).with_suffix('.json').open('w') as outstream:
#               json.dump(result_busket[schema_name], outstream, ensure_ascii=False, indent=4)
            pd.DataFrame.from_records(result_busket[schema_name]).to_csv((outdir_fp/schema_name).with_suffix('.csv'), index=False)

        return 0

if __name__ == "__main__":
    status = Main.run()
    sys.exit(status)
