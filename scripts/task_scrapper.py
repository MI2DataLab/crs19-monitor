import os
import time
import sys
from config import conda_sh_path, repo_path, gisaid_fasta_dir, db_path

region = os.environ.get('REGION') or 'Europe'

if not os.path.exists(gisaid_fasta_dir):
    os.makedirs(gisaid_fasta_dir)

work_dir = repo_path + '/scrapper'

os.environ["FASTA_FILES_DIR"] = gisaid_fasta_dir
os.environ["ROOT_REGION"] = region
os.environ["DB_PATH"] = db_path
os.environ["MAX_DATE_RANGE"] = '6'
os.environ["MINIMUM_START_DATE"] = '2020-01-29'

out = os.system('bash -c "source ' + conda_sh_path + ' && cd ' + work_dir + ' && conda activate crs19 && python script.py"')
sys.exit(out >> 8)
