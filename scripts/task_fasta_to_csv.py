import os

conda_sh_path = "/home/crs19monitor/miniconda3/etc/profile.d/conda.sh"
repo_path = "/home/crs19monitor/crs19-monitor"
data_dir = "/home/crs19monitor/data"

csv_path = data_dir + "/lineage_report.csv"
fasta_path = data_dir + "/input.fasta"
work_dir = repo_path + '/fasta_to_csv'

os.environ['LINEAGE_REPORT_PATH'] = csv_path
os.environ["FASTA_FILE_PATH"] = fasta_path

out = os.system('bash -c "source ' + conda_sh_path + ' && cd ' + work_dir + ' && conda activate crs19 && python script.py"')
