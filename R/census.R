#' @rdname census
#'
#' @title Obtain a reference to a CELLxGENE 'SOMA' collection
#'
#' @description `census()` queries CELLxGENE for a particulalr census.
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
#' @importFrom cellxgene.census get_census_version_description
#'     new_SOMATileDBContext_for_census
#'
#' @export
census <-
    function(census_version = "stable", uri = NULL, tiledbsoma_ctx = NULL)
{
    stopifnot(
        is_census_version(census_version),
        is.null(uri) || is_scalar_character(uri)
    )
    ## work around census() error, starting 15 Jul 2023
    ## Error: [TileDB::GroupDirectory] Error: Error while listing
    ##   with prefix
    ##   's3://cellxgene-data-public/cell-census/2023-05-15/soma/' and
    ##   delimiter '/' Exception:
    ## Error message: curlCode: 60, SSL peer certificate or SSH remote
    ##   key was not O
    if (is.null(tiledbsoma_ctx)) {
        description <- get_census_version_description(census_version)
        uri <- description$soma.uri
        tiledbsoma_ctx <- new_SOMATileDBContext_for_census(description)
        tiledbsoma_ctx$set("vfs.s3.verify_ssl", "false")
    }

    open_soma(
        census_version = census_version,
        uri = uri,
        tiledbsoma_ctx = tiledbsoma_ctx
    )
}

#' @rdname census
#'
#' @description `census_id()` reports a unique identifier for a
#'     particular census version.
#'
#' @param ... arguments passed to `census()`.
#'
#' @param census an object returned by `census()`; if present, this
#'     overrides specifications in `...`.
#'
#' @return `census_id()` returns the 7-character git commit sha that
#'     uniquely identifies the current release of the census.
#'
#' @examples
#' census_id()
#'
#' @export
census_id <-
    function(...)
{
    census <- census(...)
    sha <- census$get_metadata()$git_commit_sha
    as.vector(sha) # remove attr(sha, 'key')
}

#' @rdname census
#'
#' @description `census_names()` queries the census for available
#'     'experiments'. In CELLxGENE, experiments correspond to
#'     organisms, e.g., `"homo_sapiens"` or `"mus_musculus"`.
#'
#' @return `census_names()` returns a character vector of possible
#'     values. Use these values in calls to, e.g., `feature_data()` or
#'     `observation_data()`.
#'
#' @examples
#' census_names()
#'
#' @export
census_names <-
    function(...)
{
    census <- census(...)
    census$get("census_data")$names()
}

census_versions <-
    function()
{
    uri <- cellxgene.census:::CELL_CENSUS_RELEASE_DIRECTORY_URL
    response <- httr::GET(uri)
    httr::stop_for_status(response)
    content <- httr::content(response, as = "text", encoding = "UTF-8")

    labels <-
        jmespathr(content, "[stable, latest]") |>
        as.Date(format = "%Y-%m-%d")
    dates <-
        jmespathr(content, "keys(@)") |>
        as.Date(format = "%Y-%m-%d")
    status <- c("stable", "latest")[match(dates, labels)]

    tibble(
        version = dates[!is.na(dates)],
        status = status[!is.na(dates)]
    )
}

#' @rdname census
#'
#' @name show_package_versions
#'
#' @examples
#' tiledbsoma::show_package_versions()
NULL
