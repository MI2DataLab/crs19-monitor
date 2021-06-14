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
    print('Filling dates table')
    fmt = '%Y-%m-%d'
    dates = [datetime.strptime(x, fmt) for x in dates]
    with sqlite3.connect(clean_db) as con:
        cur = con.cursor()
        for d in dates:
            fields = ['date', 'year', 'month', 'day', 'week', 'week_start', 'month_start', 'is_weekend', 'weekday']
            values = [d.strftime(fmt), d.year, d.month, d.day, d.isocalendar()[1], (d - timedelta(days=d.weekday())).strftime(fmt), datetime(d.year, d.month, 1).strftime(fmt), d.weekday() >= 6, d.weekday() + 1]
            cur.execute('INSERT INTO dates (' + ','.join(fields) + ') VALUES (' + ','.join((['?'] * len(fields))) + ')', values)
        con.commit()


def load_clade(clean_db, clade_config_path, unique_clade):
    """
    Fill clade table
    """
    print('Filling clade table')
    config = pd.read_csv(clade_config_path, sep='\t')
    others = [str(x) for x in unique_clade if x not in list(config['clade'])]
    with sqlite3.connect(clean_db) as con:
        config.to_sql('clade', con, if_exists='append', index=None)
        cur = con.cursor()
        for other in others:
            cur.execute('INSERT INTO clade (clade, color, is_alarm, name) VALUES (?, ?, ?, ?)', (other, None, 0, ''))
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
    print('Filling pango table')
    handle = open(pango_config_path, 'r')
    config = yaml.safe_load(handle)
    handle.close()
    with sqlite3.connect(clean_db) as con:
        cur = con.cursor()
        for p in unique_pango:
            attrs = get_pango_attributes(config, str(p))
            cur.execute('INSERT INTO pango (pango, color, is_alarm, name) VALUES (?, ?, ?, ?)', (p, attrs['color'], int(attrs['alarm']), attrs['name']))
        con.commit()


def load_substitutions(clean_db, raw_db, df):
    """
    Fill substitutions and substitutions_bridge tables
    """
    def load_part(con, frames, ids_gen, source):
        cur = con.cursor()
        for sub_id, sub_name in ids_gen.get_update():
            cur.execute('INSERT INTO substitutions (substitution_id, substitution, source) VALUES (?, ?, ?)', (sub_id, sub_name, source))
        con.commit()

        merged = pd.concat(frames)
        merged.to_sql('substitutions_bridge', con, if_exists='append', index=None)

    class ids_generator:
        def __init__(self, start_id=0):
            self.last_new_id = start_id
            self.ids_dict = {}
            self.last_loaded_id = start_id
        def get_id(self, name):
            id_ = self.ids_dict.get(name)
            if id_ is None:
                id_ = self.last_new_id = self.last_new_id + 1
                self.ids_dict[name] = id_
            return id_
        def get_update(self):
            ids = [(id_, name) for name, id_ in self.ids_dict.items() if id_ > self.last_loaded_id]
            self.last_loaded_id = self.last_new_id
            return ids

    print('Filling substitutions and substitutions_bridge table')
    with sqlite3.connect(clean_db) as con:
        frames = []
        id_gen = ids_generator()
        for index, row in tqdm(df.iterrows(), total=df.shape[0]):
            # Each row contain substitutions as strings seperated by comma
            subs = np.unique((row['aaSubstitutions'] if type(row['aaSubstitutions']) is str else '').split(','))
            if len(subs) == 1 and subs[0] == '':
                continue
            # Generate ids for given substitutions
            subs_ids = [id_gen.get_id(sub) for sub in subs]
            frames.append(pd.DataFrame({'accession_id': row['accession_id'], 'substitution_id': subs_ids}))
            # Load part to db
            if len(frames) == 50000:
                load_part(con, frames, id_gen, 'our')
                frames = []
        if len(frames) > 0:
            load_part(con, frames, id_gen, 'our')
            frames = []
        # We want to keep separate rows for different sources
        id_gen = ids_generator(id_gen.last_new_id)
        with sqlite3.connect(raw_db) as raw_con:
            raw_cur = raw_con.cursor()
            raw_cur.execute('SELECT accession_id, substitutions FROM metadata WHERE substitutions IS NOT NULL')
            for accession_id, substitutions_str in tqdm(raw_cur.fetchall()):
                # Each row contain substitutions as strings seperated by comma
                subs = np.unique((substitutions_str if type(substitutions_str) is str else '').split(','))
                if len(subs) == 1 and subs[0] == '':
                    continue
                # Generate ids for given substitutions
                subs_ids = [id_gen.get_id(sub) for sub in subs]
                frames.append(pd.DataFrame({'accession_id': accession_id, 'substitution_id': subs_ids}))
                # Load part to db
                if len(frames) == 50000:
                    load_part(con, frames, id_gen, 'gisaid')
                    frames = []
            if len(frames) > 0:
                load_part(con, frames, id_gen, 'gisaid')
                frames = []


