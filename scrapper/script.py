#!/usr/bin/env python3
# coding: utf-8
import glob
import os
import time
import shutil
import re
import datetime
import math
import sys
import traceback

from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.action_chains import ActionChains
import pandas as pd
import sqlite3
from utils import *

from selenium.common.exceptions import NoAlertPresentException, MoveTargetOutOfBoundsException,TimeoutException, ElementClickInterceptedException, StaleElementReferenceException, WebDriverException, NoSuchWindowException

from secret import elogin, epass  # file secret.py with credentials


def get_driver(region = None, download_dir = None, headless = True):
    """
    Returns firefox driver logged to https://@epicov.org/epi3/ 
    @param region - used to filtered by Location for example "Europe / Poland" 
    """
    print("Setting up driver")
    url = "https://@epicov.org/epi3/"
    
    profile = webdriver.FirefoxProfile()
    profile.set_preference("browser.download.folderList", 2)
    profile.set_preference("browser.download.manager.useWindow", False)
    if download_dir is not None:
        profile.set_preference("browser.download.dir", download_dir)
    profile.set_preference(
        "browser.helperApps.neverAsk.saveToDisk", "application/octet-stream"
    )
    profile.set_preference(
        "browser.helperApps.neverAsk.saveToDisk", "application/x-tar"
    )

    options = webdriver.firefox.options.Options()
    # comment to allow firefox window
    if headless:
        options.add_argument("--headless")

    driver = webdriver.Firefox(
        executable_path="./geckodriver", firefox_profile=profile, options=options
    )
    try:
        driver.get(url)
        time.sleep(3)

        print("Logging in as ", elogin)
        # login
        driver.find_element_by_id("elogin").send_keys(elogin)
        driver.find_element_by_id("epassword").send_keys(epass)
        driver.find_element_by_class_name("form_button_submit").click()
        time.sleep(3)

        # navigate to search
        driver.find_elements_by_class_name("sys-actionbar-action")[1].click()
        time.sleep(3)

        if region is not None:
            set_region(driver, region)

        driver.execute_script("document.getElementById('sys_curtain').remove()")

    except Exception as e:
        name = str(int(time.time() * 1000))
        driver.save_screenshot(name + ".png")
        with open(name + '.html', 'w') as f:
            f.write(driver.page_source)

        driver.quit()
        raise e

    return driver

def scrap_fasta(db_path, fasta_files_dir, download_dir = None):
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

    ids_str = ",".join([ p[0] for p in part_ids])

    if download_dir is None:
        download_dir = os.getcwd() + "/gisaid_data"
    n_files_before = get_number_of_files(download_dir)
    driver = get_driver(None, download_dir)

    try:
        driver.find_element_by_xpath(("//button[contains(., 'Select')]")).click()
        wait_for_timer(driver)

        find_and_switch_to_iframe(driver)

        readed_records = driver.find_element_by_class_name("sys-event-hook.sys-fi-mark.sys-form-fi-multiline").send_keys(ids_str)
        wait_for_timer(driver)

        driver.find_element_by_xpath(("//button[contains(., 'OK')]")).click()
        time.sleep(3)
        try:
            buttons = driver.find_elements_by_class_name("sys-form-button")

            if len(buttons) == 4:
                #message dialog
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
        name = str(int(time.time() * 1000))
        driver.save_screenshot(name + ".png")
        with open(name + '.html', 'w') as f:
            f.write(driver.page_source)
        driver.quit()
        raise e
    driver.quit()

    time_file = str(int(time.time() * 1000))
    metadata = load_from_tar(tar, fasta_files_dir + "/" + time_file + ".fasta", missing_fasta_ids).set_index('gisaid_epi_isl')

    for accession_id in missing_fasta_ids:
        meta = metadata[accession_id,:]
        cur.execute("UPDATE metadata SET fasta_file=? WHERE accession_id=?", (time_file, accession_id))

    for accession_id in missing_meta_ids:
        meta = metadata[accession_id,:]
        cur.execute("UPDATE metadata SET sex=?, age=?, is_meta_loaded=1 WHERE accession_id=?", (meta['sex'], meta['age'], accession_id))

    con.commit()
    con.close()

    return len(part_ids)

