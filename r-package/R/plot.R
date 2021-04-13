#' @import ggplot2 dplyr tidyr lubridate forcats
#'
#' @param df cleaned `lineage` data.frame
#' @export
plot_sequence_count <- function(df,
                                title = "") {

  ggplot(df, aes(ymd(date) - wday(ymd(date)))) +
    geom_histogram(binwidth = 7, color = "white") +
    theme_minimal(base_family = "Arial") +
    scale_x_date("", date_breaks = "2 months", date_labels = "%m") +
    scale_y_continuous("", expand = c(0, 0)) +
    ggtitle(title)
}


#' @param df cleaned `lineage` data.frame
#' @export
plot_sequence_cumulative <- function(df,
                                     title = "") {

  df <- as.data.frame(table(df$date))

  ggplot(df, aes(x = ymd(Var1), ymin = 0, ymax = cumsum(Freq))) +
    pammtools::geom_stepribbon() + geom_hline(yintercept = 0) +
    theme_minimal(base_family = "Arial") +
    scale_x_date("", date_breaks = "2 months", date_labels = "%m") +
    scale_y_continuous("", expand = c(0, 0)) +
    ggtitle(title)
}


#' @param df cleaned `nextclade` data.frame
#' @export
plot_clade_facet <- function(df,
                             alarm_pattern,
                             lineage_date,
                             no_months_plots,
                             title = "") {

  tab <- apply(table(df$date, df$clade_small), 2, cumsum)
  df <- as.data.frame(as.table(tab))
  colnames(df) <- c("date", "variant", "n")
  variant <- tab[nrow(tab),]
  counts <- data.frame(
    variant = factor(names(variant), levels = names(variant)),
    label = variant,
    date = as.character(ymd(lineage_date) %m-% months(NO_MONTHS_PLOTS)),
    n = max(variant)
  )

  ggplot(df, aes(ymd(date), ymax = n, ymin = 0, fill = grepl(variant, pattern = alarm_pattern))) +
    pammtools::geom_stepribbon() +
    geom_text(data = counts,
              aes(x = ymd(date),
                  y = n,
                  label = label,
                  hjust = 0,
                  vjust = 1),
              size = 2.7) +
    scale_fill_manual(values = c("blue4", "red4")) +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    #  scale_x_date("", date_breaks = "2 months", date_labels = "%m") +
    facet_wrap(~variant, ncol = 6) +
    theme_minimal(base_family = "Arial") +
    scale_y_continuous("", expand = c(0, 0)) +
    ggtitle(title) +
    theme(legend.position = "none")
}


#' @param df cleaned `nextclade` data.frame
#' @export
plot_clade_cumulative <- function(df,
                                  alarm_clade,
                                  lineage_date,
                                  no_months_plots_long,
                                  title = "") {

  tab <- apply(table(df$date, df$clade_medium), 2, cumsum)
  df <- as.data.frame(as.table(tab))
  colnames(df) <- c("date", "variant", "n")
  variant <- tab[nrow(tab),]
  counts <- data.frame(
    variant = factor(names(variant), levels = names(variant)),
    label = variant,
    date = "2020/03/01",
    n = max(variant)
  )
  counts <- counts[counts$variant %in% alarm_clade,]

  ggplot(df, aes(ymd(date), y = n, color = variant %in% alarm_clade, group = variant)) +
    geom_step() +
    geom_step(data = df[df$variant %in% alarm_clade,], size = 1.1) +
    ggrepel::geom_text_repel(data = counts,
                             aes(x = ymd(lineage_date),
                                 y = label,
                                 label = variant,
                                 hjust = 0,
                                 vjust = 0.6),
                             size = 2.9,
                             direction = "y") +
    scale_color_manual(values = c("grey", "red3")) +
    scale_x_date("", date_breaks = "2 weeks", date_labels = "%m/%d",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots_long), ymd(lineage_date))) +
    theme_minimal(base_family = "Arial") +
    scale_y_continuous("", expand = c(0, 0)) +
    ggtitle(title) +
    theme(legend.position = "none")

}


