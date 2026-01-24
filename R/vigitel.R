#' VIGITEL Data Functions
#'
#' Functions to access data from VIGITEL (Vigilância de Fatores de Risco e
#' Proteção para Doenças Crônicas por Inquérito Telefônico).
#'
#' @name vigitel
NULL

# Internal data: available years
.vigitel_available_years <- function() {

  2006:2023
}

#' List Available VIGITEL Years
#'
#' Returns a vector of years for which VIGITEL data is available.
#'
#' @return An integer vector of available years.
#'
#' @export
#'
#' @examples
#' vigitel_years()
vigitel_years <- function() {
 .vigitel_available_years()
}

#' List VIGITEL Variables
#'
#' Returns a tibble with available variables for a given year or all years.
#'
#' @param year Integer. The year to list variables for. If NULL (default),
#'   returns variables available across all years.
#'
#' @return A tibble with columns:
#'   \itemize{
#'     \item \code{variable}: Variable code
#'     \item \code{label}: Variable label in Portuguese
#'     \item \code{label_en}: Variable label in English
#'     \item \code{type}: Variable type (numeric, categorical, etc.)
#'     \item \code{year_start}: First year variable appears
#'     \item \code{year_end}: Last year variable appears
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # List all variables
#' vigitel_variables()
#'
#' # List variables for a specific year
#' vigitel_variables(year = 2023)
#' }
vigitel_variables <- function(year = NULL) {

  # Validate year if provided

if (!is.null(year)) {
    .validate_vigitel_year(year)
  }

  # Get variables metadata
  vars <- .get_vigitel_variables_metadata()

  # Filter by year if specified
  if (!is.null(year)) {
    vars <- vars |>
      dplyr::filter(
        .data$year_start <= year,
        .data$year_end >= year
      )
  }

  vars
}

#' Get VIGITEL Dictionary
#'
#' Returns the data dictionary for VIGITEL variables.
#'
#' @param year Integer. If NULL (default), lists all available dictionaries.
#'   If specified, returns the dictionary for that year.
#' @param variable Character. Optional. If specified along with year, returns
#'   the dictionary entry for that specific variable.
#'
#' @return A tibble. Content depends on arguments:
#'   \itemize{
#'     \item No arguments: list of available dictionaries by year
#'     \item Year only: complete dictionary for that year
#'     \item Year and variable: dictionary entry for that variable
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # List available dictionaries
#' vigitel_dictionary()
#'
#' # Get dictionary for 2023
#' vigitel_dictionary(year = 2023)
#'
#' # Get specific variable
#' vigitel_dictionary(year = 2023, variable = "q006")
#' }
vigitel_dictionary <- function(year = NULL, variable = NULL) {

  # If no year, list available dictionaries
  if (is.null(year)) {
    return(.list_vigitel_dictionaries())
  }

  # Validate year
  .validate_vigitel_year(year)

  # Get dictionary for year
  dict <- .get_vigitel_dictionary(year)

  # Filter by variable if specified
  if (!is.null(variable)) {
    dict <- dict |>
      dplyr::filter(.data$variable == !!variable)

    if (nrow(dict) == 0) {
      cli::cli_abort(
        "Variable {.val {variable}} not found in VIGITEL {year}."
      )
    }
  }

  dict
}

#' Download VIGITEL Data
#'
#' Downloads and returns VIGITEL microdata for specified years and variables.
#'
#' @param years Integer vector. Years to download. Required.
#' @param variables Character vector. Optional. Specific variables to select.
#'   If NULL (default), returns all variables.
#' @param cache Logical. If TRUE (default
#' ), caches downloaded data locally.
#'
#' @return A tibble in tidy format with VIGITEL microdata.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Download data for one year
#' vigitel_data(years = 2023)
#'
#' # Download multiple years
#' vigitel_data(years = 2020:2023)
#'
#' # Download specific variables
#' vigitel_data(years = 2023, variables = c("q006", "q007", "sexo", "idade"))
#' }
vigitel_data <- function(years, variables = NULL, cache = TRUE) {

  # Validate years
  for (y in years) {
    .validate_vigitel_year(y)
  }

  # Download data for each year
  cli::cli_progress_bar(
    "Downloading VIGITEL data",
    total = length(years)
  )

  data_list <- lapply(years, function(y) {
    cli::cli_progress_update()
    .download_vigitel_year(y, cache = cache)
  })

  cli::cli_progress_done()

  # Bind all years
  data <- dplyr::bind_rows(data_list)

  # Select variables if specified
  if (!is.null(variables)) {
    # Always include year and id
    variables <- unique(c("year", "id", variables))

    # Check if all variables exist
    missing <- setdiff(variables, names(data))
    if (length(missing) > 0) {
      cli::cli_warn(
        "Variables not found in data: {.val {missing}}"
      )
    }

    # Select existing variables only
    variables <- intersect(variables, names(data))
    data <- data |> dplyr::select(dplyr::all_of(variables))
  }

  data
}


# -----------------------------------------------------------------------------
# Internal helper functions
# -----------------------------------------------------------------------------

#' Validate VIGITEL year
#' @noRd
.validate_vigitel_year <- function(year) {
  available <- .vigitel_available_years()

  if (!year %in% available) {
    cli::cli_abort(c(
      "Year {.val {year}} is not available.",
      "i" = "Available years: {.val {min(available)}} to {.val {max(available)}}"
    ))
  }

  invisible(TRUE)
}

#' Get VIGITEL variables metadata
#' @noRd
.get_vigitel_variables_metadata <- function() {
  # TODO: Load from internal data or fetch from source
  # For now, return placeholder structure

  tibble::tibble(
    variable = character(),
    label = character(),
    label_en = character(),
    type = character(),
    year_start = integer(),
    year_end = integer()
  )
}

#' List available VIGITEL dictionaries
#' @noRd
.list_vigitel_dictionaries <- function() {
  years <- .vigitel_available_years()

  tibble::tibble(
    year = years,
    n_variables = NA_integer_,
    available = TRUE
  )
}

#' Get VIGITEL dictionary for a specific year
#' @noRd
.get_vigitel_dictionary <- function(year) {
  # TODO: Load dictionary data for specific year
  # For now, return placeholder structure

  tibble::tibble(
    variable = character(),
    label = character(),
    description = character(),
    type = character(),
    values = list(),
    notes = character()
  )
}

#' Download VIGITEL data for a specific year
#' @noRd
.download_vigitel_year <- function(year, cache = TRUE) {
  # TODO: Implement actual download logic
  # 1. Check cache if enabled
  # 2. Download from source
  # 3. Clean and standardize column names
  # 4. Return tibble

  cli::cli_inform("Downloading VIGITEL {year}...")

  # Placeholder: return empty tibble with expected structure
  tibble::tibble(
    year = integer(),
    id = character()
  )
}
