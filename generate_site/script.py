import os
import sqlite3
import random
import time
import re
import sys
import pandas as pd
import json
import shutil
from datetime import datetime

run_id = str(int(time.time() * 1000))

clean_db = os.environ.get('CLEAN_DB')
log_db = os.environ.get('LOG_DB')
tmp_dir = os.environ.get('TMP_DIR') + '/generate_site_' + run_id
build_dir = tmp_dir + '/build'
output_path = os.environ.get('OUTPUT_PATH')
generation_date = os.environ.get('GENERATION_DATE')
os.makedirs(tmp_dir)
os.makedirs(build_dir)
print('Running site generator (tmp_dir: %s)' % tmp_dir, flush=True)

with sqlite3.connect(clean_db) as con:
    cur = con.cursor()
    cur.execute("select continent, country from sequences group by continent, country having count(*) > 300 order by continent, country")
    regions = [{'continent': r[0], 'country': r[1] } for r in cur.fetchall()]

with sqlite3.connect(log_db) as con:
    cur = con.cursor()
    # Prepare tables
    cur.execute('CREATE TABLE IF NOT EXISTS log (id INTEGER PRIMARY KEY AUTOINCREMENT, iteration INT NOT NULL, continent TEXT NOT NULL, country TEXT NOT NULL, success INT NOT NULL, time TEXT NOT NULL)')
    cur.execute('CREATE TABLE IF NOT EXISTS time_log (id INT NOT NULL, log_id INTEGER NOT NULL, name TEXT NOT NULL, type TEXT NOT NULL, time REAL NOT NULL, PRIMARY KEY (id, log_id), FOREIGN KEY (log_id) REFERENCES log(id))')
    con.commit()

    # Get regions that was successfully built at least one in the last 4 iterations
    cur.execute('SELECT continent, country FROM log WHERE iteration > (SELECT MAX(iteration) FROM log) - 4 GROUP BY continent, country HAVING SUM(success) >= 1')
    last_success_regions = [{'continent': r[0], 'country': r[1] } for r in cur.fetchall()]

    # Get all regions in log
    cur.execute('SELECT DISTINCT continent, country FROM log')
    not_new_regions = [{'continent': r[0], 'country': r[1] } for r in cur.fetchall()]

    # Get averaged ratio of successes in last 10 iterations
    cur.execute('SELECT AVG(avg_success) FROM (SELECT AVG(CAST(success as FLOAT)) as avg_success FROM log GROUP BY iteration ORDER BY iteration DESC LIMIT 10)')
    tmp = cur.fetchall()
    last_success_ratio = tmp[0][0] or 0

# Limit regions without success builds in history
if os.environ.get('RUN_ALL') is None:
    # Build regions with positive history or the new one
    # 10% chance of retry for region that failed last time
    regions = [r for r in regions if r in last_success_regions or r not in not_new_regions or random.random() < 0.1]

# Define properties for each region
for region in regions:
    # Pretty label for region
    region['label'] = region['continent'] + ' / ' + region['country']
    # Simplified name for directories
    region['simplified'] = re.sub(r'_+', '_', re.sub(r'[^a-z0-9 ]', '', region['label'].lower()).rstrip(' ').lstrip(' ').replace(' ', '_')).replace('europe_', '')
    # dir for site build
    region['build_dir'] = build_dir + '/' + region['simplified']
    # tmp path for region time log
    region['log_path'] = tmp_dir + '/time_log_' + region['simplified'] + '.csv'


# Run builds
success = []
for index, region in enumerate(regions):
    region['build_time'] = str(datetime.now())
    print('[%s / %s] Generating %s [%s]' % (index + 1, len(regions), region['label'], region['build_time']), flush=True)
    print('Build dir: %s' % region['build_dir'], flush=True)
    os.makedirs(region['build_dir'])

    # Parameters GENERATION_DATE, CLEAN_DB are inherited from parent scope
    os.environ['INSTALL_PACKAGE'] = str(int(len(success) == 0))
    os.environ['TIME_LOG_PATH'] = region['log_path']
    os.environ['OUTPUT_DATE_REGION_PATH'] = region['build_dir']
    os.environ['CONTINENT'] = region['continent']
    os.environ['COUNTRY'] = region['country']

    # run
    out = os.system('Rscript script.R')
    region['success'] = out == 0
    if region['success']:
        region['log'] = pd.read_csv(region['log_path'])
        success.append(region)


success_ratio = len(success) / len(regions)
print('Success ratio: %s\nSuccess: %s\nFailed: %s' % (success_ratio, [x['label'] for x in regions if x['success']], [x['label'] for x in regions if not x['success']]), flush=True)

with sqlite3.connect(log_db) as con:
    cur = con.cursor()
    # Exclusive lock on database (prevent from reading)
    cur.execute('BEGIN EXCLUSIVE')
    # get iteration id
    cur.execute('select IFNULL(max(iteration) + 1, 0) from log')
    iteration = cur.fetchall()[0][0]
    print('Saving logs. Iteration id: %s' % iteration, flush=True)

    # get log id
    cur.execute('select IFNULL(max(id) + 1, 1) from log')
    log_id = cur.fetchall()[0][0]
    for region in regions:
        cur.execute('INSERT INTO log (id, iteration, continent, country, success, time) VALUES (?, ?, ?, ?, ?, ?)', (log_id, iteration, region['continent'], region['country'], region['success'], region['build_time']))
        region['log_id'] = log_id
        log_id += 1
    con.commit()
    for region in [r for r in regions if r['success']]:
        for index, row in region['log'].iterrows():
            cur.execute('INSERT INTO time_log (id, log_id, name, type, time) VALUES (?, ?, ?, ?, ?)', (index, region['log_id'], row['name'], row['type'], row['time']))
    con.commit()

if success_ratio < 0.7 * last_success_ratio and os.environ.get('SKIP_RATIO_CHECK') is None:
    print('Success ratio is smaller than 70% of averaged success ratio of last iterations(%s). Stopping.' % last_success_ratio, flush=True)
    print('Set env SKIP_RATIO_CHECK=1 to skip this check', flush=True)
    sys.exit(1)


print('Creating summary', flush=True)
source_summary_file = os.path.dirname(os.path.realpath(__file__)) + '/source/index_source_summary.html'
shutil.copy(source_summary_file, build_dir + '/index.html')


print('Creating language files', flush=True)
def get_lang_source(lang):
    path = os.path.dirname(os.path.realpath(__file__)) + '/source/lang_' + lang + '.txt'
    return pd.read_csv(path, sep=':', quoting=3).set_index('tag')['names'].to_dict()
# create dict
i18n_value = {lang: get_lang_source(lang) for lang in ['pl', 'en']}
# save
with open(build_dir + '/i18n.json', 'w') as f:
    f.write(json.dumps(i18n_value))


print('Saving regions list file', flush=True)
regions_list_value = [{'name': region['label'], 'dir': region['simplified']} for region in success]
# save
with open(build_dir + '/regions.json', 'w') as f:
    json.dump(regions_list_value, f)


print('Copying generated site to production directory', flush=True)
site_path = output_path + '/' + generation_date
shutil.rmtree(site_path, ignore_errors=True)
shutil.copytree(build_dir, site_path)

print('Removing tmp directory', flush=True)
shutil.rmtree(tmp_dir, ignore_errors=True)

print('Updating dates file', flush=True)
with open(output_path + '/dates.json', 'r') as f:
    dates_list = json.load(f)
    if generation_date not in dates_list:
        dates_list.append(generation_date)
with open(output_path + '/dates.json', 'w') as f:
    json.dump(dates_list, f)
