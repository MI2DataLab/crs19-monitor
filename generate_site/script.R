# This flag should be set only for the first country
if (Sys.getenv("INSTALL_PACKAGE") == "1") {
  try(devtools::uninstall("covar"), silent = TRUE)
  devtools::install_local('../r-package/', force=TRUE)
}

# ----- LOAD PACKAGES ----- #

suppressMessages(library(dplyr))
suppressMessages(library(tidyr))
options(dplyr.summarise.inform = FALSE)
suppressMessages(library(lubridate))

# ----- GLOBAL VARS ----- #

DB_PATH <- Sys.getenv('CLEAN_DB')
TIME_LOG_PATH <- Sys.getenv('TIME_LOG_PATH')
GENERATION_DATE <- Sys.getenv('GENERATION_DATE')
OUTPUT_DATE_REGION_PATH <- Sys.getenv('OUTPUT_DATE_REGION_PATH')
continent <- Sys.getenv('CONTINENT')
country <- Sys.getenv('COUNTRY')
LANGUAGES <- c('pl', 'en')
NO_MONTHS_PLOTS <- 4
NO_MONTHS_PLOTS_LONG <- 8
START_DATE <- as.character(ymd(GENERATION_DATE) %m-% months(NO_MONTHS_PLOTS))
START_DATE_LONG <- as.character(ymd(GENERATION_DATE) %m-% months(NO_MONTHS_PLOTS_LONG))

# ----- ITERATE OVER LANGUAGES ----- #
# log for time elapsed on different tasks
time_log <- list()
measure_time <- function(expr, name, type, lang) {
  time <- as.numeric(system.time(expr)['elapsed'])
  time_log[[length(time_log) + 1]] <<- list(name=name, type=type, lang=lang, time=time)
}

