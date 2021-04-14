import os
import glob
import sys
from config import conda_sh_path, gisaid_fasta_dir, mutation_output_dir, repo_path, mutation_merged_file
from utils import unpack_fasta

work_dir = repo_path + '/fasta_to_mutation'
db_dir = work_dir + '/db.fa'

# Create output directory if not exists
if not os.path.exists(mutation_output_dir):
    os.makedirs(mutation_output_dir)

# Check if input directory exists
if not os.path.exists(gisaid_fasta_dir):
    raise Exception("Directory %s does not exist" % (gisaid_fasta_dir,))

input_files = glob.glob(gisaid_fasta_dir + '/*.fasta.gz')
processed_files = glob.glob(mutation_output_dir + '/*.csv')

os.environ['FASTA_TO_MUTATION_DB'] = db_dir
for f in input_files:
    print('File %s' % f)
    timestamp = int(os.path.basename(f).split('.')[0])
    output_file = mutation_output_dir + '/' + str(timestamp) + '.csv'
    if output_file not in processed_files:
        unpacked = unpack_fasta(timestamp)
        os.environ['FASTA_TO_MUTATION'] = unpacked
        os.environ["FASTA_TO_MUTATION_OUT"] = output_file
        out = os.system('bash -c "source ' + conda_sh_path + ' && cd ' + work_dir + ' && conda activate crs19 && python script.py"')
        os.unlink(unpacked)
        if out != 0:
            sys.exit(out >> 8)

out = os.system('bash -c "awk \'(NR == 1) || (FNR > 1)\' ' + mutation_output_dir + '/*.csv' + ' > ' + mutation_merged_file + '"')
sys.exit(out >> 8)
