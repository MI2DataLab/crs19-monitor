import os

conda_sh_path = "/home/crs19monitor/miniconda3/etc/profile.d/conda.sh"
repo_path = "/home/crs19monitor/crs19-monitor"
data_dir = "/home/crs19monitor/data"

fasta_path = data_dir + "/input.fasta"
work_dir = repo_path + '/scrapper'

os.environ["FASTA_FILE_PATH"] = fasta_path

out = os.system('bash -c "source ' + conda_sh_path + ' && cd ' + work_dir + ' && conda activate crs19 && python script.py"')
