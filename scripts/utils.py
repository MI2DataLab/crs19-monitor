import gzip
import os
import shutil
from config import unpacked_fasta_dir, gisaid_fasta_dir

def unpack_fasta(timestamp):
    # Create output directory if not exists
    if not os.path.exists(unpacked_fasta_dir):
        os.makedirs(unpacked_fasta_dir)
    
    in_path = gisaid_fasta_dir + '/' + str(timestamp) + '.fasta.gz'
    out_path = unpacked_fasta_dir + '/' + str(timestamp) + '.fasta'

    with gzip.open(in_path, 'rb') as f_in:
        with open(out_path, 'wb') as f_out:
            shutil.copyfileobj(f_in, f_out)

    return out_path
