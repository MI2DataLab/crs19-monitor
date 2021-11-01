import os
import time
import sys
import shutil
from config import conda_sh_path, repo_path, gisaid_fasta_dir, db_path, tmp_dir, region, start_date, max_scrapping_days, scrapper_logs_dir, pango_merged_file, scrapper_login, scrapper_pass

region = os.environ.get('REGION') or region

run_id = str(int(time.time() * 1000))
run_tmp_dir = tmp_dir + '/' + run_id

if not os.path.exists(gisaid_fasta_dir):
    os.makedirs(gisaid_fasta_dir)

if not os.path.exists(run_tmp_dir):
    os.makedirs(run_tmp_dir)

if not os.path.exists(scrapper_logs_dir):
    os.makedirs(scrapper_logs_dir)

work_dir = repo_path + '/scrapper'

os.environ["FASTA_FILES_DIR"] = gisaid_fasta_dir
os.environ["ROOT_REGION"] = region
os.environ["DB_PATH"] = db_path
os.environ["MAX_DATE_RANGE"] = str(max_scrapping_days)
os.environ["MINIMUM_START_DATE"] = start_date
os.environ["TMP_DIR"] = run_tmp_dir
os.environ["LOG_DIR"] = scrapper_logs_dir
os.environ["PANGO_FILE"] = pango_merged_file
os.environ["LOGIN"] = scrapper_login
os.environ["PASS"] = scrapper_pass

out = os.system('bash -c "source ' + conda_sh_path + ' && cd ' + work_dir + ' && conda activate crs19 && python script.py"')
if out == 2: #keyboard abort
    sys.exit(2)
if out == 0:
    shutil.rmtree(run_tmp_dir)
    os.makedirs(run_tmp_dir)
    out = os.system('cd ' + gisaid_fasta_dir + ' && find . -type f ! -name \'*.gz\' -exec gzip -9 "{}" \;')
else:
    print('Scrapping fasta failed. Tmp directory: ' + run_tmp_dir)
sys.exit(out >> 8)
