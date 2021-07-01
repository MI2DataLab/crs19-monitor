#' @export
plot_who_location_count <- function(df,
                                     lineage_date,
                                     no_months_plots,
                                     title = "") {
  palette <- df %>% select(name, color) %>% unique %>% tibble::deframe()
  p <- ggplot(df, aes(ymd(week_start) %m+% days(3), y = count, fill = name)) +
    geom_col() +
    scale_fill_manual(values = palette, name="") +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    facet_wrap(~state, ncol = 3, scales = "free_y") +
    theme_minimal(base_family = "Arial") +
    scale_y_continuous("", expand = c(0, 0)) +
    ggtitle(title) + labs(x = NULL, y = NULL) + 
    guides(fill=guide_legend(nrow=1,byrow=TRUE)) +
    theme(legend.position = "bottom", plot.margin = margin(4, 4, 0, 4))
  p$plot_env <- rlang::new_environment()
  p
}


#' @export
plot_who_location_proportion <- function(df,
                                     lineage_date,
                                     no_months_plots,
                                     title = "") {
  palette <- df %>% select(name, color) %>% unique %>% tibble::deframe()
  df <- df %>% group_by(state, week_start) %>% mutate(proportion=count / sum(count))
  p <- ggplot(df, aes(ymd(week_start) %m+% days(3), y = proportion, fill = name)) +
    geom_col() +
    scale_fill_manual(values = palette, name="") +
    scale_y_continuous("", labels = scales::percent, expand = c(0, 0)) +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    facet_wrap(~state, ncol = 3) +
    theme_minimal(base_family = "Arial") +
    ggtitle(title) + labs(x = NULL, y = NULL) + 
    guides(fill=guide_legend(nrow=1,byrow=TRUE)) +
    theme(legend.position = "bottom", plot.margin = margin(4, 4, 0, 4))
  p$plot_env <- rlang::new_environment()
  p
}

#' @export
plot_who_count <- function(df,
                                     lineage_date,
                                     no_months_plots,
                                     title = "") {
  palette <- df %>% select(name, color) %>% unique %>% tibble::deframe()
  p <- ggplot(df, aes(ymd(week_start) %m+% days(3), y = count, fill = name)) +
    geom_col(position = "stack", color = "white") +
    scale_fill_manual(values = palette, name="") +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    theme_minimal(base_family = "Arial") +
    scale_y_continuous("", expand = c(0, 0)) +
    ggtitle(title) + labs(x = NULL, y = NULL) + 
    theme(legend.key.size = unit(0.4, 'cm'),
          legend.text = element_text(size=10),
          plot.margin = margin(4, 4, 0, 4), legend.position="bottom", legend.margin=margin(-20,0,0,0))
  p$plot_env <- rlang::new_environment()
  p
}

#' @export
plot_who_proportion <- function(df,
                                     lineage_date,
                                     no_months_plots,
                                     title = "") {
  palette <- df %>% select(name, color) %>% unique %>% tibble::deframe()
  df <- df %>% group_by(week_start) %>% mutate(proportion=count / sum(count))
  p <- ggplot(df, aes(ymd(week_start) %m+% days(3), y = proportion, fill = name)) +
    geom_col(position = "stack", color = "white") +
    scale_fill_manual(values = palette, name="") +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    theme_minimal(base_family = "Arial") +
    scale_y_continuous("", expand = c(0, 0)) +
    ggtitle(title) + labs(x = NULL, y = NULL) + 
    theme(legend.key.size = unit(0.4, 'cm'),
          legend.text = element_text(size=10),
          plot.margin = margin(4, 4, 0, 4), legend.position="bottom", legend.margin=margin(-20,0,0,0))
  p$plot_env <- rlang::new_environment()
  p
}

#' @export
plot_who_cumulative <- function(df,
                                  lineage_date,
                                  no_months_plots_long,
                                  title = "") {
  palette <- df %>% select(name, color) %>% unique %>% tibble::deframe()
  # Add cummulative counts
  df <- df %>% group_by(name) %>% mutate(cum_count = cumsum(count)) %>% ungroup
  # Get last point of each pango
  last_points <- df %>% group_by(name) %>% summarise(date=max(date), cum_count=sum(count), class=first(class))
  # plot
  p <- ggplot(df, aes(ymd(date), y = cum_count, color = name, group=name, size=class=='voc')) +
    geom_step() +
    ggrepel::geom_text_repel(data = last_points,
                             aes(x = ymd(lineage_date) %m+% days(4),
                                 y = cum_count,
                                 label = name,
                                 hjust = 0,
                                 vjust = 0.5),
                             size = 2.9,
                             force = 0.2,
                             direction = "y") +
    scale_x_date("", date_breaks = "2 weeks", date_labels = "%m/%d",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots_long), ymd(lineage_date) %m+% days(7))) +
    scale_size_manual(values = c("FALSE"=0.4, "TRUE"=1.2), guide=FALSE) +
    theme_minimal(base_family = "Arial") +
    scale_color_manual(values = palette, name="") +
    scale_y_log10(
      breaks = scales::trans_breaks("log10", function(x) 10^x),
      labels = scales::trans_format("log10", scales::math_format(10^.x)),
      name = "", n.breaks = 4) +
    ggtitle(title) + labs(x = NULL, y = NULL) + 
    theme(plot.margin = unit(c(5.5, 5.5, 2, 5.5), "pt"), legend.position="none")
  p$plot_env <- rlang::new_environment()
  p
}
