#' @export
load_metadata_dates <- function(db_path, continent, country, start_submission_date, start_collection_date) {
  query <- "
  select color, collection_date, submission_date
  from pango
           join (select collection_date, submission_date, our_pango
                 from sequences
                 where continent = $CONTINENT
                   AND country = $COUNTRY
                   AND collection_date IS NOT NULL
                   AND submission_date IS NOT NULL
                   AND submission_date > $MIN_SUBMISSION_DATE
                   AND collection_date > $MIN_COLLECTION_DATE) AS B on pango.pango = B.our_pango
  ORDER BY RANDOM();
  "
  read_sql(db_path, query, list(CONTINENT=continent, COUNTRY=country, MIN_SUBMISSION_DATE=as.character(start_submission_date), MIN_COLLECTION_DATE=as.character(start_collection_date)))
}
