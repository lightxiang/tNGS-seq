import pandas as pd
from pathlib import Path
infile = Path.cwd() / 'fastp_summary.json'
df = pd.read_json(infile)
df.to_csv('./fastp_summary.csv', index=False)
