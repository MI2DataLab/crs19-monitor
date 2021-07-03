import os
import sys
import subprocess

import pandas as pd
from biotite.sequence.io.fasta import FastaFile
from tqdm import tqdm

pangolin_out_file_name = "lineage_report.csv"
analysis_results = os.environ['LINEAGE_REPORT_PATH']
temp_fasta_path = "temp.fasta"
max_fasta_size = int(os.environ["MAX_FASTA_SIZE"])
input_fasta_path = os.environ["FASTA_FILE_PATH"]

unprocessed_sequences = FastaFile.read(input_fasta_path)
print(f"Found {len(unprocessed_sequences)} unprocessed sequences")

parts = []
tmp = FastaFile()
output_lines = []

for index,key in enumerate(unprocessed_sequences.keys()):
    part = index // max_fasta_size
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
