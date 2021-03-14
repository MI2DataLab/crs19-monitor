import os
import glob
from config import conda_sh_path, diff_fasta_dir, pango_output_dir, repo_path, pango_merged_file

work_dir = repo_path + '/fasta_to_pango'

# Create output directory if not exists
if not os.path.exists(pango_output_dir):
    os.makedirs(pango_output_dir)

# Check if input directory exists
if not os.path.exists(diff_fasta_dir):
    raise Exception("Directory %s does not exist" % (diff_fasta_dir,))

input_files = glob.glob(diff_fasta_dir + '/*.fasta')
processed_files = glob.glob(pango_output_dir + '/*.csv')

for f in input_files:
    timestamp = int(os.path.basename(f).split('.')[0])
    output_file = pango_output_dir + '/' + str(timestamp) + '.csv'
    if output_file not in processed_files:
        os.environ['LINEAGE_REPORT_PATH'] = output_file
        os.environ["FASTA_FILE_PATH"] = f
        out = os.system('bash -c "source ' + conda_sh_path + ' && cd ' + work_dir + ' && conda activate crs19 && python script.py"')
        if out != 0:
            sys.exit(out)

out = os.system('bash -c "cat ' + pango_output_dir + '/*.csv' + ' > ' + pango_merged_file + '"')
sys.exit(out)