#' @param df cleaned `lineage` data.frame
#' @export
plot_pango_facet <- function(df,
                             alarm_pango,
                             lineage_date,
                             no_months_plots,
                             title = "") {

  tab <- apply(table(df$date, df$pango_small), 2, cumsum)
  df <- as.data.frame(as.table(tab))
  colnames(df) <- c("date", "variant", "n")
  variant <- tab[nrow(tab),]
  counts <- data.frame(
    variant = factor(names(variant), levels = names(variant)),
    label = variant,
    date = as.character(ymd(lineage_date) %m-% months(NO_MONTHS_PLOTS)),
    n = max(variant)
  )

  ggplot(df, aes(ymd(date), ymax = n, ymin = 0, fill = variant %in% alarm_pango)) +
    pammtools::geom_stepribbon() +
    geom_text(data = counts,
              aes(x = ymd(date),
                  y = n,
                  label = label,
                  hjust = 0,
                  vjust = 1),
              size = 2.7) +
    scale_fill_manual(values = c("blue4", "red4")) +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    #  scale_x_date("", date_breaks = "2 months", date_labels = "%m") +
    facet_wrap(~variant, ncol = 5) +
    theme_minimal(base_family = "Arial") +
    scale_y_continuous("", expand = c(0, 0)) +
    ggtitle(title) +
    theme(legend.position = "none")
}


#' @param df cleaned `lineage` data.frame
#' @export
plot_pango_cumulative <- function(df,
                                  alarm_pango,
                                  lineage_date,
                                  no_months_plots_long,
                                  title = "") {

  tab <- apply(table(df$date, df$pango_medium), 2, cumsum)
  df <- as.data.frame(as.table(tab))
  colnames(df) <- c("date", "variant", "n")
  variant <- tab[nrow(tab),]
  counts <- data.frame(
    variant = factor(names(variant), levels = names(variant)),
    label = variant,
    date = "2020/03/01",
    n = max(variant)
  )
  counts <- counts[counts$variant %in% alarm_pango,]

  ggplot(df, aes(ymd(date), y = n, color = variant %in% alarm_pango, group = variant)) +
    geom_step() +
    geom_step(data = df[df$variant %in% alarm_pango,], size = 1.1) +
    ggrepel::geom_text_repel(data = counts,
                             aes(x = ymd(lineage_date),
                                 y = label,
                                 label = variant,
                                 hjust = 0,
                                 vjust = 0.6),
                             size = 2.9,
                             direction = "y") +
    scale_color_manual(values = c("grey", "red3")) +
    scale_x_date("", date_breaks = "2 weeks", date_labels = "%m/%d",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots_long), ymd(lineage_date))) +
    theme_minimal(base_family = "Arial") +
    scale_y_continuous("", expand = c(0, 0)) +
    ggtitle(title) +
    theme(legend.position = "none")

}


#' @param df `metadata` joined with cleaned `nextclade` data.frame
#' @export
plot_metadata_dates <- function(df,
                                alarm_pattern,
                                lineage_date,
                                no_months_plots,
                                xlab = "",
                                ylab = "",
                                title = "") {

  ggplot(df, aes(x = ymd(collection_date),
                 y = ymd(submission_date),
                 color = grepl(clade_small, pattern = alarm_pattern))) +
    geom_abline(slope = 1, intercept = 0, color = "grey", lty = 4) +
    geom_abline(slope = 1, intercept = 14, color = "grey", lty = 2) +
    geom_abline(slope = 1, intercept = 28, color = "grey", lty = 3) +
    geom_jitter(size = 0.5) +
    ggtitle("", subtitle = title) +
    theme_bw(base_family = "Arial") +
    coord_fixed() +
    scale_color_manual("", values = c("blue4", "red2")) +
    scale_x_date(xlab, date_breaks = "2 weeks", date_labels = "%m/%d",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date)))  +
    scale_y_date(ylab, date_breaks = "2 weeks", date_labels = "%m/%d",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots - 1), ymd(lineage_date))) +
    theme(legend.position = "none")
}


#' @param df `metadata` joined with cleaned `nextclade` data.frame
#' @export
plot_location_facet <- function(df,
                                max_regions,
                                lineage_date,
                                no_months_plots,
                                other_level = "Other",
                                title = "") {

  tab <- table(df$week_start, df$LocationClean, df$is_alarm)
  tab_df <- data.frame(as.table(tab))

  selected_regions <- head(levels(tab_df$Var2), max_regions)
  n_unique_regions <- max(length(unique(selected_regions)), 1)

  try({
    df$LocationClean <- fct_other(df$LocationClean,
                                  keep = selected_regions,
                                  other_level = other_level)
  }, silent = TRUE)

  # calculate this table again with combined levels
  tab <- table(df$week_start, df$LocationClean, df$is_alarm)
  tab_df <- data.frame(as.table(tab_df))

  p <- ggplot(tab_df, aes(ymd(Var1), y = Freq, fill = Var3)) +
    geom_col() +
    scale_fill_manual(values = c("grey", "red3")) +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    facet_wrap(~Var2, ncol = 5) +
    theme_minimal(base_family = "Arial") +
    scale_y_continuous("", expand = c(0, 0)) +
    ggtitle(title) +
    theme(legend.position = "none")

  attr(p, "n_unique_regions") <- n_unique_regions
  p
}
