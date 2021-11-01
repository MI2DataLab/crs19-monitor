import sqlite3
import os
import re
import yaml
import pandas as pd
import numpy as np
from unidecode import unidecode
from pathlib import Path
from datetime import datetime, timedelta
from tqdm import tqdm
from locations_utils import update_locations_level


def init_db(db_path):
    """
    Drop and creates tables
    """
    query = Path(os.path.dirname(os.path.realpath(__file__)) + '/init_database.sql').read_text()
    with sqlite3.connect(db_path) as con:
        cur = con.cursor()
        cur.executescript(query)
        con.commit()
        cur.execute('SELECT COUNT(*) FROM sequences;')


def init_locations_db(db_path):
    """
    Creates table if not exists
    """
    query = Path(os.path.dirname(os.path.realpath(__file__)) + '/init_locations.sql').read_text()
    with sqlite3.connect(db_path) as con:
        cur = con.cursor()
        cur.executescript(query)
        con.commit()


def extract_location(location, level=0):
    """
    Returns location at given level from location string
    """
    locs = location.split("/")
    if len(locs) <= level:
        return 'UNDEFINED'
    striped = locs[level].rstrip(" ").lstrip(" ")
    return striped if len(striped) > 0 else 'UNDEFINED'

def clean_location(location):
    cleaned = (location or '').rstrip(' ').lstrip(' ')
    return cleaned if len(cleaned) > 0 else 'UNDEFINED'

minimal_date = datetime.strptime('2019-12-01', '%Y-%m-%d')
today_date = datetime.today()


def clean_date(date):
    # Fast path
    if date is None:
        return None
    parts = str(date).split('-')
    if len(parts) != 3 or len(parts[0]) != 4 or len(parts[1]) != 2 or len(parts[2]) != 2:
        return None
    if 2019 <= int(parts[0]) <= 2022 and 0 <= int(parts[1]) <= 12 and 0 <= int(parts[2]) <= 28:
        return date
    # Slow path
    try:
        parsed = datetime.strptime(date, '%Y-%m-%d')
        if minimal_date <= parsed <= today_date:
            return parsed.strftime('%Y-%m-%d')
    except:
        return None


def clean_age(age):
    if age is None:
        return (None, None)
    age = str(age)
    age = age.replace(" ", "")
    age = age.lower()

    def single_sanity_check(x):
        return x if 0 <= x <= 120 else None

    def sanity_check(lower, upper):
        return (lower, upper) if (0 <= lower <= 120 and 0 <= upper <= 120 and lower <= upper) else (None, None)

    range_ = re.findall(r"\d+-\d+", age)
    if range_:
        bounds = range_[0].split("-")
        return sanity_check(int(bounds[0]), int(bounds[1]))
    lower = re.findall(r">\d+", age)
    if lower:
        low = single_sanity_check(int(lower[0][1:]))
        return (low, None)
    lower = re.findall(r"\d+\+", age)
    if lower:
        low = single_sanity_check(int(lower[0][:-1]))
        return (low, None)
    upper = re.findall(r"<\d+", age)
    if upper:
        up = single_sanity_check(int(upper[0][1:]))
        return (None, up)
    range_ = re.findall(r"\d+to\d+", age)
    if range_:
        bounds = range_[0].split("to")
        return sanity_check(int(bounds[0]), int(bounds[1]))
    months = re.findall(r"\d+month", age)
    if months:
        age_ = single_sanity_check(int(months[0][:-5]) / 12)
        return (age_, age_)
    range_ = re.findall(r"\d+unknown", age)
    if range_:
        decimal = range_[0][:-7]
        return sanity_check(int(decimal + "0"), int(decimal + "9"))
    years = re.findall(r"\d+year", age)
    if years:
        years = years[0][:-4]
        return sanity_check(int(years), int(years))
    else:
        return (None, None)


def clean_sex(sex):
    if sex is None:
        return None
    sex = sex.lower()
    if sex in ["female", "moteris", "femmina", "f"]:
        return "Female"
    if sex in ["male", "maschio", "m"]:
        return "Male"
    else:
        return None

def load_dates(clean_db, dates):
    """
    Fill dates table
    """
    print('Filling dates table', flush=True)
    fmt = '%Y-%m-%d'
    dates = [datetime.strptime(x, fmt) for x in dates]
    with sqlite3.connect(clean_db) as con:
        cur = con.cursor()
        for d in dates:
            fields = ['date', 'year', 'month', 'day', 'week', 'week_start', 'month_start', 'is_weekend', 'weekday']
            values = [d.strftime(fmt), d.year, d.month, d.day, d.isocalendar()[1], (d - timedelta(days=d.weekday())).strftime(fmt), datetime(d.year, d.month, 1).strftime(fmt), d.weekday() >= 6, d.weekday() + 1]
            cur.execute('INSERT OR IGNORE INTO dates (' + ','.join(fields) + ') VALUES (' + ','.join((['?'] * len(fields))) + ')', values)
        con.commit()


