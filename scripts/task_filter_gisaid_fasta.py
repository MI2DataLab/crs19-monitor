import os
import glob
import sys
from config import conda_sh_path, repo_path, data_dir, gisaid_fasta_dir, diff_fasta_dir

source = 'gisaid'
work_dir = repo_path + '/filter_fasta'
db_path = data_dir + '/sequences.sqlite'
full_fasta_dir = gisaid_fasta_dir

# Create output directory if not exists
if not os.path.exists(diff_fasta_dir):
    os.makedirs(diff_fasta_dir)

# Check if input directory exists
if not os.path.exists(full_fasta_dir):
    raise Exception("Directory %s does not exist" % (full_fasta_dir,))

# Find latest full fasta file
files = glob.glob(full_fasta_dir + '/*.fasta')
latest = max(files, key=lambda f: int(os.path.basename(f).split('.')[0]))

os.environ['INPUT_FASTA'] = latest
os.environ['OUTPUT_FASTA'] = diff_fasta_dir + '/' + os.path.basename(latest)
os.environ['FASTA_SOURCE'] = source
os.environ['DB_PATH'] = db_path

out = os.system('bash -c "source ' + conda_sh_path + ' && cd ' + work_dir + ' && conda activate crs19 && python script.py"')
sys.exit(out)
