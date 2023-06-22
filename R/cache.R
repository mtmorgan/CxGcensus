#' @importFrom tools R_user_dir
cache_directory <-
    function()
{
    file.path(R_user_dir("CxGcensus", "cache"), "cachem")
}

#' @importFrom dplyr as_tibble select
#'
#' @export
cache_info <-
    function()
{
    files <- dir(cache_directory(), full.names = TRUE)
    info <- file.info(files)
    info |>
        as_tibble(rownames = "file") |>
        mutate(file =  basename(file)) |>
        select(file, size, mtime)
}

#' @importFrom cachem cache_disk
cache <-
    function()
{
    cache_disk(cache_directory())
}

memoise_disk <-
    function(f, ...)
{
    memoise(f, ..., cache = cache())
}
