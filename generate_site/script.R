cat('---- START \n')
try(devtools::uninstall("covar"), silent = TRUE)
devtools::install_local('../r-package/', force=TRUE)

# ----- GLOBAL VARS ----- #

DB_PATH <- Sys.getenv('DB_PATH')
OUTPUT_PATH <- Sys.getenv('OUTPUT_PATH')
LINEAGE_DATE <- Sys.getenv('LINEAGE_DATE')
LINEAGE_DATE <- gsub('/', '-', LINEAGE_DATE)
OUTPUT_DATE_PATH <- paste0(OUTPUT_PATH, '/', LINEAGE_DATE)
LANGUAGES <- c('pl', 'en')
NO_MONTHS_PLOTS <- 4
NO_MONTHS_PLOTS_LONG <- 8
library(lubridate)
START_DATE <- as.character(ymd(LINEAGE_DATE) %m-% months(NO_MONTHS_PLOTS))
START_DATE_LONG <- as.character(ymd(LINEAGE_DATE) %m-% months(NO_MONTHS_PLOTS_LONG))

# ----- READ DATA ----- #
query <- "SELECT continent, country, continent || ' / ' || country as label from sequences where cast(collection_date as text) > ? group by country,continent having count(*) > 500 order by continent,country"
metadata <- covar::read_sql(DB_PATH, query, bind=list(as.character(lubridate::`%m-%`(lubridate::ymd(LINEAGE_DATE),months(3)))))

regions <- split(metadata, seq(nrow(metadata)))
print(regions)
#regions <- c('Poland', 'Czech Republic', 'Germany')

# ----- SUMMARY ----- #

dir.create(OUTPUT_DATE_PATH, recursive = TRUE, showWarnings = FALSE)
if (file.copy('./source/index_source_summary.html',
              paste0(OUTPUT_DATE_PATH, '/index.html'),
              overwrite = TRUE)) cat('--- CREATE SUMMARY \n')

covar::create_i18n(
  input_paths = sapply(LANGUAGES, function(lang) paste0("./source/lang_", lang, ".txt")),
  output_path = OUTPUT_DATE_PATH
)


# ----- LOAD PACKAGES ----- #

suppressMessages(library(dplyr))
library(tidyr)
options(dplyr.summarise.inform = FALSE)


# ----- REPORTS ----- #

cat('--- CREATE REPORTS \n')

