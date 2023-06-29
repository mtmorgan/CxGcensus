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
    tbl <- census$get("census_info")$get("summary_cell_counts")$read()
    if (inherits(tbl, "ReadIter"))
        tbl <- tbl$concat()
    as.data.frame(tbl)
}

#' @rdname census_info
#'
#' @description `feature_data()` reports information about features
#'     (genes) present in the census.
#'
#' @param organism one of the values returned by `census_names()`,
#'     specifically 'homo_sapiens' or 'mus_musculus' at the time of
#'     writing this documentation.
#'
#' @return `feature_data()` returns a tibble with columns describing
#'     each feature (gene) in `organism`.
#'
#' @examples
#' feature_data("mus_musculus")
#'
#' @export
feature_data <-
    function(organism, ...)
{
    stopifnot(organism %in% census_names(...))
    if (interactive())
        message("retrieving feature_data...")
    census <- census(...)
    tbl <- census$get("census_data")$get(organism)$ms$get("RNA")$var$read()
    if (inherits(tbl, "ReadIter"))
        tbl <- tbl$concat()
    as.data.frame(tbl)
}

#' @importFrom duckdb duckdb
#'
#' @importMethodsFrom duckdb dbConnect dbDisconnect dbWriteTable
observation_data_download <-
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
    duckdb_file <- tempfile(
        pattern = "", tmpdir = duckdb_dir, fileext = ".duckdb"
    )
    con <- dbConnect(duckdb::duckdb(), duckdb_file)
    on.exit(dbDisconnect(con))

    ## establish reader
    iter <- census$get("census_data")$get(organism)$get("obs")$read()
    if (inherits(iter, "ReadIter")) {
        iter_progress <- progress_iterator()
        ## read in chunks and provide feedback
        while (!iter$read_complete()) {
            tbl <- iter$read_next() |> as.data.frame()
            dbWriteTable(con, "obs", tbl, append = TRUE)
            iter_progress$increment(nrow(tbl))
        }
        iter_progress$done()
    } else {
        tbl <- iter |> as.data.frame()
        dbWriteTable(con, "obs", tbl, append = TRUE)
    }

    duckdb_file
}

#' @rdname census_info
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
#' mus |>
#'     count(assay, sort = TRUE)
#' mus |>
#'     filter(grepl("diabetes", disease)) |>
#'     count(disease, sex, tissue)
#'
#' @importFrom dplyr tbl
#'
#' @export
observation_data <-
    function(organism, ...)
{
    stopifnot(organism %in% census_names(...))
    duckdb_file <- observation_data_download(organism, ...)
    con <- dbConnect(duckdb::duckdb(), duckdb_file, read_only = TRUE)
    tbl(con, "obs")
}

#' @rdname census_info
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
#' counts <- assay_data(features, observations, organism = "mus_musculus")
#'
#' @importFrom dplyr collect
#'
#' @importMethodsFrom Matrix t
#'
#' @export
assay_data <-
    function(organism, features, observations, ...)
{
    stopifnot(
        inherits(features, "tbl"),
        "soma_joinid" %in% names(features),
        !anyNA(features$soma_joinid),
        inherits(observations, "tbl"),
        "soma_joinid" %in% names(observations),
        !anyNA(observations$soma_joinid),
        organism %in% census_names(...)
    )
    measurement <- "RNA"
    collection <- "X"
    layer <- "raw"

    census <- census(...)
    experiment <- census$get("census_data")$get(organism)

    message("creating axis and experiment queries")
    ## ids must be unique, else they are returned twice and collated
    ## into a single row. ids are always returned in sorted order
    feature_ids <- sort(unique(pull(features, "soma_joinid")))
    feature_query <- tiledbsoma::SOMAAxisQuery$new(coords = feature_ids)

    observation_ids <- sort(unique(pull(observations, "soma_joinid")))
    observation_query <- tiledbsoma::SOMAAxisQuery$new(coords = observation_ids)

    experiment_query <- tiledbsoma::SOMAExperimentAxisQuery$new(
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

#' @rdname census_info
#'
#' @description `single_cell_experiment()` queries the census for
#'     assay data corresponding to features and observations, and
#'     assembles the result into a SingleCellExperiment. The count
#'     data are accessible using `SingleCellExperiment::counts()`.
#'
#' @details `single_cell_experiment()` requires that the
#'     SingleCellExperiment Biocductor package is installed, e.g., via
#'     `BiocManager::install("SingleCellExperiment")`.
#'
#' @examples
#' single_cell_experiment("mus_musculus", features, observations)
#'
#' @export
single_cell_experiment <-
    function(organism, features, observations, ...)
{
    census <- census(...)
    sce <- single_cell_experiment_constructor()
    assay <- assay_data(organism, features, observations, ...)

    dimnames(assay) <- list(NULL, NULL)
    ## 'observations' may not yet have been realized...
    observations <-
        observations |>
        collect()
    census_metadata <- census$get_metadata()

    ## assemble the single-cell experiment
    sce(
        metadata = list(census_metadata = census_metadata),
        assays = list(counts = assay),
        colData = observations,
        rowData = features
    )
}
