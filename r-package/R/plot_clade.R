#' @param df cleaned `nextclade` data.frame
#' @export
plot_clade_facet <- function(df,
                             lineage_date,
                             no_months_plots,
                             title = "") {
  # Add cummulative counts
  df <- df %>% group_by(clade) %>% mutate(cum_count = cumsum(count), is_alarm=is_alarm==1) %>% ungroup
  # Fix order of facets
  df$clade <- factor(df$clade, levels=unique(df$clade))
  # Total counts
  counts <- df %>% group_by(clade) %>% summarise(cum_count=sum(count), is_alarm=first(is_alarm), date=ymd(lineage_date) %m-% months(no_months_plots))
  # plot
  p <- ggplot(df, aes(ymd(date), ymax = cum_count, ymin = 0, fill = is_alarm)) +
    pammtools::geom_stepribbon() +
    geom_text(data = counts,
              aes(x = ymd(date),
                  y = max(cum_count),
                  label = format(cum_count, big.mark=" ", scientific=FALSE),
                  hjust = -0.1,
                  vjust = 1),
              size = 2.7) +
    scale_fill_manual(values = c("blue4", "red4")) +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    facet_wrap(~clade, ncol = 5) +
    theme_minimal(base_family = "Arial") +
    scale_y_log10(
      breaks = scales::trans_breaks("log10", function(x) 10^x),
      labels = scales::trans_format("log10", scales::math_format(10^.x)),
      name = "", expand = c(0, 0), n.breaks = 4) +
    ggtitle(title) + labs(x = NULL, y = NULL) + 
    theme(legend.position = "none", plot.margin = margin(4, 4, 0, 4))
  p$plot_env <- rlang::new_environment()
  p
}


#' @param df cleaned `nextclade` data.frame
#' @export
plot_clade_cumulative <- function(df,
                                  lineage_date,
                                  no_months_plots_long,
                                  title = "") {
  # Add cummulative counts
  df <- df %>% group_by(clade) %>% mutate(cum_count = cumsum(count), is_alarm=is_alarm==1) %>% ungroup
  # Get last point of each alarm clade to put label there
  last_points <- df %>% group_by(clade) %>% summarise(date=max(date), cum_count=sum(count), is_alarm=first(is_alarm)) %>% filter(is_alarm)
  # plot
  p <- ggplot(df, aes(ymd(date), y = cum_count, color = is_alarm, group = clade, size=is_alarm)) +
    geom_step() +
    ggrepel::geom_text_repel(data = last_points,
                             aes(x = ymd(lineage_date),
                                 y = cum_count,
                                 label = clade,
                                 hjust = 0,
                                 vjust = 0.6),
                             size = 2.9,
                             direction = "y") +
    scale_size_manual(values = c(0.4, 1.2)) +
    scale_color_manual(values = c("grey", "red3")) +
    scale_x_date("", date_breaks = "2 weeks", date_labels = "%m/%d",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots_long), ymd(lineage_date))) +
    theme_minimal(base_family = "Arial") +
    scale_y_log10(
      breaks = scales::trans_breaks("log10", function(x) 10^x),
      labels = scales::trans_format("log10", scales::math_format(10^.x)),
      name = "", expand = c(0, 0), n.breaks = 4) +
    ggtitle(title) + labs(x = NULL, y = NULL) + 
    theme(legend.position = "none", plot.margin = margin(4, 4, 0, 4))
  p$plot_env <- rlang::new_environment()
  p
}
