#' @export
create_i18n <- function(input_paths, output_path) {
  i18n <- sapply(input_paths, function(path) {
    i18n_table <- read.table(path,
                             sep = ":",
                             header = TRUE,
                             fileEncoding = "UTF-8",
                             quote = NULL)
    # Transform table to dictionary
    obj <- as.list(i18n_table[["names"]])
    names(obj) <- i18n_table[["tag"]]
    obj
  }, simplify = FALSE)
  write(jsonlite::toJSON(i18n, auto_unbox = TRUE), paste0(output_path, '/i18n.json'))
}
