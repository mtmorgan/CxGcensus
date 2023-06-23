#' @importFrom memoise memoise
.onLoad <-
    function(libname, pkgname)
{
    ## per-session memoisation
    census <<- memoise(census)

    ## disk-based memoisation
    suppressMessages({
        ## "The stable Census release is currently ..."
        datasets <<- memoise_disk(datasets)
        summary_cell_counts <<- memoise_disk(summary_cell_counts)
        feature_data <<- memoise_disk(feature_data)
        cell_data_download <<- memoise_disk(cell_data_download)
    })
}