def get_pango_attributes(tree, pango):
    if type(pango) is str and len(pango) > 0:
        pango = pango.split('.')
    root_attrs = {k:tree[k] for k in tree.keys() if k != 'sub' and k != 'id'}
    if len(pango) == 0:
        return root_attrs
    child = next(filter(lambda x: str(x['id']) == pango[0], tree.get('sub') or []), None)
    if child is None:
        return root_attrs
    child_attrs = get_pango_attributes(child, pango[1:])
    # override root attributes with more specific child attributes
    for k in child_attrs.keys():
        root_attrs[k] = child_attrs[k]
    return root_attrs

        
def load_pango(clean_db, pango_config_path, unique_pango):
    """
    Fill pango table
    """
    print('Filling pango table', flush=True)
    handle = open(pango_config_path, 'r')
    config = yaml.safe_load(handle)
    handle.close()
    with sqlite3.connect(clean_db) as con:
        cur = con.cursor()
        for p in unique_pango:
            attrs = get_pango_attributes(config, str(p))
            cur.execute('INSERT OR IGNORE INTO pango (pango, color, is_alarm, class, name) VALUES (?, ?, ?, ?, ?)', (p, attrs['color'], int(attrs['alarm']), attrs['class'], attrs['name']))
        con.commit()


def load(raw_db, loc_db, clean_db, pango_path, pango_config_path, batch_size=30000):
    """
    Cleans data and loads to new database
    """
    columns = [
        'accession_id', 'continent', 'country', 'state', 'submission_date', 'collection_date',
        'host', 'age', 'sex', 'gisaid_nextstrain_clade', 'gisaid_clade', 'gisaid_pango', 'strain',
        'virus', 'segment'
    ]
    with sqlite3.connect(loc_db) as con:
        cur = con.cursor()
        cur.execute('UPDATE mappings SET count = 0')
        con.commit()

    with sqlite3.connect(raw_db) as con:
        cur = con.cursor()
        cur.execute('SELECT DISTINCT fasta_file_id from metadata')
        file_ids = [x[0] for x in cur.fetchall()]
        cur.execute('SELECT DISTINCT continent, country, state from metadata where deleted != 1')
        distinct_locations = list(cur.fetchall())

    print('Generating geography table', flush=True)
    geography = pd.DataFrame({
        'raw_continent': [clean_location(x[0]) for x in distinct_locations],
        'raw_country': [clean_location(x[1]) for x in distinct_locations],
        'raw_state': [clean_location(x[2]) for x in distinct_locations]
    })
    
    print('Assigning location nodes', flush=True)
    geography['continent_id'] = update_locations_level(loc_db, geography[['raw_continent']].rename(columns={'raw_continent': 'name'}))
    geography['country_id'] = update_locations_level(loc_db, geography[['raw_country', 'continent_id']].rename(columns={'continent_id': 'parent_id', 'raw_country': 'name'}))
    geography['state_id'] = update_locations_level(loc_db, geography[['raw_state', 'country_id']].rename(columns={'country_id': 'parent_id', 'raw_state': 'name'}))
    geography = geography.drop(columns=['raw_continent', 'raw_country', 'raw_state']).drop_duplicates().reset_index(drop=True)
        
    print('Loading location nodes table', flush=True)
    with sqlite3.connect(loc_db) as con:
        loc_nodes = pd.read_sql('select name, id, iso_code, lat, lng from nodes', con)
        
    print('Unique locations merge with nodes', flush=True)
    for pre in ['continent', 'country', 'state']:
        geography = pd.merge(geography, loc_nodes, how='left', left_on=pre + '_id', right_on='id') \
                .rename(columns={'name': pre, 'iso_code': pre + '_iso_code', 'lat': pre + '_lat', 'lng': pre + '_lng'}) \
                .drop(columns=['id', pre + '_id'])
        
    print('Saving geography', flush=True)
    with sqlite3.connect(clean_db) as con:
        geography.to_sql('geography', con, if_exists='append', index=None)
    
    # Simplify loc_nodes for future use
    loc_nodes = loc_nodes[['id', 'name']].copy()
    
    to_save = []
    # Iterate over batches (one source fasta file = one batch)
    for file_id in tqdm(file_ids):
        print('Reading data', flush=True)
        with sqlite3.connect(raw_db) as con:
            raw = pd.read_sql('select ' + ','.join(columns) + ' from metadata where deleted != 1 AND fasta_file_id = "' + str(file_id) + '"', con)

        # Location cleaning
        print('Cleaning location', flush=True)
        raw['raw_continent'] = [clean_location(x) for x in raw['continent']]
        raw['raw_country'] = [clean_location(x) for x in raw['country']]
        raw['raw_state'] = [clean_location(x) for x in raw['state']]
        raw = raw.drop(columns=['continent', 'country', 'state'])

        print('Assigning location nodes', flush=True)
        raw['continent_id'] = update_locations_level(loc_db, raw[['raw_continent']].rename(columns={'raw_continent': 'name'}))
        raw['country_id'] = update_locations_level(loc_db, raw[['raw_country', 'continent_id']].rename(columns={'continent_id': 'parent_id', 'raw_country': 'name'}))
        raw['state_id'] = update_locations_level(loc_db, raw[['raw_state', 'country_id']].rename(columns={'country_id': 'parent_id', 'raw_state': 'name'}))
        raw = raw.drop(columns=['raw_continent', 'raw_country', 'raw_state'])
            
        print('Assigning corrected names to location ids', flush=True)
        for pre in ['continent', 'country', 'state']:
            raw = pd.merge(raw, loc_nodes, how='left', left_on=pre + '_id', right_on='id') \
                    .rename(columns={'name': pre }) \
                    .drop(columns=['id', pre + '_id'])

        # Clean dates
        print('Cleaning date', flush=True)
        raw['collection_date'] = [clean_date(x) for x in raw['collection_date']]
        raw['submission_date'] = [clean_date(x) for x in raw['submission_date']]

        # Get unique dates
        unique_collection_date = np.unique([x for x in raw['collection_date'] if x is not None]).tolist()
        unique_submission_date = np.unique([x for x in raw['submission_date'] if x is not None]).tolist()
        unique_dates = np.unique(unique_collection_date + unique_submission_date)
        load_dates(clean_db, unique_dates)

        # Clean sex
        print('Cleaning sex', flush=True)
        raw['sex'] = [clean_sex(x) for x in raw['sex']]

        # Clean age
        print('Cleaning age', flush=True)
        ages = [clean_age(x) for x in raw['age']]
        raw['min_age'] = [x[0] for x in ages]
        raw['max_age'] = [x[1] for x in ages]
        raw = raw.drop(columns=['age'])

        # Pango
        print('Loading pango', flush=True)
        with sqlite3.connect(pango_path) as con:
            pango = pd.read_sql('select accession_id, lineage as our_pango from pango where file_id = "' + str(file_id) + '"', con)
        pango['our_pango'] = [str(x) if x is not np.nan and x is not None and x != 'None' else np.nan for x in pango['our_pango']]
        pango.drop_duplicates(['accession_id'], keep='first', inplace=True)
        raw = pd.merge(raw, pango, how='left', on='accession_id')

        # Get unique pango
        unique_pango = np.unique([str(x) for x in pango['our_pango'] if x is not None and x is not np.nan])
        load_pango(clean_db, pango_config_path, unique_pango)

        if len(to_save) <= 49:
            to_save.append(raw)
            print('Saving sequences to buffor', flush=True)
        else:
            print('Saving buffor to clean database', flush=True)
            with sqlite3.connect(clean_db) as con:
                pd.concat(to_save).to_sql('sequences', con, if_exists='append', index=None)
            to_save = []

if __name__ == "__main__":
    RAW_DB_PATH = os.environ.get("RAW_DB_PATH")
    LOCATIONS_DB_PATH = os.environ.get('LOCATIONS_DB_PATH')
    CLEAN_DB_PATH = os.environ.get("CLEAN_DB_PATH")
    PANGO_PATH = os.environ.get('PANGO_PATH')
    PANGO_CONFIG_PATH = os.environ.get('PANGO_CONFIG_PATH')
    print('Initializing database', flush=True)
    init_db(CLEAN_DB_PATH)
    print('Creating locations database', flush=True)
    init_locations_db(LOCATIONS_DB_PATH)
    print('Cleaning data', flush=True)
    load(RAW_DB_PATH, LOCATIONS_DB_PATH, CLEAN_DB_PATH, PANGO_PATH, PANGO_CONFIG_PATH)
