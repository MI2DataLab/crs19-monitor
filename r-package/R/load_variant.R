#' @export
load_variant_col <- function(db_path, continent, country, start_date) {
    query <- "
    select color, count, week_start, C.clade
    from clade
             join (select week_start, clade, sum(count) as count
                   from dates
                            join (select collection_date as date, our_clade as clade, count(*) as count
                                  from sequences
                                  where continent = ?
                                    AND country = ?
                                    AND collection_date > ?
                                  group by date, clade) as B on B.date = dates.date
                   where week_start > ?
                   group by week_start, clade) as C on C.clade = clade.clade
    "
    read_sql(db_path, query, list(continent, country, start_date, start_date))
}

#' @export
load_variant_point <- function(db_path, continent, country, start_date) {
    query <- "
    select color, count, date, C.clade
    from clade
             join (select collection_date as date, our_clade as clade, count(*) as count
                   from sequences
                   where continent = ?
                     AND country = ?
                     AND collection_date > ?
                   group by date, clade) as C on C.clade = clade.clade
    "
    read_sql(db_path, query, list(continent, country, start_date))
}
