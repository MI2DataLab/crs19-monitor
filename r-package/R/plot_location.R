#' @param df `metadata` joined with cleaned `nextclade` data.frame
#' @export
plot_location_count <- function(df,
                                max_regions,
                                lineage_date,
                                no_months_plots,
                                other_level = "Other",
                                title = "") {

  tab <- table(df$week_start, df$LocationClean, df$is_alarm)
  tab_df <- data.frame(as.table(tab))
  cat(head(tab_df))
  selected_regions <- head(levels(tab_df$Var2), max_regions)
  n_unique_regions <- max(length(unique(selected_regions)), 1)

  try({
    df$LocationClean <- fct_other(df$LocationClean,
                                  keep = selected_regions,
                                  other_level = other_level)
  }, silent = TRUE)

  # calculate this table again with combined levels
  tab <- table(df$week_start, df$LocationClean, df$is_alarm)
  tab_df <- data.frame(as.table(tab))

  rm('df')
  rm('tab')

  p <- ggplot(tab_df, aes(ymd(Var1), y = Freq, fill = Var3)) +
    geom_col() +
    scale_fill_manual(values = c("grey", "red3")) +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    facet_wrap(~Var2, ncol = 5, scales = "free_y") +
    theme_minimal(base_family = "Arial") +
    scale_y_continuous("", expand = c(0, 0)) +
    ggtitle(title) +
    theme(legend.position = "none")

  attr(p, "n_unique_regions") <- n_unique_regions
  p$plot_env <- rlang::new_environment()
  p
}


#' @param df `metadata` joined with cleaned `nextclade` data.frame
#' @export
plot_location_proportion <- function(df,
                                     max_regions,
                                     lineage_date,
                                     no_months_plots,
                                     other_level = "Other",
                                     title = "") {

  tab <- table(df$week_start, df$LocationClean, df$is_alarm)
  tab_df <- data.frame(as.table(tab))

  selected_regions <- head(levels(tab_df$Var2), max_regions)
  try({
    df$LocationClean <- fct_other(df$LocationClean,
                                  keep = selected_regions,
                                  other_level = other_level)
  }, silent = TRUE)

  # calculate this table again with combined levels
  tab <- table(df$week_start, df$LocationClean, df$is_alarm)
  tab_df <- data.frame(as.table(tab))
  l <- levels(tab_df$Var2)

  # normalize for proportion
  normalizer <-  tab[,,1] + tab[,,2]
  tab[,,1] <- tab[,,1] / normalizer
  tab[,,2] <- tab[,,2] / normalizer
  tab_df <- data.frame(as.table(tab))
  tab_df$Var2 <- factor(tab_df$Var2, levels = l)

  rm('df')
  rm('tab')

  p <- ggplot(tab_df, aes(ymd(Var1), y = Freq, fill = Var3)) +
    geom_col() +
    scale_fill_manual(values = c("grey", "red3")) +
    scale_y_continuous("", labels = scales::percent, expand = c(0, 0)) +
    scale_x_date("", date_breaks = "1 month", date_labels = "%m",
                 limits = c(ymd(lineage_date) %m-% months(no_months_plots), ymd(lineage_date))) +
    facet_wrap(~Var2, ncol = 5) +
    theme_minimal(base_family = "Arial") +
    ggtitle(title) +
    theme(legend.position = "none")

  p$plot_env <- rlang::new_environment()
  p
}
