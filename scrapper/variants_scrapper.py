import datetime
import sqlite3

import numpy as np

from api import Api
from utils import repeater


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


def manage_variants_scrapping(db_path, max_date_range, region, log_dir, credentials):
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
    end_date = min(datetime.date.today(), start_date + datetime.timedelta(days=max_date_range))

    repeater(scrap_variants, region, db_path, start_date, end_date, history, log_dir, credentials)


def scrap_variants(region, db_path, start_date, end_date, history, log_dir, credentials):
    if end_date < start_date:
        return
    with Api(credentials, log_dir) as api:
        api.set_region(region)
        api.set_date(start_date, end_date)

        con = sqlite3.connect(db_path)
        cur = con.cursor()
        total_records = api.get_total_records()

        repeater(update_clade, api, cur, con, history)
        assert api.get_total_records() >= total_records

        repeater(update_substitutions, api, cur, con, history)
        assert api.get_total_records() >= total_records

        repeater(update_variants, api, cur, con, history)

        cur.execute('UPDATE metadata SET is_variant_loaded = 1 WHERE submission_date >= ? and submission_date <= ?', (start_date, end_date))
        con.commit()
        con.close()


def update_clade(api, cur, con, history):
    # get clade list
    clades = api.get_filter_options('clades')
    clades.remove('all')
    api.print_log("Found clades: %s" % clades)

    for clade in clades:
        if history.is_done('clade', clade):
            continue
        api.filter_by_name('clades', clade)

        if api.get_total_records() == 0:
            api.print_log('Found 0 records, skipping')
            continue

        # get list of ids
        ids = api.get_accesion_ids()
        api.print_log("Found %s ids for clade %s" % (len(ids), clade))

        # update database
        for accession_id in ids:
            cur.execute("UPDATE metadata SET clade=? WHERE accession_id=?", (clade, accession_id))
        con.commit()
        history.set_done('clade', clade)
    api.filter_by_name('clades', 'all')


def update_variants(api, cur, con, history):
    # get variants list
    variants = api.get_filter_options('variants')
    api.print_log("Found variants: ", variants)

    for v in variants:
        if history.is_done('variant', v):
            continue
        api.filter_by_name('variants', v)

        if api.get_total_records() == 0:
            api.print_log('Found 0 records, skipping')
            continue

        # get list of ids
        ids = api.get_accesion_ids()
        api.print_log("Found %s ids for variant %s" % (len(ids), v))

        # update database
        for accession_id in ids:
            cur.execute("UPDATE metadata SET variant=? WHERE accession_id=?", (v, accession_id))
        con.commit()
        history.set_done('variant', v)
    api.filter_by_index('variants', 0)


def update_substitutions(api, cur, con, history):
    subs = api.get_filter_options('substitutions')
    api.print_log("Found substitutions: ", subs)

    for sub in subs:
        if history.is_done('substitutions', sub):
            continue
        api.filter_by_name('substitutions', sub)

        if api.get_total_records() == 0:
            api.print_log('Found 0 records, skipping')
            continue

        # get list of ids
        ids = api.get_accesion_ids()
        api.print_log("Found %s ids for substitution %s" % (len(ids), sub))

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
    api.filter_by_name('substitutions', '')
