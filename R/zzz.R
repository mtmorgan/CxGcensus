#' @importFrom memoise memoise
.onLoad <-
    function(libname, pkgname)
{
    arrow_dataset <- arrow::arrow_info()[["capabilities"]][["dataset"]]
    if (!isTRUE(arrow_dataset)) {
        stop(wrap(
            "'", pkgname, "' requires the 'arrow' package to have been ",
            "installed with 'dataset' capabilities. Check arrow capabilities ",
            'with `arrow::arrow_info()[["capabilities"]][["dataset"]]`. ',
            "See the README file for a little more information"
        ), call. = FALSE)
    }

    ## per-session memoisation
    census <<- memoise(census)
    census_names <<- memoise(census_names)

    ## disk-based memoisation
    suppressMessages({
        ## "The stable Census release is currently ..."
        datasets <<- memoise_disk(datasets)
        summary_cell_counts <<- memoise_disk(summary_cell_counts)
        feature_data <<- memoise_disk(feature_data)
        observation_data_download <<- memoise_disk(observation_data_download)
        assay_data <<- memoise_disk(assay_data)
    })
}
