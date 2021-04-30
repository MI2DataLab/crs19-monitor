import sqlite3
import time
import pandas as pd
import numpy as np
import datetime
from utils import repeater, get_driver, save_log
from input_utils import set_region, set_date, get_accesion_ids
from variants_scrapper import ScrappingVariantsHistory


def manage_pango_scrapping(db_path, max_date_range, region, pango_file, log_dir):
    """
    Handles pango scrapping
    """
    con = sqlite3.connect(db_path)
    cur = con.cursor()
    cur.execute("SELECT COUNT(*) FROM metadata WHERE is_pango_loaded=0")
    if cur.fetchone()[0] == 0:
        print('All sequences have scrapped pango')
        return

    cur.execute("SELECT MIN(submission_date) FROM metadata WHERE is_pango_loaded=0")
    start_date = cur.fetchone()[0]
    start_date = datetime.datetime.strptime(start_date, '%Y-%m-%d').date()
    end_date = min(datetime.date.today(), start_date + datetime.timedelta(days = max_date_range))

    cur.execute("SELECT accession_id FROM metadata WHERE is_pango_loaded=0 AND submission_date >= ? AND submission_date <= ?", (start_date, end_date))
    ids = [x[0] for x in cur.fetchall()]
    pango_df = pd.read_csv(pango_file)
    pango_df['accession_id'] = [x.split('|')[1] for x in pango_df['taxon']]
    lineages = pango_df[pango_df['accession_id'].isin(ids)]['lineage']
    lineages = np.unique(lineages).tolist()
    if 'None' in lineages:
        lineages.remove('None')
    con.close()
    print('Lineages to scan: %s' % lineages)

    history = ScrappingVariantsHistory()
    repeater(scrap_pango, db_path, region, start_date, end_date, lineages, history, log_dir)

    con = sqlite3.connect(db_path)
    cur = con.cursor()
    cur.execute('UPDATE metadata SET is_pango_loaded = 1 WHERE submission_date >= ? and submission_date <= ? and is_pango_loaded=0', (start_date, end_date))
    con.commit()
    con.close()

def scrap_pango(db_path, region, start_date, end_date, lineages, history, log_dir):

    if end_date < start_date:
        print('Skipping, invalid date range')
        return
    try:
        driver = get_driver(log_dir)
        set_region(driver, region)
        set_date(driver, start_date, end_date)

        con = sqlite3.connect(db_path)
        cur = con.cursor()

        for p in lineages:
            if history.is_done('pango', p):
                continue
            print("Checking lineage %s" % p)

            lineage_input = driver.find_elements_by_class_name("sys-event-hook.sys-fi-mark.yui-ac-input")[3]
            lineage_input.clear()
            lineage_input.send_keys(p)

            ids = get_accesion_ids(driver)
            for accession_id in ids:
                cur.execute("UPDATE metadata SET gisaid_pango=? WHERE accession_id=?", (p, accession_id))
            con.commit()

            history.set_done('pango', p)

        con.close()
    except Exception as e:
        save_log(log_dir, driver)
        driver.quit()
        raise e
    driver.quit()
