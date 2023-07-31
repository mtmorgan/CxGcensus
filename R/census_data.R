feature_data_download <-
    function(
        organism,
        version = "stable", uri = NULL, tiledbsoma_ctx = NULL
    )
{
    if (interactive())
        message("retrieving feature_data...")
    census <- census(version, uri, tiledbsoma_ctx)
    tbl <- census$get("census_data")$get(organism)$ms$get("RNA")$var$read()
    if (inherits(tbl, "ReadIter"))
        tbl <- tbl$concat()
    as.data.frame(tbl)
}

#' @rdname census_data
#'
#' @title Discover census features, observations, and assays (counts)
#'
#' @description `feature_data()` reports information about features
#'     (genes) present in the census.
#'
#' @param organism one of the values returned by `census_names()`,
#'     specifically 'homo_sapiens' or 'mus_musculus' at the time of
#'     writing this documentation.
#'
#' @inheritParams census
#'
#' @return `feature_data()` returns a tibble with columns describing
#'     each feature (gene) in `organism`.
#'
#' @examples
#' feature_data("mus_musculus")
#'
#' @export
feature_data <-
    function(
        organism,
        version = "stable", uri = NULL, tiledbsoma_ctx = NULL
    )
{
    stopifnot(
        is_census_version(version),
        organism %in% census_names(version, uri, tiledbsoma_ctx)
    )
    version <- census_version(version)
    feature_data_download(organism, version, uri, tiledbsoma_ctx)
}

#' @importFrom duckdb duckdb duckdb_register_arrow
#'     duckdb_unregister_arrow
#'
#' @importMethodsFrom duckdb dbConnect dbDisconnect
#'
#' @importMethodsFrom DBI dbGetQuery dbExecute
observation_data_download <-
    function(
        organism,
        version = "stable", uri = NULL, tiledbsoma_ctx = NULL
    )
{
    census <- census(version, uri, tiledbsoma_ctx)
    census_id <- census_id(version, uri, tiledbsoma_ctx)

    if (interactive()) {
        message(wrap(
            "retrieving ", organism, " cell data as a duckdb database; ",
            "there are 10's of millions of records and this can take ",
            "several minutes..."
        ))
    }

    ## set up duckdb
    duckdb_dir <- dirname(cache_directory(census_id))
    duckdb_file <- tempfile("", duckdb_dir, ".duckdb")
    con <- dbConnect(duckdb::duckdb(), duckdb_file)
    on.exit(dbDisconnect(con, shutdown = TRUE))
    table_name <- "obs"
    view_name <- paste0(table_name, "_view")
    sql_view_count <- paste0("SELECT COUNT(*) AS n FROM '", view_name, "'")

    ## establish reader
    iter <- census$get("census_data")$get(organism)$get("obs")$read()
    cmd <- paste0("CREATE TABLE '", table_name, "' as ")
    if (inherits(iter, "ReadIter")) {
        iter_progress <- progress_iterator()
        ## read in chunks and provide feedback
        while (!iter$read_complete()) {
            ## create a VIEW
            duckdb_register_arrow(con, view_name, iter$read_next())
            nrow <-
                dbGetQuery(con, sql_view_count)[["n"]] |>
                as.integer()
            ## CREATE or INSERT INTO table, unregister view
            sql <- paste0(cmd, "SELECT * FROM '", view_name, "'")
            dbExecute(con, sql)
            duckdb_unregister_arrow(con, view_name)
            ## update SQL command and iterate progress bar
            cmd <- paste0("INSERT INTO '", table_name, "' ")
            gc() # memory management
            iter_progress$increment(nrow)
        }
        iter_progress$done()
    } else {
        ## create a VIEW
        duckdb_register_arrow(con, view_name, iter$read_next())
        ## CREATE a table, unregister view
        sql <- paste0(cmd, "SELECT * FROM '", view_name, "'")
        dbExecute(con, sql)
        duckdb_unregister_arrow(con, view_name)
    }

    duckdb_file
}

#' @rdname census_data
#'
#' @description `observation_data()` reports information about all
#'     cells in the census.
#'
#' @details
#'
#' `observation_data()` is memoised to disk. The data is large (e.g.,
#' more than 50 million rows for *Homo sapiens*) so the initial
#' download can be time-consuming (10's of minutes). During download
#' in an interactive session, the number of 'chunks' and records are
#' displayed; for the 2023-05-15 census of `homo_sapiens`, there were
#' more than 52 million records (cells) downloaded in 124 chunks.
#'
#' The data are stored in a 'duckdb' database. The return value can be
#' used via `dbplyr` for very fast and memory efficient filtering,
#' selection, and summary.
#'
#' @return `observation_data()` returns a dbplyr-based tibble of cell
#'     annotations. An aesthetic problem is that the 'connection' to
#'     the database is not available to the user, and duckdb warns
#'     that `Database is garbage-collected...`; this message can be
#'     ignored.
#'
#' @examples
#' mus <- observation_data("mus_musculus")
#' mus
#'
#' mus |>
#'     count(assay, sort = TRUE)
#'
#' mus |>
#'     filter(grepl("diabetes", disease)) |>
#'     count(disease, sex, tissue)
#'
#' @importFrom dplyr tbl
#'
#' @export
observation_data <-
    function(organism, version = "stable", uri = NULL, tiledbsoma_ctx = NULL)
{
    stopifnot(
        is_census_version(version),
        organism %in% census_names(version, uri, tiledbsoma_ctx)
    )
    version <- census_version(version)
    duckdb_file <- observation_data_download(
        organism, version, uri, tiledbsoma_ctx
    )
    con <- dbConnect(
        ## soma_joinids are BIGINT
        duckdb::duckdb(duckdb_file, read_only = TRUE, bigint = "integer64")
    )
    tbl <- tbl(con, "obs")

    ## arrange for quiet clean up when 'tbl' or references are no
    ## longer referenced
    reg.finalizer(environment(), function(...) {
        DBI::dbDisconnect(con, shutdown = TRUE)
    }, onexit = TRUE)
    tbl$src$.cxgcensus_finalizer_environment <- environment()

    tbl
}

