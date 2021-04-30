#!/usr/bin/env python3
# coding: utf-8
import os
from datetime import datetime
from fasta_scrapper import manage_fasta_scrapping
from meta_table_scrapper import manage_table_scrapping
from variants_scrapper import manage_variants_scrapping
from pango_scrapper import manage_pango_scrapping
from utils import init_db

if __name__ == "__main__":
    DB_PATH = os.environ["DB_PATH"]
    FASTA_FILES_DIR = os.environ["FASTA_FILES_DIR"]
    MINIMUM_START_DATE = datetime.strptime(os.environ['MINIMUM_START_DATE'], '%Y-%m-%d').date()
    MAX_DATE_RANGE = int(os.environ['MAX_DATE_RANGE'])
    ROOT_REGION = os.environ['ROOT_REGION']
    TMP_DIR = os.environ['TMP_DIR']
    LOG_DIR = os.environ['LOG_DIR']
    PANGO_FILE = os.environ['PANGO_FILE']

    init_db(DB_PATH)
    if not os.environ.get('SKIP_METATABLE'):
        manage_table_scrapping(DB_PATH, MINIMUM_START_DATE, MAX_DATE_RANGE, ROOT_REGION, LOG_DIR)
    if not os.environ.get('SKIP_FASTA'):
        manage_fasta_scrapping(DB_PATH, FASTA_FILES_DIR, TMP_DIR, LOG_DIR)
    if not os.environ.get('SKIP_VARIANTS'):
        manage_variants_scrapping(DB_PATH, MAX_DATE_RANGE, ROOT_REGION, LOG_DIR)
    if not os.environ.get('SKIP_PANGO'):
        manage_pango_scrapping(DB_PATH, MAX_DATE_RANGE, ROOT_REGION, PANGO_FILE, LOG_DIR)
