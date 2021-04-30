import sqlite3
import time
import os
import glob
from selenium.common.exceptions import NoSuchWindowException
from utils import repeater, get_driver, get_number_of_files, load_from_tar, save_log
from input_utils import find_and_switch_to_iframe, wait_for_timer


def manage_fasta_scrapping(db_path, fasta_files_dir, download_dir, log_dir):
    """
    Loop fasta scrapping
    """
    while repeater(scrap_fasta, db_path, fasta_files_dir, download_dir, log_dir) == 5 * (10**3):
        pass

def scrap_fasta(db_path, fasta_files_dir, download_dir, log_dir):
    """
    Downloads fasta files and updates them in given database
    """

    # connect to db
    con = sqlite3.connect(db_path)
    cur = con.cursor()

    # get ids from db without fasta file
    cur.execute("SELECT accession_id, (fasta_file IS NULL), (is_meta_loaded == 0) FROM metadata WHERE fasta_file IS NULL OR is_meta_loaded == 0 ORDER BY submission_date DESC LIMIT 5000")
    part_ids = cur.fetchall()
    missing_fasta_ids = [p[0] for p in part_ids if p[1]]
    missing_meta_ids = [p[0] for p in part_ids if p[2]]

    # handle empty list
    if len(part_ids) == 0:
        con.commit()
        con.close()
        return 0

    ids_str = ",".join([p[0] for p in part_ids])

    if download_dir is None:
        download_dir = os.getcwd() + "/gisaid_data"
    n_files_before = get_number_of_files(download_dir)
    driver = get_driver(log_dir, download_dir=download_dir)

    try:
        driver.find_element_by_xpath(("//button[contains(., 'Select')]")).click()
        wait_for_timer(driver)

        find_and_switch_to_iframe(driver)

        # readed_records = driver.find_element_by_class_name("sys-event-hook.sys-fi-mark.sys-form-fi-multiline").send_keys(ids_str)
        driver.find_element_by_class_name("sys-event-hook.sys-fi-mark.sys-form-fi-multiline").send_keys(ids_str)
        wait_for_timer(driver)

        driver.find_element_by_xpath(("//button[contains(., 'OK')]")).click()
        time.sleep(3)
        try:
            buttons = driver.find_elements_by_class_name("sys-form-button")

            if len(buttons) == 4:
                # message dialog
                driver.find_element_by_xpath(("//button[contains(., 'OK')]")).click()
                time.sleep(10)
                driver.switch_to.default_content()

        except NoSuchWindowException:
            driver.switch_to.default_content()
        
        print("Downloading tar file")
        driver.find_element_by_xpath(("//button[contains(., 'Download')]")).click()
        find_and_switch_to_iframe(driver)
        
        driver.find_element_by_xpath(("//input[@value='augur_input']")).click()
        wait_for_timer(driver)
        
        driver.find_element_by_xpath(("//button[contains(., 'Download')]")).click()

        while get_number_of_files(download_dir) == n_files_before:
            # sleep until file is downloaded
            time.sleep(1)

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
    except Exception as e:
        save_log(log_dir, driver)
        driver.quit()
        raise e
    driver.quit()

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
