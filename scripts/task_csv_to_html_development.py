import os

repo_path = "/home/crs19monitor/crs19-monitor"
data_dir = "/home/crs19monitor/data"
output_path = "/home/crs19monitor/site_dist_development"

exec_path = repo_path + "/csv_to_html/lineage_report.R"
csv_path = data_dir + "/lineage_report.csv"
tsv_path = data_dir + "/lineage_report.tsv"
meta_path = data_dir + "/metadata.csv"

os.environ["LINEAGE_DATE"] = "2021/03/09"
os.environ["LINEAGE_REPORT_PATH"] = csv_path
os.environ["NEXTCLADE_REPORT_PATH"] = tsv_path
os.environ["METADATA_REPORT_PATH"] = meta_path
os.environ["OUTPUT_PATH"] = output_path

out = os.system('Rscript ' + exec_path)
if out == 0:
    os.system('cd ' + output_path + ' && git add -A && git commit -m "update" && git push -f -u origin gh-pages')
else:
    pass
