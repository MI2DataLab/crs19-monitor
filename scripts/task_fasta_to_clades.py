import os
import glob
import sys
from config import gisaid_fasta_dir, clades_output_dir, clades_merged_file, repo_path, conda_sh_path, nextclade_reference_dir
from utils import unpack_fasta

if os.environ.get('UPDATE_REFERENCE'):
    out = os.system('svn checkout https://github.com/nextstrain/nextclade/trunk/data/sars-cov-2 ' + nextclade_reference_dir)
    if out != 0:
        sys.exit(out >> 8)

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
        os.environ['REFERENCE_DIR'] = nextclade_reference_dir
        out = os.system('bash -c "source ~/.bashrc && source ' + conda_sh_path + ' && cd ' + work_dir + ' && conda activate crs19 && python script.py"')
        os.unlink(unpacked)
        if out != 0:
            sys.exit(out >> 8)

os.environ["CLADES_DIR"] = clades_output_dir
os.environ['CLADES_MERGED_FILE'] = clades_merged_file
out = os.system('bash -c "source ~/.bashrc && source ' + conda_sh_path + ' && cd ' + work_dir + ' && conda activate crs19 && python merge_results.py"')
sys.exit(out >> 8)
