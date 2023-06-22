#' @importFrom memoise memoise
.onLoad <-
    function(libname, pkgname)
{
    ## memoisation
    census <<- memoise(census)

    datasets <<- memoise_disk(datasets)
    summary_cell_counts <<- memoise_disk(summary_cell_counts)
    feature_data <<- memoise_disk(feature_data)
}
