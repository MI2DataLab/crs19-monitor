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


#' @export
read_map <- function(path, simplify_factor = 0.15) {
  # simplify_factor 0.1 oversimplifies and returns an error
  map_cord <- sf::st_read(path, quiet = TRUE)
  map_cord <- tmaptools::simplify_shape(map_cord, fact = simplify_factor)
  map_cord <- sf::st_transform(map_cord, 2180) # long and lat is no longer used
  map_cord_df <- as.data.frame(sf::st_coordinates(map_cord)) %>% rename(id = L3)
  centroid_cord <- as.data.frame(sf::st_coordinates(sf::st_centroid(map_cord)))

  map_metadata <- data.frame(
    id   = as.data.frame(map_cord)$JPT_KOD_JE,
    name = as.data.frame(map_cord)$JPT_NAZWA_,
    X = centroid_cord$X,
    Y = centroid_cord$Y
  )

  list(map_cord = map_cord_df, map_metadata = map_metadata)
}
