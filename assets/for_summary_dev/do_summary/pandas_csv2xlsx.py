import pandas as pd
from pathlib import Path
import sys



if __name__ == "__main__":
    inpath = sys.argv[1]
    infile = Path(inpath)
    df = pd.read_csv(infile)
    df.to_excel(infile.with_suffix('.xlsx'), index=False)
