import os
import time
from datetime import datetime
import sys
import glob
from config import data_dir, backup_dir, backups_number, site_dist, clean_db_path

for d in [data_dir, backup_dir, site_dist]:
    if not os.path.exists(d):
        os.makedirs(d)

filename = datetime.now().strftime("%Y-%m-%d_%H-%M-%S") + '.tar.gz'

out = os.system('bash -c "xz -k -z -1 -f ' + clean_db_path + ' "')
if out != 0:
    sys.exit(out >> 8)
out = os.system('bash -c "tar -cf - --exclude=\'clean.sqlite\' --exclude=\'.git\' ' + data_dir + ' ' + site_dist + ' |gzip > ' + backup_dir + '/' + filename + '"')
if out != 0:
    sys.exit(out >> 8)

# This time format can be sorted as string
backups = glob.glob(backup_dir + '/*.tar.gz')
backups.sort()
to_remove = max(len(backups) - backups_number, 0)
for i in range(to_remove):
    print('Removing old backup ' + backups[i])
    os.remove(backups[i])
