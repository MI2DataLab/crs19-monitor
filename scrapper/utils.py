import time, os, sqlite3
import lzma
import pandas as pd
from io import StringIO
from biotite.sequence.io.fasta import FastaFile
import tarfile
import operator
import re


def init_db(db_path):
    """
    Creates table metadata in database if not exists
    """
    con = sqlite3.connect(db_path)
    cur = con.cursor()
    cur.execute("""CREATE TABLE IF NOT EXISTS metadata (
                          accession_id CHAR(16) PRIMARY KEY NOT NULL, 
                          fasta_file VARCHAR(16) NULL,
                          passage VARCHAR(32) NULL,
                          submission_date DATE NOT NULL, 
                          collection_date DATE NULL,
                          host VARCHAR(32) NULL,
                          location VARCHAR(128) NULL,
                          originating_lab TEXT NULL,
                          submitting_lab TEXT NULL,
                          country VARCHAR(32) NULL,
                          sex VARCHAR(32) NULL,
                          age INT NULL,
                          substitutions VARCHAR(64) NULL,
                          clade VARCHAR(32) NULL,
                          is_meta_loaded BIT NOT NULL DEFAULT 0,
                          is_variant_loaded BIT NOT NULL DEFAULT 0
    )""")
    con.commit()


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
        self.driver.execute_script(
            "document.getElementById('sys_curtain').remove()")
        action.move_to_element(element).perform()
        element.click()
    
def get_number_of_files(dir : str):
    """
    Returns number of files in dir
    Excludes .part files
    """
    if os.path.exists(dir):
        files = [f for f in os.listdir(dir) if ".part" not in f]
        n_files = len(files)
    else:
        n_files = 0
    return n_files

def extract_country(location: str):
    """
    Returns country from location string
    """
    l = location.split("/")
    if len(l) < 2:
        return None
    
    c = l[1].rstrip(" ").lstrip(" ")
    
    return c


def get_elem_or_None(driver,class_name):
    """
    Returns element by class_name or None if it doesn't exist
    """
    try:
        elem = driver.find_element_by_class_name(class_name)
    except:
        elem = None
    return elem

def get_elements_or_empty(driver,class_name):
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
        if elem is not None and list(elem.rect.values()) != [0,0,0,0]:
            return True
    return False

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
    driver.find_element_by_class_name("sys-event-hook.sys-fi-mark.yui-ac-input").clear()
    #wait_for_timer(driver)
    
    print("Setting region to ", region)
    driver.find_element_by_class_name("sys-event-hook.sys-fi-mark.yui-ac-input").send_keys(region)
    wait_for_timer(driver)
    
    return


def fix_metadata_table(input_handle, output_handle, delim='\t'):
    lines = input_handle.readlines()
    parts = [line.replace("\n", "").replace("\r", "").split(delim) for line in lines]
    parts = [part for part in parts if len(part) > 0]
    cols = len(parts[0])
    fixed = [parts[0]]
    # Reverse to use .pop()
    to_fix = list(reversed(parts[1:]))
    while len(to_fix) > 0:
        new_line = to_fix.pop()
        # -1 because we concat last column with the first of next row
        while len(to_fix) > 0 and len(new_line) + len(to_fix[-1]) - 1 <= cols:
            # First column of next row we join with last column of previous
            new_line[-1] = new_line[-1] + to_fix[-1][0]
            new_line = new_line + to_fix.pop()[1:]
        if len(new_line) != cols:
            raise Exception('Function cannot fix file')
        fixed.append(new_line)
    fixed_lines = [delim.join(row) + '\n' for row in fixed]
    output_handle.writelines(fixed_lines)
    
def load_metadata_table(compressed_metadata):
    with StringIO() as fixed_metadata_handle:
        with lzma.open(compressed_metadata, 'rt') as raw_metadata_handle:
            fix_metadata_table(raw_metadata_handle, fixed_metadata_handle)
            fixed_metadata_handle.seek(0)
        return pd.read_csv(fixed_metadata_handle, sep="\t", quoting=3) # 3 = disabled

