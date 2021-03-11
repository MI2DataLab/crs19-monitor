import os

conda_sh_path = "/home/crs19monitor/miniconda3/etc/profile.d/conda.sh"
repo_path = "/home/crs19monitor/crs19-monitor"
data_dir = "/home/crs19monitor/data"

mutation_path = data_dir + "/mutation.csv"
fasta_path = data_dir + "/gisaid.fasta"
work_dir = repo_path + '/fasta_to_mutation'
db_dir = work_dir + '/db.fa'

os.environ['FASTA_TO_MUTATION'] = fasta_path
os.environ['FASTA_TO_MUTATION_DB'] = db_dir
os.environ["FASTA_TO_MUTATION_OUT"] = mutation_path

out = os.system('bash -c "source ' + conda_sh_path + ' && cd ' + work_dir + ' && conda activate crs19 && python script.py"')
