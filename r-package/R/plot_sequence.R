#' @param df cleaned `lineage` data.frame
#' @export
plot_sequence_count <- function(df,
                                title = "") {
  p <- ggplot(df, aes(x=ymd(week_start),y=count)) +
    geom_col(width=4) +
    theme_minimal(base_family = "Arial") +
    scale_x_date("", date_breaks = "2 months", date_labels = "%m") +
    scale_y_continuous("", expand = c(0, 0), labels = scales::label_number_si()) +
    ggtitle(title) + labs(x = NULL, y = NULL) + 
    theme(plot.margin = margin(4, 4, 0, 4))
  p$plot_env <- rlang::new_environment()
  p
}


#' @param df cleaned `lineage` data.frame
#' @export
plot_sequence_cumulative <- function(df,
                                     title = "") {
  df$cum_count <- cumsum(df$count)
  p <- ggplot(df, aes(x = ymd(date), ymin = 0, ymax = cum_count)) +
    pammtools::geom_stepribbon() +
    geom_hline(yintercept = 0) +
    theme_minimal(base_family = "Arial") +
    scale_x_date("", date_breaks = "2 months", date_labels = "%m") +
    scale_y_continuous("", expand = c(0, 0), labels = scales::label_number_si()) +
    ggtitle(title) + labs(x = NULL, y = NULL) + 
    theme(plot.margin = margin(4, 4, 0, 4))
  p$plot_env <- rlang::new_environment()
  p
}