def fix_fasta_file(metadata, input_fasta_path, output_fasta_path, missing_fasta_ids):
    if len(missing_fasta_ids) == 0:
        return

    with lzma.open(input_fasta_path, 'rt') as raw_fasta_handle:
        lines = raw_fasta_handle.readlines()

    # Just check if order and values of keys are the same as in metadata
    # fasta files can contain duplicated keys
    fasta_keys = [l[1:].replace('\n', '') for l in lines if l.startswith('>')]
    assert metadata['strain'].tolist() == fasta_keys

    # Create fasta file in buffor with gisaid accession_id as key
    with StringIO() as tmp_fasta_handle:
        header_counter = 0
        for line in lines:
            if line.startswith('>'):
                row = metadata.iloc[header_counter]
                tmp_fasta_handle.write('>' + row['gisaid_epi_isl'] + '\n')
                header_counter += 1
            else:
                tmp_fasta_handle.write(line)
        tmp_fasta_handle.seek(0)
        full_fasta = FastaFile.read(tmp_fasta_handle)

    output_fasta = FastaFile()
    metadata = metadata.set_index('gisaid_epi_isl')
    for accession_id in full_fasta.keys():
        if accession_id in missing_fasta_ids:
            row = metadata.loc[accession_id]
            new_key = '|'.join([row['strain'], accession_id, str(row['date'])])
            output_fasta[new_key] = full_fasta[accession_id]
    output_fasta.write(output_fasta_path)

def load_from_tar(tar_file, output_fasta_path, missing_fasta_ids):
    with tarfile.open(tar_file) as tar_handle:
        members = tar_handle.getmembers()
        members.sort(key = operator.attrgetter('name'))
        # check if tar structure does not changed
        assert members[0].name.endswith('metadata.tsv.xz')
        assert members[1].name.endswith('sequences.fasta.xz')
        # extract handles for files
        compressed_metadata = tar_handle.extractfile(members[0])
        compressed_fasta = tar_handle.extractfile(members[1])
        # get pandas df from compressed metadata
        metadata = load_metadata_table(compressed_metadata)
        fix_fasta_file(metadata, compressed_fasta, output_fasta_path, missing_fasta_ids)
        return metadata

def get_accesion_ids(driver):
    time.sleep(1)

    wait_for_timer(driver)
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
    
    total_records = driver.find_element_by_class_name("sys-datatable-info-left").text
    total_records = int(re.sub(r'[^0-9]*', "", total_records))
    
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

def update_clade(driver, cur):
    # get clade list
    clades = driver.find_elements_by_class_name("sys-event-hook.sys-fi-mark")[8].text.split('\n')
    clades.remove('all')

    print("Found clades: ", clades)

    for clade in clades:
        clades_selector = driver.find_element_by_xpath("//select[@class='sys-event-hook sys-fi-mark']")
        try:
            clades_selector.clear()
        except:
            pass
        clades_selector.send_keys(clade)
        wait_for_timer(driver)

        #get list of ids
        ids = get_accesion_ids(driver)
        print("found %s ids for clade %s" %(len(ids), clade))
        # update database
        for accession_id in ids:
            cur.execute("UPDATE metadata SET clade=? WHERE accession_id=?", (clade, accession_id))

            con.commit()
    clades_selector = driver.find_element_by_xpath("//select[@class='sys-event-hook sys-fi-mark']")
    try:
        clades_selector.clear()
    except:
        pass
    clades_selector.send_keys("all")
    
