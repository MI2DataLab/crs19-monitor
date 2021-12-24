import os
import glob
import sys
import time
import shutil
from datetime import datetime
from config import repo_path, clean_db_path, tmp_dir, site_dist

run_id = str(int(time.time() * 1000))
run_tmp_dir = tmp_dir + '/' + run_id
covar_dir = repo_path + '/generate_covar'
frontend_dir = covar_dir + '/frontend'

os.environ["CLEAN_DB_PATH"] = clean_db_path
os.environ["BUILD_PATH"] = run_tmp_dir

out = os.system('bash -c "cd ' +  frontend_dir + ' && npm run build"')
if out != 0:
    sys.exit(out >> 8)

out = os.system('bash -c "cd ' +  covar_dir + ' && Rscript script.R"')
if out != 0:
    sys.exit(out >> 8)

shutil.move(run_tmp_dir, site_dist + '/covar')
