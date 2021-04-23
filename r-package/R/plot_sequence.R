#' @param df cleaned `lineage` data.frame
#' @export
plot_sequence_count <- function(df,
                                title = "") {
  
  tdf <- df %>% select(date)
  ggplot(tdf, aes(ymd(date) - wday(ymd(date)))) +
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

  tab_df <- as.data.frame(table(df$date))

  ggplot(tab_df, aes(x = ymd(Var1), ymin = 0, ymax = cumsum(Freq))) +
    pammtools::geom_stepribbon() + geom_hline(yintercept = 0) +
    theme_minimal(base_family = "Arial") +
    scale_x_date("", date_breaks = "2 months", date_labels = "%m") +
    scale_y_continuous("", expand = c(0, 0)) +
    ggtitle(title)
}
