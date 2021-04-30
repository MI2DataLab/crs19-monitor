import sqlite3
import datetime
import time
import numpy as np
from utils import repeater, get_driver, save_log
from input_utils import set_region, set_date, wait_for_timer, get_accesion_ids, get_total_records
from bs4 import BeautifulSoup
from selenium.webdriver.support.select import Select

class ScrappingVariantsHistory:
    def __init__(self):
        self.done = {}
    def set_done(self, category, name):
        if self.done.get(category) is None:
            self.done[category] = []
        self.done[category].append(name)
    def is_done(self, category, name):
        if self.done.get(category) is None:
            self.done[category] = []
        return name in self.done[category]

def manage_variants_scrapping(db_path, max_date_range, region, log_dir):
    """
    Handles date ranges for variant scrapping
    """
    con = sqlite3.connect(db_path)
    cur = con.cursor()
    cur.execute("SELECT COUNT(*) FROM metadata WHERE is_variant_loaded=0")
    if cur.fetchone()[0] == 0:
        print('All sequences have scrapped variants')
        return

    cur.execute("SELECT MIN(submission_date) FROM metadata WHERE is_variant_loaded=0")
    start_date = cur.fetchone()[0]
    con.close()

    start_date = datetime.datetime.strptime(start_date, '%Y-%m-%d').date()
    history = ScrappingVariantsHistory()
    end_date = min(datetime.date.today(), start_date + datetime.timedelta(days = max_date_range))

    repeater(scrap_variants, region, db_path, start_date, end_date, history, log_dir)

def scrap_variants(region, db_path, start_date, end_date, history, log_dir):
    if end_date < start_date:
        print('Skipping, invalid date range')
        return
    try:
        driver = get_driver(log_dir)
        set_region(driver, region)
        set_date(driver, start_date, end_date)

        con = sqlite3.connect(db_path)
        cur = con.cursor()
        total_records = get_total_records(driver)

        repeater(update_clade, driver, cur, con, history)
        assert get_total_records(driver) >= total_records

        repeater(update_substitusions, driver, cur, con, history)
        assert get_total_records(driver) >= total_records

        repeater(update_variants, driver, cur, con, history)

        cur.execute('UPDATE metadata SET is_variant_loaded = 1 WHERE submission_date >= ? and submission_date <= ?', (start_date, end_date))
        con.commit()
        con.close()

        driver.quit()
    except Exception as e:
        save_log(log_dir, driver)
        driver.quit()
        raise e

def update_clade(driver, cur, con, history):
    # get clade list
    clades = driver.find_elements_by_class_name("sys-event-hook.sys-fi-mark")[8].text.split('\n')
    clades.remove('all')

    print("Found clades: ", clades)

    for clade in clades:
        if history.is_done('clade', clade):
            continue
        clades_selector = Select(driver.find_element_by_xpath("//select[@class='sys-event-hook sys-fi-mark']"))
        clades_selector.select_by_visible_text(clade)
        wait_for_timer(driver)

        total_records = get_total_records(driver)
        if total_records == 0:
            print('Found 0 records, skipping')
            continue

        #get list of ids
        ids = get_accesion_ids(driver)
        print("found %s ids for clade %s" % (len(ids), clade))
        # update database
        for accession_id in ids:
            cur.execute("UPDATE metadata SET clade=? WHERE accession_id=?", (clade, accession_id))
        con.commit()
        history.set_done('clade', clade)
    clades_selector = Select(driver.find_element_by_xpath("//select[@class='sys-event-hook sys-fi-mark']"))
    clades_selector.select_by_visible_text('all')
    wait_for_timer(driver)
    
def update_variants(driver, cur, con, history):
    # get variants list
    variants = driver.find_elements_by_class_name("sys-event-hook.sys-fi-mark")[11].text.split('\n')

    print("Found variants: ", variants)

    for v in variants:
        if history.is_done('variant', v):
            continue
        variants_selector = Select(driver.find_elements_by_xpath("//select[@class='sys-event-hook sys-fi-mark']")[1])
        variants_selector.select_by_visible_text(v)
        wait_for_timer(driver)

        total_records = get_total_records(driver)
        if total_records == 0:
            print('Found 0 records, skipping')
            continue

        #get list of ids
        ids = get_accesion_ids(driver)
        print("found %s ids for variant %s" % (len(ids), v))
        # update database
        for accession_id in ids:
            cur.execute("UPDATE metadata SET variant=? WHERE accession_id=?", (v, accession_id))
        con.commit()
        history.set_done('variant', v)
    variants_selector = Select(driver.find_elements_by_xpath("//select[@class='sys-event-hook sys-fi-mark']")[1])
    variants_selector.select_by_index(0)
    return

def update_substitusions(driver, cur, con, history):
    subs = get_substitusions(driver)
    selector = driver.find_elements_by_xpath("//input[@class='sys-event-hook sys-fi-mark yui-ac-input']")[4]
    
    for sub in subs:
        if history.is_done('substitutions', sub):
            continue
        selector.clear()
        wait_for_timer(driver)
        selector.send_keys(sub)
        wait_for_timer(driver)

        total_records = get_total_records(driver)
        if total_records == 0:
            print('Found 0 records, skipping')
            continue

        # get list of ids
        ids = get_accesion_ids(driver)
    
        print("found %s ids for substitusions %s" % (len(ids), sub))
        
        # update database
        for accession_id in ids:
            cur.execute("SELECT accession_id, substitutions FROM metadata WHERE accession_id=?", (accession_id,))
            curr_id = cur.fetchall()[0]
            curr_id_subs = curr_id[1]
            subs_list = [sub] if curr_id_subs is None or curr_id_subs == '' else (curr_id_subs.split(',') + [sub])
            subs_list = np.unique(subs_list).tolist()
            cur.execute("UPDATE metadata SET substitutions=? WHERE accession_id=?", (','.join(subs_list), accession_id))
        con.commit()
        history.set_done('substitutions', sub)
    selector.clear()
    wait_for_timer(driver)

def get_substitusions(driver):
    substitusions = driver.find_elements_by_class_name("sys-event-hook.sys-fi-mark.yui-ac-input")[4]
    substitusions.clear() 
    wait_for_timer(driver)
    substitusions.click()
    wait_for_timer(driver)
    
    cont_table_html = driver.find_elements_by_class_name("yui-ac-content")[4].get_attribute("innerHTML")
    soup = BeautifulSoup(cont_table_html, features="lxml")
    subs = []
    for elem in soup.findAll('li'):
        if elem['style'] == 'display: none;':
            continue
        subs.append(elem.text)
    
    print("Substitusions found: %s" % subs)
    return subs
