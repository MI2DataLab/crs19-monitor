import os
import pandas as pd
import sqlite3

clades_path = os.environ.get('CLADES_PATH')
pango_path = os.environ.get('PANGO_PATH')
metadata_path = os.environ.get('METADATA_PATH')
output_path = os.environ.get('OUTPUT_PATH')

clades = pd.read_csv(clades_path, sep='\t')
clades['accession_id'] = [x.split('|')[1] for x in clades['seqName']]
clades = clades[['seqName', 'accession_id', 'clade']]


pango = pd.read_csv(pango_path)
pango['accession_id'] = [x.split('|')[1] for x in pango['taxon']]
pango = pango[['accession_id', 'lineage']]

con = sqlite3.connect(metadata_path)
metadata = pd.read_sql_query(
    """
    SELECT accession_id, submission_date, collection_date, host, location, country, sex, age,
    clade as gisaid_clade, variant as gisaid_variant, gisaid_pango as gisaid_lineage,
    substitutions as gisaid_substitutions from metadata
    """, con)
con.close()

merged = pd.merge(metadata, clades, on='accession_id', how='left')
merged = pd.merge(merged, pango, on='accession_id', how='left')
merged.to_csv(output_path)
