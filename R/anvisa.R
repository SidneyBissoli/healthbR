# ANVISA functions for healthbR package
# Functions to access health surveillance data from ANVISA (Agencia Nacional
# de Vigilancia Sanitaria) open data portal

# ============================================================================
# Internal validation functions
# ============================================================================

#' Validate ANVISA type parameter
#' @noRd
.anvisa_validate_type <- function(type) {
  type <- tolower(type)
  valid <- anvisa_valid_types$code

  if (!type %in% valid) {
    cli::cli_abort(c(
      "Invalid ANVISA type: {.val {type}}.",
      "i" = "Valid types: {.val {valid}}",
      "i" = "Use {.code anvisa_types()} to see type descriptions."
    ))
  }

  type
}

#' Validate ANVISA SNGPC year parameter
#' @noRd
.anvisa_validate_sngpc_year <- function(year) {
  .validate_year(year, anvisa_sngpc_years,
                 years_fn_hint = "SNGPC data: 2014-2026")
}

#' Validate ANVISA SNGPC month parameter
#' @noRd
.anvisa_validate_sngpc_month <- function(month) {
  .validate_month(month)
}

#' Validate ANVISA vars parameter (warning only)
#' @noRd
.anvisa_validate_vars <- function(vars, type) {
  meta <- .anvisa_get_metadata(type)
  known_vars <- meta$variable
  invalid <- vars[!vars %in% known_vars]

  if (length(invalid) > 0) {
    cli::cli_warn(c(
      "Variable(s) {.val {invalid}} not in known ANVISA {type} variables.",
      "i" = "Use {.code anvisa_variables(type = '{type}')} to see available variables.",
      "i" = "Proceeding anyway (variables will be dropped if not found)."
    ))
  }
}


# ============================================================================
# Internal URL builders
# ============================================================================

#' Build URL for ANVISA snapshot CSV
#' @noRd
.anvisa_snapshot_url <- function(type) {
  paste0(anvisa_base_url, "/", anvisa_type_files[[type]])
}

#' Build URL for ANVISA SNGPC monthly CSV
#' @noRd
.anvisa_sngpc_url <- function(type, year, month) {
  subdir <- anvisa_sngpc_subdirs[[type]]
  prefix <- anvisa_sngpc_prefixes[[type]]
  yyyymm <- sprintf("%d%02d", year, month)
  paste0(anvisa_base_url, "/SNGPC/", subdir, "/", prefix, yyyymm, ".csv")
}


# ============================================================================
# Internal helper functions
# ============================================================================

#' Get/create ANVISA cache directory
#' @noRd
.anvisa_cache_dir <- function(cache_dir = NULL) {
  .module_cache_dir("anvisa", cache_dir)
}


#' Download and read an ANVISA snapshot CSV
#' @noRd
.anvisa_download_snapshot <- function(type, cache = TRUE, cache_dir = NULL) {
  cache_dir <- .anvisa_cache_dir(cache_dir)
  cache_base <- paste0("anvisa_", type)

  # check flat cache
  if (isTRUE(cache)) {
    cached <- .cache_read(cache_dir, cache_base)
    if (!is.null(cached)) return(cached)
  }

  url <- .anvisa_snapshot_url(type)
  temp_csv <- tempfile(fileext = ".csv")
  on.exit(if (file.exists(temp_csv)) file.remove(temp_csv), add = TRUE)

  type_name <- anvisa_valid_types$name[anvisa_valid_types$code == type]
  cli::cli_inform(c(
    "i" = "Downloading ANVISA {type_name}..."
  ))

  .http_download(url, temp_csv, ssl_verifypeer = FALSE)

  delim <- anvisa_csv_delim[[type]]
  data <- readr::read_delim(
    temp_csv, delim = delim, show_col_types = FALSE,
    locale = readr::locale(encoding = "latin1"),
    col_types = readr::cols(.default = "c")
  )

  # write to flat cache
  if (isTRUE(cache)) {
    .cache_write(data, cache_dir, cache_base)
  }

  data
}


