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

## output (to stderr, via message(), a progress iterator when the
## total number of records is not known
##
## iterator_progress <- progress_iterator()
## while (...) {
##     iterator_progress$increment(n)
## }
## iterator_progress$done()
progress_iterator <-
    function(
        label_digits = 3L, progress_digits = 8L,
        output_width = getOption("width")
    )
{
    label_format <- paste0("[%", label_digits, "d]")
    label_width <- label_digits + 2L
    element_format <- paste0(" %", progress_digits, "d")
    element_width <- progress_digits + 1L

    current_width <- output_width
    iteration <- 0L
    n_total <- 0L
    interactive <- interactive() # only display in interactive sessions
    valid_iterator <- TRUE
    increment <- function(n) {
        if (!valid_iterator)
            stop("invalid iterator")
        if (!interactive)
            return()
        iteration <<-iteration + 1L
        n_total <<- n_total + n
        if (current_width + element_width > output_width) {
            if (iteration != 1L)
                message("") # new-line
            message(sprintf(label_format, iteration), appendLF = FALSE)
            current_width <<- label_width
        }
        message(sprintf(element_format, n_total), appendLF = FALSE)
        current_width <<- current_width + element_width
    }
    done <- function() {
        valid_iterator <<- FALSE
        if (interactive)
            message("") # trailing new line
    }
    list(increment = increment, done = done)
}