def update_variants(driver, cur):
    # get variants list
    variants = driver.find_elements_by_class_name("sys-event-hook.sys-fi-mark")[11].text.split('\n')

    print("Found variants: ", variants)

    for v in variants:
        variants_selector = driver.find_elements_by_xpath("//select[@class='sys-event-hook sys-fi-mark']")[1]
        try:
            variants_selector.clear()
        except:
            pass
        variants_selector.send_keys(v)
        wait_for_timer(driver)

        #get list of ids
        ids = get_accesion_ids(driver)
        print("found %s ids for variant %s" %(len(ids), v))
        # update database
        for accession_id in ids:
            cur.execute("UPDATE metadata SET variant=? WHERE accession_id=?", (v, accession_id))

            con.commit()
    variants_selector = driver.find_elements_by_xpath("//select[@class='sys-event-hook sys-fi-mark']")[1]
    variants_selector.find_element_by_xpath("//option[@selected='']").click()
    return

def update_substitusions(driver, cur):
    subs = get_substitusions(driver)
    selector = driver.find_elements_by_xpath("//input[@class='sys-event-hook sys-fi-mark yui-ac-input']")[4]
    
    for sub in subs:
        selector.clear()
        wait_for_timer(driver)
        selector.send_keys(sub)
        wait_for_timer(driver)
        #get list of ids
        ids = get_accesion_ids(driver)
    
        print("found %s ids for substitusions %s" %(len(ids), sub))
        
        # update database
        for accession_id in ids:
            cur.execute("SELECT accession_id, substitutions FROM metadata WHERE accession_id=?", (id_,))
            curr_id = cur.fetchall()[0]
            curr_id_subs = curr_id[1]
            if curr_id_subs is None:
                merged_subs = sub
            else:
                merged_subs = curr_id_subs + "," + sub
            
            cur.execute("UPDATE metadata SET substitutions=?, is_variant_loaded=1  WHERE accession_id=?", (merged_subs, accession_id))
    
            con.commit()

def get_substitusions(driver):
    substitusions = driver.find_elements_by_class_name("sys-event-hook.sys-fi-mark.yui-ac-input")[4]
    substitusions.clear() 
    wait_for_timer(driver)
    substitusions.click()
    wait_for_timer(driver)
    
    cont_table_html = driver.find_elements_by_class_name("yui-ac-content")[4].get_attribute("innerHTML")
    soup =   BeautifulSoup(cont_table_html)
    subs = []
    for elem in soup.findAll('li'):
        if elem['style'] == 'display: none;':
            continue
        subs.append(elem.text)
    
    print("Substitusions found: %s" %subs)
    return subs

def get_search(driver, region, db_path, start_date, end_date, headless = True):
    
    set_region(driver, region)

    con = sqlite3.connect(db_path)
    cur = con.cursor()

    cur.execute("SELECT COUNT(*) FROM metadata WHERE submission_date <= ? AND submission_date >= ?", (end_date, start_date))
    total_records_in_db = cur.fetchone()[0]
    con.commit()
    con.close()
        
    # read total_records from left bottom corner
    total_records_before_filter = driver.find_element_by_class_name("sys-datatable-info-left").text
    total_records_before_filter = int(re.sub(r'[^0-9]*', "", total_records_before_filter))

    # filter by date 
    print("Scrapping date from ", start_date, "to ", end_date)
    driver.find_elements_by_class_name("sys-event-hook.sys-fi-mark.hasDatepicker")[2].send_keys(start_date.strftime('%Y-%m-%d'))
    driver.find_elements_by_class_name("sys-event-hook.sys-fi-mark.hasDatepicker")[3].send_keys(end_date.strftime('%Y-%m-%d'))
    wait_for_timer(driver)

    # read total_records from left bottom corner
    total_records = driver.find_element_by_class_name("sys-datatable-info-left").text
    total_records = int(re.sub(r'[^0-9]*', "", total_records))
    if total_records == 0:
        print("No records found")
        driver.quit()
        #return
    elif total_records <= total_records_in_db:
        print('Skipping range %s : %s because total_records[%s] <= total_records_in_db[%s]' % (start_date, end_date, total_records, total_records_in_db))
        driver.quit()
        #return
    elif total_records == total_records_before_filter:
        # handle unresponsive gisaid
        raise Exception('Number of records didn\'t changed after filtering by date')
    return total_records

