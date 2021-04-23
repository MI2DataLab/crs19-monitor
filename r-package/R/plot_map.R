#' @param df `metadata` joined with cleaned `nextclade` data.frame
#' @param map a list containing `map_cord` and `map_metadata`
#' @export
plot_map <- function(df,
                     map,
                     alarm_mutation,
                     date_last_sample,
                     max_regions,
                     other_level = "Other",
                     subtitle1 = "",
                     subtitle2 = "",
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

  t_dat_map <- tab_df %>% rename(date = Var1, name = Var2, type = Var3, count = Freq)

  ((t_dat_map %>%
      filter(ymd(date) %m+% months(3) >= date_last_sample) %>%
      mutate(name = tolower(name)) -> t_map_metadata_left) %>%
      group_by(name, type) %>%
      summarise(count = sum(count))  %>%
      pivot_wider(id_cols = name, names_from = type, values_from = count) %>%
      inner_join(t_map_metadata_left %>%
                   group_by(name) %>%
                   summarise(ratio = sum(count) / sum(t_map_metadata_left$count)),
                 by = "name") -> t_map_metadata_left) %>%
    mutate(ratio = 2 * (10e12 * ratio / max(t_map_metadata_left$ratio)) ** (1/3)) -> t_map_metadata_left

  ((t_dat_map %>%
      filter(ymd(date) %m+% months(1) >= date_last_sample) %>%
      mutate(name = tolower(name)) -> t_map_metadata_right) %>%
      group_by(name, type) %>%
      summarise(count = sum(count))  %>%
      pivot_wider(id_cols = name, names_from = type, values_from = count) %>%
      inner_join(t_map_metadata_right %>%
                   group_by(name) %>%
                   summarise(ratio = sum(count) / sum(t_map_metadata_right$count)),
                 by = "name") -> t_map_metadata_right) %>%
    mutate(ratio = 2 * (10e12 * ratio / max(t_map_metadata_right$ratio)) ** (1/3)) -> t_map_metadata_right

  map_cord <- map$map_cord %>% select(X, Y, id)
  map_metadata_left <- map$map_metadata %>%
                          left_join(t_map_metadata_left, by = "name") %>%
                          drop_na() %>%
                          select(X, Y, ratio, id)
  map_metadata_right <- map$map_metadata %>%
                          left_join(t_map_metadata_right, by = "name") %>%
                          drop_na() %>%
                          select(X, Y, ratio, id)
  print(head(map_cord))
  print(head(map_metadata_left))
  pl_map_1 <- ggplot(map_cord) +
    geom_polygon(aes(X, Y, group = id), color = "black", fill = "white") +
    scatterpie::geom_scatterpie(data = map_metadata_left,
                                cols = c(alarm_mutation, "-"),
                                aes(x = X, y = Y, r = ratio, group = id)) +
    coord_equal() +
    scale_fill_manual(values = c("red3", "grey")) +
    theme_void() +
    theme(legend.position = "none") +
    ggtitle(subtitle1) +
    theme(plot.title = element_text(size = 12, hjust = 0.5))

  pl_map_2 <- ggplot(map_cord) +
    geom_polygon(aes(X, Y, group = id), color = "black", fill = "white") +
    scatterpie::geom_scatterpie(data = map_metadata_right,
                                cols = c(alarm_mutation, "-"),
                                aes(x = X, y = Y, r = ratio, group = id)) +
    coord_equal() +
    scale_fill_manual(values = c("red3", "grey")) +
    theme_void() +
    theme(legend.position = "none") +
    ggtitle(subtitle2) +
    theme(plot.title = element_text(size = 12, hjust = 0.5))

  p <- (pl_map_1 + pl_map_2) +
    plot_annotation(
      title = title,
      theme = theme(plot.title = element_text(size = 15, hjust = 0.5))
    )
  print("cpt")
  p
}
