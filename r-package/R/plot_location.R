#' @param df `metadata` joined with cleaned `nextclade` data.frame
#' @export
plot_location_count <- function(df,
                                lineage_date,
                                no_months_plots,
                                title = "") {
  df$is_alarm <- df$is_alarm == 1
  p <- ggplot(df, aes(ymd(week_start) %m+% days(3), y = count, fill = is_alarm)) +
    geom_col() +
    scale_fill_manual(values = c("grey", "red3")) +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    facet_wrap(~state, ncol = 5, scales = "free_y") +
    theme_minimal(base_family = "Arial") +
    scale_y_continuous("", expand = c(0, 0)) +
    ggtitle(title) + labs(x = NULL, y = NULL) + 
    theme(legend.position = "none", plot.margin = margin(4, 4, 0, 4))
  p$plot_env <- rlang::new_environment()
  p
}


#' @param df `metadata` joined with cleaned `nextclade` data.frame
#' @export
plot_location_proportion <- function(df,
                                     lineage_date,
                                     no_months_plots,
                                     title = "") {
  df$is_alarm <- df$is_alarm == 1
  df <- df %>% group_by(state, week_start) %>% mutate(proportion=count / sum(count))
  p <- ggplot(df, aes(ymd(week_start) %m+% days(3), y = proportion, fill = is_alarm)) +
    geom_col() +
    scale_fill_manual(values = c("grey", "red3")) +
    scale_y_continuous("", labels = scales::percent, expand = c(0, 0)) +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    facet_wrap(~state, ncol = 5) +
    theme_minimal(base_family = "Arial") +
    ggtitle(title) + labs(x = NULL, y = NULL) + 
    theme(legend.position = "none", plot.margin = margin(4, 4, 0, 4))
  p$plot_env <- rlang::new_environment()
  p
}
