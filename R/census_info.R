#' @rdname census_info
#'
#' @title Discover census datasets, cells, features, and observations
#'
#' @description `datasets()` queries CELLxGENE for datasets used in
#'     constructing the census.
#'
#' @param ... arguments passed to [census()], specifying the census
#'     release to be used. When missing, the default (current stable)
#'     census is used.
#'
#' @details
#'
#' `datasets()`, `summary_cell_counts()`, an `feature_data()` are
#' 'memoised' so that they are only expensive on their first use. The
#' 'tibble' returned by these functions is memoised to disk, so that
#' re-using the function is fast even across sessions. See
#' `?cache_info()` for details on cache management.
#'
#' @return `datasets()` returns a tibble with information about the
#'     collections and datasets represented in the census.
#'
#' @examples
#' datasets() |>
#'     glimpse()
#'
#' @export
datasets <-
    function(...)
{
    if (interactive())
        message("retrieving datasets...")
    census <- census(...)
    datasets <- census$get("census_info")$get("datasets")
    tbl <- datasets$read()$concat() |>
        as.data.frame()

    ## clean up "" to NA
    replace_zchar <- function(x) {
        x[!nzchar(x)] <- NA_character_
        x
    }
    tbl |>
        mutate(across(where(is.character), replace_zchar))
}

#' @rdname census_info
#'
#' @description `summary_cell_counts()` reports the facets (e.g., sex)
#'     and levels (e.g., male, female) in the census, and the number
#'     of cells associated with each facet and level.
#'
#' @return `summary_cell_counts()` returns a tibble summarizing the
#'     organism, facets (`category`, e.g., 'sex') and levels (`label`,
#'     e.g., 'female') represented in the data, and unique and total
#'     cell counts in each facet and level.
#'
#' @examples
#' summary_cell_counts() |>
#'     count(category)
#'
#' ## number of cells from female, male, and 'unknown' samples in
#' ## humans and mice
#' summary_cell_counts() |>
#'     filter(category == "sex") |>
#'     select(
#'         organism, label,
#'         unique_cell_count, total_cell_count
#'     )
#'
#' @export
summary_cell_counts <-
    function(...)
{
    if (interactive())
        message("retrieving summary_cell_counts...")
    census <- census(...)
    census$get("census_info")$get("summary_cell_counts")$read()$concat() |>
        as.data.frame()
}

#' @rdname census_info
#'
#' @description `feature_data()` reports information about features
#'     (genes) present in the census.
#'
#' @param organism one of 'homo_sapiens' or 'mus_musculus'. Default:
#'     'homo_sapiens'.
#'
#' @return `feature_data()` returns a tibble with columns describing
#'     each feature (gene) in `organism`.
#'
#' @examples
#' feature_data()  # default: homo_sapiens
#' feature_data("mus_musculus")
#'
#' @export
feature_data <-
    function(organism = c("homo_sapiens", "mus_musculus"), ...)
{
    if (interactive())
        message("retrieving feature_data...")
    organism <- match.arg(organism)
    census <- census(...)
    census$get("census_data")$get(organism)$ms$get("RNA")$var$read()$concat() |>
        as.data.frame()
}

#' @importFrom duckdb duckdb
#'
#' @importMethodsFrom duckdb dbConnect dbDisconnect dbWriteTable
cell_data_download <-
    function(organism, ...)
{
    census <- census(...)
    census_id <- census_id(...)

    if (interactive()) {
        message(wrap(
            "retrieving ", organism, " cell data as a duckdb database; ",
            "there are 10's of millions of records and this can take ",
            "several minutes..."
        ))
    }

    ## set up duckdb
    duckdb_dir <- dirname(cache_directory(census_id))
    duckdb_file <- tempfile(tmpdir = duckdb_dir, fileext = ".duckdb")
    con <- dbConnect(duckdb::duckdb(), duckdb_file)
    on.exit(dbDisconnect(con))

    ## establish reader
    obs <- census$get("census_data")$get(organism)$get("obs")
    iter <- obs$read(iterated = TRUE)
    iter_progress <- progress_iterator()

    ## read in chunks and provide feedback
    while (!iter$read_complete()) {
        tbl <- iter$read_next() |> as.data.frame()
        dbWriteTable(con, "obs", tbl, append = TRUE)
        iter_progress$increment(nrow(tbl))
    }
    iter_progress$done()

    duckdb_file
}

#' @rdname census_info
#'
#' @description `cell_data()` reports information about all cells in
#'     the census.
#'
#' @details
#'
#' `cell_data()` is memoised to disk. The data is large (e.g., more
#' than 50 million rows for *Homo sapiens*) so the initial download
#' can be time-consuming (10's of minutes). During download in an
#' interactive session, the number of 'chunks' and records are
#' displayed; for the 2023-05-15 census of `homo_sapiens`, there were
#' more than 52 million records (cells) downloaded in 124 chunks.
#'
#' The data are stored in a 'duckdb' database. The return value can be
#' used via `dbplyr` for very fast and memory efficient filtering,
#' selection, and summary.
#'
#' @return `cell_data()` returns a dbplyr-based tibble of cell
#'     annotations. An aesthetic problem is that the 'connection' to
#'     the database is not available to the user, and duckdb warns
#'     that `Database is garbage-collected...`; this message can be
#'     ignored.
#'
#' @examples \dontrun{
#' mus <- cell_data("mus_musculus")
#' mus |>
#'     count(assay, sort = TRUE)
#' mus |>
#'     filter(grepl("diabetes", disease)) |>
#'     count(disease, sex, tissue)
#' }
#'
#' @importFrom dplyr tbl
#' 
#' @export
cell_data <-
    function(organism = c("homo_sapiens", "mus_musculus"), ...)
{
    organism <- match.arg(organism)
    duckdb_file <- cell_data_download(organism, ...)
    con <- dbConnect(duckdb::duckdb(), duckdb_file, read_only = TRUE)
    tbl(con, "obs")
}
