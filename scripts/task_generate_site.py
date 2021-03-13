import os
from datetime import datetime

repo_path = "/home/crs19monitor/crs19-monitor"
data_dir = "/home/crs19monitor/data"
output_path = "/home/crs19monitor/site_dist"

exec_path = repo_path + "/generate_site/lineage_report.R"
csv_path = data_dir + "/lineage_report.csv"
tsv_path = data_dir + "/nextclade.tsv"
meta_path = data_dir + "/metadata.csv"

os.environ["LINEAGE_DATE"] = datetime.today().strftime('%Y/%m/%d')
os.environ["LINEAGE_REPORT_PATH"] = csv_path
os.environ["NEXTCLADE_REPORT_PATH"] = tsv_path
os.environ["METADATA_REPORT_PATH"] = meta_path
os.environ["OUTPUT_PATH"] = output_path

remote =' origin' if not os.environ.get('DEV') else 'dev'

out = os.system('Rscript ' + exec_path)
if out == 0 and not os.environ.get('NOT_PUSH'):
    os.system('cd ' + output_path + ' && git add -A && git commit -m "update" && git push -f -u ' + remote + ' gh-pages')
else:
    pass
