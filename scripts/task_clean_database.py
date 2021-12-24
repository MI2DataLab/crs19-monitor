import os
import time
import sys
import shutil
from config import conda_sh_path, repo_path, db_path, clean_db_path, locations_db_path, pango_merged_file, clades_merged_file, clade_config_path, pango_config_path

work_dir = repo_path + '/clean_database'

os.environ["RAW_DB_PATH"] = db_path
os.environ["CLEAN_DB_PATH"] =  clean_db_path
os.environ["LOCATIONS_DB_PATH"] = locations_db_path
os.environ["PANGO_PATH"] = pango_merged_file
os.environ["CLADES_PATH"] = clades_merged_file
os.environ["CLADE_CONFIG_PATH"] = clade_config_path
os.environ["PANGO_CONFIG_PATH"] = pango_config_path

if os.path.exists(clean_db_path):
    os.unlink(clean_db_path)
out = os.system('bash -c "source ' + conda_sh_path + ' && cd ' + work_dir + ' && conda activate crs19 && python script.py"')
sys.exit(out >> 8)