#' Download and read an ANVISA SNGPC CSV for one year/month
#' @noRd
.anvisa_download_sngpc <- function(type, year, month,
                                   cache = TRUE, cache_dir = NULL) {
  cache_dir <- .anvisa_cache_dir(cache_dir)
  dataset_name <- if (type == "sngpc") {
    "anvisa_sngpc_data"
  } else {
    "anvisa_sngpc_compounded_data"
  }
  target_year <- as.integer(year)
  target_month <- as.integer(month)

  # 1. check partitioned cache
  if (isTRUE(cache) && .has_arrow() &&
      .has_partitioned_cache(cache_dir, dataset_name)) {
    ds <- arrow::open_dataset(file.path(cache_dir, dataset_name))
    cached <- ds |>
      dplyr::filter(.data$year == target_year,
                     .data$month == target_month) |>
      dplyr::collect()
    if (nrow(cached) > 0) return(cached)
  }

  # 2. download CSV
  url <- .anvisa_sngpc_url(type, year, month)
  temp_csv <- tempfile(fileext = ".csv")
  on.exit(if (file.exists(temp_csv)) file.remove(temp_csv), add = TRUE)

  type_name <- if (type == "sngpc") "Industrializados" else "Manipulados"
  cli::cli_inform(c(
    "i" = "Downloading ANVISA SNGPC {type_name}: {year}/{sprintf('%02d', month)}..."
  ))

  .http_download(url, temp_csv, ssl_verifypeer = FALSE)

  delim <- anvisa_csv_delim[[type]]
  data <- readr::read_delim(
    temp_csv, delim = delim, show_col_types = FALSE,
    locale = readr::locale(encoding = "latin1"),
    col_types = readr::cols(.default = "c")
  )

  # add partition columns
  data$year <- target_year
  data$month <- target_month
  cols <- names(data)
  data <- data[, c("year", "month",
                    setdiff(cols, c("year", "month")))]

  # 3. write to partitioned cache
  if (isTRUE(cache)) {
    .cache_append_partitioned(data, cache_dir, dataset_name,
                              c("year", "month"))
  }

  data
}


# ============================================================================
# Routing dispatch functions
# ============================================================================

#' Dispatch snapshot data download
#' @noRd
.anvisa_data_snapshot <- function(type, vars, cache, cache_dir) {
  if (!is.null(vars)) .anvisa_validate_vars(vars, type)

  data <- .anvisa_download_snapshot(type, cache = cache, cache_dir = cache_dir)

  # column selection
  if (!is.null(vars)) {
    keep_cols <- intersect(vars, names(data))
    if (length(keep_cols) == 0) {
      cli::cli_warn("None of the requested variables found in the data.")
    } else {
      data <- data[, keep_cols, drop = FALSE]
    }
  }

  tibble::as_tibble(data)
}


#' Dispatch SNGPC data download
#' @noRd
.anvisa_data_sngpc <- function(type, year, month, vars,
                               cache, cache_dir,
                               lazy, backend) {
  year <- .anvisa_validate_sngpc_year(year)
  month <- .anvisa_validate_sngpc_month(month)
  if (!is.null(vars)) .anvisa_validate_vars(vars, type)

  cache_dir_resolved <- .anvisa_cache_dir(cache_dir)
  dataset_name <- if (type == "sngpc") {
    "anvisa_sngpc_data"
  } else {
    "anvisa_sngpc_compounded_data"
  }
  lazy_filters <- list(year = year, month = as.integer(month))
  lazy_select <- if (!is.null(vars)) {
    unique(c("year", "month", vars))
  } else {
    NULL
  }

  # pre-download lazy check
  ds <- .try_lazy_cache(lazy, backend, cache_dir_resolved,
                        dataset_name, lazy_filters, lazy_select)
  if (!is.null(ds)) return(ds)

  # build year/month combinations
  combinations <- expand.grid(
    year = year, month = month,
    stringsAsFactors = FALSE
  )

  n_combos <- nrow(combinations)
  if (n_combos > 1) {
    cli::cli_inform(c("i" = "Downloading {n_combos} file(s)..."))
  }

  labels <- paste0(combinations$year, "/",
                   sprintf("%02d", combinations$month))

  results <- .map_parallel(seq_len(n_combos), .delay = 0.5, function(i) {
    tryCatch({
      .anvisa_download_sngpc(
        type, combinations$year[i], combinations$month[i],
        cache = cache, cache_dir = cache_dir
      )
    }, error = function(e) NULL)
  })

  succeeded <- !vapply(results, is.null, logical(1))
  failed_labels <- labels[!succeeded]
  results <- results[succeeded]

  if (length(results) == 0) {
    cli::cli_abort("No data could be downloaded for the requested parameters.")
  }

  data <- dplyr::bind_rows(results)

  type_label <- if (type == "sngpc") "ANVISA SNGPC" else "ANVISA SNGPC Manipulados"

  .data_return(data, lazy, backend, cache_dir_resolved,
               dataset_name,
               lazy_filters, lazy_select, failed_labels, type_label)
}


