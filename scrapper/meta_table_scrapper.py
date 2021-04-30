import sqlite3
import time
import datetime
import math
import pandas as pd
from utils import repeater, get_driver, extract_country, save_log
from input_utils import find_and_switch_to_iframe, wait_for_timer, set_date, set_region, get_total_records


class ScrappingMetaHistory:
    def __init__(self):
        self.pages_list = []
        self.last_done_page = 0
    def add_page(self, page_num, data):
        if page_num != self.last_done_page + 1:
            raise Exception("page_num(%s) != last_done_page(%s) + 1" % (page_num, self.last_done_page))
        self.pages_list.append(data)
        self.last_done_page = page_num


def manage_table_scrapping(db_path, minimum_start_date, max_date_range, region, log_dir):
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
        print('Scrapping 3 days before proper date range')
        history = ScrappingMetaHistory()
        repeater(scrap_meta_table, region, db_path, start_date - datetime.timedelta(days=3), start_date - datetime.timedelta(days=1), history, log_dir)
        print('Scrapping starting day')
        history = ScrappingMetaHistory()
        repeater(scrap_meta_table, region, db_path, start_date, start_date, history, log_dir)
        start_date = start_date + datetime.timedelta(days=1)

    end_date = min(datetime.date.today(), start_date + datetime.timedelta(days=max_date_range))

    history = ScrappingMetaHistory()
    repeater(scrap_meta_table, region, db_path, start_date, end_date, history, log_dir)


def scrap_meta_table(region, db_path, start_date, end_date, history, log_dir):
    """
    Uploads metadata from table to given database
    Filters from start_date and end_date
    """
    if end_date < start_date:
        print('Skipping, invalid date range')
        return
    try:
        driver = get_driver(log_dir)
        set_region(driver, region)

        con = sqlite3.connect(db_path)
        cur = con.cursor()

        cur.execute("SELECT COUNT(*) FROM metadata WHERE submission_date <= ? AND submission_date >= ?", (end_date, start_date))
        total_records_in_db = cur.fetchone()[0]
        con.commit()
        
        set_date(driver, start_date, end_date)
        total_records = get_total_records(driver)

        if total_records == 0:
            print("No records found")
            driver.quit()
            return
        elif total_records <= total_records_in_db:
            print('Skipping range %s : %s because total_records[%s] <= total_records_in_db[%s]' % (start_date, end_date, total_records, total_records_in_db))
            driver.quit()
            return
        expected_pages = math.ceil(total_records / 50)

        # go to last readed page 
        if history.last_done_page != 0:
            driver.execute_script('document.getElementsByClassName("yui-pg-page")[1].setAttribute("page", %s)' % (history.last_done_page + 1,))
            time.sleep(3)
            driver.find_elements_by_class_name("yui-pg-page")[1].click()
            time.sleep(30)
        
        last_readed_page = history.last_done_page + 1

        while True:
                
            #get current page number
            page_num = int(driver.find_element_by_class_name("yui-pg-current-page.yui-pg-page").text)
            
            print("Scrapping page %s / %s (%s%%)" %(page_num, expected_pages, ((10**4 * page_num) // expected_pages) / 10**2 ))
            
            page = driver.find_element_by_class_name("yui-dt-bd").get_attribute("innerHTML")
            df = pd.read_html(page)[0]
            
            # get page number after read
            page_num_post = int(driver.find_element_by_class_name("yui-pg-current-page.yui-pg-page").text)
            
            if page_num != page_num_post:
                raise Exception('Page skipped while reading')

            history.add_page(page_num, df)
            
            # stop if reached last page
            if not ('href' in driver.find_element_by_class_name("yui-pg-next").get_attribute("outerHTML")):
                print("Got to last page, exiting")
                break
            
            # go to next page
            driver.find_element_by_class_name("yui-pg-next").click()

            # sleep until gisaid changes next-page attribute and go to next page
            page_loading_counter = 0
            while last_readed_page == page_num:
                time.sleep(0.5)
                try:
                    page_num = int(driver.find_element_by_class_name("yui-pg-current-page.yui-pg-page").text)
                except:
                    page_num = int(driver.find_element_by_class_name("yui-pg-current-page.yui-pg-page").text)
                page_loading_counter += 1
                if page_loading_counter == 120:
                    raise Exception("Scrapping same page twice for 60s")

            last_readed_page = page_num
    except Exception as e:
        save_log(log_dir, driver)
        driver.quit()
        raise e

    driver.quit()

    meta_df = pd.concat(history.pages_list)
    # drop column of checkboxes and symbol
    meta_df = meta_df.drop(['Unnamed: 0', 'Unnamed: 6'], axis=1)

    df_clean = meta_df.drop_duplicates()

    cur.execute("SELECT accession_id FROM metadata WHERE submission_date <= ? AND submission_date >= ?", (end_date, start_date))
    duplicated = [x[0] for x in cur.fetchall()]
    
    # upload to database
    for index, row in df_clean.iterrows():
        if row['Accession ID'] not in duplicated:
            country = extract_country(row['Location'])
            cur.execute("""INSERT INTO metadata (
                                                accession_id, 
                                                passage,
                                                submission_date,
                                                collection_date,
                                                host,
                                                location,
                                                originating_lab,
                                                submitting_lab,
                                                country
                                                ) VALUES (?,?,?,?,?,?,?,?,?)""", 
                                                (
                                                row['Accession ID'],
                                                row['Passage details/history'],
                                                row['Submission Date'],
                                                row['Collection date'],
                                                row['Host'],
                                                row['Location'],
                                                row['Originating lab'],
                                                row['Submitting lab'],
                                                country
                                                ))
    con.commit()
    con.close()
    return
