from pathlib import Path

conda_sh_path = "/home/crs19monitor/miniconda3/etc/profile.d/conda.sh"
parent_path = str(Path(__file__).absolute().parents[2])
repo_path = parent_path + "/repo"
data_dir = parent_path + "/data"
site_dist = parent_path + "/site_dist"
backup_dir = parent_path + "/backups"
keys_dir = parent_path + "/keys"
tmp_dir = parent_path + '/tmp'
# List of remotes (name,ssh key,cname)
remotes = []
rsync_remotes = ['europe-monitor-site@dementor:/monitor/'] if 'production' in parent_path else []
backups_number = 3

gisaid_fasta_dir = data_dir + '/gisaid_fasta'
clades_output_dir = data_dir + '/clades'
clades_merged_file = data_dir + '/clades.tsv'
pango_output_dir = data_dir + '/pango'
pango_merged_file = data_dir + '/pango.csv'
mutation_output_dir = data_dir + '/mutation'
mutation_merged_file = data_dir + '/mutation.csv'
unpacked_fasta_dir = tmp_dir + '/unpacked_fasta'
db_path = data_dir + '/sequences.sqlite'
