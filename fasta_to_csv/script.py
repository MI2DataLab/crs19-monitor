import os
import subprocess

import pandas as pd
from biotite.sequence.io.fasta import FastaFile

pangolin_out_file_name = "lineage_report.csv"
analysis_results = os.environ['LINEAGE_REPORT_PATH']
temp_fasta_path = "temp.fasta"

input_fasta_path = os.environ["FASTA_FILE_PATH"]

# checking old results
if os.path.isfile(analysis_results):
    old_results = pd.read_csv(analysis_results)
    exclude_from_analysis = list(old_results["taxon"])
else:
    old_results = []
    exclude_from_analysis = list()
scrapped_fasta = FastaFile.read(input_fasta_path)
# Excluding processed sequences
unprocessed_sequences = FastaFile()
for key in scrapped_fasta:
    if key not in exclude_from_analysis:
        unprocessed_sequences[key] = scrapped_fasta[key]
print(f"Found {len(unprocessed_sequences)} unprocessed sequences")
unprocessed_sequences.write(temp_fasta_path)
# Runing pangolin
subprocess.run(f"pangolin {temp_fasta_path}", shell=True, check=True)
new_results = pd.read_csv(pangolin_out_file_name)

if len(old_results) != 0:  # if there are previous results, merge them with new
    new_results = pd.concat([old_results, new_results])

new_results.to_csv(analysis_results, index=False)
# removign tempfiles
os.unlink(temp_fasta_path)
os.unlink(pangolin_out_file_name)
print(f"Results in {analysis_results}")
