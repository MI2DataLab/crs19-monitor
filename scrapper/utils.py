from io import StringIO
import os
import sys
import lzma
import sqlite3
import tarfile
import operator
import traceback
import pandas as pd
from biotite.sequence.io.fasta import FastaFile


def init_db(db_path):
    """
    Creates table metadata in database if not exists
    """
    con = sqlite3.connect(db_path)
    cur = con.cursor()
    cur.execute("""CREATE TABLE IF NOT EXISTS metadata (
                          accession_id CHAR(16) PRIMARY KEY NOT NULL,
                          fasta_file VARCHAR(16) NULL,
                          passage VARCHAR(32) NULL,
                          submission_date DATE NOT NULL,
                          collection_date DATE NULL,
                          host VARCHAR(32) NULL,
                          location VARCHAR(128) NULL,
                          originating_lab TEXT NULL,
                          submitting_lab TEXT NULL,
                          country VARCHAR(32) NULL,
                          sex VARCHAR(32) NULL,
                          age INT NULL,
                          substitutions VARCHAR(64) NULL,
                          clade VARCHAR(32) NULL,
                          variant VARCHAR(32) NULL,
                          gisaid_pango VARCHAR(32) NULL,
                          is_meta_loaded BIT NOT NULL DEFAULT 0,
                          is_variant_loaded BIT NOT NULL DEFAULT 0,
                          is_pango_loaded INT NOT NULL DEFAULT 0,
                          last_meta_load_try DATE NOT NULL DEFAULT '1970-11-03'
    )""")
    con.commit()


def repeater(function, *args, **kwargs):
    """
    Loop scrapping
    """
    repeats = 15
    for i in range(repeats):
        try:
            done = function(*args, **kwargs)
            return done
        except Exception as e:
            exc_info = sys.exc_info()
            if i == repeats - 1:
                raise e
            else:
                traceback.print_exception(*exc_info)
            del exc_info
            print('%s try failed' % (i,))


def get_number_of_files(dir: str):
    """
    Returns number of files in dir
    Excludes .part files
    """
    if os.path.exists(dir):
        files = [f for f in os.listdir(dir) if ".part" not in f]
        n_files = len(files)
    else:
        n_files = 0
    return n_files


def extract_country(location: str):
    """
    Returns country from location string
    """
    l = location.split("/")
    if len(l) < 2:
        return None

    c = l[1].rstrip(" ").lstrip(" ")

    return c


def fix_metadata_table(input_handle, output_handle, delim='\t'):
    lines = input_handle.readlines()
    parts = [line.replace("\n", "").replace("\r", "").split(delim) for line in lines]
    parts = [part for part in parts if len(part) > 0]
    cols = len(parts[0])
    fixed = [parts[0]]
    # Reverse to use .pop()
    to_fix = list(reversed(parts[1:]))
    while len(to_fix) > 0:
        new_line = to_fix.pop()
        # -1 because we concat last column with the first of next row
        while len(to_fix) > 0 and len(new_line) + len(to_fix[-1]) - 1 <= cols:
            # First column of next row we join with last column of previous
            new_line[-1] = new_line[-1] + to_fix[-1][0]
            new_line = new_line + to_fix.pop()[1:]
        if len(new_line) != cols:
            raise Exception('Function cannot fix file')
        fixed.append(new_line)
    fixed_lines = [delim.join(row) + '\n' for row in fixed]
    output_handle.writelines(fixed_lines)


def load_metadata_table(compressed_metadata):
    with StringIO() as fixed_metadata_handle:
        with lzma.open(compressed_metadata, 'rt') as raw_metadata_handle:
            fix_metadata_table(raw_metadata_handle, fixed_metadata_handle)
            fixed_metadata_handle.seek(0)
        return pd.read_csv(fixed_metadata_handle, sep="\t", quoting=3)  # 3 = disabled


def fix_fasta_file(metadata, input_fasta_path, output_fasta_path, missing_fasta_ids):
    if len(missing_fasta_ids) == 0:
        return

    with lzma.open(input_fasta_path, 'rt') as raw_fasta_handle:
        lines = raw_fasta_handle.readlines()

    # Just check if order and values of keys are the same as in metadata
    # fasta files can contain duplicated keys
    fasta_keys = [l[1:].replace('\n', '') for l in lines if l.startswith('>')]
    assert metadata['strain'].tolist() == fasta_keys

    # Create fasta file in buffor with gisaid accession_id as key
    with StringIO() as tmp_fasta_handle:
        header_counter = 0
        for line in lines:
            if line.startswith('>'):
                row = metadata.iloc[header_counter]
                tmp_fasta_handle.write('>' + row['gisaid_epi_isl'] + '\n')
                header_counter += 1
            else:
                tmp_fasta_handle.write(line)
        tmp_fasta_handle.seek(0)
        full_fasta = FastaFile.read(tmp_fasta_handle)

    output_fasta = FastaFile()
    metadata = metadata.set_index('gisaid_epi_isl')
    for accession_id in full_fasta.keys():
        if accession_id in missing_fasta_ids:
            row = metadata.loc[accession_id]
            new_key = '|'.join([row['strain'], accession_id, str(row['date'])])
            output_fasta[new_key] = full_fasta[accession_id]
    output_fasta.write(output_fasta_path)


def load_from_tar(tar_file, output_fasta_path, missing_fasta_ids):
    with tarfile.open(tar_file) as tar_handle:
        members = tar_handle.getmembers()
        members.sort(key = operator.attrgetter('name'))
        # check if tar structure does not changed
        assert members[0].name.endswith('metadata.tsv.xz')
        assert members[1].name.endswith('sequences.fasta.xz')
        # extract handles for files
        compressed_metadata = tar_handle.extractfile(members[0])
        compressed_fasta = tar_handle.extractfile(members[1])
        # get pandas df from compressed metadata
        metadata = load_metadata_table(compressed_metadata)
        fix_fasta_file(metadata, compressed_fasta, output_fasta_path, missing_fasta_ids)
        return metadata
