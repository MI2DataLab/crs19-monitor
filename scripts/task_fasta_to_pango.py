import os
import glob
import sys
import shutil
import multiprocessing as mp
from config import conda_sh_path, gisaid_fasta_dir, pango_output_dir, repo_path, pango_merged_file, pango_threads, pango_max_fasta_size
from utils import unpack_fasta

work_dir = repo_path + '/fasta_to_pango'

# Create output directory if not exists
if not os.path.exists(pango_output_dir):
    os.makedirs(pango_output_dir)

# Check if input directory exists
if not os.path.exists(gisaid_fasta_dir):
    raise Exception("Directory %s does not exist" % (gisaid_fasta_dir,))

input_files = glob.glob(gisaid_fasta_dir + '/*.fasta.gz')
processed_files = glob.glob(pango_output_dir + '/*.csv')

to_process = []
for f in input_files:
    timestamp = int(os.path.basename(f).split('.')[0])
    output_file = pango_output_dir + '/' + str(timestamp) + '.csv'
    if output_file not in processed_files:
        to_process.append(timestamp)

def runner(timestamp):
    unpacked = unpack_fasta(timestamp)
    output_file = pango_output_dir + '/' + str(timestamp) + '.csv'
    if os.path.exists(work_dir + '/' + str(timestamp)):
        shutil.rmtree(work_dir + '/' + str(timestamp))
    os.makedirs(work_dir + '/' + str(timestamp))
    os.environ['LINEAGE_REPORT_PATH'] = output_file
    os.environ["FASTA_FILE_PATH"] = unpacked
    os.environ["MAX_FASTA_SIZE"] = str(pango_max_fasta_size)
    out = os.system('bash -c "source ' + conda_sh_path + ' && cd ' + work_dir + '/' + str(timestamp) + ' && conda activate crs19 && python ../script.py"')
    os.unlink(unpacked)
    shutil.rmtree(work_dir + '/' + str(timestamp))
    if out != 0:
        raise Exception('Subproccess have failed')

if __name__ == '__main__':
    pool = mp.get_context('spawn').Pool(pango_threads)
    pool.starmap_async(runner, [(x, ) for x in to_process]).get()

    os.environ["PANGO_DIR"] = pango_output_dir
    os.environ['PANGO_MERGED_FILE'] = pango_merged_file
    out = os.system('bash -c "source ~/.bashrc && source ' + conda_sh_path + ' && cd ' + work_dir + ' && conda activate crs19 && python merge_results.py"')
    sys.exit(out >> 8)
