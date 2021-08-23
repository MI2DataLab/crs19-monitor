import pandas as pd
import os
import sys
import sqlite3
from glob import glob

pango_dir = os.environ['PANGO_DIR']
output_file = os.environ['PANGO_MERGED_FILE']
export_seq_name = os.environ.get('EXPORT_SEQNAME') is not None

con = sqlite3.connect(output_file)
cur = con.cursor()
cur.execute("DROP TABLE IF EXISTS pango")
cur.execute("CREATE TABLE pango (seq_name TEXT, accession_id TEXT, lineage TEXT, file_id TEXT)")
cur.execute("CREATE INDEX file_id_index ON pango(file_id)")
con.commit()

files = glob(pango_dir + '/*.csv')
dataframes = []
for file_name in files:
    try:
        raw = pd.read_csv(file_name)
        file_id = os.path.basename(file_name).split('.')[0]
        df = pd.DataFrame({
            'accession_id': [x.split('|')[1] for x in raw['taxon']],
            'lineage': raw['lineage'],
            'file_id': file_id
        })
        if export_seq_name:
            df['seq_name'] = raw['taxon']
        df.to_sql('pango', con, if_exists='append', index=None)
    except Exception as e:
        print('Failed reading %s' % file_name)