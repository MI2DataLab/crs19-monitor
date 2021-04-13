# ----- LOAD PACKAGES ----- #

library(ggplot2)                          # plot
library(patchwork)                        # plot
suppressMessages(library(dplyr))          # data
library(tidyr)                            # drop_na
suppressMessages(library(lubridate))      # date
library(forcats)                          # factor
options(dplyr.summarise.inform = FALSE)


# ----- GLOBAL VARS ----- #

ALARM_MUTATION <- "N501Y"
ALARM_PATTERN <- "501Y"
ALARM_PANGO <- c("B.1.1.7", "B.1.351", "P.1")
ALARM_CLADE <- c("20I/501Y.V1","20H/501Y.V2", "20J/501Y.V3")
MAX_REGIONS <- 23
NO_MONTHS_PLOTS <- 4
NO_MONTHS_PLOTS_LONG <- 8
PALETTE <- structure(
  c("#E9C622", "#51A4B8", "#E5BC13", "#67AFBF", "#E1B103",
    "#82B8B6", "#E58600", "#ACC07E", "#3B9AB2", "#7F00FF", "#EB5000", "#F21A00"),
  .Names = c("20A.EU2", "19A", "20D", "19B", "20C", "20E (EU1)",
             "20G", "20A", "20B", "20J/501Y.V3", "20H/501Y.V2", "20I/501Y.V1"))
SMOOTH_VARIANTS <- c("20I/501Y.V1", "20A", "20B")


# ----- REPORT ----- #

