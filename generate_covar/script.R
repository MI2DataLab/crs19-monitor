library(dplyr)
library(tidyr)
library(RSQLite)
library(DBI)
library(lubridate)
library(ggplot2)
library(patchwork)
library(stringr)
library(forcats)

# ---- HARDCODED ---- #
variants_order <- c("Alpha", "Beta", "Gamma", "Delta", "Omicron", "Dziki")
allowed_states <- c("Wielkopolskie", "Małopolskie", "Lubuskie", "Pomorskie", "Dolnośląskie", "Mazowieckie", "Podkarpackie", "Śląskie", "Zachodniopomorskie", "Podlaskie", "Opolskie", "Warmińsko-Mazurskie", "Świętokrzyskie", "Kujawsko-Pomorskie", "Lubelskie", "Łódzkie")
countries <- c("Angola", "Argentina", "Armenia", "Aruba", "Australia", "Austria", "Bahrain", "Bangladesh", "Belarus", "Belgium", "Belize", "Bolivia", "Bonaire", "Botswana", "Brazil", "Bulgaria", "Cambodia", "Cameroon", "Canada", "Chile", "Colombia", "Croatia", "Cyprus", "Denmark", "Ecuador", "Egypt", "Estonia", "Finland", "France", "Gabon", "Gambia", "Georgia", "Germany", "Ghana", "Gibraltar", "Greece", "Guadeloupe", "Hungary", "Iceland", "India", "Indonesia", "Iran", "Iraq", "Ireland", "Israel", "Italy", "Japan", "Jordan", "Kazakhstan", "Kenya", "Latvia", "Lebanon", "Lithuania", "Luxembourg", "Malaysia", "Malta", "Mauritius", "Mayotte", "Mexico", "Montenegro", "Morocco", "Mozambique", "Nepal", "Netherlands", "Nigeria", "Norway", "Oman", "Pakistan", "Palestine", "Panama", "Paraguay", "Peru", "Philippines", "Poland", "Portugal", "Qatar", "Reunion", "Romania", "Russia", "Rwanda", "Senegal", "Serbia", "Singapore", "Slovakia", "Slovenia", "Spain", "Sweden", "Switzerland", "Taiwan", "Thailand", "Togo", "Tunisia", "Turkey", "Uganda", "Ukraine", "United Kingdom", "Uruguay", "USA", "Vietnam", "Zambia", "Zimbabwe")

# ---- UTILS ---- #

read_sql <- function(path, query, bind = NULL) {
  con <- RSQLite::dbConnect(RSQLite::SQLite(), path)
  res <- RSQLite::dbSendQuery(con, query)
  if (!is.null(bind)) RSQLite::dbBind(res, bind)
  metadata <- RSQLite::dbFetch(res)
  RSQLite::dbClearResult(res)
  RSQLite::dbDisconnect(con)
  metadata
}

# ---- INPUT ---- #

lineage_date <- lubridate::today()
db_path <- Sys.getenv('CLEAN_DB_PATH', unset='clean.sqlite')
build_dir <- Sys.getenv('BUILD_PATH', unset='frontend/public')

# ---- CREATE DIRS ---- #

if (!dir.exists(build_dir)) { dir.create(build_dir) }
if (!dir.exists(paste0(build_dir, '/data'))) { dir.create(paste0(build_dir, '/data')) }
if (!dir.exists(paste0(build_dir, '/grafika'))) { dir.create(paste0(build_dir, '/grafika')) }
if (!dir.exists(paste0(build_dir, '/grafika/pango'))) { dir.create(paste0(build_dir, '/grafika/pango')) }
if (!dir.exists(paste0(build_dir, '/grafika/area'))) { dir.create(paste0(build_dir, '/grafika/area')) }

# ---- GISAID MAP ---- #

