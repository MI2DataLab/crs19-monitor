conda_sh_path = "/home/crs19monitor/miniconda3/etc/profile.d/conda.sh"
repo_path = "/crs19/production/repo"
data_dir = "/crs19/production/data"
site_dist = "/crs19/production/site_dist"
backup_dir = "/crs19/production/backups"
# List of remotes (name,ssh key,cname)
remotes = [('crs19', '/home/crs19monitor/.ssh/id_rsa', 'monitor.crs19.pl'),('mi2ai', '/home/crs19monitor/.ssh/id_rsa.mi2ai', 'monitor.mi2.ai')]

gisaid_fasta_dir = data_dir + '/gisaid_fasta'
clades_output_dir = data_dir + '/clades'
clades_merged_file = data_dir + '/clades.tsv'
pango_output_dir = data_dir + '/pango'
pango_merged_file = data_dir + '/pango.csv'
mutation_output_dir = data_dir + '/mutation'
mutation_merged_file = data_dir + '/mutation.csv'
db_path = data_dir + '/sequences.sqlite'
