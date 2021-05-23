import pandas as pd
import os
import sys
from glob import glob

pango_dir = os.environ['PANGO_DIR']
output_file = os.environ['PANGO_MERGED_FILE']

files = glob(pango_dir + '/*.csv')
dataframes = []
for file_name in files:
    try:
        dataframes.append(pd.read_csv(file_name))
    except Exception as e:
        print('Failed reading %s' % file_name)
merged = pd.concat(dataframes)[['taxon', 'lineage']]
merged.to_csv(output_file, index=False)