df <- read_sql(db_path, "
  SELECT S.state,
         state_lat,
         state_lng,
         submission_date,
         IFNULL(name, 'other') AS name,
         count(*) AS count
  FROM sequences AS S
  JOIN pango AS P ON P.pango = S.our_pango
  JOIN geography AS G ON G.continent = S.continent
  AND G.country = S.country
  AND G.state = S.state
  WHERE S.country = 'Poland'
    AND submission_date >= '2020-01-01'
  GROUP BY S.state,
           S.country,
           name,
           submission_date
")

df_wider <- pivot_wider(df, names_from = name, values_from = count, values_fill = 0) %>%
  # Dla próbek bez lokalizacji ustawiamy pozycję, która jest poza mapą
  mutate(state_lat=replace_na(state_lat, -20), state_lng=replace_na(state_lng, -20)) %>%
  rename(data=submission_date, miasto=state, szerokosc=state_lat, dlugosc=state_lng)

writeLines(jsonlite::toJSON(df_wider, pretty=TRUE), paste0(build_dir, '/data/gisaid.json'))


# ---- AGE ---- #

df <- read_sql(db_path, "
  select 
    min_age as age, 
    ifnull(name, 'dziki') as name, 
    color 
  from 
    sequences as S 
    join pango as P on P.pango = S.our_pango 
  where 
    min_age = max_age 
    and min_age is not null 
    and country = 'Poland' 
    and continent = 'Europe' 
    and (
      is_alarm 
      or name is null
    )
") %>%
  mutate(name = str_to_title(name)) %>%
  mutate(name = factor(name, levels=c(variants_order, setdiff(name, variants_order))))

palette <- df %>% select(name, color) %>% unique %>% tibble::deframe()
p <- ggplot(df, aes(pmin(age, 100), fill=name)) +
  geom_histogram(bins = 20, color = "white") +
  facet_wrap(ncol=1, ~name, scales = "free_y") +
  scale_fill_manual(values = palette, name="") +
  scale_y_continuous("Liczba sekwencji", expand = c(0,0)) +
  scale_x_continuous("Wiek", breaks = seq(0,100,5)) +
  theme_bw() + theme(strip.background = element_rect(fill = "#110c35", color = "white"),
                     strip.text = element_text(colour = "white"),
                     legend.position = "none",
                     text = element_text(family = "Barlow", size = 12),
                     panel.background = element_rect(fill = "transparent", colour = NA),  
                     plot.background = element_rect(fill = "transparent", colour = NA),
                     panel.border = element_rect(colour = "#110c35", fill = NA)) +
  ggtitle("")
ggsave(paste0(build_dir, "/grafika/age.svg"), p, width = 7, height = 7,  bg = "transparent")

df <- read_sql(db_path, "
  select 
    min_age as age, 
    month_start, 
    ifnull(name, 'dziki') as name, 
    color 
  from 
    sequences as S 
    join pango as P on P.pango = S.our_pango 
    join dates as D on S.collection_date = D.date 
  where 
    min_age = max_age 
    and min_age is not null 
    and country = 'Poland' 
    and continent = 'Europe' 
    and (
      is_alarm 
      or name is null
    ) 
    and month_start > '2021-09-01'
") %>%
  mutate(name = str_to_title(name)) %>%
  mutate(name = factor(name, levels=c(variants_order, setdiff(name, variants_order)))) %>%
  mutate(month_start = substr(month_start, 0, 7))

palette <- df %>% select(name, color) %>% unique %>% tibble::deframe()
p <- ggplot(df, aes(pmin(age, 100), fill=name)) +
  geom_histogram(bins = 20, color = "white") +
  facet_grid(name~month_start, scales = "free_y") +
  scale_fill_manual(values = palette, name="") +
  scale_y_continuous("Liczba sekwencji", expand = c(0,0)) +
  scale_x_continuous("Wiek", breaks = seq(0,100,5)) +
  theme_bw() + theme(strip.background = element_rect(fill = "#110c35", color = "white"),
                     strip.text = element_text(colour = "white"),
                     legend.position = "none",
                     text = element_text(family = "Barlow", size = 12),
                     panel.background = element_rect(fill = "transparent", colour = NA),  
                     plot.background = element_rect(fill = "transparent", colour = NA),
                     panel.border = element_rect(colour = "#110c35", fill = NA)) +
  ggtitle("")
ggsave(paste0(build_dir, "/grafika/age2.svg"), p, width = 12, height = 1 + 2 * length(unique(df$name)),  bg = "transparent")


# ---- STATES WHO ---- #

load_who_location <- function(db_path, continent, country, start_date, max_regions) {
  query <- "
  select B.state, count(*) as count, week_start, ifnull(name, 'dziki') as name, color
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
  where week_start > $MIN_DATE AND (is_alarm OR name IS NULL)
  group by B.state, name, week_start
  order by week_start, B.state;
  "
  read_sql(db_path, query, list(CONTINENT=continent, COUNTRY=country, LIMIT=max_regions, MIN_DATE=start_date))
}

plot_who_location_count <- function(df,
                                     lineage_date,
                                     no_months_plots) {
  palette <- df %>% select(name, color) %>% unique %>% tibble::deframe()
  p <- ggplot(df, aes(ymd(week_start) %m+% days(3), y = count, fill = name)) +
    geom_col() +
    scale_fill_manual(values = palette, name="") +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date) %m+% days(7))) +
    facet_wrap(~state, ncol = 4, scales = "free_y") +
    theme_minimal(base_family = "Arial") +
    scale_y_continuous("", expand = c(0, 0)) +
    labs(x = NULL, y = NULL) + 
    ggtitle("") +
    theme_bw() + theme(strip.background = element_rect(fill = "#110c35", color = "white"),
                       strip.text = element_text(colour = "white"),
                       text = element_text(family = "Barlow"),
                       panel.background = element_rect(fill = "transparent", colour = NA),  
                       plot.background = element_rect(fill = "transparent", colour = NA),
                       panel.border = element_rect(colour = "#110c35", fill = NA),
                       legend.position = "none")
  p
}

