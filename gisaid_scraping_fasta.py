#!/usr/bin/env python3
# coding: utf-8

import os
import time

from secret import elogin, epass  # file secret.py with credentials
from selenium import webdriver
from selenium.webdriver.common.keys import Keys

url = "https://@epicov.org/epi3/"

profile = webdriver.FirefoxProfile()
profile.set_preference("browser.download.folderList", 2)
profile.set_preference("browser.download.manager.useWindow", False)
profile.set_preference("browser.download.dir", os.getcwd() + "/gisaid_data")
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

# login
driver.find_element_by_id("elogin").send_keys(elogin)
driver.find_element_by_id("epassword").send_keys(epass)
driver.find_element_by_class_name("form_button_submit").click()
time.sleep(3)

# navigate to search
driver.find_elements_by_class_name("sys-actionbar-action")[1].click()
time.sleep(3)

# filter
driver.find_element_by_id("ce_qpcb0m_a2_entry").send_keys("Europe / Poland")
time.sleep(4)

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

time.sleep(5)
driver.close()
