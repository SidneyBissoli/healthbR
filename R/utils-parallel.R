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
#' @param .progress Controls progress bar display. `FALSE` (default) shows
#'   no progress bar. `TRUE` shows a progress bar with a generic label.
#'   A character string shows a progress bar with that string as the label
#'   (e.g. `"Downloading"`). Progress bars are only shown when
#'   `length(.x) > 1`. When using furrr, a simpler text-based progress
#'   indicator is shown instead.
#'
#' @return A list of results (same as `purrr::map()`).
#'
#' @noRd
.map_parallel <- function(.x, .f, ..., .delay = NULL, .progress = FALSE) {
  n <- length(.x)
  use_furrr <- requireNamespace("furrr", quietly = TRUE) &&
    requireNamespace("future", quietly = TRUE) &&
    !inherits(future::plan(), "sequential")

  show_progress <- !isFALSE(.progress) && n > 1L

  if (use_furrr) {
    return(furrr::future_map(.x, .f, ..., .progress = show_progress))
  }

  # sequential paths
  if (show_progress) {
    label <- if (is.character(.progress)) .progress else "Processing"
    pb_id <- cli::cli_progress_bar(
      total = n,
      format = paste0(
        "{cli::pb_spin} ", label,
        " [{cli::pb_current}/{cli::pb_total}] {cli::pb_bar} | ETA: {cli::pb_eta}"
      )
    )
  }

  use_delay <- !is.null(.delay) && .delay > 0 && n > 1L

  if (use_delay || show_progress) {
    purrr::imap(.x, function(elem, idx) {
      if (use_delay && idx > 1L) Sys.sleep(.delay)
      result <- .f(elem, ...)
      if (show_progress) cli::cli_progress_update(id = pb_id)
      result
    })
  } else {
    purrr::map(.x, .f, ...)
  }
}