# ============================================================================
# Exported functions
# ============================================================================

#' List ANVISA Data Types
#'
#' Returns a tibble with available ANVISA data types, their names,
#' descriptions, and categories.
#'
#' @return A tibble with columns: code, name, description, category.
#'
#' @export
#' @family anvisa
#'
#' @examples
#' anvisa_types()
anvisa_types <- function() {
  anvisa_valid_types
}


#' ANVISA Module Information
#'
#' Displays information about the ANVISA (Agencia Nacional de Vigilancia
#' Sanitaria) module, including data sources, available types, and
#' usage guidance.
#'
#' @return A list with module information (invisibly).
#'
#' @export
#' @family anvisa
#'
#' @examples
#' anvisa_info()
anvisa_info <- function() {
  cli::cli_h1("ANVISA \u2014 Ag\u00eancia Nacional de Vigil\u00e2ncia Sanit\u00e1ria")

  cli::cli_text("")
  cli::cli_text("Fonte:    Ag\u00eancia Nacional de Vigil\u00e2ncia Sanit\u00e1ria (ANVISA)")
  cli::cli_text("Acesso:   Portal de Dados Abertos (HTTPS)")
  cli::cli_text("Conte\u00fado: Registros de produtos, vigil\u00e2ncia p\u00f3s-mercado, SNGPC")

  cli::cli_h2("Fun\u00e7\u00f5es dispon\u00edveis")
  cli::cli_bullets(c(
    "*" = "{.fun anvisa_data}: Dados de registros, vigil\u00e2ncia e SNGPC",
    "*" = "{.fun anvisa_types}: Tipos de dados dispon\u00edveis",
    "*" = "{.fun anvisa_variables}: Lista de vari\u00e1veis por tipo"
  ))

  cli::cli_h2("Categorias de dados")

  cli::cli_text("{.strong Registros de produtos} (snapshot):")
  types_reg <- anvisa_valid_types[anvisa_valid_types$category == "product_registration", ]
  for (i in seq_len(nrow(types_reg))) {
    cli::cli_text("  {types_reg$code[i]} \u2014 {types_reg$name[i]}")
  }

  cli::cli_text("")
  cli::cli_text("{.strong Refer\u00eancia} (snapshot):")
  types_ref <- anvisa_valid_types[anvisa_valid_types$category == "reference", ]
  for (i in seq_len(nrow(types_ref))) {
    cli::cli_text("  {types_ref$code[i]} \u2014 {types_ref$name[i]}")
  }

  cli::cli_text("")
  cli::cli_text("{.strong Vigil\u00e2ncia p\u00f3s-mercado} (snapshot):")
  types_surv <- anvisa_valid_types[anvisa_valid_types$category == "surveillance", ]
  for (i in seq_len(nrow(types_surv))) {
    cli::cli_text("  {types_surv$code[i]} \u2014 {types_surv$name[i]}")
  }

  cli::cli_text("")
  cli::cli_text("{.strong SNGPC - Subst\u00e2ncias controladas} (s\u00e9rie temporal):")
  types_sngpc <- anvisa_valid_types[anvisa_valid_types$category == "sngpc", ]
  for (i in seq_len(nrow(types_sngpc))) {
    cli::cli_text("  {types_sngpc$code[i]} \u2014 {types_sngpc$name[i]}")
  }

  cli::cli_h2("Per\u00edodos dispon\u00edveis")
  cli::cli_text("  Registros/Vigil\u00e2ncia: Instant\u00e2neo (snapshot atual)")
  cli::cli_text("  SNGPC:                2014\u20132026 (mensal)")

  cli::cli_text("")

  invisible(list(
    name = "ANVISA - Ag\u00eancia Nacional de Vigil\u00e2ncia Sanit\u00e1ria",
    source = "Portal de Dados Abertos ANVISA",
    n_types = nrow(anvisa_valid_types),
    sngpc_years = anvisa_sngpc_years,
    url = anvisa_base_url
  ))
}


