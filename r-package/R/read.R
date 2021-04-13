#' @export
read_sql <- function(path, query, bind = NULL) {
  con <- RSQLite::dbConnect(RSQLite::SQLite(), path)
  res <- RSQLite::dbSendQuery(con, query)
  if (!is.null(bind)) RSQLite::dbBind(res, bind)
  metadata <- RSQLite::dbFetch(res)
  RSQLite::dbClearResult(res)
  RSQLite::dbDisconnect(con)
  metadata
}
