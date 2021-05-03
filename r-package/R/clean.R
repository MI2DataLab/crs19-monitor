#' @param df `metadata` data.frame
#' @export
clean_metadata <- function(df) {

  location_dict_to_from <- location_dict()
  location_dict_from_to <- reverse_dict(location_dict_to_from)

  location_from <- sapply(strsplit(df$location, split = "/"), `[`, 3,
                          simplify = TRUE, USE.NAMES = FALSE)
  df$LocationRaw <- location_from
  location_to <- location_dict_from_to[location_from]
  location_to[is.na(names(location_to))] <- NA
  df$LocationClean <- unlist(location_to)

  if (all(is.na(df$LocationClean)) & !all(is.na(location_from))) {
    df$LocationClean <- unlist(location_from)
  } else if (all(is.na(df$LocationClean))) {
    df$LocationClean <- "country"
  }

  df$week_start <- ymd(df$collection_date) - days(wday(ymd(df$collection_date)))

  df
}


#' @param df `lineage` data.frame
#' @export
clean_lineage <- function(df, alarm_pango, other_level = "Other") {

  df$date <- sapply(
    strsplit(df$Sequence.name, split = "|", fixed = TRUE),
    function(x) substr(paste0(tail(x, 1), "-01"), 1, 10)
  )

  sample <- sapply(strsplit(df$Sequence.name, split = "\\|"), `[`, 2)
  df$sample <- gsub(sample, pattern = " ", replacement = "")

  lineage <- fct_infreq(df$Lineage)
  is_alarm <- levels(lineage) %in% alarm_pango
  alarm_count <- sum(is_alarm)
  not_alarm_pango <- levels(lineage)[!is_alarm]
  df$pango_small <- fct_other(
    lineage,
    keep = unique(c(head(levels(not_alarm_pango), (3*5)-alarm_count-1), alarm_pango)),
    other_level = other_level
  )
  df$pango_medium <- fct_other(
    lineage,
    keep = unique(c(head(levels(not_alarm_pango), 20), alarm_pango)),
    other_level = other_level
  )

  df
}


#' @param df `nextclade` data.frame
#' @export
clean_nextclade <- function(df, alarm_clade, alarm_mutation, alarm_pattern, other_level = "Other") {

  df$date <- sapply(
    strsplit(df$seqName, split = "|", fixed = TRUE),
    function(x) substr(paste0(tail(x, 1), "-01"), 1, 10)
  )

  sample <- sapply(strsplit(df$seqName, split = "\\|"), `[`, 2)
  df$sample <- gsub(sample, pattern = " ", replacement = "")

  clade <- fct_infreq(df$clade)
  is_alarm <- levels(clade) %in% alarm_clade
  alarm_count <- sum(is_alarm)
  not_alarm_clade <- levels(clade)[!is_alarm]
  cat(head(levels(not_alarm_clade), (2*6)-alarm_count-1))
  cat(alarm_clade)
  to_keep <- unique(c(head(levels(not_alarm_clade), (2*6)-alarm_count-1), alarm_clade))
  df$clade_small <- fct_other(
    clade,
    keep = to_keep,
    other_level = other_level
  )
  df$clade_medium <- clade

  df$seqName <- gsub(df$seqName, pattern = "\\|.*", replacement = "")

  df$is_alarm <- ifelse(grepl(df$clade_small, pattern = alarm_pattern), alarm_mutation, "-")

  df
}