#' List ANVISA Variables
#'
#' Returns a tibble with available variables for a given ANVISA data type,
#' including descriptions.
#'
#' @param type Character. ANVISA data type code. Default: \code{"medicines"}.
#'   Use \code{\link{anvisa_types}()} to see all valid types.
#' @param search Character. Optional search term to filter variables by
#'   name or description. Case-insensitive and accent-insensitive.
#'
#' @return A tibble with columns: variable, description.
#'
#' @export
#' @family anvisa
#'
#' @examples
#' anvisa_variables()
#' anvisa_variables(type = "hemovigilance")
#' anvisa_variables(search = "registro")
anvisa_variables <- function(type = "medicines", search = NULL) {
  type <- .anvisa_validate_type(type)
  result <- .anvisa_get_metadata(type)
  .search_metadata(result, search, c("variable", "description"))
}


#' Download ANVISA Data
#'
#' Downloads and returns data from the ANVISA (Agencia Nacional de Vigilancia
#' Sanitaria) open data portal. Supports 14 data types across 4 categories:
#' product registrations, reference tables, post-market surveillance, and
#' controlled substance sales (SNGPC).
#'
#' @param type Character. Type of data to download. Default: \code{"medicines"}.
#'   Use \code{\link{anvisa_types}()} to see all 14 available types.
#'
#'   \strong{Snapshot types} (no year/month needed):
#'   \code{"medicines"}, \code{"medical_devices"}, \code{"food"},
#'   \code{"cosmetics"}, \code{"sanitizers"}, \code{"tobacco"},
#'   \code{"pesticides"}, \code{"hemovigilance"}, \code{"technovigilance"},
#'   \code{"vigimed_notifications"}, \code{"vigimed_medicines"},
#'   \code{"vigimed_reactions"}.
#'
#'   \strong{Time-series types} (year required):
#'   \code{"sngpc"}, \code{"sngpc_compounded"}.
#'
#' @param year Integer. Year(s) of the data. Only used for SNGPC types
#'   (2014-2026). Ignored with a warning for snapshot types.
#' @param month Integer. Month(s) 1-12. Only used for SNGPC types.
#'   If NULL (default), downloads all 12 months. Ignored with a warning
#'   for snapshot types.
#' @param vars Character vector. Variables to keep. If NULL (default),
#'   returns all available variables. Use \code{\link{anvisa_variables}()}
#'   to see available variables per type.
#' @param cache Logical. If TRUE (default), caches downloaded data for
#'   faster future access.
#' @param cache_dir Character. Directory for caching. Default:
#'   \code{tools::R_user_dir("healthbR", "cache")}.
#' @param lazy Logical. If TRUE, returns a lazy query object instead of a
#'   tibble. Only available for SNGPC types (partitioned cache). Requires
#'   the \pkg{arrow} package. Default: FALSE.
#' @param backend Character. Backend for lazy evaluation: \code{"arrow"}
#'   (default) or \code{"duckdb"}. Only used when \code{lazy = TRUE}.
#'
#' @return A tibble with ANVISA data. SNGPC types include \code{year} and
#'   \code{month} partition columns.
#'
#' @details
#' Data is downloaded from the ANVISA open data portal at
#' \verb{https://dados.anvisa.gov.br/dados/}.
#'
#' \strong{Snapshot types}: Download a single CSV file representing the
#' current state of the registry/database. No time dimension. Cached as
#' flat files.
#'
#' \strong{SNGPC types}: Monthly CSV files with controlled substance sales
#' data. Data available from January 2014 to October 2021, with new data
#' from January 2026. Cached as Hive-style partitioned parquet datasets.
#'
#' The three VigiMed types share the \code{IDENTIFICACAO_NOTIFICACAO} key
#' for linking notifications, medicines, and reactions.
#'
#' ## Parallel downloads
#' When downloading multiple SNGPC months, install \pkg{furrr} and \pkg{future}
#' and set a parallel plan to speed up downloads:
#' `future::plan(future::multisession, workers = 4)`. See
#' `vignette("healthbR")` for details.
#'
#' @export
#' @family anvisa
#'
#' @seealso \code{\link{anvisa_types}()} for available types,
#'   \code{\link{anvisa_variables}()} for variable descriptions.
#'
#' @examplesIf interactive()
#' # registered medicines
#' med <- anvisa_data(type = "medicines")
#'
#' # hemovigilance notifications
#' hemo <- anvisa_data(type = "hemovigilance")
#'
#' # SNGPC controlled substance sales, Jan 2020
#' sngpc <- anvisa_data(type = "sngpc", year = 2020, month = 1)
anvisa_data <- function(type = "medicines",
                        year = NULL, month = NULL,
                        vars = NULL,
                        cache = TRUE, cache_dir = NULL,
                        lazy = FALSE, backend = c("arrow", "duckdb")) {

  type <- .anvisa_validate_type(type)
  is_sngpc <- type %in% anvisa_sngpc_types

  # warn about unused parameters for snapshot types
  if (!is_sngpc) {
    if (!is.null(year)) {
      cli::cli_warn("{.arg year} is ignored for snapshot type {.val {type}}.")
    }
    if (!is.null(month)) {
      cli::cli_warn("{.arg month} is ignored for snapshot type {.val {type}}.")
    }
    if (isTRUE(lazy)) {
      cli::cli_warn("{.arg lazy} is ignored for snapshot type {.val {type}} (flat cache).")
    }
  }

  # SNGPC requires year
  if (is_sngpc && is.null(year)) {
    cli::cli_abort(c(
      "{.arg year} is required for SNGPC types.",
      "i" = "Available years: 2014-2026."
    ))
  }

  # dispatch
  if (is_sngpc) {
    .anvisa_data_sngpc(type, year, month, vars,
                       cache, cache_dir, lazy, backend)
  } else {
    .anvisa_data_snapshot(type, vars, cache, cache_dir)
  }
}


#' Show ANVISA Cache Status
#'
#' Shows information about cached ANVISA data files.
#'
#' @param cache_dir Character. Cache directory path. Default:
#'   \code{tools::R_user_dir("healthbR", "cache")}.
#'
#' @return A tibble with cache file information (invisibly).
#'
#' @export
#' @family anvisa
#'
#' @examples
#' anvisa_cache_status()
anvisa_cache_status <- function(cache_dir = NULL) {
  .cache_status("anvisa", "ANVISA", .anvisa_cache_dir(cache_dir))
}


#' Clear ANVISA Cache
#'
#' Deletes cached ANVISA data files.
#'
#' @param cache_dir Character. Cache directory path. Default:
#'   \code{tools::R_user_dir("healthbR", "cache")}.
#'
#' @return Invisible NULL.
#'
#' @export
#' @family anvisa
#'
#' @examplesIf interactive()
#' anvisa_clear_cache()
anvisa_clear_cache <- function(cache_dir = NULL) {
  .clear_cache("anvisa", "ANVISA", .anvisa_cache_dir(cache_dir))
}
