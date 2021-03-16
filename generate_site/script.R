library(DBI)
library(stringr)

con <- dbConnect(RSQLite::SQLite(), Sys.getenv('DB_PATH'))
res <- dbSendQuery(con, 'SELECT DISTINCT region FROM sequences')
regions <- dbFetch(res)$region
dbClearResult(res)
dbDisconnect(con)

output_path = Sys.getenv('OUTPUT_PATH')
main_region = Sys.getenv('MAIN_REGION')

for (region in regions) {
  region_dir <- gsub(" ", "_", str_squish(gsub("[^a-z0-9 ]","",tolower(region))))
  region_output_path <- paste0(output_path, '/', region_dir)
  Sys.setenv('OUTPUT_PATH'=region_output_path)
  Sys.setenv('REGION'=region)
  source('lineage_report.R')
}

Sys.setenv('OUTPUT_PATH'=output_path)
Sys.setenv('REGION'=main_region)
source('lineage_report.R')
