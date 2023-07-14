#' @importFrom memoise memoise
.onLoad <-
    function(libname, pkgname)
{
    arrow_dataset <- arrow::arrow_info()[["capabilities"]][["dataset"]]
    if (!isTRUE(arrow_dataset)) {
        stop(wrap(
            "the 'arrow' package must be installed with 'dataset' ",
            "capabilities. Check arrow capabilities with ",
            '`arrow::arrow_info()[["capabilities"]][["dataset"]]`. ',
            "See the '", pkgname, "' README file for more information."
        ), call. = FALSE)
    }

    ## per-session memoisation
    census <<- memoise(census)
    census_names <<- memoise(census_names)
    census_versions <<- memoise(census_versions)

    ## disk-based memoisation
    suppressMessages({
        datasets <<- memoise_disk(datasets)
        summary_cell_counts <<- memoise_disk(summary_cell_counts)
        feature_data <<- memoise_disk(feature_data)
        observation_data_download <<- memoise_disk(observation_data_download)
        assay_data <<- memoise_disk(assay_data)
    })
}
