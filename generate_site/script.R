library(DBI)
library(stringr)
library(jsonlite)

con <- dbConnect(RSQLite::SQLite(), Sys.getenv('DB_PATH'))
res <- dbSendQuery(con, "SELECT country FROM metadata GROUP BY country HAVING COUNT(*) > 200")
# regions <- dbFetch(res)$country
regions <- c('Poland', 'Czech Republic', 'Germany')
dbClearResult(res)
dbDisconnect(con)

regions <- lapply(regions, function(name) {
	list(
		name=name,
		dir=gsub(" ", "_", str_squish(gsub("[^a-z0-9 ]","",tolower(name))))
	)
})

output_path = Sys.getenv('OUTPUT_PATH')
main_region = Sys.getenv('MAIN_REGION')
path_date = gsub('/', '-', Sys.getenv('LINEAGE_DATE'))


# Preload data for subscripts
lineage_report <- Sys.getenv("LINEAGE_REPORT_PATH")
nextclade_report <- Sys.getenv("NEXTCLADE_REPORT_PATH")
lineage_full <- read.table(lineage_report, sep = ",", header = TRUE, fileEncoding = "UTF-8")
colnames(lineage_full)[1:2] = c('Sequence.name', 'Lineage')
lineage_full$accession_id <- stringi::stri_extract_first_regex(lineage_full$Sequence.name, 'EPI_ISL_[0-9]+')
nextclade_full <- read.table(nextclade_report, sep = "\t", header = TRUE, fileEncoding = "UTF-8")
nextclade_full$accession_id <- stringi::stri_extract_first_regex(nextclade_full$seqName, 'EPI_ISL_[0-9]+')
print(paste('Full pango rows:',nrow(lineage_full)))
print(paste('Full nextclade rows:',nrow(nextclade_full)))


for (region in regions) {
  region_output_path <- paste0(output_path, '/', path_date, '/', region$dir)
  Sys.setenv('OUTPUT_PATH'=region_output_path)
  Sys.setenv('REGION'=region$name)
  source('lineage_report.R')
}

# Save regions list
write(toJSON(regions, auto_unbox=TRUE), paste0(output_path, '/', path_date, '/regions.json'))

# Save dates list
subdirs <- list.dirs(path=output_path, full.names=FALSE, recursive=FALSE)
date_dirs <- stringi::stri_subset_regex(subdirs, '^\\d{4}-\\d{2}-\\d{2}$')
write(toJSON(date_dirs, auto_unbox=FALSE), paste0(output_path, '/dates.json'))


# Add summary
file.copy('./source/index_source_summary.html', paste0(output_path, '/', path_date, '/index.html'), overwrite=TRUE)

langs <- c('pl', 'en')
i18n <- lapply(langs, function(lang) {
	i18n_table <- read.table(paste0("lang_", lang, ".txt"), sep=":", header = TRUE, fileEncoding = "UTF-8", quote=NULL)
	# Transform table to dictionary
	obj = as.list(i18n_table[,"names"])
	names(obj) <- i18n_table[,"tag"]
	obj
})
names(i18n) <- langs
write(toJSON(i18n, auto_unbox=TRUE), paste0(output_path, '/', path_date, '/i18n.json'))
