#' @rdname cache
#'
#' @title On-disk cache management
#'
#' @description `cache_directory()` reports the path to the on-disk
#'     cache for a particular census.
#'
#' @param id character(1) unique identifier associated with a
#'     particular census snapshot, as returned by `census_id()`.
#'
#' @details The on-disk cache is created and managed by the
#'     `cache_disk()` function in the cachem package. Consult that
#'     package for details about working with this object.
#'
#' @return `cache_directory()` returns a character(1) file path to the
#'     location of the cache associated with the census with `id`.
#'
#' @examples
#' cache_directory()
#'
#' @importFrom tools R_user_dir
#'
#' @export
cache_directory <-
    function(id = census_id())
{
    stopifnot(is_scalar_character(id))
    file.path(R_user_dir("CxGcensus", "cache"), id)
}

#' @rdname cache
#'
#' @description `cache_info()` summarizes file size and last
#'     modification time of files in the cache.
#'
#' @details File names in the cache are a hash of the function
#'     arguments and body of which they are a cache; it is not
#'     possible to know transparently which file corresponds to which
#'     memoized function.
#'
#' @return `cache_info()` returns a tibble with file name, size, and
#'     'mtime' (last-modified time). The mtime is used by
#'     `cache_disk()` to manage the size and age of objects in the
#'     cache. 
#'
#' @examples
#' cache_info()
#'
#' @importFrom dplyr as_tibble select .data
#'
#' @export
cache_info <-
    function(id = census_id())
{
    files <- dir(cache_directory(id), full.names = TRUE)
    info <- file.info(files)
    info |>
        as_tibble(rownames = "file") |>
        mutate(file =  basename(file)) |>
        select(.data$file, .data$size, .data$mtime)
}

#' @rdname cache
#'
#' @description `cache()` returns an object used to manage the cache.
#'
#' @return `cache()` returns an object created by
#'     `cachem::chach_disk()` that can be used to query and delete
#'     items in the cache.
#'
#' @examples
#' cache()
#'
#' @importFrom cachem cache_disk
#'
#' @export
cache <-
    function(id = census_id())
{
    cache_disk(cache_directory(id))
}

memoise_disk <-
    function(f, ...)
{
    memoise(f, ..., cache = cache())
}
