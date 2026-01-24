#' @importFrom rlang .data
#' @importFrom dplyr filter select bind_rows
#' @importFrom tibble tibble
#' @importFrom cli cli_abort cli_warn cli_inform cli_progress_bar cli_progress_update cli_progress_done
NULL

.onLoad <- function(libname, pkgname) {
  # Set default options if not already set
  op <- options()
  op_healthbR <- list(
    healthbR.cache = TRUE,
    healthbR.verbose = TRUE
  )
  toset <- !(names(op_healthbR) %in% names(op))
  if (any(toset)) options(op_healthbR[toset])

  invisible()
}

.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    "healthbR: Access Brazilian Public Health Data\n",
    "Use list_sources() to see available data sources."
  )
}
