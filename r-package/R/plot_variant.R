#' @param df cleaned `nextclade` data.frame
#' @export
plot_variant_col_fill <- function(df,
                                  alarm_clade,
                                  lineage_date,
                                  palette,
                                  no_months_plots,
                                  title = "") {

  tab <- table(ymd(df$date) - days(wday(ymd(df$date))), df$clade_small)
  tab_df <- as.data.frame(as.table(tab))
  colnames(tab_df) <- c("date", "variant", "n")

  tab_df$variant <- reorder(tab_df$variant, tab_df$n, tail, 1)
  tab_df$variant <- fct_relevel(tab_df$variant, alarm_clade, after = Inf)

  tab_df <- tab_df[tab_df$variant %in% names(palette),]
  tab_df <- tab_df[ymd(tab_df$date) > ymd(lineage_date) %m-% months(no_months_plots),]

  rm('df')
  rm('tab')

  p <- ggplot(tab_df, aes(ymd(date) + days(3), y = n, fill = variant)) +
    geom_col(position = "fill", color = "white") +
    coord_cartesian(xlim = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date)), ylim = c(0, 1)) +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    scale_fill_manual("", values = palette) +
    ggtitle(title) +
    theme_minimal(base_family = "Arial") +
    theme(legend.key.size = unit(0.66, 'cm'), legend.text = element_text(size=9)) +
    scale_y_continuous("", expand = c(0, 0), labels = scales::percent)

  p$plot_env <- rlang::new_environment()
  p
}


#' @param df cleaned `nextclade` data.frame
#' @export
plot_variant_col_stack <- function(df,
                                   alarm_clade,
                                   lineage_date,
                                   palette,
                                   no_months_plots,
                                   title = "") {

  tab <- table(ymd(df$date) - days(wday(ymd(df$date))), df$clade_small)
  tab_df <- as.data.frame(as.table(tab))
  colnames(tab_df) <- c("date", "variant", "n")

  tab_df$variant <- reorder(tab_df$variant, tab_df$n, tail, 1)
  tab_df$variant <- fct_relevel(tab_df$variant, alarm_clade, after = Inf)

  tab_df <- tab_df[tab_df$variant %in% names(palette),]
  tab_df <- tab_df[ymd(tab_df$date) > ymd(lineage_date) %m-% months(no_months_plots),]

  rm('df')
  rm('tab')

  p <- ggplot(tab_df, aes(ymd(date) + days(3), y = n, fill = variant)) +
    geom_col(position = "stack", color = "white") +
    coord_cartesian(xlim = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    scale_fill_manual("", values = palette) +
    ggtitle(title) +
    theme_minimal(base_family = "Arial") +
    theme(legend.key.size = unit(0.66, 'cm'), legend.text = element_text(size=9)) +
    scale_y_continuous("", expand = c(0, 0))

  p$plot_env <- rlang::new_environment()
  p
}


#' @param df cleaned `nextclade` data.frame
#' @export
plot_variant_area <- function(df,
                              k,
                              alarm_clade,
                              lineage_date,
                              palette,
                              no_months_plots,
                              title = "") {

  tab <- table(df$date, df$clade_small)
  # add +k days for reporting lag
  for (i in nrow(tab):k) {
    tab[i,] <- colSums(tab[i - (1:k) + 1,])
  }

  tab_df <- as.data.frame(as.table(tab))
  colnames(tab_df) <- c("date", "variant", "n")

  tab_df$variant <- reorder(tab_df$variant, tab_df$n, tail, 1)
  tab_df$variant <- fct_relevel(tab_df$variant, alarm_clade, after = Inf)

  tab_df <- tab_df[tab_df$variant %in% names(palette),]
  tab_df <- tab_df[ymd(tab_df$date) > ymd(lineage_date) %m-% months(no_months_plots),]

  rm('df')
  rm('tab')

  p <- ggplot(tab_df, aes(ymd(date), y = n, fill = variant)) +
    geom_area(position = "fill", color = "white") +
    coord_cartesian(xlim = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date)), ylim = c(0, 1)) +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    scale_fill_manual("", values = palette) +
    ggtitle(title) +
    theme_minimal(base_family = "Arial") +
    theme(legend.key.size = unit(0.66, 'cm'), legend.text = element_text(size=9)) +
    scale_y_continuous("", expand = c(0, 0), labels = scales::percent)

  p$plot_env <- rlang::new_environment()
  p
}


#' @param df cleaned `nextclade` data.frame
#' @export
plot_variant_point_smooth <- function(df,
                                      k,
                                      smooth_variants,
                                      alarm_clade,
                                      lineage_date,
                                      palette,
                                      no_months_plots,
                                      title = "") {

  tab <- table(df$date, df$clade_small)
  # add +k days for reporting lag
  for (i in nrow(tab):k) {
    tab[i,] <- colSums(tab[i - (1:k) + 1,])
  }

  tab <- apply(tab, 1, function(x) x / sum(x))
  tab <- t(tab)

  tab_df <- as.data.frame(as.table(tab))
  colnames(tab_df) <- c("date", "variant", "n")

  tab_df$variant <- reorder(tab_df$variant, tab_df$n, tail, 1)
  tab_df$variant <- fct_relevel(tab_df$variant, alarm_clade, after = Inf)

  tab_df <- tab_df[tab_df$variant %in% names(palette),]
  tab_df <- tab_df[ymd(tab_df$date) > ymd(lineage_date) %m-% months(no_months_plots),]

  df_point <- na.omit(tab_df[tab_df$n > 0 & tab_df$n < 1,])
  df_smooth <- tab_df[(tab_df$variant %in% smooth_variants) &
                      (ymd(tab_df$date) > ymd(lineage_date) %m-% months(2)),]

  rm('df')
  rm('tab')
  rm('tab_df')

  p <- ggplot(df_point, aes(ymd(date), y = n, color = variant)) +
    geom_point() +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    geom_smooth(data = df_smooth, se = FALSE, span = 1, method = 'loess', formula = y ~ x) +
    scale_y_continuous("", expand = c(0, 0),
                       breaks = c(0.01, 0.1, 0.25, 0.5, 0.75, 0.9, 0.99), limits = c(0, 1)) +
    scale_color_manual("", values = palette) +
    ggtitle(title) +
    theme_minimal(base_family = "Arial") +
    theme(legend.key.size = unit(0.66, 'cm'), legend.text = element_text(size=9)) +
    coord_cartesian(xlim = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date)))

  p$plot_env <- rlang::new_environment()
  p
}