for (region in regions) {

  cat(paste('-- REGION:', region$label, '\n'))
  continent <- region$continent
  country <- region$country

  # ----- ITERATE OVER LANGUAGES ----- #

  plots_output <- list()

  for (lang in LANGUAGES) {
    cat(paste0('- creating plots in ', lang, '\n'))

    plots_output[[lang]] <- list()

    description_input <- read.table(paste0("./source/lang_", lang, ".txt"),
                                    sep = ":", header = TRUE, row.names = 1,
                                    fileEncoding = "UTF-8", quote = NULL)

    df <- covar::load_sequence_count(DB_PATH, continent, country)
    plots_output[[lang]][['pl_seq_1']] <-
      covar::plot_sequence_count(
        df = df,
        title = description_input["pl_seq_1_tit", "names"]
      )

    df <- covar::load_sequence_cumulative(DB_PATH, continent, country)
    plots_output[[lang]][['pl_seq_2']] <-
      covar::plot_sequence_cumulative(
        df = df,
        title = description_input["pl_seq_2_tit", "names"]
      )


    df <- covar::load_pango(DB_PATH, continent, country, START_DATE_LONG, LINEAGE_DATE)
    plots_output[[lang]][['pl_var_1']] <-
      covar::plot_pango_facet(
        df = df,
        lineage_date = LINEAGE_DATE,
        no_months_plots = NO_MONTHS_PLOTS,
        title = description_input["pl_var_1_tit", "names"]
      )
    plots_output[[lang]][['pl_var_2']] <-
      covar::plot_pango_cumulative(
        df = df,
        lineage_date = LINEAGE_DATE,
        no_months_plots_long = NO_MONTHS_PLOTS_LONG,
        title = description_input["pl_var_2_tit", "names"]
      )


    df <- covar::load_clade(DB_PATH, continent, country, START_DATE_LONG, LINEAGE_DATE)
    plots_output[[lang]][['pl_var_3']] <-
      covar::plot_clade_facet(
        df = df,
        lineage_date = LINEAGE_DATE,
        no_months_plots = NO_MONTHS_PLOTS,
        title = description_input["pl_var_3_tit", "names"]
      )
    plots_output[[lang]][['pl_var_4']] <-
      covar::plot_clade_cumulative(
        df = df,
        lineage_date = LINEAGE_DATE,
        no_months_plots_long = NO_MONTHS_PLOTS_LONG,
        title = description_input["pl_var_4_tit", "names"]
      )


    df <- covar::load_metadata_dates(DB_PATH, continent, country, ymd(START_DATE) %m+% months(1), START_DATE)
    plots_output[[lang]][['pl_var_5']] <-
      covar::plot_metadata_dates(
        df = df,
        lineage_date = LINEAGE_DATE,
        no_months_plots = NO_MONTHS_PLOTS,
        xlab = description_input["pl_var_5_scx", "names"],
        ylab = description_input["pl_var_5_scy", "names"],
        title = description_input["pl_var_5_tit", "names"]
      )


    df <- covar::load_location(DB_PATH, continent, country, START_DATE, 25)
    plots_output[[lang]][['pl_loc_1']] <-
      covar::plot_location_count(
        df = df,
        lineage_date = LINEAGE_DATE,
        no_months_plots = NO_MONTHS_PLOTS,
        title = description_input["pl_loc_1_tit", "names"]
      )
    plots_output[[lang]][['pl_loc_2']] <-
      covar::plot_location_proportion(
        df = df,
        lineage_date = LINEAGE_DATE,
        no_months_plots = NO_MONTHS_PLOTS,
        title = description_input["pl_loc_2_tit", "names"]
      )

    df <- covar::load_variant_col(DB_PATH, continent, country, START_DATE)
    plots_output[[lang]][['pl_var_all_2']] <-
      covar::plot_variant_col_fill(
        df = df,
        lineage_date = LINEAGE_DATE,
        no_months_plots = NO_MONTHS_PLOTS,
        title = description_input["pl_var_all_2_tit", "names"]
      )
    plots_output[[lang]][['pl_var_all_3']] <-
      covar::plot_variant_col_stack(
        df = df,
        lineage_date = LINEAGE_DATE,
        no_months_plots = NO_MONTHS_PLOTS,
        title = description_input["pl_var_all_3_tit", "names"]
      )


    # add +k days for reporting lag
    k <- 7
    df <- covar::load_variant_point(DB_PATH, continent, country, START_DATE)
    plots_output[[lang]][['pl_var_all_1']] <-
      covar::plot_variant_area(
        df = df,
        k = k,
        lineage_date = LINEAGE_DATE,
        no_months_plots = NO_MONTHS_PLOTS,
        title = description_input["pl_var_all_1_tit", "names"]
      )
    plots_output[[lang]][['pl_var_all_4']] <-
      covar::plot_variant_point_smooth(
        df = df,
        k = k,
        lineage_date = LINEAGE_DATE,
        no_months_plots = NO_MONTHS_PLOTS,
        title = description_input["pl_var_all_4_tit", "names"]
      )

    #if (region == "Europe / Poland") {
    #  path <- "./map/pl-voi.shp"
    #  map <- covar::read_map(path)

    #  plots_output[[lang]][['pl_map']] <-
    #    covar::plot_map(
    #      df = metadata_nextclade,
    #      map = map,
    #      alarm_mutation = ALARM_MUTATION,
    #      date_last_sample = DATE_LAST_SAMPLE,
    #      max_regions = MAX_REGIONS,
    #      other_level = description_input["other_level", "names"],
    #      subtitle1 = paste(description_input["pl_map_sub1", "names"], DATE_LAST_SAMPLE),
    #      subtitle2 = paste(description_input["pl_map_sub2", "names"], DATE_LAST_SAMPLE),
    #      title = paste(description_input["pl_map_pt1", "names"],
    #                    ALARM_MUTATION,
    #                    description_input["pl_map_pt2", "names"])
    #    )
    #}
  }


  # ----- CREATE OUTPUT DIR----- #

  REGION_CLEAN <- gsub("europe_", "", gsub(" ", "_", stringr::str_squish(gsub("[^a-z0-9 ]", "", tolower(region$label)))))
  OUTPUT_DATE_REGION_PATH <- paste0(OUTPUT_DATE_PATH, '/', REGION_CLEAN)

  dir.create(paste0(OUTPUT_DATE_REGION_PATH, '/', 'images'), recursive = TRUE, showWarnings = FALSE)


  # ----- CREATE HTML ----- #

  #tab <- table(lineage_input$date, lineage_input$pango_small)
  #variants <- head(colnames(tab)[-ncol(tab)], 7)
  #variants_list <- paste0(paste0('<a href="https://cov-lineages.org/lineages/lineage_', variants, '.html">', variants, '</a>'), collapse = ",\n")
  #variants2 <- head(colnames(tab), 5)
  #variants2_list <- paste0(paste0('<a href="https://www.cdc.gov/coronavirus/2019-ncov/more/science-and-research/scientific-brief-emerging-variants.html">', variants2, '</a>'), collapse = ",\n")

  placeholders <- list(
    DATE = LINEAGE_DATE,
    NUMBER = 0,#nrow(lineage_input),
    DATELAST = "",#max(lineage_input$date),
    VARIANTSLIST = "", #variants_list,
    VARIANTS = 0, #length(unique(lineage_input$Lineage)),
    VARIANTSLIST2 = "", #variants2_list,
    VARIANTS2 = 0#length(colnames(tab))
  )
  write(jsonlite::toJSON(placeholders, auto_unbox = TRUE), paste0(OUTPUT_DATE_REGION_PATH, '/placeholders.json'))
  file.copy('./source/index_source.html', paste0(OUTPUT_DATE_REGION_PATH, '/index.html'), overwrite = TRUE)

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

    ggplot2::ggsave(plot = plots[['pl_seq_1']], file = paste0(dir_prefix, "liczba_seq_1.svg"), width = 4, height = 2.5)
    ggplot2::ggsave(plot = plots[['pl_seq_2']], file = paste0(dir_prefix, "liczba_seq_2.svg"), width = 4, height = 2.5)

    #th <- ceiling(attr(plots[['pl_loc_1']], "n_unique_regions") / 5) * 5 / 4
    th <- 4
    ggplot2::ggsave(plot = plots[['pl_loc_1']], file = paste0(dir_prefix, "liczba_loc_1.svg"), width = 8, height = th, limitsize = FALSE)
    ggplot2::ggsave(plot = plots[['pl_loc_2']], file = paste0(dir_prefix, "liczba_loc_2.svg"), width = 8, height = th, limitsize = FALSE)

    ggplot2::ggsave(plot = plots[['pl_var_1']], file = paste0(dir_prefix, "liczba_warianty_1.svg"), width = 8, height = 5)
    ggplot2::ggsave(plot = plots[['pl_var_2']], file = paste0(dir_prefix, "liczba_warianty_2.svg"), width = 8, height = 3)
    ggplot2::ggsave(plot = plots[['pl_var_3']], file = paste0(dir_prefix, "liczba_warianty_3.svg"), width = 8, height = 5)
    ggplot2::ggsave(plot = plots[['pl_var_4']], file = paste0(dir_prefix, "liczba_warianty_4.svg"), width = 8, height = 3)
    ggplot2::ggsave(plot = plots[['pl_var_5']], file = paste0(dir_prefix, "liczba_warianty_5.png"), width = 8, height = 5)

    # pre v1.1.0 it was 5.5/3.5
    tw <- 4 
    th <- 2.5 
    ggplot2::ggsave(plot = plots[['pl_var_all_1']], file = paste0(dir_prefix, "udzial_warianty_1.svg"), width = tw, height = th)
    ggplot2::ggsave(plot = plots[['pl_var_all_2']], file = paste0(dir_prefix, "udzial_warianty_2.svg"), width = tw, height = th)
    ggplot2::ggsave(plot = plots[['pl_var_all_3']], file = paste0(dir_prefix, "udzial_warianty_3.svg"), width = tw, height = th)
    ggplot2::ggsave(plot = plots[['pl_var_all_4']], file = paste0(dir_prefix, "udzial_warianty_4.svg"), width = tw, height = th)

    #if ('pl_map' %in% names(plots)) {
    #  ggplot2::ggsave(plot = plots[['pl_map']], file = paste0(dir_prefix, "mapa_mutacje.svg"), width = 10, height = 5)
    #}

    save(plots, file = paste0(dir_prefix, 'gg_objects.rda'))
  }
}


# ----- REGIONS ----- #

regions_list <- lapply(regions, function(region) {
  list(
    name = region$label,
    dir = gsub("europe_", "", gsub(" ", "_", stringr::str_squish(gsub("[^a-z0-9 ]", "", tolower(region$label)))))
  )
})
write(jsonlite::toJSON(regions_list, auto_unbox = TRUE), paste0(OUTPUT_DATE_PATH, '/regions.json'))


# ----- DATES ----- #

subdirs <- list.dirs(path = OUTPUT_PATH, full.names = FALSE, recursive = FALSE)
date_dirs <- stringi::stri_subset_regex(subdirs, '^\\d{4}-\\d{2}-\\d{2}$')
write(jsonlite::toJSON(date_dirs, auto_unbox = FALSE), paste0(OUTPUT_PATH, '/dates.json'))


cat('---- END \n')
