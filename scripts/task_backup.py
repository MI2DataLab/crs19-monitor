import os
import time
from datetime import datetime
import sys
from config import data_dir, backup_dir

if not os.path.exists(data_dir):
    print('Skipping backup, because data directory doeas not exists')

if not os.path.exists(backup_dir):
    os.makedirs(backup_dir)

filename = datetime.now().strftime("%Y-%m-%d_%H-%M-%S") + '.tar.gz'

out = os.system('bash -c "tar -cf - ' + data_dir + '|gzip > ' + backup_dir + '/' + filename + '"')
sys.exit(out >> 8)
