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

  if (sum(!is.na(df$LocationClean)) == 0) {
    df$LocationClean <- unlist(location_from)
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
  df$pango_small <- fct_other(
    lineage,
    keep = unique(c(head(levels(lineage), 7), alarm_pango)),
    other_level = other_level
  )
  df$pango_medium <- fct_other(
    lineage,
    keep = unique(c(head(levels(lineage), 20), alarm_pango)),
    other_level = other_level
  )

  df
}


#' @param df `nextclade` data.frame
#' @export
clean_nextclade <- function(df, other_level = "Other") {

  df$date <- sapply(
    strsplit(df$seqName, split = "|", fixed = TRUE),
    function(x) substr(paste0(tail(x, 1), "-01"), 1, 10)
  )

  sample <- sapply(strsplit(df$seqName, split = "\\|"), `[`, 2)
  df$sample <- gsub(sample, pattern = " ", replacement = "")

  clade <- fct_infreq(df$clade)
  df$clade_small <- fct_lump(
    clade,
    n = 12,
    other_level = other_level
  )
  df$clade_medium <- clade

  df$seqName <- gsub(df$seqName, pattern = "\\|.*", replacement = "")

  df
}
