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
    census <<- memoise_memory(census, omit_args = NULL)
    census_names <<- memoise_memory(census_names)
    census_versions <<- memoise(census_versions)

    ## disk-based memoisation
    suppressMessages({
        datasets_download <<- memoise_disk(datasets_download)
        summary_cell_counts_download <<-
            memoise_disk(summary_cell_counts_download)
        feature_data_download <<- memoise_disk(feature_data_download)
        observation_data_download <<- memoise_disk(observation_data_download)
        assay_data <<- memoise_disk(assay_data)
    })
}
