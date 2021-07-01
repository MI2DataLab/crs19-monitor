#' @export
plot_category_location_count <- function(df,
                                lineage_date,
                                no_months_plots,
                                title = "") {
  df$class <- factor(df$class, levels=rev(c("voc", "voi", "vum", "none")))
  p <- ggplot(df, aes(ymd(week_start) %m+% days(3), y = count, fill = class)) +
    geom_col() +
    scale_fill_manual(values = c("voc"="#292349", "voi"="#7d7c92", "vum"="#a9aab8", "none"="#d4d5de"), labels=c("Variants of concern", "Variants of interest", "Variants under monitoring", "Other"), name="") +
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
plot_category_location_proportion <- function(df,
                                     lineage_date,
                                     no_months_plots,
                                     title = "") {
  df$class <- factor(df$class, levels=rev(c("voc", "voi", "vum", "none")))
  df <- df %>% group_by(state, week_start) %>% mutate(proportion=count / sum(count))
  p <- ggplot(df, aes(ymd(week_start) %m+% days(3), y = proportion, fill = class)) +
    geom_col() +
    scale_fill_manual(values = c("voc"="#292349", "voi"="#7d7c92", "vum"="#a9aab8", "none"="#d4d5de"), labels=c("Variants of concern", "Variants of interest", "Variants under monitoring", "Other"), name="") +
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
plot_category_count <- function(df,
                                lineage_date,
                                no_months_plots,
                                title = "") {
  df$class <- factor(df$class, levels=rev(c("voc", "voi", "vum", "none")))
  p <- ggplot(df, aes(ymd(week_start) %m+% days(3), y = count, fill = class)) +
    geom_col(position = "stack", color = "white") +
    scale_fill_manual(values = c("voc"="#292349", "voi"="#7d7c92", "vum"="#a9aab8", "none"="#d4d5de"), labels=c("VOC", "VOI", "VUM", "Other"), name="") +
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
plot_category_proportion <- function(df,
                                lineage_date,
                                no_months_plots,
                                title = "") {
  df$class <- factor(df$class, levels=rev(c("voc", "voi", "vum", "none")))
  df <- df %>% group_by(week_start) %>% mutate(proportion=count / sum(count))
  p <- ggplot(df, aes(ymd(week_start) %m+% days(3), y = proportion, fill = class)) +
    geom_col(position = "stack", color = "white") +
    scale_fill_manual(values = c("voc"="#292349", "voi"="#7d7c92", "vum"="#a9aab8", "none"="#d4d5de"), labels=c("VOC", "VOI", "VUM", "Other"), name="") +
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
