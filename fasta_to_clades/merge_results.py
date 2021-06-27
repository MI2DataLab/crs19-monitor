import pandas as pd
import os
import sys
from glob import glob

clades_dir = os.environ['CLADES_DIR']
output_file = os.environ['CLADES_MERGED_FILE']

files = glob(clades_dir + '/*.tsv')
dataframes = []
for file_name in files:
    try:
        dataframes.append(pd.read_csv(file_name, sep='\t'))
    except Exception as e:
        print('Failed reading %s' % file_name)
if os.environ.get('FULL') is None:
    merged = pd.concat(dataframes)[['seqName', 'clade']]
else:
    merged = pd.concat(dataframes)[['seqName', 'clade', 'aaSubstitutions', 'substitutions', 'deletions', 'aaDeletions']]
merged.to_csv(output_file, sep='\t', index=False)
os.system('cat ' + output_file + ' | grep -v "Unable to align" |grep -v "In sequence" > ' + output_file + '.tmp')
os.system('mv ' + output_file + '.tmp ' + output_file)
