import pandas as pd
import os
import sys
from glob import glob
from tqdm import tqdm

clades_dir = os.environ['CLADES_DIR']
output_file = os.environ['CLADES_MERGED_FILE']

files = glob(clades_dir + '/*.tsv')
if os.path.exists(output_file):
    os.unlink(output_file)
if os.path.exists(output_file + '.tmp'):
    os.unlink(output_file + '.tmp')

for index, file_name in tqdm(list(enumerate(files))):
    try:
        dataframe = pd.read_csv(file_name, sep='\t')
    except Exception as e:
        print('Failed reading %s' % file_name)
    if os.environ.get('FULL') is None:
        dataframe = dataframe[['seqName', 'clade']]
    else:
        dataframe = dataframe[['seqName', 'clade', 'aaSubstitutions', 'substitutions', 'deletions', 'aaDeletions', 'qc.overallStatus', 'missing', 'insertions']]
    dataframe.to_csv(output_file + '.tmp', sep='\t', index=False, header=index==0)
    os.system('cat ' + output_file + '.tmp | grep -v "Unable to align" |grep -v "In sequence" >> ' + output_file)
