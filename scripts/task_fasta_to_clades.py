import os
import glob
import sys
from config import gisaid_fasta_dir, clades_output_dir, clades_merged_file, repo_path, conda_sh_path
from utils import unpack_fasta

work_dir = repo_path + '/fasta_to_clades'

# Create output directory if not exists
if not os.path.exists(clades_output_dir):
    os.makedirs(clades_output_dir)

# Check if input directory exists
if not os.path.exists(gisaid_fasta_dir):
    raise Exception("Directory %s does not exist" % (gisaid_fasta_dir,))

input_files = glob.glob(gisaid_fasta_dir + '/*.fasta.gz')
processed_files = glob.glob(clades_output_dir + '/*.tsv')

for f in input_files:
    timestamp = int(os.path.basename(f).split('.')[0])
    output_file = clades_output_dir + '/' + str(timestamp) + '.tsv'
    if output_file not in processed_files:
        unpacked = unpack_fasta(timestamp)
        os.environ['OUTPUT'] = output_file
        os.environ["INPUT_FASTA"] = unpacked
        out = os.system('bash -c "source ~/.bashrc && source ' + conda_sh_path + ' && cd ' + work_dir + ' && conda activate crs19 && python script.py"')
        os.unlink(unpacked)
        if out != 0:
            sys.exit(out >> 8)

out = os.system('bash -c "awk \'(NR == 1) || (FNR > 1)\' ' + clades_output_dir + '/*.tsv' + ' > ' + clades_merged_file + '"')
sys.exit(out >> 8)
