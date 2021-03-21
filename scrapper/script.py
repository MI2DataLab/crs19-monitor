#!/usr/bin/env python3
# coding: utf-8

import glob
import os
import time
import shutil
import re
import datetime
import math

from selenium import webdriver
from selenium.webdriver.common.keys import Keys
import pandas as pd
import sqlite3

from secret import elogin, epass  # file secret.py with credentials


def get_number_of_files(dir):
    if os.path.exists(dir):
        files = [f for f in os.listdir("./gisaid_data") if ".part" not in f]
        n_files = len(os.listdir("./gisaid_data"))
    else:
        n_files = 0
    return n_files

def get_driver(region = None, download_dir = None):
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

    options = webdriver.firefox.options.Options()
    # comment to allow firefox window
    options.add_argument("--headless")

    driver = webdriver.Firefox(
        executable_path="./geckodriver", firefox_profile=profile, options=options
    )
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

    return driver

def scrap_fasta(DB_PATH):
    
    con = sqlite3.connect(DB_PATH)
    cur = con.cursor()

    cur.execute("SELECT accession_id FROM metadata WHERE fasta_file IS NULL LIMIT 10000")
    part_ids = cur.fetchall()

    ids_str = ",".join([ p[0] for p in part_ids])

    download_dir = os.getcwd() + "/gisaid_data"
    n_files_before = get_number_of_files(download_dir)
    driver = get_driver(None, download_dir)

    try:
        driver.find_elements_by_class_name("sys-form-button")[2].click()
        wait_for_timer(driver)

        print("Switching to iframe")
        iframe = driver.find_element_by_class_name("sys-overlay-style")
        driver.switch_to.frame(iframe)
        time.sleep(1)

        readed_records = driver.find_element_by_class_name("sys-event-hook.sys-fi-mark.sys-form-fi-multiline").send_keys(ids_str)
        wait_for_timer(driver)

        driver.find_elements_by_class_name("sys-form-button")[1].click()
        buttons = driver.find_elements_by_class_name("sys-form-button")

        if len(buttons) == 3:
            #message dialog
            driver.find_element_by_xpath(("//button[contains(., 'OK')]")).click()
            time.sleep(1)
            driver.switch_to_default_content()

        print("Downloading fasta file")
        driver.find_elements_by_class_name("sys-form-button")[4].click()
        wait_for_timer(driver)

        # switch to frame
        iframe = driver.find_element_by_tag_name("iframe").get_attribute("id")
        driver.switch_to.frame(iframe)
        time.sleep(1)
        driver.find_elements_by_class_name("sys-event-hook.sys-form-button")[1].click()

        while get_number_of_files(download_dir) == n_files_before:
            # sleep until file is downloaded
            time.sleep(1)

        time.sleep(1)
    except:
        driver.save_screenshot(str(int(time.time() * 1000)) + ".png")
    driver.close()

    list_of_files = glob.glob(
            download_dir + "/*"
    ) 
    fasta = max(list_of_files, key=os.path.getmtime)
    time_file = str(int(time.time() * 1000))
    move_fast = os.environ["FASTA_FILE_DIR"] + "/" + time_file + ".fasta"
    shutil.move(fasta, move_fasta)

    for p in part_ids: 
        cur.execute("UPDATE metadata SET fast_file=? WHERE accession_id=?", (time_file, p[0]))

    con.commit()
    con.close()

    return len(part_ids)

def manage_fasta_scrapping(DB_PATH):
    while scrap_fasta(DB_PATH) == 10**4:
        pass

def get_elem_or_None(driver,class_name):
    try:
        elem = driver.find_element_by_class_name(class_name)
    except:
        elem = None
    return elem

def is_spinning(driver, class_name):
    elem = get_elem_or_None(driver, class_name)
    return elem is not None and list(elem.rect.values()) != [0,0,0,0]

def wait_for_timer(driver):
    time.sleep(5)
    while is_spinning(driver, "sys_timer_img") or is_spinning(driver, "small_spinner"):
        time.sleep(1)
        
