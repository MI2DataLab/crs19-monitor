#' @export
load_who_cumulative <- function(db_path, continent, country, start_date, end_date) {
  query <- "
  select sum(count) as count, date, ifnull(name, 'other') as name, color, class
  from pango
           join (
      select our_pango as pango, 0 as count, $MINDATE as date
      from sequences
      where continent = $CONTINENT
        AND country = $COUNTRY
      group by pango
      having min(collection_date) > $MINDATE
      UNION ALL
      select our_pango as pango, count(*) as count, $MINDATE as date
      from sequences
      where continent = $CONTINENT
        AND country = $COUNTRY
        AND collection_date <= $MINDATE
      group by pango
      UNION ALL
      select our_pango as pango, count(*) as count, collection_date as date
      from sequences
      where continent = $CONTINENT
        AND country = $COUNTRY
        AND date > $MINDATE
      group by date, pango
      UNION ALL
      select our_pango as pango, 0 as count, $MAXDATE as date
      from sequences
      where continent = $CONTINENT
        and country = $COUNTRY
      group by our_pango
      having max(collection_date) < $MAXDATE
  ) as C on C.pango = pango.pango
  group by date, name
  ORDER BY date;
  "
  read_sql(db_path, query, list(CONTINENT=continent, COUNTRY=country, MINDATE=start_date, MAXDATE=end_date))
}

#' @export
load_who_location <- function(db_path, continent, country, start_date, max_regions, class) {
  query <- "
  select B.state, count(*) as count, week_start, ifnull(name, 'other') as name, color
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
  where week_start > $MIN_DATE AND class = $CLASS
  group by B.state, name, week_start
  order by week_start, B.state;
  "
  read_sql(db_path, query, list(CONTINENT=continent, COUNTRY=country, LIMIT=max_regions, MIN_DATE=start_date, CLASS=class))
}

#' @export
load_who <- function(db_path, continent, country, start_date, class) {
  query <- "
  select count(*) as count, week_start, ifnull(name, 'other') as name, color
  from sequences
           join dates on sequences.collection_date = dates.date
           join pango on sequences.our_pango = pango.pango
  where week_start > $MIN_DATE AND class = $CLASS
  AND continent = $CONTINENT AND country = $COUNTRY
  group by name, week_start
  order by week_start;
  "
  read_sql(db_path, query, list(CONTINENT=continent, COUNTRY=country, MIN_DATE=start_date, CLASS=class))
}
