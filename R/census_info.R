#' @rdname census_info
#'
#' @title Discover census datasets, cells, features, and observations
#'
#' @description `datasets()` queries CELLxGENE for datasets used in
#'     constructing the census.
#'
#' @param census a `tiledbsoma::SOMACollection` object as returned by
#'     `census()`. If `NULL`, then the default returned by `census()`.
#'
#' @details
#'
#' `datasets()`, `summary_cell_counts()`, and `feature_data()` are
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
    function(census = NULL)
{
    if (is.null(census))
        census <- census()
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
    function(census = NULL)
{
    if (is.null(census))
        census <- census()
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
    function(organism = c("homo_sapiens", "mus_musculus"), census = NULL)
{
    organism <- match.arg(organism)
    if (is.null(census))
        census <- census()
    census$get("census_data")$get(organism)$ms$get("RNA")$var$read()$concat() |>
        as.data.frame()
}

cell_data_obs <-
    function(organism = c("homo_sapiens", "mus_musculus"), census = NULL)
{
    organism <- match.arg(organism)
    if (is.null(census))
        census <- census()
    census$get("census_data")$get(organism)$get("obs")
}

cell_data <-
    function(organism = c("homo_sapiens", "mus_musculus"), census = NULL)
{
    obs <- cell_data_obs(organism, census)
}
