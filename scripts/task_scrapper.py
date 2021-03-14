import os
import time
import sys
from config import conda_sh_path, repo_path, gisaid_fasta_dir, gisaid_metadata_dir

region = "Europe / Poland"
# In nanoseconds
timestamp = int(time.time() * 1000)

if not os.path.exists(gisaid_fasta_dir):
    os.makedirs(gisaid_fasta_dir)

if not os.path.exists(gisaid_metadata_dir):
    os.makedirs(gisaid_metadata_dir)

fasta_path = gisaid_fasta_dir + '/' + str(timestamp) + '.fasta'
meta_path = gisaid_metadata_dir + '/' + str(timestamp) + '.csv'
work_dir = repo_path + '/scrapper'

os.environ["FASTA_FILE_PATH"] = fasta_path
os.environ["META_FILE_PATH"] = meta_path
os.environ["REGION"] = region

out = os.system('bash -c "source ' + conda_sh_path + ' && cd ' + work_dir + ' && conda activate crs19 && python script.py"')
sys.exit(out)