def set_region(driver, region):
    driver.find_element_by_class_name("sys-event-hook.sys-fi-mark.yui-ac-input").clear()
    #wait_for_timer(driver)
    
    print("Setting region to ", region)
    driver.find_element_by_class_name("sys-event-hook.sys-fi-mark.yui-ac-input").send_keys(region)
    wait_for_timer(driver)
    
    return

def scrap_meta_table(region, db_path, start_date, end_date):

    try:
        driver = get_driver()
        set_region(driver, region)

        con = sqlite3.connect(db_path)
        cur = con.cursor()

        print("Scrapping date from ", start_date, "to ", end_date)
        driver.find_elements_by_class_name("sys-event-hook.sys-fi-mark.hasDatepicker")[2].send_keys(start_date.strftime('%Y-%m-%d'))
        driver.find_elements_by_class_name("sys-event-hook.sys-fi-mark.hasDatepicker")[3].send_keys(end_date.strftime('%Y-%m-%d'))
        wait_for_timer(driver)

        total_records = driver.find_element_by_class_name("sys-datatable-info-left").text
        total_records = int(re.sub(r'[^0-9]*', "", total_records))
        if total_records == 0:
            print("No records found")
            return

        expected_pages = math.ceil(total_records / 50)
        pages_list = []

        last_readed_page = 1

        while True:

            page = driver.find_element_by_class_name("yui-dt-bd").get_attribute("innerHTML")
            df = pd.read_html(page)[0]

            pages_list.append(df)

            #get current page number
            page_num = int(driver.find_element_by_class_name("yui-pg-current-page.yui-pg-page").text)
            print("Scrapping page %s / %s" %(page_num,expected_pages))

            # stop if reached last page
            if not ('href' in driver.find_element_by_class_name("yui-pg-next").get_attribute("outerHTML")):
                print("Got to last page, exiting")
                break
            
            # go to next page
            driver.find_element_by_class_name("yui-pg-next").click()

            page_loading_counter = 0
            while last_readed_page == page_num:
                time.sleep(0.5)
                page_num = int(driver.find_element_by_class_name("yui-pg-current-page.yui-pg-page").text)
                page_loading_counter += 1
                if page_loading_counter == 30:
                    raise Exception("Scrapping same page twice for 15s")

            last_readed_page = page_num

     except:
         driver.save_screenshot(str(int(time.time() * 1000)) + ".png")


    driver.close()
        
    meta_df = pd.concat(pages_list)
        # drop column of checkboxes and symbol
    meta_df = meta_df.drop(['Unnamed: 0', 'Unnamed: 6'], axis=1)
    
    df_clean = meta_df.drop_duplicates()

    for index, row in df_clean.iterrows():
        country = row['Location'].split(" / ")[1]
        cur.execute(""" INSERT INTO metadata (accession_id, 
                                                passage,
                                                submission_date,
                                                collection_date,
                                                host,
                                                location,
                                                originating_lab,
                                                submitting_lab,
                                                country) VALUES (?,?,?,?,?,?,?,?,?)""", 
                                                (row['Accession ID'],
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

def manage_table_scrapping(DB_PATH, region):

    LAST_START_DATE = datetime.date(2021, 2, 10)
    MAX_DATE_RANGE = 10

    if start_date is None:
        start_date = LAST_START_DATE
    else:
        start_date = datetime.datetime.strptime(start_date, '%Y-%m-%d').date()
        start_date = start_date - datetime.timedelta(days=3)

    end_date = min(datetime.date.today(), start_date + datetime.timedelta(days = MAX_DATE_RANGE))

    scrap_meta_table(region, DB_PATH, start_date, end_date)


if __name__ == "__main__":

    DB_PATH = "gisaid_meta.db"
    manage_table_scrapping(DB_PATH, "Europe / Poland")
    manage_fasta_scrapping(DB_PATH)
