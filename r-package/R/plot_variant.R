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

  ggplot(tab_df, aes(ymd(date) + days(3), y = n, fill = variant)) +
    geom_col(position = "fill", color = "white") +
    coord_cartesian(xlim = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date)), ylim = c(0, 1)) +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    scale_fill_manual("", values = palette) +
    ggtitle(title) +
    theme_minimal(base_family = "Arial") +
    scale_y_continuous("", expand = c(0, 0), labels = scales::percent)
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

  ggplot(tab_df, aes(ymd(date) + days(3), y=n, fill = variant)) +
    geom_col(position = "stack", color = "white") +
    coord_cartesian(xlim = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    scale_fill_manual("", values = palette) +
    ggtitle(title) +
    theme_minimal(base_family = "Arial") +
    scale_y_continuous("", expand = c(0,0))
}
