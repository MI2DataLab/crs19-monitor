cat('---- START')
# ----- GLOBAL VARS ----- #

DB_PATH <- Sys.getenv('DB_PATH')
OUTPUT_PATH <- Sys.getenv('OUTPUT_PATH')
LINEAGE_PATH <- Sys.getenv("LINEAGE_REPORT_PATH")
NEXTCLADE_PATH <- Sys.getenv("NEXTCLADE_REPORT_PATH")
LINEAGE_DATE <- Sys.getenv('LINEAGE_DATE')

LINEAGE_DATE_CLEAN <- gsub('/', '-', LINEAGE_DATE)
OUTPUT_DATE_PATH <- paste0(OUTPUT_PATH, '/', LINEAGE_DATE_CLEAN)
LANGUAGES <- c('pl', 'en')


# ----- READ DATA ----- #

query <- "SELECT country FROM metadata GROUP BY country HAVING COUNT(*) > 200"
metadata <- monitor::read_sql(DB_PATH, query)

regions <- metadata$country
regions <- c('Poland', 'Czech Republic', 'Germany') # TODO DELETE

lineage_full <- read.table(LINEAGE_PATH, sep = ",", header = TRUE, fileEncoding = "UTF-8")
colnames(lineage_full)[1:2] <- c('Sequence.name', 'Lineage')
lineage_full$accession_id <- stringi::stri_extract_first_regex(lineage_full$Sequence.name, 'EPI_ISL_[0-9]+')

nextclade_full <- read.table(NEXTCLADE_PATH, sep = "\t", header = TRUE, fileEncoding = "UTF-8")
nextclade_full$accession_id <- stringi::stri_extract_first_regex(nextclade_full$seqName, 'EPI_ISL_[0-9]+')

cat(paste('full pango rows:', nrow(lineage_full)))
cat(paste('full nextclade rows:', nrow(nextclade_full)))


# ----- DATES ----- #

subdirs <- list.dirs(path = OUTPUT_PATH, full.names = FALSE, recursive = FALSE)
date_dirs <- stringi::stri_subset_regex(subdirs, '^\\d{4}-\\d{2}-\\d{2}$')
write(jsonlite::toJSON(date_dirs, auto_unbox = FALSE), paste0(OUTPUT_PATH, '/dates.json'))


# ----- SUMMARY ----- #

dir.create(OUTPUT_DATE_PATH, recursive = TRUE, showWarnings = FALSE)
if (file.copy('./source/index_source_summary.html',
              paste0(OUTPUT_DATE_PATH, '/index.html'),
              overwrite = TRUE)) cat('--- CREATE SUMMARY')

monitor::create_i18n(
  input_paths = sapply(LANGUAGES, function(lang) paste0("./source/lang_", lang, ".txt")),
  output_path = OUTPUT_DATE_PATH
)


# ----- REPORTS ----- #

cat('--- CREATE REPORTS')

source('lineage_report.R')
for (region in regions) {
  cat(paste('-- REGION:', region))
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

cat('---- END')
