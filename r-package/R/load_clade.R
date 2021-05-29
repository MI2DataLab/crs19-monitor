#' @export
load_clade <- function(db_path, continent, country, start_date, end_date) {
  query <- "
  select is_alarm, count, date, C.clade, B.clade_count
  from (select clade.clade, is_alarm, clade_count
        from clade
                 join
             (select our_clade as clade, count(*) as clade_count
              from sequences
              where continent = $CONTINENT
                and country = $COUNTRY
              group by clade) as D on D.clade = clade.clade
        order by is_alarm desc, clade_count desc
        limit 15) as B
           join (
      select our_clade as clade, 0 as count, $MINDATE as date
      from sequences
      where continent = $CONTINENT
        AND country = $COUNTRY
      group by clade
      having min(collection_date) > $MINDATE
      UNION ALL
      select our_clade as clade, count(*) as count, $MINDATE as date
      from sequences
      where continent = $CONTINENT
        AND country = $COUNTRY
        AND collection_date <= $MINDATE
      group by clade
      UNION ALL
      select our_clade as clade, count(*) as count, collection_date as date
      from sequences
      where continent = $CONTINENT
        AND country = $COUNTRY
        AND date > $MINDATE
      group by date, clade
      UNION ALL
      select our_clade as clade, 0 as count, $MAXDATE as date
      from sequences
      where continent = $CONTINENT
        and country = $COUNTRY
      group by our_clade
      having max(collection_date) < $MAXDATE
  ) as C on C.clade = B.clade
  ORDER BY clade_count desc, date;
  "
  read_sql(db_path, query, list(CONTINENT=continent, COUNTRY=country, MINDATE=start_date, MAXDATE=end_date))
}
