#' @param df cleaned `nextclade` data.frame
#' @export
plot_variant_col_fill <- function(df,
                                  lineage_date,
                                  no_months_plots,
                                  title = "") {
  palette <- df %>% select(clade, color) %>% unique %>% tibble::deframe()
  p <- ggplot(df, aes(ymd(week_start) + days(3), y = count, fill = clade)) +
    geom_col(position = "fill", color = "white") +
    coord_cartesian(xlim = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date)), ylim = c(0, 1)) +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    scale_fill_manual("", values = palette) +
    ggtitle(title) + labs(x = NULL, y = NULL) + 
    theme_minimal(base_family = "Arial") +
    theme(legend.key.size = unit(0.4, 'cm'),
          legend.text = element_text(size=7),
          plot.title = element_text(size = rel(1)),
          plot.margin = margin(4, 4, 0, 4)) +
    scale_y_continuous("", expand = c(0, 0), labels = scales::percent)
  p$plot_env <- rlang::new_environment()
  p
}


#' @param df cleaned `nextclade` data.frame
#' @export
plot_variant_col_stack <- function(df,
                                   lineage_date,
                                   no_months_plots,
                                   title = "") {
  palette <- df %>% select(clade, color) %>% unique %>% tibble::deframe()
  p <- ggplot(df, aes(ymd(week_start) + days(3), y = count, fill = clade)) +
    geom_col(position = "stack", color = "white") +
    coord_cartesian(xlim = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    scale_fill_manual("", values = palette) +
    ggtitle(title) + labs(x = NULL, y = NULL) + 
    theme_minimal(base_family = "Arial") +
    theme(legend.key.size = unit(0.4, 'cm'),
          legend.text = element_text(size=7),
          plot.title = element_text(size = rel(1)),
          plot.margin = margin(4, 4, 0, 4)) +
    scale_y_continuous("", expand = c(0, 0))
  p$plot_env <- rlang::new_environment()
  p
}


#' @param df cleaned `nextclade` data.frame
#' @export
plot_variant_area <- function(df,
                              k,
                              lineage_date,
                              no_months_plots,
                              title = "") {
  palette <- df %>% select(clade, color) %>% unique %>% tibble::deframe()
  df <- smooth_variants_count(df, k, variant_column="clade")
  p <- ggplot(df, aes(ymd(date), y = count, fill = clade)) +
    geom_area(position = "fill", color = "white") +
    coord_cartesian(xlim = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date)), ylim = c(0, 1)) +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    scale_fill_manual("", values = palette) +
    ggtitle(title) + labs(x = NULL, y = NULL) + 
    theme_minimal(base_family = "Arial") +
    theme(legend.key.size = unit(0.4, 'cm'),
          legend.text = element_text(size=7),
          plot.title = element_text(size = rel(1)),
          plot.margin = margin(4, 4, 0, 4)) +
    scale_y_continuous("", expand = c(0, 0), labels = scales::percent)
  p$plot_env <- rlang::new_environment()
  p
}


#' @param df cleaned `nextclade` data.frame
#' @export
plot_variant_point_smooth <- function(df,
                                      k,
                                      lineage_date,
                                      no_months_plots,
                                      title = "") {
  palette <- df %>% select(clade, color) %>% unique %>% tibble::deframe()
  df <- smooth_variants_count(df, k, variant_column="clade")
  df_smooth <- df[(ymd(df$date) > ymd(lineage_date) %m-% months(2)),]
  p <- ggplot(df, aes(ymd(date), y = count, color = clade)) +
    geom_point(size = 0.75) +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    geom_smooth(data = df_smooth, 
                se = FALSE, 
                span = 1, 
                method = 'loess', 
                formula = y ~ x,
                size = 0.75) +
    scale_y_continuous("", expand = c(0, 0),
                       breaks = c(0.01, 0.1, 0.25, 0.5, 0.75, 0.9, 0.99), limits = c(-0.01, 1)) +
    scale_color_manual("", values = palette) +
    ggtitle(title) + labs(x = NULL, y = NULL) + 
    theme_minimal(base_family = "Arial") +
    theme(legend.key.size = unit(0.4, 'cm'),
          legend.text = element_text(size=7),
          plot.title = element_text(size = rel(1)),
          plot.margin = margin(4, 4, 0, 4)) +
    coord_cartesian(xlim = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date)))
  p$plot_env <- rlang::new_environment()
  p
}
