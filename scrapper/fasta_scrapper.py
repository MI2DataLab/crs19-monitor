import glob
import os
import sqlite3
import time
import shutil

from api import Api
from utils import get_number_of_files, load_from_tar, repeater

SEQ_LIMIT = 5000


def manage_fasta_scrapping(db_path, fasta_files_dir, download_dir, log_dir, credentials):
    """
    Loop fasta scrapping
    """
    while repeater(scrap_fasta_augur, db_path, fasta_files_dir, download_dir, log_dir, credentials) == SEQ_LIMIT:
        pass

    while repeater(scrap_fasta, db_path, fasta_files_dir, download_dir, log_dir, credentials) == SEQ_LIMIT:
        pass

def scrap_fasta_augur(db_path, fasta_files_dir, download_dir, log_dir, credentials):
    """
    Downloads fasta files and updates them in given database
    """

    # connect to db
    con = sqlite3.connect(db_path)
    cur = con.cursor()

    # get ids from db without fasta file
    cur.execute("SELECT accession_id, (fasta_file IS NULL), (is_meta_loaded == 0) FROM metadata WHERE fasta_file IS NULL OR is_meta_loaded == 0 ORDER BY submission_date DESC LIMIT ?", (SEQ_LIMIT,))
    part_ids = cur.fetchall()
    missing_fasta_ids = [p[0] for p in part_ids if p[1]]
    missing_meta_ids = [p[0] for p in part_ids if p[2]]

    # handle empty list
    if len(part_ids) == 0:
        con.close()
        return 0

    n_files_before = get_number_of_files(download_dir)
    with Api(credentials, log_dir, download_dir) as api:
        api.select_accession_ids([p[0] for p in part_ids])

        api.print_log("Downloading tar file")
        api.start_downloading_augur()

        fail_counter = 0
        while get_number_of_files(download_dir) == n_files_before:
            # sleep until file is downloaded
            time.sleep(1)
            fail_counter += 1
            if fail_counter == 60:
                api.print_log('Downloading timeout')
                return 0


        list_of_files = glob.glob(download_dir + "/*")
        tar = max(list_of_files, key=os.path.getmtime)

        last_size = os.path.getsize(tar)
        time.sleep(20)
        while os.path.exists(tar) and last_size < os.path.getsize(tar):
            last_size = os.path.getsize(tar)
            time.sleep(1)
        if tar.endswith('.part'):
            tar = tar[:-5]

        time.sleep(1)

    time_file = str(int(time.time() * 1000))
    metadata = load_from_tar(tar, fasta_files_dir + "/" + time_file + ".fasta", missing_fasta_ids).set_index('gisaid_epi_isl')

    for accession_id in missing_fasta_ids:
        meta = metadata.loc[accession_id]
        cur.execute("UPDATE metadata SET fasta_file=? WHERE accession_id=?", (time_file, accession_id))

    for accession_id in missing_meta_ids:
        if accession_id in metadata.index:
            meta = metadata.loc[accession_id]
            cur.execute("UPDATE metadata SET sex=?, age=?, is_meta_loaded=1 WHERE accession_id=?", (meta['sex'], meta['age'], accession_id))
        else:
            cur.execute("UPDATE metadata SET is_meta_loaded=1 WHERE accession_id=?", (accession_id,))

    con.commit()
    con.close()

    return len(part_ids)

def scrap_fasta(db_path, fasta_files_dir, download_dir, log_dir, credentials):
    """
    Downloads fasta files and updates them in given database
    """

    # connect to db
    con = sqlite3.connect(db_path)
    cur = con.cursor()

    # get ids from db without fasta file
    cur.execute("SELECT accession_id FROM metadata WHERE fasta_file IS NULL ORDER BY submission_date DESC LIMIT ?", (SEQ_LIMIT,))
    part_ids = cur.fetchall()
    part_ids = [p[0] for p in part_ids]

    # handle empty list
    if len(part_ids) == 0:
        con.close()
        return 0

    n_files_before = get_number_of_files(download_dir)
    with Api(credentials, log_dir, download_dir) as api:
        api.select_accession_ids(part_ids)

        api.print_log("Downloading fasta file")
        api.start_downloading_fasta()

        fail_counter = 0
        while get_number_of_files(download_dir) == n_files_before:
            # sleep until file is downloaded
            time.sleep(1)
            fail_counter += 1
            if fail_counter == 60:
                api.print_log('Downloading timeout')
                return 0


        list_of_files = glob.glob(download_dir + "/*")
        fasta_file = max(list_of_files, key=os.path.getmtime)

        last_size = os.path.getsize(fasta_file)
        time.sleep(20)
        while os.path.exists(fasta_file) and last_size < os.path.getsize(fasta_file):
            last_size = os.path.getsize(tar)
            time.sleep(3)
        if fasta_file.endswith('.part'):
            fasta_file = fasta_file[:-5]

        time.sleep(1)

    time_id = str(int(time.time() * 1000))
    shutil.copyfile(fasta_file, fasta_files_dir + '/' + time_id + '.fasta')

    for accession_id in part_ids:
        cur.execute("UPDATE metadata SET fasta_file=? WHERE accession_id=?", (time_id, accession_id))

    con.commit()
    con.close()

    return len(part_ids)
