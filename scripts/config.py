from pathlib import Path

conda_sh_path = "/home/crs19monitor/miniconda3/etc/profile.d/conda.sh"
parent_path = str(Path(__file__).absolute().parents[2])
repo_path = parent_path + "/repo"
data_dir = parent_path + "/data"
site_dist = parent_path + "/site_dist"
backup_dir = parent_path + "/backups"
keys_dir = parent_path + "/keys"
# List of remotes (name,ssh key,cname)
remotes = [('crs19', keys_dir + '/' + 'monitor_crs19_pl', 'monitor.crs19.pl'),('mi2ai', keys_dir + '/' + 'monitor_mi2_ai', 'monitor.mi2.ai')]
backups_number = 3

gisaid_fasta_dir = data_dir + '/gisaid_fasta'
clades_output_dir = data_dir + '/clades'
clades_merged_file = data_dir + '/clades.tsv'
pango_output_dir = data_dir + '/pango'
pango_merged_file = data_dir + '/pango.csv'
mutation_output_dir = data_dir + '/mutation'
mutation_merged_file = data_dir + '/mutation.csv'
db_path = data_dir + '/sequences.sqlite'
