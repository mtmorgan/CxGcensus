is_scalar_character <-
    function(x)
{
    is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)
}

wrap <-
    function(...)
{
    x <- paste0(...)
    paste(strwrap(x), collapse = "\n")
}
