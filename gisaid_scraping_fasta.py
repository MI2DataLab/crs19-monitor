#!/usr/bin/env python3
# coding: utf-8

import glob
import os
import time

from selenium import webdriver
from selenium.webdriver.common.keys import Keys

from secret import elogin, epass  # file secret.py with credentials


def get_number_of_files(dir):
    if os.path.exists(dir):
        n_files = len(os.listdir("./gisaid_data"))
    else:
        n_files = 0
    return n_files


def scrap_fasta():

    url = "https://@epicov.org/epi3/"
    download_dir = os.getcwd() + "/gisaid_data"

    profile = webdriver.FirefoxProfile()
    profile.set_preference("browser.download.folderList", 2)
    profile.set_preference("browser.download.manager.useWindow", False)
    profile.set_preference("browser.download.dir", download_dir)
    profile.set_preference(
        "browser.helperApps.neverAsk.saveToDisk", "application/octet-stream"
    )

    options = webdriver.firefox.options.Options()
    # comment to allow firefox window
    options.add_argument("--headless")

    n_files_before = get_number_of_files(download_dir)

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
    ).send_keys("Europe / Poland")
    time.sleep(4)

    driver.execute_script("document.getElementById('sys_curtain').remove()")

    # select all
    driver.find_elements_by_xpath("//input[starts-with(@type, 'checkbox')]")[5].click()
    time.sleep(10)

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
    )  # * means all if need specific format then *.csv
    fasta = max(list_of_files, key=os.path.getmtime)

    return fasta


if __name__ == "__main__":
    scrap_fasta()