plots_output <- list()
for (lang in LANGUAGES) {
  cat(paste0('- creating plots in ', lang, '\n'))

  plots_output[[lang]] <- list()

  description_input <- read.table(paste0("./source/lang_", lang, ".txt"),
                                  sep = ":", header = TRUE, row.names = 1,
                                  fileEncoding = "UTF-8", quote = NULL)

  measure_time(
    df <- covar::load_sequence_count(DB_PATH, continent, country),
    'sequence_count', 'load', lang
  )
  measure_time(
    plots_output[[lang]][['pl_seq_1']] <-
      covar::plot_sequence_count(
        df = df,
        title = description_input["pl_seq_1_tit", "names"]
      ),
    'sequence_count', 'plot', lang
  )

  measure_time(
    df <- covar::load_sequence_cumulative(DB_PATH, continent, country),
    'sequence_cumulative', 'load', lang
  )
  measure_time(
    plots_output[[lang]][['pl_seq_2']] <-
      covar::plot_sequence_cumulative(
        df = df,
        title = description_input["pl_seq_2_tit", "names"]
      ),
    'sequence_cumulative', 'plot', lang
  )

  measure_time(
    df <- covar::load_pango(DB_PATH, continent, country, START_DATE_LONG, GENERATION_DATE),
    'pango', 'load', lang
  )

  measure_time(
    plots_output[[lang]][['pl_var_1']] <-
      covar::plot_pango_facet(
        df = df,
        lineage_date = GENERATION_DATE,
        no_months_plots = NO_MONTHS_PLOTS,
        title = description_input["pl_var_1_tit", "names"]
      ),
    'pango_facet', 'plot', lang
  )
  measure_time(
    plots_output[[lang]][['pl_var_2']] <-
      covar::plot_pango_cumulative(
        df = df,
        lineage_date = GENERATION_DATE,
        no_months_plots_long = NO_MONTHS_PLOTS_LONG,
        title = description_input["pl_var_2_tit", "names"]
      ),
    'pango_cumulative', 'plot', lang
  )


  measure_time(
    df <- covar::load_clade(DB_PATH, continent, country, START_DATE_LONG, GENERATION_DATE),
    'clade', 'load', lang
  )
  measure_time(
    plots_output[[lang]][['pl_var_3']] <-
      covar::plot_clade_facet(
        df = df,
        lineage_date = GENERATION_DATE,
        no_months_plots = NO_MONTHS_PLOTS,
        title = description_input["pl_var_3_tit", "names"]
      ),
    'clade_facet', 'plot', lang
  )
  measure_time(
    plots_output[[lang]][['pl_var_4']] <-
      covar::plot_clade_cumulative(
        df = df,
        lineage_date = GENERATION_DATE,
        no_months_plots_long = NO_MONTHS_PLOTS_LONG,
        title = description_input["pl_var_4_tit", "names"]
      ),
    'clade_cumulative', 'plot', lang
  )


  measure_time(
    df <- covar::load_metadata_dates(DB_PATH, continent, country, ymd(START_DATE) %m+% months(1), START_DATE),
    'metadata_dates', 'load', lang
  )
  measure_time(
    plots_output[[lang]][['pl_var_5']] <-
      covar::plot_metadata_dates(
        df = df,
        lineage_date = GENERATION_DATE,
        no_months_plots = NO_MONTHS_PLOTS,
        xlab = description_input["pl_var_5_scx", "names"],
        ylab = description_input["pl_var_5_scy", "names"],
        title = description_input["pl_var_5_tit", "names"]
      ),
    'metadata_dates', 'plot', lang
  )


  measure_time(
    df <- covar::load_location(DB_PATH, continent, country, START_DATE, 25),
    'location', 'load', lang
  )
  n_unique_regions <- length(unique(df$state))
  measure_time(
    plots_output[[lang]][['pl_loc_1']] <-
      covar::plot_location_count(
        df = df,
        lineage_date = GENERATION_DATE,
        no_months_plots = NO_MONTHS_PLOTS,
        title = description_input["pl_loc_1_tit", "names"]
      ),
    'location_count', 'plot', lang
  )
  measure_time(
    plots_output[[lang]][['pl_loc_2']] <-
      covar::plot_location_proportion(
        df = df,
        lineage_date = GENERATION_DATE,
        no_months_plots = NO_MONTHS_PLOTS,
        title = description_input["pl_loc_2_tit", "names"]
      ),
    'location_proportion', 'plot', lang
  )

  measure_time(
    df <- covar::load_variant_col(DB_PATH, continent, country, START_DATE),
    'variant_col', 'load', lang
  )
  measure_time(
    plots_output[[lang]][['pl_var_all_2']] <-
      covar::plot_variant_col_fill(
        df = df,
        lineage_date = GENERATION_DATE,
        no_months_plots = NO_MONTHS_PLOTS,
        title = description_input["pl_var_all_2_tit", "names"]
      ),
    'variant_col_fill', 'plot', lang
  )
  measure_time(
    plots_output[[lang]][['pl_var_all_3']] <-
      covar::plot_variant_col_stack(
        df = df,
        lineage_date = GENERATION_DATE,
        no_months_plots = NO_MONTHS_PLOTS,
        title = description_input["pl_var_all_3_tit", "names"]
      ),
    'variant_col_stack', 'plot', lang
  )


  # add +k days for reporting lag
  k <- 7
  measure_time(
    df <- covar::load_variant_point(DB_PATH, continent, country, START_DATE),
    'variant_point', 'load', lang
  )
  measure_time(
    plots_output[[lang]][['pl_var_all_1']] <-
      covar::plot_variant_area(
        df = df,
        k = k,
        lineage_date = GENERATION_DATE,
        no_months_plots = NO_MONTHS_PLOTS,
        title = description_input["pl_var_all_1_tit", "names"]
      ),
    'variant_point_area', 'plot', lang
  )
  measure_time(
    plots_output[[lang]][['pl_var_all_4']] <-
      covar::plot_variant_point_smooth(
        df = df,
        k = k,
        lineage_date = GENERATION_DATE,
        no_months_plots = NO_MONTHS_PLOTS,
        title = description_input["pl_var_all_4_tit", "names"]
      ),
    'variant_point_smooth', 'plot', lang
  )
}
# ----- CREATE OUTPUT DIR----- #
dir.create(paste0(OUTPUT_DATE_REGION_PATH, '/', 'images'), recursive = TRUE, showWarnings = FALSE)


# ----- CREATE HTML ----- #
df_pango <- covar::load_pango_count(DB_PATH, continent, country)
variants_pango_list <- paste0(paste0('<a href="https://cov-lineages.org/lineages/lineage_', head(df_pango$pango, 7), '.html">', head(df_pango$pango, 7), '</a>'), collapse = ",\n")
df_clade <- covar::load_clade_count(DB_PATH,continent, country)
variants_clade_list <- paste0(paste0('<a href="https://www.cdc.gov/coronavirus/2019-ncov/more/science-and-research/scientific-brief-emerging-variants.html">', head(df_clade$clade, 7), '</a>'), collapse = ",\n")
df_stats <- covar::load_sequence_stats(DB_PATH, continent, country)

