# Shared parallel processing utilities for healthbR
# Provides a unified interface that uses furrr when available and configured,
# falling back to sequential purrr::map() otherwise

# ============================================================================
# parallel map wrapper
# ============================================================================

#' Map a function over elements, optionally in parallel
#'
#' Uses `furrr::future_map()` when the furrr package is available and a
#' non-sequential `future::plan()` has been set by the user. Otherwise
#' falls back to `purrr::map()`.
#'
#' @param .x A list or vector to iterate over.
#' @param .f A function to apply to each element.
#' @param ... Additional arguments passed to `.f`.
#' @param .delay Optional delay in seconds between sequential iterations.
#'   Used for polite rate limiting (e.g. FTP servers). Ignored when running
#'   in parallel via furrr. Default `NULL` (no delay).
#'
#' @return A list of results (same as `purrr::map()`).
#'
#' @noRd
.map_parallel <- function(.x, .f, ..., .delay = NULL) {
  use_furrr <- requireNamespace("furrr", quietly = TRUE) &&
    requireNamespace("future", quietly = TRUE) &&
    !inherits(future::plan(), "sequential")

  if (use_furrr) {
    furrr::future_map(.x, .f, ...)
  } else if (!is.null(.delay) && .delay > 0 && length(.x) > 1) {
    purrr::imap(.x, function(elem, idx) {
      if (idx > 1L) Sys.sleep(.delay)
      .f(elem, ...)
    })
  } else {
    purrr::map(.x, .f, ...)
  }
}
