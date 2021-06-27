import datetime
import math
import sqlite3

import pandas as pd

from api import Api
from utils import extract_location, repeater


class ScrappingMetaHistory:
    def __init__(self):
        self.pages_list = []
        self.last_done_page = 0
    def add_page(self, page_num, data):
        if page_num != self.last_done_page + 1:
            raise Exception("page_num(%s) != last_done_page(%s) + 1" % (page_num, self.last_done_page))
        self.pages_list.append(data)
        self.last_done_page = page_num


def manage_table_scrapping(db_path, minimum_start_date, max_date_range, region, log_dir, credentials):
    """
    Handles date ranges for table scrapping
    """
    con = sqlite3.connect(db_path)
    cur = con.cursor()
    cur.execute("SELECT MAX(submission_date) FROM metadata")
    start_date = cur.fetchone()[0]
    con.close()

    if start_date is None:
        start_date = minimum_start_date
    else:
        start_date = datetime.datetime.strptime(start_date, '%Y-%m-%d').date()
        print('Scrapping 3rd day before proper date range')
        history = ScrappingMetaHistory()
        repeater(scrap_meta_table, region, db_path, start_date - datetime.timedelta(days=3), start_date - datetime.timedelta(days=3), history, log_dir, credentials)
        print('Scrapping 2nd day before proper date range')
        history = ScrappingMetaHistory()
        repeater(scrap_meta_table, region, db_path, start_date - datetime.timedelta(days=2), start_date - datetime.timedelta(days=2), history, log_dir, credentials)
        print('Scrapping 1st day before proper date range')
        history = ScrappingMetaHistory()
        repeater(scrap_meta_table, region, db_path, start_date - datetime.timedelta(days=1), start_date - datetime.timedelta(days=1), history, log_dir, credentials)
        print('Scrapping starting day')
        history = ScrappingMetaHistory()
        repeater(scrap_meta_table, region, db_path, start_date, start_date, history, log_dir, credentials)
        start_date = start_date + datetime.timedelta(days=1)

    while True:
        end_date = min(datetime.date.today(), start_date + datetime.timedelta(days=max_date_range))
        if start_date > end_date:
            break
        history = ScrappingMetaHistory()
        repeater(scrap_meta_table, region, db_path, start_date, end_date, history, log_dir, credentials)
        start_date = end_date + datetime.timedelta(days=1)


def scrap_meta_table(region, db_path, start_date, end_date, history, log_dir, credentials):
    """
    Uploads metadata from table to given database
    Filters from start_date and end_date
    """
    if end_date < start_date:
        return

    con = sqlite3.connect(db_path)
    cur = con.cursor()
    cur.execute("SELECT COUNT(*) FROM metadata WHERE submission_date <= ? AND submission_date >= ?", (end_date, start_date))
    total_records_in_db = cur.fetchone()[0]

    with Api(credentials, log_dir) as api:
        api.set_region(region)
        api.set_date(start_date, end_date)
        total_records = api.get_total_records()
        expected_pages = math.ceil(total_records / 50)

        if total_records <= total_records_in_db:
            api.print_log('Skipping range %s : %s because total_records[%s] <= total_records_in_db[%s]' % (start_date, end_date, total_records, total_records_in_db))
            return

        # go to last readed page
        if history.last_done_page != 0:
            api.go_to_page(history.last_done_page + 1)

        while True:
            page_num = api.get_page_number()
            api.print_log("Scrapping page %s / %s (%s%%)" % (page_num, expected_pages, ((10**4 * page_num) // expected_pages) / 10**2))
            history.add_page(page_num, api.get_page_table())

            # stop if reached last page
            if api.is_last_page():
                api.print_log("Got to last page, exiting")
                break

            api.go_to_next_page()

    meta_df = pd.concat(history.pages_list)
    df_clean = meta_df.drop_duplicates()

    cur.execute("SELECT accession_id FROM metadata WHERE submission_date <= ? AND submission_date >= ?", (end_date, start_date))
    duplicated = [x[0] for x in cur.fetchall()]

    # upload to database
    # pylint: disable=unused-variable
    for index, row in df_clean.iterrows():
        if row['Accession ID'] not in duplicated:
            continent = extract_location(row['Location'], 0)
            country = extract_location(row['Location'], 1)
            cur.execute(
                """INSERT INTO metadata (accession_id, passage, submission_date, collection_date, host, location, originating_lab, submitting_lab, country, continent) VALUES (?,?,?,?,?,?,?,?,?,?)""",
                (row['Accession ID'], row['Passage details/history'], row['Submission Date'], row['Collection date'], row['Host'], row['Location'], row['Originating lab'], row['Submitting lab'], country, continent))
    con.commit()
    con.close()
    return
