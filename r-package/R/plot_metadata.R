#' @param df `metadata` joined with cleaned `nextclade` data.frame
#' @export
plot_metadata_dates <- function(df,
                                lineage_date,
                                no_months_plots,
                                xlab = "",
                                ylab = "",
                                title = "") {
  p <- ggplot(df, aes(x = ymd(collection_date), y = ymd(submission_date))) +
    geom_abline(slope = 1, intercept = 0, color = "grey", lty = 4) +
    geom_abline(slope = 1, intercept = 14, color = "grey", lty = 2) +
    geom_abline(slope = 1, intercept = 28, color = "grey", lty = 3) +
    geom_jitter(size=0.5, color=df$color) +
    ggtitle("", subtitle = title) +
    theme_bw(base_family = "Arial") +
    coord_fixed() +
    scale_x_date(xlab, date_breaks = "2 weeks", date_labels = "%m/%d",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots) %m-% days(3), ymd(lineage_date) %m+% days(3)))  +
    scale_y_date(ylab, date_breaks = "2 weeks", date_labels = "%m/%d",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots - 1) %m-% days(3), ymd(lineage_date) %m+% days(3))) +
    theme(legend.position = "none")
  p
  p$plot_env <- rlang::new_environment()
  p
}
