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
#'
#' @return A list of results (same as `purrr::map()`).
#'
#' @noRd
.map_parallel <- function(.x, .f, ...) {
  use_furrr <- requireNamespace("furrr", quietly = TRUE) &&
    requireNamespace("future", quietly = TRUE) &&
    !inherits(future::plan(), "sequential")

  if (use_furrr) {
    furrr::future_map(.x, .f, ...)
  } else {
    purrr::map(.x, .f, ...)
  }
}
