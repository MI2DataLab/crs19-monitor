import os

conda_sh_path = "/home/crs19monitor/miniconda3/etc/profile.d/conda.sh"
repo_path = "/home/crs19monitor/crs19-monitor"
data_dir = "/home/crs19monitor/data"
region = "Europe / Poland"

fasta_path = data_dir + "/gisaid.fasta"
meta_path = data_dir + "/metadata.csv"
work_dir = repo_path + '/scrapper'

os.environ["FASTA_FILE_PATH"] = fasta_path
os.environ["META_FILE_PATH"] = meta_path
os.environ["REGION"] = region

out = os.system('bash -c "source ' + conda_sh_path + ' && cd ' + work_dir + ' && conda activate crs19 && python script.py"')
