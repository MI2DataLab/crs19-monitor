import time, os, sqlite3


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
                          country VARCHAR(32) NULL
    )""")
    con.commit()

    
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
