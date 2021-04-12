#' @param df cleaned `lineage` data.frame
#' @export
plot_sequence_count <- function(df, title = NULL) {
  if (is.null(df)) return(NULL)

  ggplot(df, aes(ymd(date) - wday(ymd(date)))) +
    geom_histogram(binwidth = 7, color = "white") +
    theme_minimal(base_family = 'Arial') +
    scale_x_date("", date_breaks = "2 months", date_labels = "%m") +
    scale_y_continuous("", expand = c(0,0)) +
    ggtitle(title)
}

#' @param df cleaned `lineage` data.frame
#' @export
plot_sequence_cumulative <- function(df, title = NULL) {
  if (is.null(df)) return(NULL)

  df <- as.data.frame(table(df$date))

  ggplot(df, aes(x = ymd(Var1), ymin = 0, ymax = cumsum(Freq))) +
    pammtools::geom_stepribbon() + geom_hline(yintercept = 0) +
    theme_minimal(base_family = 'Arial') +
    scale_x_date("", date_breaks = "2 months", date_labels = "%m") +
    scale_y_continuous("", expand = c(0,0)) +
    ggtitle(title)
}

#' @param df cleaned `lineage` data.frame
#' @export
plot_cumulative_pango <- function(df, lineage_date, alarm_pango, no_months_plots, title = NULL) {
  if (is.null(df)) return(NULL)

  tab <- apply(table(df$date, df$lineage_small), 2, cumsum)
  df <- as.data.frame(tab)
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
    geom_text(data = counts, aes(x = ymd(date), y = n, label = label, hjust = 0, vjust = 1), size = 2.7) +
    scale_fill_manual(values = c("blue4", "red4")) +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    #  scale_x_date("", date_breaks = "2 months", date_labels = "%m") +
    facet_wrap(~variant, ncol = 5) +
    theme_minimal(base_family = 'Arial') + scale_y_continuous("", expand = c(0,0)) +
    ggtitle(title) +
    theme(legend.position = "none")
}
