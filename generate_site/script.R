# ----- READ DATA ----- #

db_path <- Sys.getenv('DB_PATH')
output_path <- Sys.getenv('OUTPUT_PATH')
lineage_path <- Sys.getenv("LINEAGE_REPORT_PATH")
nextclade_path <- Sys.getenv("NEXTCLADE_REPORT_PATH")
main_region <- Sys.getenv('MAIN_REGION')
lineage_date_clean <- gsub('/', '-', Sys.getenv('LINEAGE_DATE'))

query <- "SELECT country FROM metadata GROUP BY country HAVING COUNT(*) > 200"
con <- RSQLite::dbConnect(RSQLite::SQLite(), db_path)
res <- RSQLite::dbSendQuery(con, query)
metadata <- RSQLite::dbFetch(res)
RSQLite::dbClearResult(res)
RSQLite::dbDisconnect(con)

regions <- metadata$country
regions <- c('Poland', 'Czech Republic', 'Germany')

# Preload data for subscripts
lineage_full <- read.table(lineage_path, sep = ",", header = TRUE, fileEncoding = "UTF-8")
colnames(lineage_full)[1:2] <- c('Sequence.name', 'Lineage')
lineage_full$accession_id <- stringi::stri_extract_first_regex(lineage_full$Sequence.name, 'EPI_ISL_[0-9]+')

nextclade_full <- read.table(nextclade_path, sep = "\t", header = TRUE, fileEncoding = "UTF-8")
nextclade_full$accession_id <- stringi::stri_extract_first_regex(nextclade_full$seqName, 'EPI_ISL_[0-9]+')

print(paste('Full pango rows:', nrow(lineage_full)))
print(paste('Full nextclade rows:', nrow(nextclade_full)))


for (region in regions) {
  Sys.setenv('REGION') <- region
  Sys.setenv('REGION_DIR') <- gsub(" ", "_", stringr::str_squish(gsub("[^a-z0-9 ]", "", tolower(region))))
  source('lineage_report.R')
}

# Save regions list
write(jsonlite::toJSON(regions, auto_unbox = TRUE), paste0(output_path, '/', lineage_date_clean, '/regions.json'))

# Save dates list
subdirs <- list.dirs(path = output_path, full.names = FALSE, recursive = FALSE)
date_dirs <- stringi::stri_subset_regex(subdirs, '^\\d{4}-\\d{2}-\\d{2}$')
write(jsonlite::toJSON(date_dirs, auto_unbox = FALSE), paste0(output_path, '/dates.json'))


# Add summary
file.copy('./source/index_source_summary.html', paste0(output_path, '/', lineage_date_clean, '/index.html'), overwrite = TRUE)

langs <- c('pl', 'en')
i18n <- lapply(langs, function(lang) {
	i18n_table <- read.table(paste0("./source/lang_", lang, ".txt"), sep = ":", header = TRUE, fileEncoding = "UTF-8", quote = NULL)
	# Transform table to dictionary
	obj <- as.list(i18n_table[,"names"])
	names(obj) <- i18n_table[,"tag"]
	obj
})
names(i18n) <- langs
write(jsonlite::toJSON(i18n, auto_unbox = TRUE), paste0(output_path, '/', lineage_date_clean, '/i18n.json'))
