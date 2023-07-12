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
#' @importFrom dplyr tibble as_tibble select arrange desc right_join
#'     bind_rows .data
#'
#' @export
cache_info <-
    function(id = census_id())
{
    cache <- cache(id)
    cache_directory <- cache_directory(id)

    ## cachem-managed files
    files <- dir(cache_directory, full.names = TRUE)
    info <-
        file.info(files) |>
        as_tibble(rownames = "path") |>
        mutate(
            file = basename(path),
            key = sub("\\..*$", "", file)
        )
    key <- tibble(key = cache$keys())
    cache_info <-
        right_join(info, key, by = "key")

    ## duckdb files
    duckdb_files <- dir(
        dirname(cache_directory), pattern = "\\.duckdb$", full.names = TRUE
    )
    duckdb_info <-
        file.info(duckdb_files) |>
        as_tibble(rownames = "path") |>
        mutate(file = basename(path))

    ## combine cachem- and duckdb files
    bind_rows(cache_info, duckdb_info) |>
        arrange(desc(.data$mtime)) |>
        select(.data$file, .data$size, .data$mtime, .data$path)
}

## for internal use, at the moment
#' @importFrom dplyr pull filter
cache_remove_duplicate_duckdb <-
    function(id = census_id())
{
    ## find duckdb files
    cache_directory <- cache_directory(id)
    duckdb_files <- dir(
        dirname(cache_directory), pattern = "\\.duckdb$", full.names = TRUE
    )

    ## duplicates have the same size; remove these
    duplicates <-
        file.info(duckdb_files) |>
        as_tibble(rownames = "file") |>
        arrange(desc(.data$mtime)) |>
        filter(duplicated(.data$size)) |>
        pull(file)
    unlink(duplicates, force = TRUE)

    ## find keys in cache
    duckdb_keys <-
        cache_info(id) |>
        ## file paths -- plain character vectors
        filter(.data$size < 500) |>
        mutate(key = sub("\\..*", "", file)) |>
        pull(key)
    cache <- cache(id)

    ## remove no-longer-valid keys
    for (key in duckdb_keys) {
        if (cache$exists(key) && !file.exists(cache$get(key)$value))
            cache$remove(key)
    }
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
