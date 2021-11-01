import glob
import os
import sqlite3
import time
import shutil
import math
from datetime import datetime

from api import Api
from utils import get_number_of_files, load_from_tar, repeater

SEQ_LIMIT = 5000


def manage_fasta_scrapping(db_path, fasta_files_dir, download_dir, log_dir, credentials):
    """
    Loop fasta scrapping
    """
    repeater(scrap_fasta_augur, db_path, fasta_files_dir, download_dir, log_dir, credentials)
    repeater(scrap_fasta, db_path, fasta_files_dir, download_dir, log_dir, credentials)


def scrap_fasta_augur(db_path, fasta_files_dir, download_dir, log_dir, credentials):
    """
    Downloads fasta files and updates them in given database
    """
    today = datetime.today().strftime('%Y-%m-%d')

    def get_next_ids(cur):
        # get ids from db without fasta file
        cur.execute("SELECT accession_id, (fasta_file IS NULL), (is_meta_loaded == 0) FROM metadata WHERE (fasta_file IS NULL OR is_meta_loaded == 0) AND last_meta_load_try < ? ORDER BY RANDOM() LIMIT ?", (today, SEQ_LIMIT))
        part_ids = cur.fetchall()
        missing_fasta_ids = [p[0] for p in part_ids if p[1]]
        missing_meta_ids = [p[0] for p in part_ids if p[2]]
        part_ids = [p[0] for p in part_ids]
        return part_ids, missing_fasta_ids, missing_meta_ids

    # connect to db
    con = sqlite3.connect(db_path)
    cur = con.cursor()

    cur.execute("SELECT COUNT(*) FROM metadata WHERE (fasta_file IS NULL OR is_meta_loaded == 0) AND last_meta_load_try < ?", (today, ))
    todo_count = math.ceil(cur.fetchall()[0][0] / SEQ_LIMIT)

    if todo_count == 0:
        con.close()
        return

    iteration = 0
    with Api(credentials, log_dir, download_dir) as api:
        while True:
            part_ids, missing_fasta_ids, missing_meta_ids = get_next_ids(cur)
            if len(part_ids) == 0:
                con.close()
                return

            iteration += 1
            api.print_log('[%s / %s] Downloading tar file' % (iteration, todo_count))
            n_files_before = get_number_of_files(download_dir)
            # filter ids
            api.select_accession_ids(part_ids)
            api.print_log("Initializing download")
            # start downloading
            api.start_downloading_augur()
            api.print_log('Waiting for download to complete')

            # wait for new file in download directory
            fail_counter = 0
            while get_number_of_files(download_dir) == n_files_before:
                # sleep until file is downloaded
                time.sleep(1)
                fail_counter += 1
                if fail_counter == 240:
                    for accession_id in part_ids:
                        cur.execute("UPDATE metadata SET last_meta_load_try = ? WHERE accession_id=?", (today, accession_id))
                    con.commit()
                    con.close()
                    raise Exception('Downloading timeout')

            # get last modified file
            list_of_files = glob.glob(download_dir + "/*")
            downloaded = max(list_of_files, key=os.path.getmtime)

            # wait for downloaded file to complete
            last_size = os.path.getsize(downloaded)
            time.sleep(10)
            while os.path.exists(downloaded) and last_size < os.path.getsize(downloaded):
                last_size = os.path.getsize(downloaded)
                time.sleep(10)
            if downloaded.endswith('.part'):
                downloaded = downloaded[:-5]

            time.sleep(1)

            time_id = str(int(time.time() * 1000))
            metadata = load_from_tar(downloaded, fasta_files_dir + "/" + time_id + ".fasta", missing_fasta_ids).set_index('gisaid_epi_isl')

            # update fasta file path in db
            for accession_id in missing_fasta_ids:
                cur.execute("UPDATE metadata SET fasta_file=? WHERE accession_id=?", (time_id, accession_id))

            # update metadata
            for accession_id in missing_meta_ids:
                if accession_id in metadata.index:
                    meta = metadata.loc[accession_id]
                    cur.execute("UPDATE metadata SET sex=?, age=?, clade=?, gisaid_pango=?, is_meta_loaded=1, last_meta_load_try = ? WHERE accession_id=?", (meta['sex'], meta['age'], meta['GISAID_clade'], meta['pangolin_lineage'], today, accession_id))
                else:
                    cur.execute("UPDATE metadata SET is_meta_loaded=1, last_meta_load_try = ? WHERE accession_id=?", (today, accession_id))

            con.commit()
    con.close()


def scrap_fasta(db_path, fasta_files_dir, download_dir, log_dir, credentials):
    """
    Downloads fasta files and updates them in given database
    """

    # connect to db
    con = sqlite3.connect(db_path)
    cur = con.cursor()

    def get_next_ids(cur):
        # get ids from db without fasta file
        cur.execute("SELECT accession_id FROM metadata WHERE fasta_file IS NULL ORDER BY submission_date DESC LIMIT ?", (SEQ_LIMIT,))
        part_ids = cur.fetchall()
        return [p[0] for p in part_ids]

    cur.execute("SELECT COUNT(*) FROM metadata WHERE fasta_file IS NULL OR is_meta_loaded == 0")
    todo_count = math.ceil(cur.fetchall()[0][0] / SEQ_LIMIT)

    if todo_count == 0:
        con.close()
        return

    iteration = 0
    with Api(credentials, log_dir, download_dir) as api:
        while True:
            part_ids = get_next_ids(cur)
            # handle empty list
            if len(part_ids) == 0:
                con.close()
                return

            iteration += 1
            api.print_log('[%s / %s] Downloading fasta file' % (iteration, todo_count))
            n_files_before = get_number_of_files(download_dir)
            # filter ids
            api.select_accession_ids(part_ids)
            api.print_log("Initializing download")
            # start downloading
            api.start_downloading_fasta()
            api.print_log('Waiting for download to complete')

            # wait for new file in download directory
            fail_counter = 0
            while get_number_of_files(download_dir) == n_files_before:
                # sleep until file is downloaded
                time.sleep(1)
                fail_counter += 1
                if fail_counter == 60:
                    api.print_log('Downloading timeout')
                    con.close()
                    raise Exception('Downloading timeout')

            # get last modified file
            list_of_files = glob.glob(download_dir + "/*")
            downloaded = max(list_of_files, key=os.path.getmtime)

            # wait for downloaded file to complete
            last_size = os.path.getsize(downloaded)
            time.sleep(10)
            while os.path.exists(downloaded) and last_size < os.path.getsize(downloaded):
                last_size = os.path.getsize(downloaded)
                time.sleep(10)
            if downloaded.endswith('.part'):
                downloaded = downloaded[:-5]

            time.sleep(1)

            time_id = str(int(time.time() * 1000))
            shutil.copyfile(downloaded, fasta_files_dir + '/' + time_id + '.fasta')

            for accession_id in part_ids:
                cur.execute("UPDATE metadata SET fasta_file=? WHERE accession_id=?", (time_id, accession_id))
            con.commit()
    con.close()
