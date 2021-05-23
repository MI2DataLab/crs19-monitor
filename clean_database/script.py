import sqlite3
import os

import pandas as pd
from unidecode import unidecode
from pathlib import Path
from datetime import datetime


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


def simplify_location(location):
    return None if location is None else unidecode(location).lower().replace('-', ' ').replace('_', ' ')


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
        return datetime.strptime(date, '%Y-%m-%d').strftime('%Y-%m-%d')
    except:
        return None

def update_locations(raw_db, loc_db):
    """
    Adds new locations to locations db and updates counts
    """
    with sqlite3.connect(raw_db) as con:
        raw = pd.read_sql('select accession_id, location from metadata', con)
    with sqlite3.connect(loc_db) as con:
        simplified = pd.read_sql('select continent, country, simple_name, full_name from simplified', con)
    raw['continent'] = [extract_location(x, 0) for x in raw['location']]
    raw['country'] = [extract_location(x, 1) for x in raw['location']]
    raw['raw_state'] = [extract_location(x, 2) for x in raw['location']]
    raw['simple_name'] = [simplify_location(x) for x in raw['raw_state']]

    # Get most popular full name of state for each simplified state name
    stats_counts = raw.groupby(['continent', 'country', 'raw_state', 'simple_name']).size().reset_index(name='count')
    most_popular_full_name = stats_counts.sort_values('count').groupby(['continent', 'country', 'simple_name'], sort=False).tail(1).rename(columns={'raw_state': 'popular_full_name'})

    # Assign full name to simplified names from locations database
    merged = pd.merge(most_popular_full_name, simplified, how='left', left_on=['continent', 'country', 'simple_name'], right_on=['continent', 'country', 'simple_name'])
    # Rows not present in locations database
    new_states = merged.loc[merged['full_name'].isnull()]

    # Count of each simplified name
    count_stats = raw.groupby(['continent', 'country', 'simple_name']).size().reset_index(name='count')

    print('Adding %s new states to locations database' % new_states.shape[0])

    # Add new states to locations db
    # pylint: disable=unused-variable
    with sqlite3.connect(loc_db) as con:
        cur = con.cursor()
        for index, row in new_states.iterrows():
            cur.execute('INSERT INTO simplified (full_name, continent, country, simple_name) VALUES (?, ?, ?, ?)', (row['popular_full_name'], row['continent'], row['country'], row['simple_name']))
        cur.execute('UPDATE simplified SET count = 0')
        for index, row in count_stats.iterrows():
            cur.execute('UPDATE simplified SET count = ? WHERE continent = ? AND country = ? AND simple_name = ?', (row['count'], row['continent'], row['country'], row['simple_name']))
        con.commit()


def load(raw_db, loc_db, clean_db, pango_path, clades_path):
    """
    Cleans data and loads to new database
    """
    with sqlite3.connect(raw_db) as con:
        columns = [
            'accession_id', 'location', 'passage', 'submission_date', 'collection_date', 'host',
            'gisaid_pango', 'clade as gisaid_clade', 'variant as gisaid_variant'
        ]
        raw = pd.read_sql('select ' + ','.join(columns) + ' from metadata', con)
    with sqlite3.connect(loc_db) as con:
        simplified = pd.read_sql('select continent, country, simple_name, full_name from simplified', con)

    # Location cleaning
    print('Cleaning location')
    raw['continent'] = [extract_location(x, 0) for x in raw['location']]
    raw['country'] = [extract_location(x, 1) for x in raw['location']]
    raw['raw_state'] = [extract_location(x, 2) for x in raw['location']]
    raw['simple_name'] = [simplify_location(x) for x in raw['raw_state']]
    raw = pd.merge(raw, simplified, how='left', left_on=['continent', 'country', 'simple_name'], right_on=['continent', 'country', 'simple_name'])
    raw = raw.rename(columns={'full_name': 'state'}).drop(columns=['raw_state', 'simple_name', 'location'])

    # Clean dates
    print('Cleaning date')
    raw['collection_date'] = [clean_date(x) for x in raw['collection_date']]
    raw['submission_date'] = [clean_date(x) for x in raw['submission_date']]

    # Clades
    print('Loading clade')
    clades = pd.read_csv(clades_path, sep='\t')
    clades['accession_id'] = [x.split('|')[1] for x in clades['seqName']]
    clades = clades[['accession_id', 'clade']].rename(columns={'clade': 'our_clade'})
    clades.drop_duplicates(['accession_id'], keep='first', inplace=True)
    raw = pd.merge(raw, clades, how='left', on='accession_id')

    # Pango
    print('Loading pango')
    pango = pd.read_csv(pango_path)
    pango['accession_id'] = [x.split('|')[1] for x in pango['taxon']]
    pango = pango[['accession_id', 'lineage']].rename(columns={'lineage': 'our_pango'})
    pango.drop_duplicates(['accession_id'], keep='first', inplace=True)
    raw = pd.merge(raw, pango, how='left', on='accession_id')

    # Load
    print('Saving to clean database')
    with sqlite3.connect(clean_db) as con:
        #cur = con.cursor()
        #columns = list(raw.columns)
        #columns_values = [[row[c] for c in columns] for index, row in raw.iterrows()]
        # Columns names are safe
        #cur.executemany('INSERT INTO sequences (' + ','.join(columns) + ') VALUES (' + ','.join(['?'] * len(columns)) + ')', columns_values)
        #con.commit()
        raw.to_sql('sequences', con, if_exists='append', index=None)


if __name__ == "__main__":
    RAW_DB_PATH = os.environ.get("RAW_DB_PATH")
    LOCATIONS_DB_PATH = os.environ.get('LOCATIONS_DB_PATH')
    CLEAN_DB_PATH = os.environ.get("CLEAN_DB_PATH")
    PANGO_PATH = os.environ.get('PANGO_PATH')
    CLADES_PATH = os.environ.get('CLADES_PATH')
    print('Initializing database')
    init_db(CLEAN_DB_PATH)
    print('Creating locations database')
    init_locations_db(LOCATIONS_DB_PATH)
    update_locations(RAW_DB_PATH, LOCATIONS_DB_PATH)
    print('Cleaning data')
    load(RAW_DB_PATH, LOCATIONS_DB_PATH, CLEAN_DB_PATH, PANGO_PATH, CLADES_PATH)