#' @rdname census_data
#'
#' @description `assay_data()` queries the census for 'raw' counts for
#'     the RNA-seq data corresponding to selected features and columns
#'     in a census.
#'
#' @param features a `tibble`, typically derived from
#'     `feature_data()` via `filter()`, `select()`, etc., and
#'     containing the `soma_joinid` column.
#'
#' @param observations a `tibble`, typically derived from
#'     `observation_data()` via `filter()`, `select()`, etc., and
#'     containing the `soma_joinid` column.
#'
#' @details Currently, for `assay_data()` and
#'     `single_cell_experiment()`, the user must ensure that the
#'     features, observations, and assay data are for the same census
#'     and organism. Duplicate rows in `features` and `observations`
#'     are allowed.
#'
#' @return `assay_data()` returns a sparse matrix (`dgCMatrix`)
#'     summarizing counts found in the census for the `soma_joinid`
#'     columns of the `features` and `observations` tibble
#'     arguments. The counts are from the 'raw' layer' of 'X'
#'     collection of the 'RNA' measurement in the experiment.
#'
#' @examples
#' ## use features and observations as filters for assay (count) data
#' features <-
#'    feature_data("mus_musculus") |>
#'    ## rows 4, 3, 4 of the tibble
#'    slice(c(4:3, 4))
#'
#' observations <-
#'    observation_data("mus_musculus") |>
#'    ## first two rows of the tibble
#'    head(2) |>
#'    collect()
#'
#' assay_data("mus_musculus", features, observations)
#'
#' @importFrom dplyr collect
#'
#' @importMethodsFrom Matrix t
#'
#' @importFrom tiledbsoma SOMAAxisQuery SOMAExperimentAxisQuery
#'
#' @export
assay_data <-
    function(
        organism, features, observations,
        version = "stable", uri = NULL, tiledbsoma_ctx = NULL
    )
{
    stopifnot(
        inherits(features, "tbl"),
        "soma_joinid" %in% names(features),
        !anyNA(features$soma_joinid),
        inherits(observations, "tbl"),
        "soma_joinid" %in% names(observations),
        !anyNA(observations$soma_joinid),
        organism %in% census_names(version, uri, tiledbsoma_ctx)
    )
    measurement <- "RNA"
    collection <- "X"
    layer <- "raw"

    census <- census(version, uri, tiledbsoma_ctx)
    experiment <- census$get("census_data")$get(organism)

    message("creating axis and experiment queries")
    ## ids must be unique, else they are returned twice and collated
    ## into a single row. ids are always returned in sorted order
    feature_ids <- sort(unique(pull(features, "soma_joinid")))
    feature_query <- SOMAAxisQuery$new(coords = feature_ids)

    observation_ids <- sort(unique(pull(observations, "soma_joinid")))
    observation_query <- SOMAAxisQuery$new(coords = observation_ids)

    experiment_query <- SOMAExperimentAxisQuery$new(
        experiment, measurement,
        obs_query = observation_query,
        var_query = feature_query
    )

    message(wrap(
        "retrieving assay_data measurement '", measurement, "' ",
        "collection '", collection, "' layer '", layer, "' ",
        "as a sparse matrix with ",
        length(feature_ids), " x ", length(observation_ids), " ",
        "distinct features x observations"
    ))
    assay <- withCallingHandlers({
        experiment_query$to_sparse_matrix(collection, layer)
    }, warning = function(w) {
        test <-
            startsWith(conditionMessage(w), "Iteration results cannot be") &&
            (nrow(features) * nrow(observations) < .Machine$integer.max)
        if (test) # suppress unnecessary warning
            invokeRestart("muffleWarning")
    })

    assay <-                          # feature x observation
        as(assay, "CsparseMatrix") |> # to dgCMatrix
        Matrix::t()

    ## return in requested order, with appropriate replication
    ridx <- match(features$soma_joinid, feature_ids)
    cidx <- match(observations$soma_joinid, observation_ids)
    assay[ridx, cidx]
}
