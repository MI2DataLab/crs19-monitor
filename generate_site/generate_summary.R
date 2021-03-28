base_path <- "/crs19/dev/site_dist/"
date <- "2021-03-28"

path <- paste0(base_path, date)
cnts <- list.dirs(path, recursive = FALSE, full.names = FALSE)

chunks <- list()
for(cnt in cnts) {
  chunks[[cnt]] <- paste0('          <div class="row">
            <div class="col-lg-4 col-md-4 col-sm-4">
              <p><a href="',cnt,'/">',sapply(strsplit(cnt, split="_"), function(x) paste0(toupper(substr(x, 1, 1)), substr(x, 2, 100), collapse = " ")),'</a></p>
            </div>
            <div class="col-lg-4 col-md-4 col-sm-4">
              <img align="right" src="', cnt, '/images/en/udzial_warianty_3.svg" width="100%" onerror="this.parentElement.parentElement.style.display=\'none\'" :key="editTime" >
            </div>
            <div class="col-lg-4 col-md-4 col-sm-4">
              <img align="right" src="', cnt, '/images/en/udzial_warianty_2.svg" width="100%" onerror="this.parentElement.parentElement.style.display=\'none\'" :key="editTime" >
            </div>
          </div><!-- /.row -->
          <hr>
')
}

chunk <- paste(chunks, collapse = "\n")

index <- readLines("index_summary.html")
index <- paste(index, collapse = "\n")

index <- gsub('--HERE PUT THE LIST--', chunk, index)

writeLines(index, con = "index.html")

