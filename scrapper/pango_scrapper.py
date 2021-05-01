import datetime
import sqlite3

import numpy as np
import pandas as pd

from api import Api, CaptchaException
from utils import repeater
from variants_scrapper import ScrappingVariantsHistory


def manage_pango_scrapping(db_path, max_date_range, region, pango_file, log_dir, credentials):
    """
    Handles pango scrapping
    """
    history = ScrappingVariantsHistory()

    con = sqlite3.connect(db_path)
    cur = con.cursor()
    cur.execute("SELECT COUNT(*) FROM metadata WHERE is_pango_loaded=0")
    if cur.fetchone()[0] > 0:
        cur.execute("SELECT MIN(submission_date) FROM metadata WHERE is_pango_loaded=0")
        start_date = cur.fetchone()[0]
        start_date = datetime.datetime.strptime(start_date, '%Y-%m-%d').date()
        end_date = min(datetime.date.today(), start_date + datetime.timedelta(days=max_date_range))

        cur.execute("SELECT accession_id FROM metadata WHERE is_pango_loaded=0 AND submission_date >= ? AND submission_date <= ?", (start_date, end_date))
        con.commit()
        ids = [x[0] for x in cur.fetchall()]
        pango_df = pd.read_csv(pango_file)
        pango_df['accession_id'] = [x.split('|')[1] for x in pango_df['taxon']]
        lineages = pango_df[pango_df['accession_id'].isin(ids)]['lineage']
        lineages = np.unique(lineages).tolist()
        if 'None' in lineages:
            lineages.remove('None')
        print('Lineages to scan: %s' % lineages)

        repeater(scrap_pango, db_path, region, start_date, end_date, lineages, history, log_dir, credentials)

        cur.execute('UPDATE metadata SET is_pango_loaded = 1 WHERE submission_date >= ? and submission_date <= ? and is_pango_loaded=0', (start_date, end_date))
        con.commit()

    cur.execute('SELECT accession_id FROM metadata WHERE is_pango_loaded=1 AND gisaid_pango is NULL')
    accession_ids = [x[0] for x in cur.fetchall()]
    con.close()

    print('%s sequences left for manual pango check:\n%s' % (len(accession_ids), accession_ids))
    repeater(scrap_pango_manualy, db_path, accession_ids, history, log_dir, credentials)


def scrap_pango(db_path, region, start_date, end_date, lineages, history, log_dir, credentials):
    if end_date < start_date:
        return
    with Api(credentials, log_dir) as api:
        api.set_region(region)
        api.set_date(start_date, end_date)

        con = sqlite3.connect(db_path)
        cur = con.cursor()

        for index, p in enumerate(lineages):
            if history.is_done('pango', p):
                continue
            api.print_log("[%s/%s] Checking lineage %s" % ((index + 1), len(lineages), p))
            api.filter_by_name('lineages', p)

            for accession_id in api.get_accesion_ids():
                cur.execute("UPDATE metadata SET gisaid_pango=? WHERE accession_id=?", (p, accession_id))
            con.commit()

            history.set_done('pango', p)
        con.close()


def scrap_pango_manualy(db_path, accession_ids, history, log_dir, credentials):
    if len(accession_ids) == 0:
        return
    con = sqlite3.connect(db_path)
    cur = con.cursor()
    with Api(credentials, log_dir) as api:
        for index, accession_id in enumerate(accession_ids):
            if history.is_done('pango_manual', accession_id):
                continue
            api.print_log("[%s/%s] Checking id %s" % ((index + 1), len(accession_ids), accession_id))
            api.filter_by_name('accession_ids', accession_id)

            if api.get_total_records() == 0:
                api.print_log('Cannot find record %s' % accession_id)
            try:
                lineage = api.get_pango(0).split(' ')[0]
            except CaptchaException:
                api.print_log('Cannot read pango because of captcha. Stopping manual scrapping')
                return

            cur.execute('UPDATE metadata SET gisaid_pango=?, is_pango_loaded=2 WHERE accession_id=?', (lineage, accession_id))
            con.commit()
            history.set_done('pango_manual', accession_id)

    con.close()
