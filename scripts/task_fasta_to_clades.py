import os
import glob
import sys
from config import diff_fasta_dir, clades_output_dir, clades_merged_file

# Create output directory if not exists
if not os.path.exists(clades_output_dir):
    os.makedirs(clades_output_dir)

# Check if input directory exists
if not os.path.exists(diff_fasta_dir):
    raise Exception("Directory %s does not exist" % (diff_fasta_dir,))

input_files = glob.glob(diff_fasta_dir + '/*.fasta')
processed_files = glob.glob(clades_output_dir + '/*.tsv')

for f in input_files:
    timestamp = int(os.path.basename(f).split('.')[0])
    output_file = clades_output_dir + '/' + str(timestamp) + '.tsv'
    if output_file not in processed_files:
        out = os.system('bash -c "source ~/.bashrc && nextclade --input-fasta ' + f + ' --output-tsv ' + output_file + ' "')
        if out != 0:
            sys.exit(out)

out = os.system('bash -c "awk \'(NR == 1) || (FNR > 1)\' ' + clades_output_dir + '/*.tsv' + ' > ' + clades_merged_file + '"')
sys.exit(out)