def load(raw_db, loc_db, clean_db, pango_path, clades_path, clade_config_path, pango_config_path, skip_substitutions):
    """
    Cleans data and loads to new database
    """
    with sqlite3.connect(raw_db) as con:
        columns = [
            'accession_id', 'location', 'passage', 'submission_date', 'collection_date', 'host',
            'gisaid_pango', 'clade as gisaid_clade', 'variant as gisaid_variant', 'sex', 'age'
        ]
        raw = pd.read_sql('select ' + ','.join(columns) + ' from metadata', con)
    with sqlite3.connect(loc_db) as con:
        cur = con.cursor()
        cur.execute('UPDATE mappings SET count = 0')
        loc_nodes = pd.read_sql('select name, id, iso_code, lat, lng from nodes', con)

    # Location cleaning
    print('Cleaning location')
    raw['raw_continent'] = [extract_location(x, 0) for x in raw['location']]
    raw['raw_country'] = [extract_location(x, 1) for x in raw['location']]
    raw['raw_state'] = [extract_location(x, 2) for x in raw['location']]
    raw = raw.drop(columns=['location'])

    raw['continent_id'] = update_locations_level(loc_db, raw[['raw_continent']].rename(columns={'raw_continent': 'name'}))
    raw['country_id'] = update_locations_level(loc_db, raw[['raw_country', 'continent_id']].rename(columns={'continent_id': 'parent_id', 'raw_country': 'name'}))
    raw['state_id'] = update_locations_level(loc_db, raw[['raw_state', 'country_id']].rename(columns={'country_id': 'parent_id', 'raw_state': 'name'}))

    for pre in ['continent', 'country', 'state']:
        raw = pd.merge(raw, loc_nodes, how='left', left_on=pre + '_id', right_on='id') \
                .rename(columns={'name': pre, 'iso_code': pre + '_iso_code', 'lat': pre + '_lat', 'lng': pre + '_lng'}) \
                .drop(columns=['id', pre + '_id', 'raw_' + pre])

    print('Saving geography')
    geography = raw.groupby(['continent', 'country', 'state']).first().reset_index()[[a + b for a in ['continent', 'country', 'state'] for b in ['', '_iso_code', '_lat', '_lng']]]
    with sqlite3.connect(clean_db) as con:
        geography.to_sql('geography', con, if_exists='append', index=None)

    raw = raw.drop(columns=[a + b for a in ['continent', 'country', 'state'] for b in ['_iso_code', '_lat', '_lng']])
    

    # Clean dates
    print('Cleaning date')
    raw['collection_date'] = [clean_date(x) for x in raw['collection_date']]
    raw['submission_date'] = [clean_date(x) for x in raw['submission_date']]

    # Get unique dates
    unique_collection_date = np.unique([x for x in raw['collection_date'] if x is not None]).tolist()
    unique_submission_date = np.unique([x for x in raw['submission_date'] if x is not None]).tolist()
    unique_dates = np.unique(unique_collection_date + unique_submission_date)
    load_dates(clean_db, unique_dates)

    # Clean sex
    print('Cleaning sex')
    raw['sex'] = [clean_sex(x) for x in raw['sex']]

    # Clean age
    print('Cleaning age')
    ages = [clean_age(x) for x in raw['age']]
    raw['min_age'] = [x[0] for x in ages]
    raw['max_age'] = [x[1] for x in ages]
    raw = raw.drop(columns=['age'])

    # Clades
    print('Loading clade')
    clades = pd.read_csv(clades_path, sep='\t')
    clades['accession_id'] = [x.split('|')[1] for x in clades['seqName']]
    clades['clade'] = [str(x) if x is not np.nan and x is not None else np.nan for x in clades['clade']]
    clades.drop_duplicates(['accession_id'], keep='first', inplace=True)
    # substitutions will be used later
    substitutions = clades[['accession_id', 'aaSubstitutions']]
    clades = clades[['accession_id', 'clade']].rename(columns={'clade': 'our_clade'})
    raw = pd.merge(raw, clades, how='left', on='accession_id')

    # Get unique clade
    unique_clade = np.unique([str(x) for x in clades['our_clade'] if x is not None and x is not np.nan])
    load_clade(clean_db, clade_config_path, unique_clade)

    # Pango
    print('Loading pango')
    pango = pd.read_csv(pango_path)
    pango['accession_id'] = [x.split('|')[1] for x in pango['taxon']]
    pango['lineage'] = [str(x) if x is not np.nan and x is not None and x != 'None' else np.nan for x in pango['lineage']]
    pango = pango[['accession_id', 'lineage']].rename(columns={'lineage': 'our_pango'})
    pango.drop_duplicates(['accession_id'], keep='first', inplace=True)
    raw = pd.merge(raw, pango, how='left', on='accession_id')

    # Get unique clade
    unique_pango = np.unique([str(x) for x in pango['our_pango'] if x is not None and x is not np.nan])
    load_pango(clean_db, pango_config_path, unique_pango)

    # Load
    print('Saving sequences to clean database')
    with sqlite3.connect(clean_db) as con:
        raw.to_sql('sequences', con, if_exists='append', index=None)

    # Substitutions
    if not skip_substitutions:
        load_substitutions(clean_db, raw_db, substitutions)


if __name__ == "__main__":
    RAW_DB_PATH = os.environ.get("RAW_DB_PATH")
    LOCATIONS_DB_PATH = os.environ.get('LOCATIONS_DB_PATH')
    CLEAN_DB_PATH = os.environ.get("CLEAN_DB_PATH")
    PANGO_PATH = os.environ.get('PANGO_PATH')
    CLADES_PATH = os.environ.get('CLADES_PATH')
    CLADE_CONFIG_PATH = os.environ.get('CLADE_CONFIG_PATH')
    PANGO_CONFIG_PATH = os.environ.get('PANGO_CONFIG_PATH')
    SKIP_SUBSTITUTIONS = not os.environ.get('LOAD_SUBSTITUTIONS')
    print('Initializing database')
    init_db(CLEAN_DB_PATH)
    print('Creating locations database')
    init_locations_db(LOCATIONS_DB_PATH)
    print('Cleaning data')
    load(RAW_DB_PATH, LOCATIONS_DB_PATH, CLEAN_DB_PATH, PANGO_PATH, CLADES_PATH, CLADE_CONFIG_PATH, PANGO_CONFIG_PATH, SKIP_SUBSTITUTIONS)
