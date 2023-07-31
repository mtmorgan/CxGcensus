single_cell_experiment_constructor <-
    function()
{
    if (!requireNamespace("SingleCellExperiment", quietly = TRUE)) {
        stop(wrap(
            "install 'SingleCellExperiment' with ",
            "`BiocManager::install('SingleCellExperiment')`"
        ))
    }
    SingleCellExperiment::SingleCellExperiment
}

#' @rdname single_cell_experiment
#'
#' @title Construct a SingleCellExperiment from census data
#'
#' @description `single_cell_experiment()` queries the census for
#'     assay data corresponding to features and observations, and
#'     assembles the result into a SingleCellExperiment. The count
#'     data are accessible using `SingleCellExperiment::counts()`.
#'
#' @inheritParams assay_data
#'
#' @inheritParams census
#'
#' @details `single_cell_experiment()` requires that the
#'     SingleCellExperiment Bioconductor package is installed, e.g.,
#'     via `BiocManager::install("SingleCellExperiment")`.
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
#' single_cell_experiment("mus_musculus", features, observations)
#'
#' @export
single_cell_experiment <-
    function(
        organism, features, observations,
        version = "stable", uri = NULL, tiledbsoma_ctx = NULL
    )
{
    census <- census(version, uri, tiledbsoma_ctx)
    sce <- single_cell_experiment_constructor()
    assay <- assay_data(
        organism, features, observations,
        version, uri, tiledbsoma_ctx
    )

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
