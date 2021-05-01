import datetime
import sqlite3

import numpy as np
import pandas as pd

from api import Api
from utils import repeater
from variants_scrapper import ScrappingVariantsHistory


def manage_pango_scrapping(db_path, max_date_range, region, pango_file, log_dir, credentials):
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
    end_date = min(datetime.date.today(), start_date + datetime.timedelta(days=max_date_range))

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
    repeater(scrap_pango, db_path, region, start_date, end_date, lineages, history, log_dir, credentials)

    con = sqlite3.connect(db_path)
    cur = con.cursor()
    cur.execute('UPDATE metadata SET is_pango_loaded = 1 WHERE submission_date >= ? and submission_date <= ? and is_pango_loaded=0', (start_date, end_date))
    con.commit()
    con.close()


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
