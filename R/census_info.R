datasets_download <-
    function(version = "stable", uri = NULL, tiledbsoma_ctx = NULL)
{
    if (interactive())
        message("retrieving datasets...")
    census <- census(version, uri, tiledbsoma_ctx)
    tbl <- census$get("census_info")$get("datasets")$read()
    if (inherits(tbl, "ReadIter"))
        tbl <- tbl$concat()
    tbl <- as.data.frame(tbl)

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
#' @title Discover census datasets and cell count summaries
#'
#' @description `datasets()` queries CELLxGENE for datasets used in
#'     constructing the census.
#'
#' @inheritParams census
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
    function(version = "stable", uri = NULL, tiledbsoma_ctx = NULL)
{
    stopifnot(is_census_version(version))
    version <- census_version(version)
    datasets_download(version, uri, tiledbsoma_ctx)
}

summary_cell_counts_download <-
    function(version = stable, uri = NULL, tiledbsoma_ctx = NULL)
{
    if (interactive())
        message("retrieving summary_cell_counts...")
    census <- census(version, uri, tiledbsoma_ctx)
    tbl <- census$get("census_info")$get("summary_cell_counts")$read()
    if (inherits(tbl, "ReadIter"))
        tbl <- tbl$concat()
    as.data.frame(tbl)
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
    function(version = "stable", uri = NULL, tiledbsoma_ctx = NULL)
{
    stopifnot(is_census_version(version))
    version <- census_version(version)
    summary_cell_counts_download(version, uri, tiledbsoma_ctx)
}
