#' @export
load_category_location <- function(db_path, continent, country, start_date, max_regions) {
  query <- "
  select B.state, class, count(*) as count, week_start
  from sequences
           join(select continent, country, state
                from sequences
                where continent = $CONTINENT
                  and country = $COUNTRY
                group by continent, country, state
                order by count(*) desc
                limit $LIMIT) as B
               on sequences.continent = B.continent AND sequences.country = B.country AND sequences.state = B.state
           join dates on sequences.collection_date = dates.date
           join pango on sequences.our_pango = pango.pango
  where week_start > $MIN_DATE
  group by B.state, class, week_start
  order by week_start, B.state;
  "
  read_sql(db_path, query, list(CONTINENT=continent, COUNTRY=country, LIMIT=max_regions, MIN_DATE=start_date))
}

#' @export
load_category <- function(db_path, continent, country, start_date) {
  query <- "
  select class, count(*) as count, week_start
  from sequences
           join dates on sequences.collection_date = dates.date
           join pango on sequences.our_pango = pango.pango
  where week_start > $MIN_DATE AND continent = $CONTINENT AND country = $COUNTRY
  group by class, week_start
  order by week_start;
  "
  read_sql(db_path, query, list(CONTINENT=continent, COUNTRY=country, MIN_DATE=start_date))
}