#' @export
plot_who_location_proportion <- function(df,
                                         lineage_date,
                                         no_months_plots) {
  palette <- df %>% select(name, color) %>% unique %>% tibble::deframe()
  df <- df %>% group_by(state, week_start) %>% mutate(proportion=count / sum(count))
  p <- ggplot(df, aes(ymd(week_start) %m+% days(3), y = proportion, fill = name)) +
    geom_col() +
    scale_fill_manual(values = palette, name="") +
    scale_y_continuous("", labels = scales::percent, expand = c(0, 0)) +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date) %m+% days(7))) +
    facet_wrap(~state, ncol = 4) +
    labs(x = NULL, y = NULL) + 
    ggtitle("") +
    theme_bw() + theme(strip.background = element_rect(fill = "#110c35", color = "white"),
                       strip.text = element_text(colour = "white"),
                       text = element_text(family = "Barlow"),
                       panel.background = element_rect(fill = "transparent", colour = NA),  
                       plot.background = element_rect(fill = "transparent", colour = NA),
                       panel.border = element_rect(colour = "#110c35", fill = NA),
                       legend.position = "none")
  p
}

plot_who_location_trends <- function(df) {
  palette <- df %>% select(name, color) %>% unique %>% tibble::deframe()
  zeros <- expand.grid(state=unique(df$state), name=unique(df$name), count=0, week_start=unique(df$week_start))
  df <- rbind(df[, c("state", "name", "count", "week_start")], zeros) %>%
    group_by(week_start, name, state) %>%
    summarise(count=sum(count)) %>%
    group_by(state, week_start) %>% mutate(proportion=count / sum(count)) %>%
    ungroup %>%
    filter(!is.nan(proportion) | week_start == max(week_start) | week_start == min(week_start))
  last_day <- df %>%
    group_by(state, name) %>%
    filter(!is.nan(proportion)) %>%
    filter(week_start==max(week_start))
  p <- ggplot(df, aes(x=week_start, y=proportion, ymax=proportion, ymin=0, fill=name, color=name, group=name)) +
    geom_line() +
    geom_point(data=last_day) +
    geom_ribbon(alpha=0.2, color=NA) +
    facet_grid(state~name) +
    scale_fill_manual(values = palette, name="") +
    scale_color_manual(values = palette, name="") +
    scale_y_continuous("Procentowy udział wariantu")+
    theme_void() + xlab("") + theme(legend.position = "none", 
                                    text = element_text(family = "Barlow", size = 14),
                                    strip.text.y = element_text(hjust = 0))
  p
}

