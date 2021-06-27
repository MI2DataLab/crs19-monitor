import pandas as pd
from unidecode import unidecode
import numpy as np
import sqlite3


def simplify_location(location):
    return None if location is None else unidecode(location).lower().replace('-', ' ').replace('_', ' ')


def update_locations_level(loc_db, df, update_counts=True):
    """
    df - pandas dataframe with columns name, parent_id
    """
    with sqlite3.connect(loc_db) as con:
        mappings = pd.read_sql('select parent_id, simple_name, node_id from mappings', con)

    df['simple_name'] = [simplify_location(x) for x in df['name']]
    if 'parent_id' not in df.columns:
        df['parent_id'] = [1] * df.shape[0]

    # Get most popular name for each simplified name
    stats_counts = df.groupby(['parent_id', 'simple_name', 'name']).size().reset_index(name='count')
    most_popular_full_name = stats_counts.sort_values('count').groupby(['parent_id', 'simple_name'], sort=False).tail(1).rename(columns={'name': 'popular_name'})

    # Assign node id to simplified names from locations database
    merged = pd.merge(most_popular_full_name, mappings, how='left', left_on=['parent_id', 'simple_name'], right_on=['parent_id', 'simple_name'])

    # Rows not present in locations database
    new_nodes = merged.loc[merged['node_id'].isnull()]

    # Count of each simplified name
    count_stats = df.groupby(['parent_id', 'simple_name']).size().reset_index(name='count')

    print('Adding %s new nodes to locations database' % new_nodes.shape[0], flush=True)
    # pylint: disable=unused-variable
    with sqlite3.connect(loc_db) as con:
        cur = con.cursor()
        for index, row in new_nodes.iterrows():
            cur.execute('INSERT INTO nodes (name) VALUES (?)', (row['popular_name'],))
            cur.execute('INSERT INTO mappings (parent_id, simple_name, node_id) VALUES (?, ?, (SELECT MAX(id) FROM nodes))', (row['parent_id'], row['simple_name']))
        if update_counts:
            for index, row in count_stats.iterrows():
                cur.execute('UPDATE mappings SET count = ? WHERE simple_name = ? AND parent_id = ?', (row['count'], row['simple_name'], row['parent_id']))
        con.commit()
        mappings = pd.read_sql('select parent_id, simple_name, node_id from mappings', con)
        return pd.merge(df, mappings, how='left', left_on=['parent_id', 'simple_name'], right_on=['parent_id', 'simple_name'])['node_id'].tolist()


def set_missing_details(loc_db, df, tags=['lat', 'lng', 'iso_code']):
    """
    df - pandas dataframe with columns id and those specified with tags
    """
    with sqlite3.connect(loc_db) as con:
        cur = con.cursor()
        for tag in tags:   
            for index, row in df.iterrows():
                cur.execute('UPDATE nodes SET ' + tag + ' = ? WHERE id = ? AND ' + tag + ' IS NULL', (row[tag], row['id']))
        con.commit()

def merge_nodes(loc_db, ids, sort_by_count=True):
    ids = [int(x) for x in ids]
    ids_str = ','.join([str(x) for x in ids])
    with sqlite3.connect(loc_db) as con:
        df = pd.read_sql("""
            select sum(count) as count, N.id, N.iso_code, N.lat, N.lng, N.name
            from mappings as M join nodes as N on M.node_id = N.id
            WHERE M.node_id in (""" + ids_str + """) group by M.node_id
        """, con)
    df['second_order'] = [-1 * ids.index(x) for x in df['id']]
    ordering = ['count', 'second_order'] if sort_by_count else ['second_order']
    df = df.sort_values(ordering, ascending=False)
    merged_values = {}
    for tag in ['iso_code', 'lat', 'lng', 'id', 'name']:
        merged_values[tag] = next(filter(lambda x: not pd.isna(x), df[tag]), None)
    with sqlite3.connect(loc_db) as con:
        cur = con.cursor()
        cur.execute('UPDATE nodes SET name = ?, lat = ?, lng = ?, iso_code = ? WHERE id = ?',
                    [merged_values[tag] for tag in ['name', 'lat', 'lng', 'iso_code', 'id']])
        cur.execute('UPDATE mappings SET node_id = ? WHERE node_id IN (' + ids_str + ')', (merged_values['id'],))
        con.commit()
    # Merging children nodes
    for node_id in ids:
        if node_id == merged_values['id']:
            continue
        # Get pairs of children with common simple_name
        with sqlite3.connect(loc_db) as con:
            cur = con.cursor()
            cur.execute("""
                select A.node_id, B.node_id from
                (select simple_name, node_id from mappings where parent_id = ?) AS A
                join
                (select simple_name, node_id from mappings where parent_id = ?) AS B
                on A.simple_name = B.simple_name
                where
                A.node_id != B.node_id
            """, (merged_values['id'], node_id))
            conflicts = cur.fetchall()
        # Merge each pair
        for a,b in conflicts:
            merge_nodes(loc_db, [a, b])
        # Set new parent for nodes
        with sqlite3.connect(loc_db) as con:
            cur = con.cursor()
            cur.execute('UPDATE OR IGNORE mappings SET parent_id = ? WHERE parent_id = ?', (merged_values['id'], node_id))
            con.commit()

        
def delete_empty_mappings(loc_db):
    with sqlite3.connect(loc_db) as con:
        cur = con.cursor()
        cur.execute("DELETE FROM nodes WHERE id IN (SELECT id FROM nodes LEFT JOIN mappings M on M.node_id = nodes.id WHERE simple_name is NULL and id > 1)")
        con.commit()
