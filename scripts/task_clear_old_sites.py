import os
import sys
import glob
import re
from config import site_dist, old_sites_to_keep
from datetime import datetime, timedelta

last_date_to_save = (datetime.now() - timedelta(days=old_sites_to_keep - 1)).strftime("%Y-%m-%d")

paths = glob.glob(site_dist + '/*')
subdirs = [os.path.basename(f) for f in paths if os.path.isdir(f) and len(glob.glob(f + '/*')) > 0]
dates = [d for d in subdirs if re.match(r"\d{4}-\d\d-\d\d", d)]
to_clear = [d for d in dates if d < last_date_to_save]

print('Directories to clear: %s' % [site_dist + '/' + date for date in to_clear])

out = 0
for date in to_clear:
    out = os.system('rm -rf ' + site_dist + '/' + date + '/*')
    if out != 0:
        sys.exit(out >> 8)
sys.exit(out >> 8)