lineage_report <- function(region, lineage_df, nextclade_df) {

  # ----- READ DATA ----- #

  query <- "SELECT * FROM metadata WHERE country = ? AND substr(collection_date,1,4) >= '2019'"
  metadata <- covar::read_sql(DB_PATH, query, bind = list(region))

  cat(paste('found', nrow(metadata), 'rows in database \n'))

  # filter data by region
  lineage_subset <- subset(lineage_df, accession_id %in% metadata$accession_id)
  nextclade_subset <- subset(nextclade_df, accession_id %in% metadata$accession_id)

  cat(paste('region pango rows:', nrow(lineage_subset), '\n'))
  cat(paste('region nextclade rows:', nrow(nextclade_subset), '\n'))

  DATE_LAST_SAMPLE <- max(ymd(metadata$collection_date), na.rm = TRUE)

  # add location
  metadata_input <- covar::clean_metadata(metadata)

  # find misspelled data
  misspelled_rows <- is.na(metadata_input$LocationClean)
  misspelled_locations <- as.data.frame(table(metadata_input$location[misspelled_rows]))

  cat(paste("there are", sum(misspelled_rows), "unique misspelled rows \n"))
  cat(paste("there are", nrow(misspelled_locations), "misspelled locations / TOP5: \n"))
  print(head(arrange(misspelled_locations, -Freq), 5))


  # ----- ITERATE OVER LANGUAGES ----- #

  plots_output <- list()

  for (lang in LANGUAGES) {
    cat(paste0('- creating plots in ', lang, '\n'))

    plots_output[[lang]] <- list()

    description_input <- read.table(paste0("./source/lang_", lang, ".txt"),
                                    sep = ":", header = TRUE, row.names = 1,
                                    fileEncoding = "UTF-8", quote = NULL)

    lineage_input <- covar::clean_lineage(
      df = lineage_subset,
      alarm_pango = ALARM_PANGO,
      other_level = description_input["other_level", "names"]
    )

    nextclade_input <- covar::clean_nextclade(
      df = nextclade_subset,
      alarm_mutation = ALARM_MUTATION,
      alarm_pattern = ALARM_PATTERN,
      other_level = description_input["other_level", "names"]
    )

    metadata_nextclade <- merge(metadata_input, nextclade_input, by = "accession_id")

    plots_output[[lang]][['pl_seq_1']] <-
      covar::plot_sequence_count(
        df = lineage_input,
        title = description_input["pl_seq_1_tit", "names"]
      )

    plots_output[[lang]][['pl_seq_2']] <-
      covar::plot_sequence_cumulative(
        df = lineage_input,
        title = description_input["pl_seq_2_tit", "names"]
      )

    plots_output[[lang]][['pl_var_1']] <-
      covar::plot_pango_facet(
        df = lineage_input,
        alarm_pango = ALARM_PANGO,
        lineage_date = LINEAGE_DATE,
        no_months_plots = NO_MONTHS_PLOTS,
        title = description_input["pl_var_1_tit", "names"]
      )

    plots_output[[lang]][['pl_var_2']] <-
      covar::plot_pango_cumulative(
        df = lineage_input,
        alarm_pango = ALARM_PANGO,
        lineage_date = LINEAGE_DATE,
        no_months_plots_long = NO_MONTHS_PLOTS_LONG,
        title = description_input["pl_var_2_tit", "names"]
      )

    plots_output[[lang]][['pl_var_3']] <-
      covar::plot_clade_facet(
        df = nextclade_input,
        alarm_pattern = ALARM_PATTERN,
        lineage_date = LINEAGE_DATE,
        no_months_plots = NO_MONTHS_PLOTS,
        title = description_input["pl_var_3_tit", "names"]
      )

    plots_output[[lang]][['pl_var_4']] <-
      covar::plot_clade_cumulative(
        df = nextclade_input,
        alarm_clade = ALARM_CLADE,
        lineage_date = LINEAGE_DATE,
        no_months_plots_long = NO_MONTHS_PLOTS_LONG,
        title = description_input["pl_var_4_tit", "names"]
      )

    plots_output[[lang]][['pl_var_5']] <-
      covar::plot_metadata_dates(
        df = metadata_nextclade,
        alarm_pattern = ALARM_PATTERN,
        lineage_date = LINEAGE_DATE,
        no_months_plots = NO_MONTHS_PLOTS,
        xlab = description_input["pl_var_5_scx", "names"],
        ylab = description_input["pl_var_5_scy", "names"],
        title = description_input["pl_var_5_tit", "names"]
      )

    plots_output[[lang]][['pl_loc_1']] <-
      covar::plot_location_count(
        df = metadata_nextclade,
        max_regions = MAX_REGIONS,
        lineage_date = LINEAGE_DATE,
        no_months_plots = NO_MONTHS_PLOTS,
        other_level = description_input["other_level", "names"],
        title = description_input["pl_loc_1_tit", "names"]
      )

    plots_output[[lang]][['pl_loc_2']] <-
      covar::plot_location_proportion(
        df = metadata_nextclade,
        max_regions = MAX_REGIONS,
        lineage_date = LINEAGE_DATE,
        no_months_plots = NO_MONTHS_PLOTS,
        other_level = description_input["other_level", "names"],
        title = description_input["pl_loc_2_tit", "names"]
      )

    plots_output[[lang]][['pl_var_all_2']] <-
      covar::plot_variant_col_fill(
        df = nextclade_input,
        alarm_clade = ALARM_CLADE,
        lineage_date = LINEAGE_DATE,
        palette = PALETTE,
        no_months_plots = NO_MONTHS_PLOTS,
        title = description_input["pl_var_all_2_tit", "names"]
      )

    plots_output[[lang]][['pl_var_all_3']] <-
      covar::plot_variant_col_stack(
        df = nextclade_input,
        alarm_clade = ALARM_CLADE,
        lineage_date = LINEAGE_DATE,
        palette = PALETTE,
        no_months_plots = NO_MONTHS_PLOTS,
        title = description_input["pl_var_all_3_tit", "names"]
      )

    # add +k days for reporting lag
    k <- 7

    plots_output[[lang]][['pl_var_all_1']] <-
      covar::plot_variant_area(
        df = nextclade_input,
        k = k,
        alarm_clade = ALARM_CLADE,
        lineage_date = LINEAGE_DATE,
        palette = PALETTE,
        no_months_plots = NO_MONTHS_PLOTS,
        title = description_input["pl_var_all_1_tit", "names"]
      )

    plots_output[[lang]][['pl_var_all_4']] <-
      covar::plot_variant_point_smooth(
        df = nextclade_input,
        k = k,
        smooth_variants = SMOOTH_VARIANTS,
        alarm_clade = ALARM_CLADE,
        lineage_date = LINEAGE_DATE,
        palette = PALETTE,
        no_months_plots = NO_MONTHS_PLOTS,
        title = description_input["pl_var_all_4_tit", "names"]
      )

    if (region == "Poland") {
      path <- "./map/pl-voi.shp"
      map <- covar::read_map(path)

      plots_output[[lang]][['pl_map']] <-
        covar::plot_map(
          df = metadata_nextclade,
          map = map,
          alarm_mutation = ALARM_MUTATION,
          date_last_sample = DATE_LAST_SAMPLE,
          max_regions = MAX_REGIONS,
          other_level = description_input["other_level", "names"],
          subtitle1 = paste(description_input["pl_map_sub1", "names"], DATE_LAST_SAMPLE),
          subtitle2 = paste(description_input["pl_map_sub2", "names"], DATE_LAST_SAMPLE),
          title = paste(description_input["pl_map_pt1", "names"],
                        ALARM_MUTATION,
                        description_input["pl_map_pt2", "names"])
        )
    }
  }


  # ----- CREATE OUTPUT DIR----- #

  REGION_CLEAN <- gsub(" ", "_", stringr::str_squish(gsub("[^a-z0-9 ]", "", tolower(region))))
  OUTPUT_DATE_REGION_PATH <- paste0(OUTPUT_DATE_PATH, '/', REGION_CLEAN)

  dir.create(paste0(OUTPUT_DATE_REGION_PATH, '/', 'images'), recursive = TRUE, showWarnings = FALSE)


  # ----- CREATE HTML ----- #

  tab <- table(lineage_input$date, lineage_input$pango_small)
  variants <- head(colnames(tab)[-ncol(tab)], 7)
  variants_list <- paste0(paste0('<a href="https://cov-lineages.org/lineages/lineage_', variants, '.html">', variants, '</a>'), collapse = ",\n")
  variants2 <- head(colnames(t_cou_cla), 5)
  variants2_list <- paste0(paste0('<a href="https://www.cdc.gov/coronavirus/2019-ncov/more/science-and-research/scientific-brief-emerging-variants.html">', variants2, '</a>'), collapse = ",\n")

  placeholders <- list(
  	DATE = LINEAGE_DATE_CLEAN,
  	NUMBER = nrow(lineage_input),
  	DATELAST = max(lineage_input$date),
  	VARIANTSLIST = variants_list,
  	VARIANTS = length(unique(lineage_input$Lineage)),
  	VARIANTSLIST2 = variants2_list,
  	VARIANTS2 = length(colnames(t_cou_cla))
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

  	ggsave(plot = plots[['pl_seq_1']], file = paste0(dir_prefix, "liczba_seq_1.svg"), width = 4, height = 2.5)
  	ggsave(plot = plots[['pl_seq_2']], file = paste0(dir_prefix, "liczba_seq_2.svg"), width = 4, height = 2.5)

  	th <- ceiling(attr(plots[['pl_loc_1']], "n_unique_regions") / 5) * 5 / 4
		ggsave(plot = plots[['pl_loc_1']], file = paste0(dir_prefix, "liczba_loc_1.svg"), width = 8, height = th, limitsize = FALSE)
		ggsave(plot = plots[['pl_loc_2']], file = paste0(dir_prefix, "liczba_loc_2.svg"), width = 8, height = th, limitsize = FALSE)

  	ggsave(plot = plots[['pl_var_1']], file = paste0(dir_prefix, "liczba_warianty_1.svg"), width = 8, height = 3)
  	ggsave(plot = plots[['pl_var_2']], file = paste0(dir_prefix, "liczba_warianty_2.svg"), width = 8, height = 3)
  	ggsave(plot = plots[['pl_var_3']], file = paste0(dir_prefix, "liczba_warianty_3.svg"), width = 8, height = 3)
  	ggsave(plot = plots[['pl_var_4']], file = paste0(dir_prefix, "liczba_warianty_4.svg"), width = 8, height = 3)
  	ggsave(plot = plots[['pl_var_5']], file = paste0(dir_prefix, "liczba_warianty_5.png"), width = 8, height = 5)

  	ggsave(plot = plots[['pl_var_all_1']], file = paste0(dir_prefix, "udzial_warianty_1.svg"), width = 5.5, height = 3.5)
  	ggsave(plot = plots[['pl_var_all_2']], file = paste0(dir_prefix, "udzial_warianty_2.svg"), width = 5.5, height = 3.5)
  	ggsave(plot = plots[['pl_var_all_3']], file = paste0(dir_prefix, "udzial_warianty_3.svg"), width = 5.5, height = 3.5)
  	ggsave(plot = plots[['pl_var_all_4']], file = paste0(dir_prefix, "udzial_warianty_4.svg"), width = 5.5, height = 3.5)

  	if ('pl_map' %in% names(plots)) {
  		ggsave(plot = plots[['pl_map']], file = paste0(dir_prefix, "mapa_mutacje.svg"), width = 10, height = 5)
  	}

  	save(plots, file = paste0(dir_prefix, 'gg_objects.rda'))
  }
}
