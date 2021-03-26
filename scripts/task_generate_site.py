import os
import glob
import sys
from datetime import datetime
from config import repo_path, site_dist, pango_merged_file, clades_merged_file, mutation_merged_file, db_path

work_dir = repo_path + '/generate_site'
exec_path = "script.R"
main_region = 'Poland'

os.environ["LINEAGE_DATE"] = datetime.today().strftime('%Y/%m/%d')
os.environ["LINEAGE_REPORT_PATH"] = pango_merged_file
os.environ["NEXTCLADE_REPORT_PATH"] = clades_merged_file
os.environ["MUTATION_REPORT_PATH"] = mutation_merged_file
os.environ["DB_PATH"] = db_path
os.environ["MAIN_REGION"] = main_region
os.environ["OUTPUT_PATH"] = site_dist

remote =' origin'

out = os.system('cd ' + work_dir + ' && Rscript ' + exec_path)
if out == 0 and not os.environ.get('NOT_PUSH'):
    out = os.system('cd ' + site_dist + ' && git add -A && git commit -m "update" && git push -f -u ' + remote + ' gh-pages')
    sys.exit(out >> 8)
else:
    sys.exit(out >> 8)
