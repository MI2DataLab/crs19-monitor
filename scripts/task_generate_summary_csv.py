import os
import sys
from config import pango_merged_file, clades_merged_file, db_path, summary_file, conda_sh_path, repo_path

work_dir = repo_path + '/generate_summary_csv'

os.environ['OUTPUT_PATH'] = summary_file
os.environ['CLADES_PATH'] = clades_merged_file
os.environ['PANGO_PATH'] = pango_merged_file
os.environ['METADATA_PATH'] = db_path

out = os.system('bash -c "source ~/.bashrc && source ' + conda_sh_path + ' && cd ' + work_dir + ' && conda activate crs19 && python script.py"')
sys.exit(out >> 8)
