import os
import json
import sqlite3
import itertools
from flask import Flask, abort, request, redirect, Response
from flask_cors import CORS
from difflib import SequenceMatcher
import sys 
from locations_utils import merge_nodes

class App:
    def __init__(self, db_path):
        self.db_path = db_path
        self.flask = Flask(__name__)
        self.flask.add_url_rule('/nodes', view_func=self.get_nodes)
        self.flask.add_url_rule('/task/<int:parent_id>', view_func=self.get_task)
        self.flask.add_url_rule('/task/<int:parent_id>', view_func=self.solve_task, methods=['POST'])
        CORS(self.flask)

    def get_db(self):
        """
        Initializes connection to db and return connection handle
        """
        return sqlite3.connect(self.db_path)

    def run_server(self, host='0.0.0.0', port=8080):
        """
        Starts flask server on provided port and hostname
        """
        print(host)
        self.flask.run(debug=False, host=host, port=port)

    # API METHODS

    def get_nodes(self):
        with self.get_db() as con:
            cur = con.cursor()
            cur.execute('SELECT id, name, iso_code, lat, lng, count, complete FROM nodes left join (select parent_id, sum(count) as count, cast(sum(correct*count) as float)/sum(count) as complete from (select parent_id, sum(count) as count, lat is not null and lng is not null and iso_code is not null as correct from mappings M join nodes N on M.node_id = N.id group by parent_id, correct) group by parent_id) F on nodes.id = F.parent_id')
            result = [{'node_id': x[0], 'name': x[1], 'iso_code': x[2], 'lat': x[3], 'lng': x[4], 'count': x[5], 'complete': x[6]} for x in cur.fetchall()]
        return Response(json.dumps(result), mimetype="application/json")

    def get_task(self, parent_id):
        with self.get_db() as con:
            cur = con.cursor()
            cur.execute('SELECT simple_name, count, node_id FROM mappings WHERE parent_id = ?', (parent_id, ))
            result = cur.fetchall()
            mappings = [{'simple_name': x[0], 'node_id': x[2], 'count': x[1]} for x in result]
            def get_similarity(node_a, node_b):
                return SequenceMatcher(None, node_a['simple_name'], node_b['simple_name']).ratio()
            similarity = [{'a': a['simple_name'], 'b': b['simple_name'], 'similarity': get_similarity(a, b)} for a, b in itertools.combinations(mappings, 2)]
        return Response(json.dumps({'mappings': mappings, 'similarity': similarity}), mimetype="application/json")

    def solve_task(self, parent_id):
        with self.get_db() as con:
            cur = con.cursor()
            data = request.json
            for row in data.get('mappings'):
                cur.execute('select node_id from mappings where simple_name = ? and parent_id = ?', (row['simple_name'], parent_id))
                old_node_id = (cur.fetchall() or [(None, None)])[0][0]
                if row['node_id'] != old_node_id:
                    merge_nodes(self.db_path, [row['node_id'], old_node_id], sort_by_count=False)
            con.commit()
            for row in data.get('nodes'):
                cur.execute('UPDATE nodes SET iso_code = ?, lat = ?, lng = ?, name = ? WHERE id = ?', (row.get('iso_code'), row.get('lat'), row.get('lng'), row.get('name'), row.get('node_id')))
            con.commit()
        self.clean_unused_nodes()
        return Response("")

    def clean_unused_nodes(self):
        with self.get_db() as con:
            cur = con.cursor()
            cur.execute("delete from nodes where id in (select id from nodes left join mappings M on M.node_id = nodes.id where simple_name is NULL and id > 1)")
            con.commit()

if __name__ == '__main__':
    app = App(os.environ.get('DB_PATH'))
    app.run_server(os.environ.get('SERVER_HOST') or '0.0.0.0', os.environ.get('SERVER_PORT') or 8080)