df <- load_who_location(db_path, 'Europe', 'Poland', as.character(lineage_date - months(3)), 50) %>%
  filter(state %in% allowed_states) %>%
  mutate(name = str_to_title(name)) %>%
  mutate(name = factor(name, levels=c(variants_order, setdiff(name, variants_order))))

df %>%
  plot_who_location_count(lineage_date, 3) %>%
  ggsave(filename=paste0(build_dir, "/grafika/wojewodztwa_licz.svg"), width=10, height=6, bg="transparent")

df %>%
  plot_who_location_proportion(lineage_date, 3) %>%
  ggsave(filename=paste0(build_dir, "/grafika/wojewodztwa_proc.svg"), width=10, height=6, bg="transparent")

df %>%
  plot_who_location_trends %>%
  ggsave(filename=paste0(build_dir, "/grafika/wojewodztwa_sparkline.svg"), width=7, height=8, bg="transparent")


# ---- COUNTRY WHO ---- #

load_who <- function(db_path, continent, country, start_date) {
  query <- "
  select count(*) as count, week_start, ifnull(name, 'dziki') as name, color
  from sequences
           join dates on sequences.collection_date = dates.date
           join pango on sequences.our_pango = pango.pango
  where week_start > $MIN_DATE AND (is_alarm OR name IS NULL)
  AND continent = $CONTINENT AND country = $COUNTRY
  group by name, week_start
  order by week_start;
  "
  read_sql(db_path, query, list(CONTINENT=continent, COUNTRY=country, MIN_DATE=start_date))
}

plot_who_count <- function(df,
                           lineage_date,
                           no_months_plots,
                           title = "") {
  palette <- df %>% select(name, color) %>% unique %>% tibble::deframe()
  df$title <- title
  p <- ggplot(df, aes(ymd(week_start) %m+% days(3), y = count, fill = name)) +
    geom_col(position = "stack", color = "white") +
    facet_wrap(~title) +
    scale_fill_manual(values = palette, name="") +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date) %m+% days(7))) +
    scale_y_continuous("", expand = c(0, 0)) +
    ggtitle("") +
    labs(x = NULL, y = NULL) + 
    theme_bw() + theme(strip.background = element_rect(fill = "#110c35", color = "white"),
                       strip.text = element_text(colour = "white"),
                       text = element_text(family = "Barlow"),
                       panel.background = element_rect(fill = "transparent", colour = NA),  
                       legend.background = element_rect(fill = "transparent", colour = NA),  
                       plot.background = element_rect(fill = "transparent", colour = NA),
                       panel.border = element_rect(colour = "#110c35", fill = NA))
  p
}

