#' Internal functions
#'
#' @import ggplot2 dplyr tidyr lubridate forcats patchwork

smooth_variants_count <- function(df, k, date_column="date", variant_column="variant", count_column="count") {
  tab <- reshape2::acast(df, as.formula(paste(date_column, "~", variant_column)), value.var=count_column, fill=0)
  # add +k days for reporting lag
  for (i in nrow(tab):k) {
    tab[i,] <- colSums(tab[i - (1:k) + 1,])
  }
  tab <- apply(tab, 1, function(x) x / sum(x))
  tab <- t(tab)
  tab_df <- as.data.frame(as.table(tab))
  colnames(tab_df) <- c(date_column, variant_column, count_column)
  tab_df
}
