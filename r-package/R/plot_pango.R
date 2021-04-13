#' @param df cleaned `lineage` data.frame
#' @export
plot_pango_facet <- function(df,
                             alarm_pango,
                             lineage_date,
                             no_months_plots,
                             title = "") {

  tab <- apply(table(df$date, df$pango_small), 2, cumsum)
  df <- as.data.frame(as.table(tab))
  colnames(df) <- c("date", "variant", "n")
  variant <- tab[nrow(tab),]
  counts <- data.frame(
    variant = factor(names(variant), levels = names(variant)),
    label = variant,
    date = as.character(ymd(lineage_date) %m-% months(NO_MONTHS_PLOTS)),
    n = max(variant)
  )

  ggplot(df, aes(ymd(date), ymax = n, ymin = 0, fill = variant %in% alarm_pango)) +
    pammtools::geom_stepribbon() +
    geom_text(data = counts,
              aes(x = ymd(date),
                  y = n,
                  label = label,
                  hjust = 0,
                  vjust = 1),
              size = 2.7) +
    scale_fill_manual(values = c("blue4", "red4")) +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    #  scale_x_date("", date_breaks = "2 months", date_labels = "%m") +
    facet_wrap(~variant, ncol = 5) +
    theme_minimal(base_family = "Arial") +
    scale_y_continuous("", expand = c(0, 0)) +
    ggtitle(title) +
    theme(legend.position = "none")
}


#' @param df cleaned `lineage` data.frame
#' @export
plot_pango_cumulative <- function(df,
                                  alarm_pango,
                                  lineage_date,
                                  no_months_plots_long,
                                  title = "") {

  tab <- apply(table(df$date, df$pango_medium), 2, cumsum)
  df <- as.data.frame(as.table(tab))
  colnames(df) <- c("date", "variant", "n")
  variant <- tab[nrow(tab),]
  counts <- data.frame(
    variant = factor(names(variant), levels = names(variant)),
    label = variant,
    date = "2020/03/01",
    n = max(variant)
  )
  counts <- counts[counts$variant %in% alarm_pango,]

  ggplot(df, aes(ymd(date), y = n, color = variant %in% alarm_pango, group = variant)) +
    geom_step() +
    geom_step(data = df[df$variant %in% alarm_pango,], size = 1.1) +
    ggrepel::geom_text_repel(data = counts,
                             aes(x = ymd(lineage_date),
                                 y = label,
                                 label = variant,
                                 hjust = 0,
                                 vjust = 0.6),
                             size = 2.9,
                             direction = "y") +
    scale_color_manual(values = c("grey", "red3")) +
    scale_x_date("", date_breaks = "2 weeks", date_labels = "%m/%d",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots_long), ymd(lineage_date))) +
    theme_minimal(base_family = "Arial") +
    scale_y_continuous("", expand = c(0, 0)) +
    ggtitle(title) +
    theme(legend.position = "none")
}