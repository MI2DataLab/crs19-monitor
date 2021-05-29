#' @export
load_pango <- function(db_path, continent, country, start_date, end_date) {
  query <- "
  select is_alarm, count, date, C.pango, B.pango_count
  from (select pango.pango, is_alarm, pango_count
        from pango
                 join
             (select our_pango as pango, count(*) as pango_count
              from sequences
              where continent = $CONTINENT
                and country = $COUNTRY
              group by pango) as D on D.pango = pango.pango
        order by is_alarm desc, pango_count desc
        limit 15) as B
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
  ) as C on C.pango = B.pango
  ORDER BY pango_count desc, date;
  "
  read_sql(db_path, query, list(CONTINENT=continent, COUNTRY=country, MINDATE=start_date, MAXDATE=end_date))
}
