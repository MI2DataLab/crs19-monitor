import os
import json
import sqlite3
import itertools
from flask import Flask, abort, request, redirect, Response
from flask_cors import CORS
from difflib import SequenceMatcher

class App:
    def __init__(self, db_path):
        self.db_path = db_path
        self.flask = Flask(__name__)
        CORS(self.flask)
        self.flask.add_url_rule('/', view_func=self.get_available_countries)
        self.flask.add_url_rule('/task/<string:continent>/<string:country>/', view_func=self.get_task)
        self.flask.add_url_rule('/task/<string:continent>/<string:country>/', view_func=self.solve_task, methods=['POST'])

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

    def get_available_countries(self):
        """
        Returns list of countries with their continent present in database
        """
        with self.get_db() as con:
            cur = con.cursor()
            cur.execute('SELECT DISTINCT continent, country FROM simplified')
            result = [{'continent': x[0], 'country': x[1]} for x in cur.fetchall()]
        return Response(json.dumps(result), mimetype="application/json")

    def get_task(self, continent, country):
        with self.get_db() as con:
            cur = con.cursor()
            cur.execute('SELECT simple_name, full_name, count FROM simplified WHERE continent = ? AND country = ?', (continent, country))
            result = cur.fetchall()
            nodes = [{'simple_name': x[0], 'full_name': x[1], 'count': x[2]} for x in result]
            def get_similarity(node_a, node_b):
                return SequenceMatcher(None, node_a['simple_name'], node_b['simple_name']).ratio()
            edges = [{'a': a['simple_name'], 'b': b['simple_name'], 'similarity': get_similarity(a, b)} for a, b in itertools.combinations(nodes, 2)]
        return Response(json.dumps({'nodes': nodes, 'edges': edges}), mimetype="application/json")

    def solve_task(self, continent, country):
        with self.get_db() as con:
            cur = con.cursor()
            data = request.json
            for row in data.get('nodes'):
                cur.execute('UPDATE simplified SET full_name = ? WHERE simple_name = ? AND continent = ? AND country = ?', (row['full_name'], row['simple_name'], continent, country))
            con.commit()
        return Response("")

if __name__ == '__main__':
    app = App(os.environ.get('DB_PATH'))
    app.run_server(os.environ.get('SERVER_HOST') or '0.0.0.0', os.environ.get('SERVER_PORT') or 8080)
