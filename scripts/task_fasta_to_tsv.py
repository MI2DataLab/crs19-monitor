import os

data_dir = "/home/crs19monitor/data"

tsv_path = data_dir + "/nextclade.tsv"
fasta_path = data_dir + "/gisaid.fasta"

out = os.system('bash -c "source ~/.bashrc && nextclade --input-fasta ' + fasta_path + ' --output-tsv ' + tsv_path + ' "')
