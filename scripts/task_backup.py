import os
import time
from datetime import datetime
import sys
import glob
import config
from config import data_dir, backup_dir, backups_number, site_dist, clean_db_path, excluded_from_backup

for d in [data_dir, backup_dir, site_dist]:
    if not os.path.exists(d):
        os.makedirs(d)

filename = datetime.now().strftime("%Y-%m-%d_%H-%M-%S") + '.tar.gz'
to_precompress = [config.clean_db_path, config.db_path, config.pango_merged_file, config.clades_merged_file]
to_exclude = [config.clades_output_dir, config.pango_output_dir, '.git'] + excluded_from_backup

# Precompress single files
for path in to_precompress:
    out = os.system('bash -c "xz -k -z -1 -f ' + path + ' "')
    if out != 0:
        sys.exit(out >> 8)

exclude_args = ["--exclude='" + path + "'" for path in to_precompress + to_exclude]

out = os.system('bash -c "tar -cf - ' + ' '.join(exclude_args) + ' ' + data_dir + ' ' + site_dist + ' |gzip > ' + backup_dir + '/' + filename + '"')
if out != 0:
    sys.exit(out >> 8)

# This time format can be sorted as string
backups = glob.glob(backup_dir + '/*.tar.gz')
backups.sort()
to_remove = max(len(backups) - backups_number, 0)
for i in range(to_remove):
    print('Removing old backup ' + backups[i])
    os.remove(backups[i])