plot_who_proportion <- function(df,
                                lineage_date,
                                no_months_plots,
                                title = "") {
  palette <- df %>% select(name, color) %>% unique %>% tibble::deframe()
  df <- df %>% group_by(week_start) %>% mutate(proportion=count / sum(count))
  df$title <- title
  p <- ggplot(df, aes(ymd(week_start) %m+% days(3), y = proportion * 100, fill = name)) +
    geom_col(position = "stack", color = "white") +
    facet_wrap(~title) +
    scale_fill_manual(values = palette, name="") +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date) %m+% days(7))) +
    scale_y_continuous("", expand = c(0,0), breaks = seq(0,100,10)) +
    ggtitle("") +
    labs(x = NULL, y = NULL) + 
    theme_bw() + theme(strip.background = element_rect(fill = "#110c35", color = "white"),
                       strip.text = element_text(colour = "white"),
                       text = element_text(family = "Barlow"),
                       panel.background = element_rect(fill = "transparent", colour = NA),  
                       legend.background = element_rect(fill = "transparent", colour = NA),  
                       plot.background = element_rect(fill = "transparent", colour = NA),
                       panel.border = element_rect(colour = "#110c35", fill = NA),
                       legend.position = "none")
  p
}


df <- load_who(db_path, 'Europe', 'Poland', as.character(lineage_date - months(3))) %>%
  mutate(name = str_to_title(name)) %>%
  mutate(name = factor(name, levels=c(variants_order, setdiff(name, variants_order))))

df %>%
  plot_who_count(lineage_date, 3, "Liczba sekwencji") %>%
  ggsave(filename=paste0(build_dir, "/grafika/wojewodztwa_all2.svg"), width=4.5, height=3, bg="transparent")

df %>%
  plot_who_proportion(lineage_date, 3, "Udział (procent)") %>%
  ggsave(filename=paste0(build_dir, "/grafika/wojewodztwa_all1.svg"), width=3, height=3, bg="transparent")


# ---- WORLD PANGO ---- #

df <- read_sql(db_path, "
  SELECT 
    class, 
    class_root AS pango, 
    week_start, 
    country, 
    count(*) AS count 
  FROM 
    sequences AS S 
    JOIN pango AS P ON S.our_pango = P.pango 
    JOIN dates AS D ON S.collection_date = D.date 
  WHERE 
    class = 'voi' 
    OR class = 'voc' 
    OR class = 'vum' 
  GROUP BY 
    week_start, 
    class_root, 
    country
")

plot_variant <- function(df, lineage_date, no_months_plots, max_countries) {
  stats <- df %>%
    group_by(country) %>%
    summarise(max_week_count=max(count), count=sum(count)) %>%
    arrange(desc(count)) %>%
    slice(1:max_countries)
  df %>% filter(country %in% stats$country) -> df
  df$country <- factor(df$country, levels=stats$country)
  stats$country <- factor(stats$country, levels=stats$country)
  p <- ggplot(df, aes(x=ymd(week_start), y=count)) +
    facet_wrap(~country, scales = "free_y", ncol = 5) +
    geom_col(fill = "#b00064") +
    geom_text(data = stats, aes(y=max_week_count, label=count), hjust = 0, vjust= 1.5, x=ymd(lineage_date) %m-% months(no_months_plots)) +
    scale_y_continuous("", expand = c(0,0)) +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date) %m+% days(7))) +
    theme_bw() + theme(strip.background = element_rect(fill = "#110c35", color = "white"),
                       strip.text = element_text(colour = "white"),
                       panel.background = element_rect(fill = "transparent", colour = NA),  
                       plot.background = element_rect(fill = "transparent", colour = NA),
                       panel.border = element_rect(colour = "#110c35", fill = NA)) +
    ggtitle("")
  p
}

max_countries <- 50
for (variant in unique(df$pango)) {
  df_variant <- df %>% filter(pango==UQ(variant))
  # Number of months since first case until today
  months_interval <- ceiling(interval(ymd(min(df_variant$week_start)), ymd(lineage_date)) / months(1))
  p <- plot_variant(df_variant, lineage_date, max(min(months_interval, 7), 1), max_countries)
  rows <- ceiling(min(length(unique(df_variant$country)), max_countries) / 5)
  ggsave(paste0(build_dir, "/grafika/pango/", variant, ".svg"), p, width = 8, height = 0.3 + 1.1*rows,  bg = "transparent")
}


