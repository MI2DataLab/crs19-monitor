#' @export
load_location <- function(db_path, continent, country, start_date, max_regions) {
  query <- "
  select B.state, is_alarm, count(*) as count, week_start
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
           join clade on sequences.our_clade = clade.clade
  where week_start > $MIN_DATE
  group by B.state, is_alarm, week_start
  order by week_start, B.state;
  "
  read_sql(db_path, query, list(CONTINENT=continent, COUNTRY=country, LIMIT=max_regions, MIN_DATE=START_DATE))
}