placeholders <- list(
  DATE = GENERATION_DATE,
  NUMBER = df_stats$count,
  DATELAST = df_stats$last_collection_date,
  VARIANTSLIST = variants_pango_list,
  VARIANTS = nrow(df_pango),
  VARIANTSLIST2 = variants_clade_list,
  VARIANTS2 = nrow(df_clade)
)

write(jsonlite::toJSON(placeholders, auto_unbox = TRUE), paste0(OUTPUT_DATE_REGION_PATH, '/placeholders.json'))
tmp <- file.copy('./source/index_source.html', paste0(OUTPUT_DATE_REGION_PATH, '/index.html'), overwrite = TRUE)

covar::create_i18n(
  input_paths = sapply(LANGUAGES, function(lang) paste0("./source/lang_", lang, ".txt")),
  output_path = OUTPUT_DATE_REGION_PATH
)

# ----- SAVE PLOTS ----- #

for (lang in LANGUAGES) {
  cat(paste0('- saving plots in ', lang, '\n'))
  plots <- plots_output[[lang]]
  dir_prefix <- paste0(OUTPUT_DATE_REGION_PATH, '/images/', lang, '/')
  dir.create(dir_prefix, recursive = TRUE, showWarnings = FALSE)

  measure_time(
    ggplot2::ggsave(plot = plots[['pl_seq_1']], file = paste0(dir_prefix, "liczba_seq_1.svg"), width = 4, height = 2.5),
    'sequence_count', 'save', lang
  )
  measure_time(
    ggplot2::ggsave(plot = plots[['pl_seq_2']], file = paste0(dir_prefix, "liczba_seq_2.svg"), width = 4, height = 2.5),
    'sequence_cumulative', 'save', lang
  )

  th <- ceiling(n_unique_regions / 5) * 5 / 4
  measure_time(
    ggplot2::ggsave(plot = plots[['pl_loc_1']], file = paste0(dir_prefix, "liczba_loc_1.svg"), width = 8, height = th, limitsize = FALSE),
    'location_count', 'save', lang
  )
  measure_time(
    ggplot2::ggsave(plot = plots[['pl_loc_2']], file = paste0(dir_prefix, "liczba_loc_2.svg"), width = 8, height = th, limitsize = FALSE),
    'location_proportion', 'save', lang
  )

  measure_time(
    ggplot2::ggsave(plot = plots[['pl_var_1']], file = paste0(dir_prefix, "liczba_warianty_1.png"), width = 8, height = 5),
    'pango_facet', 'save', lang
  )
  measure_time(
    ggplot2::ggsave(plot = plots[['pl_var_2']], file = paste0(dir_prefix, "liczba_warianty_2.svg"), width = 8, height = 3),
    'pango_cumulative', 'save', lang
  )
  measure_time(
    ggplot2::ggsave(plot = plots[['pl_var_3']], file = paste0(dir_prefix, "liczba_warianty_3.png"), width = 8, height = 5),
    'clade_facet', 'save', lang
  )
  measure_time(
    ggplot2::ggsave(plot = plots[['pl_var_4']], file = paste0(dir_prefix, "liczba_warianty_4.svg"), width = 8, height = 3),
    'clade_cumulative', 'save', lang
  )
  measure_time(
    ggplot2::ggsave(plot = plots[['pl_var_5']], file = paste0(dir_prefix, "liczba_warianty_5.png"), width = 8, height = 5),
    'metadata_dates', 'save', lang
  )

  # pre v1.1.0 it was 5.5/3.5
  tw <- 4 
  th <- 2.5 
  measure_time(
    ggplot2::ggsave(plot = plots[['pl_var_all_1']], file = paste0(dir_prefix, "udzial_warianty_1.svg"), width = tw, height = th),
    'variant_point_area', 'save', lang
  )
  measure_time(
    ggplot2::ggsave(plot = plots[['pl_var_all_2']], file = paste0(dir_prefix, "udzial_warianty_2.svg"), width = tw, height = th),
    'variant_col_fill', 'save', lang
  )
  measure_time(
    ggplot2::ggsave(plot = plots[['pl_var_all_3']], file = paste0(dir_prefix, "udzial_warianty_3.svg"), width = tw, height = th),
    'variant_col_stack', 'save', lang
  )
  measure_time(
    ggplot2::ggsave(plot = plots[['pl_var_all_4']], file = paste0(dir_prefix, "udzial_warianty_4.svg"), width = tw, height = th),
    'variant_point_smooth', 'save', lang
  )

  measure_time(
    save(plots, file = paste0(dir_prefix, 'gg_objects.rda')),
    'ggobjects', 'save', lang
  )
}

write.csv(do.call('rbind', time_log), TIME_LOG_PATH, row.names=FALSE)