def scrap_fasta_repeater(db_path, fasta_files_dir):
    """
    Loop scrapping fasta
    """
    repeats = 15
    for i in range(repeats):
        try:
            done = scrap_fasta(db_path, fasta_files_dir)
            return done
        except Exception as e:
            exc_info = sys.exc_info()
            if i == repeats - 1:
                raise e
            else:
                traceback.print_exception(*exc_info)
            del exc_info
            print('%s try failed' % (i,))

def manage_fasta_scrapping(db_path, fasta_files_dir):
    """
    Loop fasta scrapping
    """
    while scrap_fasta_repeater(db_path, fasta_files_dir) == 10**4:
        pass

class ScrappingMetaHistory:
    def __init__(self):
        self.pages_list = []
        self.last_done_page = 0
    def add_page(self, page_num, data):
        if page_num != self.last_done_page + 1:
            raise Exception("page_num(%s) != last_done_page(%s) + 1" % (page_num, self.last_done_page))
        self.pages_list.append(data)
        self.last_done_page = page_num

def scrap_meta_table(region, db_path, start_date, end_date, history):
    """
    Uploads metadata from table to given database
    Filters from start_date and end_date
    """
    if end_date < start_date:
        print('Skipping, invalid date range')
        return
    try:
        driver = get_driver()
        set_region(driver, region)

        con = sqlite3.connect(db_path)
        cur = con.cursor()

        cur.execute("SELECT COUNT(*) FROM metadata WHERE submission_date <= ? AND submission_date >= ?", (end_date, start_date))
        total_records_in_db = cur.fetchone()[0]
        con.commit()
        
        # read total_records from left bottom corner
        total_records_before_filter = driver.find_element_by_class_name("sys-datatable-info-left").text
        total_records_before_filter = int(re.sub(r'[^0-9]*', "", total_records_before_filter))

        # filter by date 
        print("Scrapping date from ", start_date, "to ", end_date)
        driver.find_elements_by_class_name("sys-event-hook.sys-fi-mark.hasDatepicker")[2].send_keys(start_date.strftime('%Y-%m-%d'))
        driver.find_elements_by_class_name("sys-event-hook.sys-fi-mark.hasDatepicker")[3].send_keys(end_date.strftime('%Y-%m-%d'))
        wait_for_timer(driver)

        # read total_records from left bottom corner
        total_records = driver.find_element_by_class_name("sys-datatable-info-left").text
        total_records = int(re.sub(r'[^0-9]*', "", total_records))
        if total_records == 0:
            print("No records found")
            driver.quit()
            return
        elif total_records <= total_records_in_db:
            print('Skipping range %s : %s because total_records[%s] <= total_records_in_db[%s]' % (start_date, end_date, total_records, total_records_in_db))
            driver.quit()
            return
        elif total_records == total_records_before_filter:
            # handle unresponsive gisaid
            raise Exception('Number of records didn\'t changed after filtering by date')
        expected_pages = math.ceil(total_records / 50)

        # go to last readed page 
        if history.last_done_page != 0:
            driver.execute_script('document.getElementsByClassName("yui-pg-page")[1].setAttribute("page", %s)' % (history.last_done_page + 1,))
            time.sleep(3)
            driver.find_elements_by_class_name("yui-pg-page")[1].click()
            time.sleep(30)
        
        last_readed_page = history.last_done_page + 1

        while True:
                
            #get current page number
            page_num = int(driver.find_element_by_class_name("yui-pg-current-page.yui-pg-page").text)
            
            print("Scrapping page %s / %s (%s%%)" %(page_num, expected_pages, ((10**4 * page_num) // expected_pages) / 10**2 ))
            
            page = driver.find_element_by_class_name("yui-dt-bd").get_attribute("innerHTML")
            df = pd.read_html(page)[0]
            
            #get page number after read
            page_num_post = int(driver.find_element_by_class_name("yui-pg-current-page.yui-pg-page").text)
            
            if page_num != page_num_post:
                raise Exception('Page skipped while reading')

            history.add_page(page_num, df)
            
            # stop if reached last page
            if not ('href' in driver.find_element_by_class_name("yui-pg-next").get_attribute("outerHTML")):
                print("Got to last page, exiting")
                break
            
            # go to next page
            driver.find_element_by_class_name("yui-pg-next").click()

            # sleep until gisaid changes next-page attribute and go to next page
            page_loading_counter = 0
            while last_readed_page == page_num:
                time.sleep(0.5)
                try:
                    page_num = int(driver.find_element_by_class_name("yui-pg-current-page.yui-pg-page").text)
                except:
                    page_num = int(driver.find_element_by_class_name("yui-pg-current-page.yui-pg-page").text)
                page_loading_counter += 1
                if page_loading_counter == 120:
                    raise Exception("Scrapping same page twice for 60s")

            last_readed_page = page_num
    except Exception as e:
        name = str(int(time.time() * 1000))
        driver.save_screenshot(name + ".png")
        with open(name + '.html', 'w') as f:
            f.write(driver.page_source)
        driver.quit()
        raise e


    driver.quit()
        
    meta_df = pd.concat(history.pages_list)
    # drop column of checkboxes and symbol
    meta_df = meta_df.drop(['Unnamed: 0', 'Unnamed: 6'], axis=1)
    
    df_clean = meta_df.drop_duplicates()

    cur.execute("SELECT accession_id FROM metadata WHERE submission_date <= ? AND submission_date >= ?", (end_date, start_date))
    duplicated = [x[0] for x in cur.fetchall()]
    
    # upload to database
    for index, row in df_clean.iterrows():
        if row['Accession ID'] not in duplicated:
            country = extract_country(row['Location'])
            cur.execute("""INSERT INTO metadata (
                                                accession_id, 
                                                passage,
                                                submission_date,
                                                collection_date,
                                                host,
                                                location,
                                                originating_lab,
                                                submitting_lab,
                                                country
                                                ) VALUES (?,?,?,?,?,?,?,?,?)""", 
                                                (
                                                row['Accession ID'],
                                                row['Passage details/history'],
                                                row['Submission Date'],
                                                row['Collection date'],
                                                row['Host'],
                                                row['Location'],
                                                row['Originating lab'],
                                                row['Submitting lab'],
                                                country
                                                ))
    con.commit()
    con.close()
    return

def scrap_table_repeater(region, db_path, start_date, end_date):
    """
    Loop scrapping table
    """
    history = ScrappingMetaHistory()
    repeats = 15
    for i in range(repeats):
        try:
            scrap_meta_table(region, db_path, start_date, end_date, history)
            return
        except Exception as e:
            exc_info = sys.exc_info()
            if i == repeats - 1:
                raise e
            else:
                traceback.print_exception(*exc_info)
            del exc_info
            print('%s try failed' % (i,))

def manage_table_scrapping(db_path, minimum_start_date, max_date_range, region):
    """
    Handles date ranges for table scrapping
    """
    con = sqlite3.connect(db_path)
    cur = con.cursor()
    cur.execute("SELECT MAX(submission_date) FROM metadata")
    start_date = cur.fetchone()[0]
    con.close()

    if start_date is None:
        start_date = minimum_start_date
    else:
        start_date = datetime.datetime.strptime(start_date, '%Y-%m-%d').date()
        print('Scrapping 3 days before proper date range')
        scrap_table_repeater(region, db_path, start_date - datetime.timedelta(days=3), start_date - datetime.timedelta(days=1))
        print('Scrapping starting day')
        scrap_table_repeater(region, db_path, start_date, start_date)
        start_date = start_date + datetime.timedelta(days=1)

    end_date = min(datetime.date.today(), start_date + datetime.timedelta(days = max_date_range))

    scrap_table_repeater(region, db_path, start_date, end_date)


if __name__ == "__main__":
    DB_PATH = os.environ["DB_PATH"]
    FASTA_FILES_DIR = os.environ["FASTA_FILES_DIR"]
    MINIMUM_START_DATE = datetime.datetime.strptime(os.environ['MINIMUM_START_DATE'], '%Y-%m-%d').date()
    MAX_DATE_RANGE = int(os.environ['MAX_DATE_RANGE'])
    ROOT_REGION = os.environ['ROOT_REGION']
    
    init_db(DB_PATH)
    if not os.environ.get('SKIP_METATABLE'):
        manage_table_scrapping(DB_PATH, MINIMUM_START_DATE, MAX_DATE_RANGE, ROOT_REGION)
    if not os.environ.get('SKIP_FASTA'):
        manage_fasta_scrapping(DB_PATH, FASTA_FILES_DIR)
