cat('---- START \n')


# ----- GLOBAL VARS ----- #

DB_PATH <- Sys.getenv('DB_PATH')
OUTPUT_PATH <- Sys.getenv('OUTPUT_PATH')
LINEAGE_PATH <- Sys.getenv("LINEAGE_REPORT_PATH")
NEXTCLADE_PATH <- Sys.getenv("NEXTCLADE_REPORT_PATH")
LINEAGE_DATE <- Sys.getenv('LINEAGE_DATE')

LINEAGE_DATE_CLEAN <- gsub('/', '-', LINEAGE_DATE)
OUTPUT_DATE_PATH <- paste0(OUTPUT_PATH, '/', LINEAGE_DATE_CLEAN)
LANGUAGES <- c('pl', 'en')

ALARM_MUTATION <- "N501Y"
ALARM_PATTERN <- "501Y"
ALARM_PANGO <- c("B.1.1.7", "B.1.351", "P.1")
ALARM_CLADE <- c("20I/501Y.V1","20H/501Y.V2", "20J/501Y.V3")
MAX_REGIONS <- 23
NO_MONTHS_PLOTS <- 4
NO_MONTHS_PLOTS_LONG <- 8
PALETTE <- structure(
  c("#E9C622", "#51A4B8", "#E5BC13", "#67AFBF", "#E1B103",
    "#82B8B6", "#E58600", "#ACC07E", "#3B9AB2", "#7F00FF", "#EB5000", "#F21A00"),
  .Names = c("20A.EU2", "19A", "20D", "19B", "20C", "20E (EU1)",
             "20G", "20A", "20B", "20J/501Y.V3", "20H/501Y.V2", "20I/501Y.V1"))
SMOOTH_VARIANTS <- c("20I/501Y.V1", "20A", "20B")


# ----- READ DATA ----- #

query <- "SELECT country FROM metadata GROUP BY country HAVING COUNT(*) > 200"
metadata <- covar::read_sql(DB_PATH, query)

regions <- metadata$country
regions <- c('Poland', 'Czech Republic', 'Germany') # TODO DELETE

lineage_full <- read.table(LINEAGE_PATH, sep = ",", header = TRUE, fileEncoding = "UTF-8")
colnames(lineage_full)[1:2] <- c('Sequence.name', 'Lineage')
lineage_full$accession_id <- stringi::stri_extract_first_regex(lineage_full$Sequence.name, 'EPI_ISL_[0-9]+')

nextclade_full <- read.table(NEXTCLADE_PATH, sep = "\t", header = TRUE, fileEncoding = "UTF-8")
nextclade_full$accession_id <- stringi::stri_extract_first_regex(nextclade_full$seqName, 'EPI_ISL_[0-9]+')

cat(paste('full pango rows:', nrow(lineage_full), '\n'))
cat(paste('full nextclade rows:', nrow(nextclade_full), '\n'))


# ----- DATES ----- #

subdirs <- list.dirs(path = OUTPUT_PATH, full.names = FALSE, recursive = FALSE)
date_dirs <- stringi::stri_subset_regex(subdirs, '^\\d{4}-\\d{2}-\\d{2}$')
write(jsonlite::toJSON(date_dirs, auto_unbox = FALSE), paste0(OUTPUT_PATH, '/dates.json'))


# ----- SUMMARY ----- #

dir.create(OUTPUT_DATE_PATH, recursive = TRUE, showWarnings = FALSE)
if (file.copy('./source/index_source_summary.html',
              paste0(OUTPUT_DATE_PATH, '/index.html'),
              overwrite = TRUE)) cat('--- CREATE SUMMARY \n')

covar::create_i18n(
  input_paths = sapply(LANGUAGES, function(lang) paste0("./source/lang_", lang, ".txt")),
  output_path = OUTPUT_DATE_PATH
)


# ----- LOAD PACKAGES ----- #

suppressMessages(library(dplyr))          # data
library(tidyr)                            # drop_na
suppressMessages(library(lubridate))      # date
options(dplyr.summarise.inform = FALSE)


# ----- REPORTS ----- #

cat('--- CREATE REPORTS \n')

source('lineage_report.R')
for (region in regions) {
  cat(paste('-- REGION:', region, '\n'))
  lineage_report(region, lineage_full, nextclade_full)
}


# ----- REGIONS ----- #

regions_list <- lapply(regions, function(name) {
  list(
    name = name,
    dir = gsub(" ", "_", stringr::str_squish(gsub("[^a-z0-9 ]", "", tolower(name))))
  )
})
write(jsonlite::toJSON(regions_list, auto_unbox = TRUE), paste0(OUTPUT_DATE_PATH, '/regions.json'))

cat('---- END \n')
