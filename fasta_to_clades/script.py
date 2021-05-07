import pandas as pd
import os
import sys
import math
from biotite.sequence.io.fasta import FastaFile
from tqdm import tqdm

input_file = os.environ['INPUT_FASTA']
output_file = os.environ['OUTPUT']
reference_dir = os.environ['REFERENCE_DIR']
tmp_input = 'input.fasta'
tmp_output = 'output.tsv'

arguments = [
    ('genes', 'E,M,N,ORF1a,ORF1b,ORF3a,ORF6,ORF7a,ORF7b,ORF8,ORF9b,S'),
    ('input-root-seq', reference_dir + '/reference.fasta'),
    ('input-gene-map', reference_dir + '/genemap.gff'),
    ('input-tree', reference_dir + '/tree.json'),
    ('input-qc-config', reference_dir + '/qc.json'),
    ('input-pcr-primers', reference_dir + '/primers.csv')
]

arguments_str = ' '.join(['--' + arg[0] + '=' + arg[1] for arg in arguments])

# Read input fasta
sequences = FastaFile.read(input_file)
parts = []


tmp = FastaFile()
output_lines = []

# Append not sequences not existing in db to new_sequences
for index,key in enumerate(sequences.keys()):
    part = index // 500
    if len(parts) - 1 < part:
        parts.append(FastaFile())
    parts[part][key] = sequences[key]

for part in tqdm(parts):
    part.write(tmp_input)
    out = os.system('nextclade --input-fasta ' + tmp_input + ' --output-tsv ' + tmp_output + ' ' + arguments_str)
    if out != 0:
        sys.exit(out >> 8)
    with open(tmp_output, 'r') as f:
        part_output_lines = f.readlines()
        if len(output_lines) > 0: # Add header only one time
            part_output_lines = part_output_lines[1:]
        output_lines = output_lines + part_output_lines

with open(output_file, 'w') as f:
    f.writelines(output_lines)
