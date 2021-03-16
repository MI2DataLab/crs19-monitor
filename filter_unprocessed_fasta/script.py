import sqlite3
import pandas as pd
import os
from biotite.sequence.io.fasta import FastaFile

input_file = os.environ['INPUT_FASTA']
output_file = os.environ['OUTPUT_FASTA']
source = os.environ['FASTA_SOURCE']
region = os.environ['REGION']
db_path = os.environ['DB_PATH']

con = sqlite3.connect(db_path)
cur = con.cursor()

# Create table if not exists
cur.execute('CREATE TABLE IF NOT EXISTS sequences (key VARCHAR(128) PRIMARY KEY, file VARCHAR(256), source VARCHAR(32), region VARCHAR(32))')
con.commit()

# Read input fasta
sequences = FastaFile.read(input_file)
new_sequences = FastaFile()

# Append not sequences not existing in db to new_sequences
for key in sequences.keys():
    exists = cur.execute('SELECT key FROM sequences WHERE key = ?', (key,)).fetchone()
    if not exists:
        new_sequences[key] = sequences[key]

# If there is at least one new sequence
if len(list(new_sequences.keys())) > 0:
    # Write fasta file
    new_sequences.write(output_file)
    # Update database
    for key in new_sequences.keys():
        cur.execute('INSERT INTO sequences (key, file, source, region) VALUES (?, ?, ?, ?)', (key, output_file, source, region))
    con.commit()
