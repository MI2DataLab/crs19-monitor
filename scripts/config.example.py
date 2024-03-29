from pathlib import Path

conda_sh_path = "/home/user/miniconda3/etc/profile.d/conda.sh"
region = 'Europe'
start_date = '2020-01-29'
max_scrapping_days = 6
scrapper_login = ""
scrapper_pass = ""
parent_path = str(Path(__file__).absolute().parents[2])
repo_path = parent_path + "/repo"
data_dir = parent_path + "/data"
site_dist = parent_path + "/site_dist"
backup_dir = parent_path + "/backups"
keys_dir = parent_path + "/keys"
tmp_dir = parent_path + '/tmp'
# List of remotes (name,ssh key,cname)
remotes = []
# List of rsync remotes 'user@server:/path/'
rsync_remotes = []
backups_number = 3
old_sites_to_keep = 4
pango_threads = 1
# Maximum number of sequences processed in one pangoling run
pango_max_fasta_size = 2000

gisaid_fasta_dir = data_dir + '/gisaid_fasta'
clades_output_dir = data_dir + '/clades'
clades_merged_file = data_dir + '/clades.tsv'
pango_output_dir = data_dir + '/pango'
pango_merged_file = data_dir + '/pango.csv'
mutation_output_dir = data_dir + '/mutation'
mutation_merged_file = data_dir + '/mutation.csv'
unpacked_fasta_dir = tmp_dir + '/unpacked_fasta'
scrapper_logs_dir = tmp_dir + '/scrapper_logs'
nextclade_reference_dir = data_dir + '/nextclade_reference'
db_path = data_dir + '/sequences.sqlite'
clean_db_path = data_dir + '/clean.sqlite'
log_db_path = data_dir + '/log.sqlite'
locations_db_path = data_dir + '/locations.sqlite'
summary_file = data_dir + '/summary.csv'
clade_config_path = data_dir + '/clade_config.tsv'
pango_config_path = data_dir + '/pango_config.yml'
