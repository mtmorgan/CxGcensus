
#' @rdname census_info
#'
#' @title Discover metadata about CELLxGENE census
#'
#' @param census_version see `?cellxgene.census::open_soma`
#'
#' @param uri see `?cellxgene.census::open_soma`
#'
#' @param tiledbsoma_ctx see `?cellxgene.census::open_soma`
#'
#' @details
#'
#' `census()` is 'memoised', requiring high-latency internet access
#' only on its first use.
#'
#' @return
#'
#' `census()` returns a `tiledbsoma::SOMACollection` object. Details
#' of the `census_version` are available with
#' `census()$get_metadata()`
#'
#' @importFrom cellxgene.census open_soma
#'
#' @importFrom dplyr mutate across where
#'
#' @examples
#' census()
#' census()$get_metadata()
#'
#' @export
census <-
    function(census_version = "stable", uri = NULL, tiledbsoma_ctx = NULL)
{
    open_soma(
        census_version = census_version,
        uri = uri,
        tiledbsoma_ctx = tiledbsoma_ctx
    )
}

census_id <-
    function()
{
    sha <- census()$get_metadata()$git_commit_sha
    as.vector(sha) # remove attr(sha, 'key')
}

#' @rdname census_info
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
#' @return
#'
#' `datasets()` returns a tibble with information about the
#' collections and datasets represented in the census.
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
#' @return
#'
#' `summary_cell_counts()` returns a tibble summarizing the organism,
#' factors (`category`) and levels represented in the data, and unique
#' and total cell counts in each category.
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
#' @param organism one of 'homo_sapiens' or 'mus_musculus'. Default:
#'     'homo_sapiens'.
#'
#' @return
#'
#' `feature_data()` returns a tibble with columns describing each
#' feature (gene) in `organism`.
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
