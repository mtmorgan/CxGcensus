#' @rdname census
#'
#' @title Obtain a reference to a CELLxGENE 'SOMA' collection
#'
#' @description `census()` queries CELLxGENE for a particular census.
#'
#' @param version The version (date) of the census to use. `version =
#'     "stable"` indicates the most recent stable release; `version =
#'     "latest"` is the most recent release. Additional dates are
#'     available with `census_versions()`.
#'
#' @param uri The uri corresponding to census `version`; this is
#'     usually discovered automatically.
#'
#' @param tiledbsoma_ctx A 'context' providing mostly low-level flags
#'     influencing the performance of tiledbsoma. One illustration of
#'     this functionality is in the body of the `census()` function.
#'
#' @details
#'
#' `census()` is 'memoised', requiring high-latency internet access
#' only on its first use.
#'
#' @return
#'
#' `census()` returns a `tiledbsoma::SOMACollection` object. Details
#' of the census are available with `census()$get_metadata()`
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
    function(version = "stable", uri = NULL, tiledbsoma_ctx = NULL)
{
    stopifnot(
        is_census_version(version),
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
        description <- get_census_version_description(version)
        uri <- description$soma.uri
        tiledbsoma_ctx <- new_SOMATileDBContext_for_census(description)
        tiledbsoma_ctx$set("vfs.s3.verify_ssl", "false")
    }

    open_soma(
        census_version = version,
        uri = uri,
        tiledbsoma_ctx = tiledbsoma_ctx
    )
}

#' @rdname census
#'
#' @description `census_id()` reports a unique identifier for a
#'     particular census version.
#'
#' @return `census_id()` returns the 7-character git commit sha that
#'     uniquely identifies the current release of the census.
#'
#' @examples
#' census_id()
#'
#' @export
census_id <-
    function(version = "stable", uri = NULL, tiledbsoma_ctx = NULL)
{
    census <- census(version, uri, tiledbsoma_ctx)
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
    function(version = "stable", uri = NULL, tiledbsoma_ctx = NULL)
{
    census <- census(version, uri, tiledbsoma_ctx)
    census$get("census_data")$names()
}

#' @rdname census
#'
#' @description `census_versions()` queries the CELLxGENE server for
#'     available versions. Versions are denoted by release date.
#'
#' @return `census_versions()` returns a tibble with a column of
#'     available versions (release dates), and a 'status' column
#'     indicating the 'stable' and 'latest' versions.
#'
#' @examples
#' census_versions()
#'
#' @export
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
