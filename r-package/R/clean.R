#' @param df `lineage` data.frame
#' @export
clean_lineage <- function(df, alarm_pango, other_level = "Other") {
  df$date <- sapply(
    strsplit(df$Sequence.name, split = "|", fixed = TRUE),
    function(x) substr(paste0(tail(x, 1), "-01"), 1, 10)
  )

  sample <- sapply(strsplit(df$Sequence.name, split = "\\|"), `[`, 2)
  df$sample <- gsub(sample, pattern = " ", replacement = "")

  lineage_small <- fct_infreq(df$Lineage)
  df$lineage_small <- fct_other(
    lineage_small,
    keep = unique(c(head(levels(lineage_small), 7), alarm_pango)),
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

  clade_small <- fct_infreq(df$clade)
  df$clade_small <- fct_lump(
    clade_small,
    n = 12,
    other_level = other_level
  )

  df
}
