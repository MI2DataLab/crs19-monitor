#' @export
load_sequence_count <- function(db_path, continent, country) {
  query <- "
    select week_start, sum(count) as count
    from dates
             join (select collection_date as date, count(*) as count
                   from sequences
                   where continent = ? AND country = ?
                   group by date) as B on B.date = dates.date
    group by week_start
  "
  read_sql(db_path, query, list(continent, country))
}


#' @export
load_sequence_cumulative <- function(db_path, continent, country) {
  query <- "
    select collection_date as date, count(*) as count
    from sequences
    where continent = ?
      AND country = ?
    group by date
  "
  read_sql(db_path, query, list(continent, country))
}

#' @export
load_sequence_stats <- function(db_path, continent, country) {
  query <- "
    select count(*) as count, max(collection_date) as last_collection_date
    from sequences
    where continent = ?
      AND country = ?
  "
  read_sql(db_path, query, list(continent, country))
}
