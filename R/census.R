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

#' @rdname census
#'
#' @description `census_id()` reports a unique identifier for a
#'     particular census version.
#'
#' @param ... arguments passed to `census()`.
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
    sha <- census()$get_metadata()$git_commit_sha
    as.vector(sha) # remove attr(sha, 'key')
}
