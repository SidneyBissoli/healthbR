# Shared validation helpers for healthbR
# Provides consistent parameter validation across all modules

#' Validate year parameter against available years
#'
#' @param year Integer vector. Year(s) to validate.
#' @param available Integer vector. Available years.
#' @param years_fn_hint Character or NULL. Code hint for error message
#'   (e.g., "sim_years(status = 'all')").
#'
#' @return Validated integer vector of years.
#'
#' @noRd
.validate_year <- function(year, available, years_fn_hint = NULL) {
  if (is.null(year) || length(year) == 0) {
    cli::cli_abort("{.arg year} is required.")
  }

  year <- as.integer(year)
  invalid <- year[!year %in% available]

  if (length(invalid) > 0) {
    msg <- c(
      "Year(s) {.val {invalid}} not available.",
      "i" = "Available years: {.val {range(available)[[1]]}}--{.val {range(available)[[2]]}}"
    )
    if (!is.null(years_fn_hint)) {
      msg <- c(msg, "i" = "Use {.code {years_fn_hint}} to see all options.")
    }
    cli::cli_abort(msg)
  }

  year
}


#' Validate month parameter
#'
#' Returns 1:12 if month is NULL (default for monthly datasets).
#'
#' @param month Integer vector or NULL.
#'
#' @return Validated integer vector of months.
#'
#' @noRd
.validate_month <- function(month) {
  if (is.null(month)) {
    return(1L:12L)
  }

  month <- as.integer(month)
  invalid <- month[month < 1L | month > 12L | is.na(month)]

  if (length(invalid) > 0) {
    cli::cli_abort(c(
      "Invalid month(s): {.val {invalid}}.",
      "i" = "Month must be between 1 and 12."
    ))
  }

  month
}


#' Validate UF (state abbreviation) parameter
#'
#' @param uf Character vector. UF abbreviation(s) to validate.
#' @param valid_ufs Character vector. Valid UF abbreviations.
#'
#' @return Validated uppercase character vector of UFs.
#'
#' @noRd
.validate_uf <- function(uf, valid_ufs) {
  uf <- toupper(uf)
  invalid <- uf[!uf %in% valid_ufs]

  if (length(invalid) > 0) {
    cli::cli_abort(c(
      "Invalid UF abbreviation(s): {.val {invalid}}.",
      "i" = "Valid values: {.val {valid_ufs}}"
    ))
  }

  uf
}


#' Validate quarter parameter
#'
#' Returns 1:4 if quarter is NULL (default for quarterly datasets).
#'
#' @param quarter Integer vector or NULL.
#'
#' @return Validated integer vector of quarters.
#'
#' @noRd
.validate_quarter <- function(quarter) {
  if (is.null(quarter)) {
    return(1L:4L)
  }

  quarter <- as.integer(quarter)
  invalid <- quarter[quarter < 1L | quarter > 4L | is.na(quarter)]

  if (length(invalid) > 0) {
    cli::cli_abort(c(
      "Invalid quarter(s): {.val {invalid}}.",
      "i" = "Quarter must be between 1 and 4."
    ))
  }

  quarter
}
