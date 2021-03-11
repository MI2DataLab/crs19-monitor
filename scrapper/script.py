#!/usr/bin/env python3
# coding: utf-8

import glob
import os
import time
import shutil

from selenium import webdriver
from selenium.webdriver.common.keys import Keys
import pandas as pd

from secret import elogin, epass  # file secret.py with credentials


def get_number_of_files(dir):
    if os.path.exists(dir):
        n_files = len(os.listdir("./gisaid_data"))
    else:
        n_files = 0
    return n_files


def get_driver(download_dir, region):
    """
    Returns firefox driver logged to https://@epicov.org/epi3/ 
    @param region - used to filtered by Location for example "Europe / Poland" 
    """

    url = "https://@epicov.org/epi3/"
    
    profile = webdriver.FirefoxProfile()
    profile.set_preference("browser.download.folderList", 2)
    profile.set_preference("browser.download.manager.useWindow", False)
    profile.set_preference("browser.download.dir", download_dir)
    profile.set_preference(
        "browser.helperApps.neverAsk.saveToDisk", "application/octet-stream"
    )

    options = webdriver.firefox.options.Options()
    # comment to allow firefox window
    #options.add_argument("--headless")

    driver = webdriver.Firefox(
        executable_path="./geckodriver", firefox_profile=profile, options=options
    )
    driver.get(url)
    time.sleep(3)

    # login
    driver.find_element_by_id("elogin").send_keys(elogin)
    driver.find_element_by_id("epassword").send_keys(epass)
    driver.find_element_by_class_name("form_button_submit").click()
    time.sleep(3)

    # navigate to search
    driver.find_elements_by_class_name("sys-actionbar-action")[1].click()
    time.sleep(3)

    # filter
    driver.find_element_by_class_name(
        "sys-event-hook.sys-fi-mark.yui-ac-input"
    ).send_keys(region)
    time.sleep(4)

    driver.execute_script("document.getElementById('sys_curtain').remove()")

    return driver

def scrap_fasta():
    """
    Downloads fasta file from https://@epicov.org/epi3/
    Filtered by Location: Europe / Poland
    """

    download_dir = os.getcwd() + "/gisaid_data"
    n_files_before = get_number_of_files(download_dir)
    driver = get_driver(download_dir)

    # select all
    driver.find_elements_by_xpath("//input[starts-with(@type, 'checkbox')]")[5].click()
    time.sleep(20)

    # download
    driver.find_elements_by_class_name("sys-form-button")[4].click()
    time.sleep(3)

    # switch to frame
    iframe = driver.find_element_by_tag_name("iframe").get_attribute("id")
    driver.switch_to.frame(iframe)
    time.sleep(3)
    driver.find_elements_by_class_name("sys-event-hook.sys-form-button")[1].click()

    while get_number_of_files(download_dir) == n_files_before:
        # sleep until file is downloaded
        time.sleep(1)

    time.sleep(1)
    driver.close()

    list_of_files = glob.glob(
        download_dir + "/*"
    ) 
    fasta = max(list_of_files, key=os.path.getmtime)

    if os.environ["FASTA_FILE_PATH"]:
        shutil.copyfile(fasta, os.environ["FASTA_FILE_PATH"])

    return fasta

def scrap_meta_table():
    """
    Scraps https://@epicov.org/epi3/ table with metadata
    """
    download_dir = os.getcwd() + "/gisaid_data"
    driver = get_driver(download_dir)

    # scrap first page
    page = driver.find_element_by_class_name("yui-dt-bd").get_attribute("innerHTML")
    meta_df = pd.read_html(page)[0]

    # go to next page
    driver.find_element_by_class_name("yui-pg-next").click()

    while True:
        page = driver.find_element_by_class_name("yui-dt-bd").get_attribute("innerHTML")
        df = pd.read_html(page)[0]
        meta_df = pd.concat([meta_df, df])
        time.sleep(5)

        # stop if reached last page
        if not ('href' in driver.find_element_by_class_name("yui-pg-next").get_attribute("outerHTML")):
            break

        # go to next page
        driver.find_element_by_class_name("yui-pg-next").click()
        time.sleep(5)
    
    time.sleep(2)
    driver.close()
    
    # drop column of checkboxes and symbol
    df = df.drop(['Unnamed: 0', 'Unnamed: 6'], axis=1)

    df_clean = df.drop_duplicates()

    df_clean.to_csv(os.environ["META_FILE_PATH"])

    return os.environ["META_FILE_PATH"]

def scrap_meta_details():
    driver = get_driver(".")


if __name__ == "__main__":
#    scrap_fasta()
#    scrap_meta_table()
    scrap_meta_details()