# ---- WORLD TRENDS ---- #

smooth_variants_count <- function(df, k, date_column="date", variant_column="variant", count_column="n") {
  tab <- reshape2::acast(df, as.formula(paste(date_column, "~", variant_column)), value.var=count_column, fill=0)
  # add +k days for reporting lag
  for (i in nrow(tab):k) {
    tab[i,] <- colSums(tab[i - (1:k) + 1,])
  }
  tab <- apply(tab, 1, function(x) x / sum(x))
  tab <- t(tab)
  tab_df <- as.data.frame(as.table(tab))
  colnames(tab_df) <- c(date_column, variant_column, count_column)
  tab_df
}

get_data <- function() {
}

plot_country <- function(df, title, hide_legend=TRUE) {
  palette <- df %>% select(name, color) %>% unique %>% tibble::deframe()
  palette <- palette[levels(df$name)]
  df_plot <- smooth_variants_count(df, 7, date_column="collection_date", variant_column="name", count_column="count")
  p <- ggplot(df_plot, aes(ymd(collection_date), y = count, fill = name)) +
    geom_area(position = "fill", color = "white") +
    coord_cartesian(xlim = c(ymd(lineage_date) %m-% months(8), ymd(lineage_date)),
                    ylim = c(0, 1)) +
    scale_x_date(date_breaks = "1 month", date_labels = "%m",
                 expand=c(0, 1),
                 limits = c(ymd(lineage_date) %m-% months(8), ymd(lineage_date))) +
    scale_fill_manual("", values = palette) +
    ggtitle(title) +
    theme_classic() + theme() +
    theme(
      legend.key.size = unit(0.5, 'cm'),
      legend.text = element_text(size=8),
      plot.title = element_text(size = rel(1.2)),
      plot.margin = margin(4, 8, 0, 4)
    ) +
    theme(strip.background = element_rect(fill = "#110c35", color = "white"),
          strip.text = element_text(colour = "white"),
          panel.background = element_rect(fill = "transparent", colour = NA),  
          plot.background = element_rect(fill = "transparent", colour = NA),
          panel.border = element_rect(colour = "#110c35", fill = NA)) +
    geom_hline(yintercept = seq(0,1,0.1), color = "white", alpha=0.3, lty=3)+
    scale_y_continuous(expand = c(0, 0), labels = scales::percent_format(accuracy = 2), breaks = seq(0,1,0.1)) +
    labs(x="", y="Proportion")
  if (hide_legend) {
    p <- p + theme(legend.position="none")
  }
  p
}

all_countries_data <- read_sql(db_path,"
  SELECT
    collection_date,
    country,
    color,
    name,
    count(*) as count
  FROM sequences AS S
  JOIN (
    SELECT
      pango,
      CASE is_alarm
        WHEN 1 then IFNULL(name, 'dziki')
        WHEN 0 then 'dziki'
      end AS name,
      color
    FROM pango
  ) AS P ON S.our_pango = P.pango
  WHERE collection_date IS NOT NULL
  GROUP BY collection_date, country, name
  ") %>%
  mutate(name = str_to_title(name)) %>%
  mutate(name = factor(name, levels=c(variants_order, setdiff(name, variants_order))))

for (country in countries) {
  df <- all_countries_data %>% filter(country==UQ(country))
  if (length(unique(df$collection_date)) < 80) next
  p <- plot_country(df, country, hide_legend=country!='Poland')
  ggsave(paste0(build_dir, "/grafika/area/", country, ".png"), p, width=4, height=3.3, bg = "transparent")  
}

# ---- BUILD DATE ---- #

obj <- list(lastUpdate=format(lineage_date, format = "%m/%d/%Y"))
writeLines(jsonlite::toJSON(obj, pretty=TRUE, auto_unbox=TRUE), paste0(build_dir, '/data/config.json'))
