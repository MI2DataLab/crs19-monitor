import os
import time
from datetime import datetime
import sys
import glob
from config import data_dir, backup_dir, backups_number

if not os.path.exists(data_dir):
    print('Skipping backup, because data directory doeas not exists')

if not os.path.exists(backup_dir):
    os.makedirs(backup_dir)

filename = datetime.now().strftime("%Y-%m-%d_%H-%M-%S") + '.tar.gz'

out = os.system('bash -c "tar -cf - ' + data_dir + '|gzip > ' + backup_dir + '/' + filename + '"')
if out != 0:
    sys.exit(out >> 8)

# This time format can be sorted as string
backups = glob.glob(backup_dir + '/*.tar.gz')
backups.sort()
to_remove = max(len(backups) - backups_number, 0)
for i in range(to_remove):
    print('Removing old backup ' + backups[i])
    os.remove(backups[i])
