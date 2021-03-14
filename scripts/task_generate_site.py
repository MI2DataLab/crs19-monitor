import os
import glob
from datetime import datetime
from config import repo_path, site_dist, pango_merged_file, clades_merged_file, mutation_merged_file, gisaid_metadata_dir

exec_path = repo_path + "/generate_site/lineage_report.R"

# Find latest metadata file
meta_files = glob.glob(gisaid_metadata_dir + '/*.csv')
meta_path = max(meta_files, key=lambda f: int(os.path.basename(f).split('.')[0]))

os.environ["LINEAGE_DATE"] = datetime.today().strftime('%Y/%m/%d')
os.environ["LINEAGE_REPORT_PATH"] = pango_merged_file
os.environ["NEXTCLADE_REPORT_PATH"] = clades_merged_file
os.environ["METADATA_REPORT_PATH"] = meta_path
os.environ["MUTATION_REPORT_PATH"] = mutation_merged_file
os.environ["OUTPUT_PATH"] = site_dist

remote =' origin' if not os.environ.get('DEV') else 'dev'

out = os.system('Rscript ' + exec_path)
if out == 0 and not os.environ.get('NOT_PUSH'):
    os.system('cd ' + output_path + ' && git add -A && git commit -m "update" && git push -f -u ' + remote + ' gh-pages')
else:
    pass
