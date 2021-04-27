#' @param df `metadata` joined with cleaned `nextclade` data.frame
#' @export
plot_metadata_dates <- function(df,
                                alarm_pattern,
                                lineage_date,
                                no_months_plots,
                                xlab = "",
                                ylab = "",
                                title = "") {

  tdf <- df %>% select(collection_date, submission_date, clade_small) 
  rm('df')

  p <- ggplot(tdf, aes(x = ymd(collection_date),
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
    
  p$plot_env <- rlang::new_environment()
  p
}
