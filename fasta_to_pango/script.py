import os
import subprocess

import pandas as pd
from biotite.sequence.io.fasta import FastaFile
from tqdm import tqdm

pangolin_out_file_name = "lineage_report.csv"
analysis_results = os.environ['LINEAGE_REPORT_PATH']
temp_fasta_path = "temp.fasta"

input_fasta_path = os.environ["FASTA_FILE_PATH"]

# checking old results
if os.path.isfile(analysis_results):
    old_results = pd.read_csv(analysis_results)
    exclude_from_analysis = list(old_results["taxon"])
else:
    old_results = []
    exclude_from_analysis = list()
scrapped_fasta = FastaFile.read(input_fasta_path)
# Excluding processed sequences
unprocessed_sequences = FastaFile()
for key in scrapped_fasta:
    if key not in exclude_from_analysis:
        unprocessed_sequences[key] = scrapped_fasta[key]
print(f"Found {len(unprocessed_sequences)} unprocessed sequences")

parts = []
tmp = FastaFile()
output_lines = []

# Append not sequences not existing in db to new_sequences
for index,key in enumerate(unprocessed_sequences.keys()):
    part = index // 2000
    if len(parts) - 1 < part:
        parts.append(FastaFile())
    parts[part][key] = unprocessed_sequences[key]

for part in tqdm(parts):
    part.write(temp_fasta_path)
    out = os.system('pangolin ' + temp_fasta_path)
    if out != 0:
        sys.exit(out >> 8)
    with open(pangolin_out_file_name, 'r') as f:
        part_output_lines = f.readlines()
        if len(output_lines) > 0: # Add header only one time
            part_output_lines = part_output_lines[1:]
        output_lines = output_lines + part_output_lines

with open(analysis_results, 'w') as f:
    f.writelines(output_lines)

os.unlink(temp_fasta_path)
os.unlink(pangolin_out_file_name)
print(f"Results in {analysis_results}")
