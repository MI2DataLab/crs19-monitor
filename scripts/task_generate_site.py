import os
import glob
import sys
from datetime import datetime
from config import repo_path, site_dist, pango_merged_file, clades_merged_file, mutation_merged_file, db_path, remotes, rsync_remotes

work_dir = repo_path + '/generate_site'
exec_path = "script.R"
main_region = 'Poland'

os.environ["LINEAGE_DATE"] = datetime.today().strftime('%Y/%m/%d')
os.environ["LINEAGE_REPORT_PATH"] = pango_merged_file
os.environ["NEXTCLADE_REPORT_PATH"] = clades_merged_file
os.environ["MUTATION_REPORT_PATH"] = mutation_merged_file
os.environ["DB_PATH"] = db_path
os.environ["MAIN_REGION"] = main_region
os.environ["OUTPUT_PATH"] = site_dist

out = 0
if not os.environ.get('NOT_BUILD'):
    out = os.system('cd ' + work_dir + ' && Rscript ' + exec_path)

if out == 0 and not os.environ.get('NOT_PUSH'):
    for remote in remotes:
        os.environ['GIT_SSH_COMMAND'] = 'ssh -i ' + remote[1] + ' -o IdentitiesOnly=yes'
        out = os.system('cd ' + site_dist + ' && echo "' + remote[2] + '" > CNAME && git add -A && git commit -m "update" && git push -f -u ' + remote[0] + ' gh-pages')
        if out != 0:
            sys.exit(out >> 8)

if out == 0 and not os.environ.get('NOT_PUSH'):
    for remote in rsync_remotes:
        out = os.system('rsync -avu --exclude \'gg_objects.rda\' --exclude \'.git\' ' + site_dist + '/ ' + remote)
        if out != 0:
            sys.exit(out >> 8)
sys.exit(out >> 8)
