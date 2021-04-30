import time
import re
import pandas as pd
from selenium.webdriver.common.action_chains import ActionChains
from selenium.common.exceptions import ElementClickInterceptedException

def get_elem_or_None(driver, class_name):
    """
    Returns element by class_name or None if it doesn't exist
    """
    try:
        elem = driver.find_element_by_class_name(class_name)
    except:
        elem = None
    return elem

def get_elements_or_empty(driver, class_name):
    """
    Returns elements by class_name or [] if there is none
    """
    try:
        elems = driver.find_elements_by_class_name(class_name)
    except:
        elems = []
    return elems

def is_spinning(driver, class_name):
    """
    Returns bool if element with class_name is visible
    """
    elems = get_elements_or_empty(driver, class_name)
    for elem in elems:
        if elem is not None and list(elem.rect.values()) != [0, 0, 0, 0]:
            return True
    return False

def find_and_switch_to_iframe(driver):
    print("Switching to iframe")
    wait_for_timer(driver)
    iframe = driver.find_element_by_class_name("sys-overlay-style")
    driver.switch_to.frame(iframe)
    time.sleep(1)
    wait_for_timer(driver)
    return

def action_click(driver, element):
    action = ActionChains(driver)
    try:
        action.move_to_element(element).perform()
        element.click()
    except ElementClickInterceptedException:
        driver.execute_script(
            "document.getElementById('sys_curtain').remove()")
        action.move_to_element(element).perform()
        element.click()

def wait_for_timer(driver):
    """
    Sleeps until "sys_timer_img" and "small_spinner" are visible
    """
    time.sleep(5)
    while is_spinning(driver, "sys_timer_img") or is_spinning(driver, "small_spinner"):
        time.sleep(1)

def set_region(driver, region):
    """
    Filters by given region
    """
    print("Setting region to ", region)

    input_region = driver.find_element_by_class_name("sys-event-hook.sys-fi-mark.yui-ac-input")

    total_records_before_filter = get_total_records(driver)
    input_region.clear()
    input_region.send_keys(region)
    wait_for_timer(driver)
    total_records = get_total_records(driver)

    if total_records != 0 and total_records >= total_records_before_filter:
        raise Exception('Number of records didn\'t changed after filtering by region')
    
    return

def set_date(driver, start_date, end_date):
    """
    Filters by given dates
    """
    input_start = driver.find_elements_by_class_name("sys-event-hook.sys-fi-mark.hasDatepicker")[2]
    input_end = driver.find_elements_by_class_name("sys-event-hook.sys-fi-mark.hasDatepicker")[3]
    total_records_before_filter = get_total_records(driver)

    print("Setting date to ", start_date, ":", end_date)
    input_start.clear()
    input_start.send_keys(start_date.strftime('%Y-%m-%d'))

    input_end.clear()
    input_end.send_keys(end_date.strftime('%Y-%m-%d'))

    wait_for_timer(driver)
    total_records = get_total_records(driver)
    if total_records != 0 and total_records >= total_records_before_filter:
        raise Exception('Number of records didn\'t changed after filtering by date')
    print("Date set")

def get_total_records(driver):
    total_records = driver.find_element_by_class_name("sys-datatable-info-left").text
    total_records = int(re.sub(r'[^0-9]*', "", total_records))
    return total_records

def get_page_table(driver):
    page = driver.find_element_by_class_name("yui-dt-bd").get_attribute("innerHTML")
    df = pd.read_html(page)[0]
    # drop column of checkboxes and symbol
    df = df.drop(['Unnamed: 0', 'Unnamed: 6'], axis=1)
    return df

def get_accesion_ids(driver):
    time.sleep(1)
    wait_for_timer(driver)

    total_records = get_total_records(driver)
    if total_records == 0:
        return []
    elif total_records <= 50:
        return get_page_table(driver)['Accession ID'].tolist()

    checkbox = driver.find_elements_by_xpath("//input[starts-with(@type, 'checkbox')]")[5]
    if checkbox.get_property('checked') is False:
        print("Checkbox not checked, checking")
        checkbox.click()
        wait_for_timer(driver)
    else:
        print("Checkbox checked from last search, unchecking")
        checkbox.click()
        wait_for_timer(driver)

        print("Checkbox checking")
        checkbox.click()
        wait_for_timer(driver)


    driver.find_element_by_xpath(("//button[contains(., 'Select')]")).click()
    wait_for_timer(driver)

    find_and_switch_to_iframe(driver)
    readed_records = driver.find_element_by_class_name("sys-event-hook.sys-fi-mark.sys-form-fi-multiline").text.split(", ")

    if readed_records == ['']:
        readed_records = []
    
    if len(readed_records) != total_records:
        raise Exception("Readed records ({})!= Total records({})".format(len(readed_records), total_records))

    print("Switching to default_content")
    driver.find_element_by_xpath(("//button[contains(., 'Back')]")).click()
    wait_for_timer(driver)
    driver.switch_to.default_content()
    
    return readed_records
