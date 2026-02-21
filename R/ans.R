# ans functions for healthbR package
# functions to access supplementary health data from ANS (Agencia Nacional
# de Saude Suplementar) open data portal

# ============================================================================
# internal validation functions
# ============================================================================

#' Validate ANS type parameter
#' @noRd
.ans_validate_type <- function(type) {
  type <- tolower(type)
  valid <- ans_valid_types$code

  if (!type %in% valid) {
    cli::cli_abort(c(
      "Invalid ANS type: {.val {type}}.",
      "i" = "Valid types: {.val {valid}}",
      "i" = "Use {.code ans_info()} to see type descriptions."
    ))
  }

  type
}

#' Validate ANS year parameter (type-specific)
#' @noRd
.ans_validate_year <- function(year, type) {
  available <- ans_available_years[[type]]
  .validate_year(year, available,
                 years_fn_hint = paste0("ans_years(type = '", type, "')"))
}

#' Validate ANS UF parameter (beneficiaries only, includes XX)
#' @noRd
.ans_validate_uf <- function(uf) {
  .validate_uf(uf, ans_uf_list_xx)
}

#' Validate ANS vars parameter (warning only)
#' @noRd
.ans_validate_vars <- function(vars, type) {
  meta <- .ans_get_variables_meta(type)
  known_vars <- meta$variable
  invalid <- vars[!vars %in% known_vars]

  if (length(invalid) > 0) {
    cli::cli_warn(c(
      "Variable(s) {.val {invalid}} not in known ANS {type} variables.",
      "i" = "Use {.code ans_variables(type = '{type}')} to see available variables.",
      "i" = "Proceeding anyway (variables will be dropped if not found)."
    ))
  }
}

#' Validate month for beneficiaries (reject Jan-Mar 2019)
#' @noRd
.ans_validate_month_beneficiaries <- function(month, year) {
  month <- .validate_month(month)

  # beneficiaries start at April 2019
  if (any(year == 2019L)) {
    invalid_2019 <- month[month < 4L]
    if (length(invalid_2019) > 0 && all(year == 2019L)) {
      cli::cli_abort(c(
        "Month(s) {.val {invalid_2019}} not available for 2019.",
        "i" = "Beneficiaries data starts at April 2019 (month 4)."
      ))
    }
  }

  month
}

#' Get variable metadata for a type
#' @noRd
.ans_get_variables_meta <- function(type) {
  switch(type,
    "beneficiaries" = ans_beneficiaries_metadata,
    "complaints" = ans_complaints_metadata,
    "financial" = ans_financial_metadata,
    ans_beneficiaries_metadata
  )
}


# ============================================================================
# internal URL builders
# ============================================================================

#' Build URL for beneficiaries ZIP
#' @noRd
.ans_beneficiaries_url <- function(year, month, uf) {
  mm <- sprintf("%02d", month)
  stringr::str_c(
    ans_base_url,
    "/informacoes_consolidadas_de_beneficiarios-024/",
    year, mm, "/pda-024-icb-", uf, "-", year, "_", mm, ".zip"
  )
}

#' Build URL for complaints CSV
#' @noRd
.ans_complaints_url <- function(year) {
  stringr::str_c(
    ans_base_url,
    "/demandas_dos_consumidores_nip/pda-013-demandas_dos_consumidores_nip-",
    year, ".csv"
  )
}

#' Build URL for financial ZIP
#' @noRd
.ans_financial_url <- function(year, quarter) {
  stringr::str_c(
    ans_base_url,
    "/demonstracoes_contabeis/", year, "/", quarter, "T", year, ".zip"
  )
}

#' Build URL for operators CSV
#' @noRd
.ans_operators_url <- function(status) {
  switch(status,
    "active" = stringr::str_c(
      ans_base_url,
      "/operadoras_de_plano_de_saude_ativas/Relatorio_cadop.csv"
    ),
    "cancelled" = stringr::str_c(
      ans_base_url,
      "/operadoras_de_plano_de_saude_canceladas/Relatorio_cadop_canceladas.csv"
    )
  )
}


# ============================================================================
# internal helper functions
# ============================================================================

#' Get/create ANS cache directory
#' @noRd
.ans_cache_dir <- function(cache_dir = NULL) {
  .module_cache_dir("ans", cache_dir)
}


#' Download and read a beneficiaries ZIP for one UF/year/month
#' @noRd
.ans_download_beneficiaries <- function(year, month, uf,
                                        cache = TRUE, cache_dir = NULL) {
  cache_dir <- .ans_cache_dir(cache_dir)
  dataset_name <- "ans_beneficiaries_data"
  target_year <- as.integer(year)
  target_month <- as.integer(month)
  target_uf <- uf

  # 1. check partitioned cache
  if (isTRUE(cache) && .has_arrow() &&
      .has_partitioned_cache(cache_dir, dataset_name)) {
    ds <- arrow::open_dataset(file.path(cache_dir, dataset_name))
    cached <- ds |>
      dplyr::filter(.data$uf_source == target_uf,
                     .data$year == target_year,
                     .data$month == target_month) |>
      dplyr::collect()
    if (nrow(cached) > 0) return(cached)
  }

  # 2. download ZIP
  url <- .ans_beneficiaries_url(year, month, uf)
  temp_zip <- tempfile(fileext = ".zip")
  on.exit(if (file.exists(temp_zip)) file.remove(temp_zip), add = TRUE)

  cli::cli_inform(c(
    "i" = "Downloading ANS beneficiaries: {uf} {year}/{sprintf('%02d', month)}..."
  ))

  .http_download(url, temp_zip)

  # 3. extract and read CSV
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  utils::unzip(temp_zip, exdir = temp_dir)
  csvs <- list.files(temp_dir, pattern = "csv$", full.names = TRUE,
                     recursive = TRUE)

  if (length(csvs) == 0) {
    cli::cli_abort("No CSV file found in downloaded ZIP for {uf} {year}/{sprintf('%02d', month)}.")
  }

  data <- readr::read_delim(
    csvs[1], delim = ";", show_col_types = FALSE,
    locale = readr::locale(encoding = "UTF-8"),
    col_types = readr::cols(.default = "c")
  )

  # add partition columns
  data$year <- target_year
  data$month <- target_month
  data$uf_source <- target_uf
  cols <- names(data)
  data <- data[, c("year", "month", "uf_source",
                    setdiff(cols, c("year", "month", "uf_source")))]

  # 4. write to partitioned cache
  if (isTRUE(cache)) {
    .cache_append_partitioned(data, cache_dir, dataset_name,
                              c("uf_source", "year", "month"))
  }

  data
}


#' Download and read a complaints CSV for one year
#' @noRd
.ans_download_complaints <- function(year, cache = TRUE, cache_dir = NULL) {
  cache_dir <- .ans_cache_dir(cache_dir)
  dataset_name <- "ans_complaints_data"
  target_year <- as.integer(year)

  # 1. check partitioned cache
  if (isTRUE(cache) && .has_arrow() &&
      .has_partitioned_cache(cache_dir, dataset_name)) {
    ds <- arrow::open_dataset(file.path(cache_dir, dataset_name))
    cached <- ds |>
      dplyr::filter(.data$year == target_year) |>
      dplyr::collect()
    if (nrow(cached) > 0) return(cached)
  }

  # 2. download CSV
  url <- .ans_complaints_url(year)
  temp_csv <- tempfile(fileext = ".csv")
  on.exit(if (file.exists(temp_csv)) file.remove(temp_csv), add = TRUE)

  cli::cli_inform(c(
    "i" = "Downloading ANS complaints: {year}..."
  ))

  .http_download(url, temp_csv)

  data <- readr::read_delim(
    temp_csv, delim = ";", show_col_types = FALSE,
    locale = readr::locale(encoding = "UTF-8"),
    col_types = readr::cols(.default = "c")
  )

  # add partition column
  data$year <- target_year
  cols <- names(data)
  data <- data[, c("year", setdiff(cols, "year"))]

  # 3. write to partitioned cache
  if (isTRUE(cache)) {
    .cache_append_partitioned(data, cache_dir, dataset_name, c("year"))
  }

  data
}


#' Download and read a financial ZIP for one year/quarter
#' @noRd
.ans_download_financial <- function(year, quarter,
                                    cache = TRUE, cache_dir = NULL) {
  cache_dir <- .ans_cache_dir(cache_dir)
  dataset_name <- "ans_financial_data"
  target_year <- as.integer(year)
  target_quarter <- as.integer(quarter)

  # 1. check partitioned cache
  if (isTRUE(cache) && .has_arrow() &&
      .has_partitioned_cache(cache_dir, dataset_name)) {
    ds <- arrow::open_dataset(file.path(cache_dir, dataset_name))
    cached <- ds |>
      dplyr::filter(.data$year == target_year,
                     .data$quarter == target_quarter) |>
      dplyr::collect()
    if (nrow(cached) > 0) return(cached)
  }

  # 2. download ZIP
  url <- .ans_financial_url(year, quarter)
  temp_zip <- tempfile(fileext = ".zip")
  on.exit(if (file.exists(temp_zip)) file.remove(temp_zip), add = TRUE)

  cli::cli_inform(c(
    "i" = "Downloading ANS financial: {year} Q{quarter}..."
  ))

  .http_download(url, temp_zip)

  # 3. extract and read CSV
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  utils::unzip(temp_zip, exdir = temp_dir)
  csvs <- list.files(temp_dir, pattern = "csv$", full.names = TRUE,
                     recursive = TRUE)

  if (length(csvs) == 0) {
    cli::cli_abort("No CSV file found in downloaded ZIP for {year} Q{quarter}.")
  }

  data <- readr::read_delim(
    csvs[1], delim = ";", show_col_types = FALSE,
    locale = readr::locale(encoding = "UTF-8"),
    col_types = readr::cols(.default = "c")
  )

  # add partition columns
  data$year <- target_year
  data$quarter <- target_quarter
  cols <- names(data)
  data <- data[, c("year", "quarter", setdiff(cols, c("year", "quarter")))]

  # 4. write to partitioned cache
  if (isTRUE(cache)) {
    .cache_append_partitioned(data, cache_dir, dataset_name,
                              c("year", "quarter"))
  }

  data
}


#' Download and read an operators CSV
#' @noRd
.ans_download_operators <- function(status, cache = TRUE, cache_dir = NULL) {
  cache_dir <- .ans_cache_dir(cache_dir)
  cache_base <- paste0("ans_operators_", status)

  # check flat cache
  if (isTRUE(cache)) {
    cached <- .cache_read(cache_dir, cache_base)
    if (!is.null(cached)) return(cached)
  }

  url <- .ans_operators_url(status)
  temp_csv <- tempfile(fileext = ".csv")
  on.exit(if (file.exists(temp_csv)) file.remove(temp_csv), add = TRUE)

  cli::cli_inform(c(
    "i" = "Downloading ANS operators ({status})..."
  ))

  .http_download(url, temp_csv)

  data <- readr::read_delim(
    temp_csv, delim = ";", show_col_types = FALSE,
    locale = readr::locale(encoding = "UTF-8"),
    col_types = readr::cols(.default = "c")
  )

  # write to flat cache
  if (isTRUE(cache)) {
    .cache_write(data, cache_dir, cache_base)
  }

  data
}


# ============================================================================
# routing dispatch functions
# ============================================================================

#' Dispatch beneficiaries data download
#' @noRd
.ans_data_beneficiaries <- function(year, uf, month, vars,
                                    cache, cache_dir,
                                    lazy, backend) {
  year <- .ans_validate_year(year, "beneficiaries")
  month <- .ans_validate_month_beneficiaries(month, year)
  if (!is.null(uf)) {
    uf <- .ans_validate_uf(uf)
  }
  if (!is.null(vars)) .ans_validate_vars(vars, "beneficiaries")

  target_ufs <- if (!is.null(uf)) toupper(uf) else ans_uf_list

  cache_dir_resolved <- .ans_cache_dir(cache_dir)
  lazy_filters <- list(year = year, uf_source = target_ufs, month = as.integer(month))
  lazy_select <- if (!is.null(vars)) {
    unique(c("year", "month", "uf_source", vars))
  } else {
    NULL
  }

  # pre-download lazy check
  ds <- .try_lazy_cache(lazy, backend, cache_dir_resolved,
                        "ans_beneficiaries_data",
                        lazy_filters, lazy_select)
  if (!is.null(ds)) return(ds)

  # build combinations, filtering out Jan-Mar 2019
  combinations <- expand.grid(
    year = year, month = month, uf = target_ufs,
    stringsAsFactors = FALSE
  )
  # remove invalid 2019 months (1-3)
  combinations <- combinations[
    !(combinations$year == 2019L & combinations$month < 4L), ]

  if (nrow(combinations) == 0) {
    cli::cli_abort("No valid year/month/UF combinations to download.")
  }

  n_combos <- nrow(combinations)
  if (n_combos > 1) {
    cli::cli_inform(c(
      "i" = "Downloading {n_combos} file(s)..."
    ))
  }

  labels <- paste(combinations$uf,
                  paste0(combinations$year, "/",
                         sprintf("%02d", combinations$month)))

  results <- .map_parallel(seq_len(n_combos), .delay = 0.5,
                            .progress = "Downloading", function(i) {
    tryCatch({
      .ans_download_beneficiaries(
        combinations$year[i], combinations$month[i], combinations$uf[i],
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

  .data_return(data, lazy, backend, cache_dir_resolved,
               "ans_beneficiaries_data",
               lazy_filters, lazy_select, failed_labels, "ANS beneficiaries")
}


#' Dispatch complaints data download
#' @noRd
.ans_data_complaints <- function(year, vars, cache, cache_dir,
                                 lazy, backend) {
  year <- .ans_validate_year(year, "complaints")
  if (!is.null(vars)) .ans_validate_vars(vars, "complaints")

  cache_dir_resolved <- .ans_cache_dir(cache_dir)
  lazy_filters <- list(year = year)
  lazy_select <- if (!is.null(vars)) unique(c("year", vars)) else NULL

  # pre-download lazy check
  ds <- .try_lazy_cache(lazy, backend, cache_dir_resolved,
                        "ans_complaints_data",
                        lazy_filters, lazy_select)
  if (!is.null(ds)) return(ds)

  n_years <- length(year)
  if (n_years > 1) {
    cli::cli_inform(c("i" = "Downloading {n_years} file(s)..."))
  }

  labels <- as.character(year)

  results <- .map_parallel(seq_along(year), .delay = 0.5,
                            .progress = "Downloading", function(i) {
    tryCatch({
      .ans_download_complaints(year[i], cache = cache, cache_dir = cache_dir)
    }, error = function(e) NULL)
  })

  succeeded <- !vapply(results, is.null, logical(1))
  failed_labels <- labels[!succeeded]
  results <- results[succeeded]

  if (length(results) == 0) {
    cli::cli_abort("No data could be downloaded for the requested year(s).")
  }

  data <- dplyr::bind_rows(results)

  .data_return(data, lazy, backend, cache_dir_resolved,
               "ans_complaints_data",
               lazy_filters, lazy_select, failed_labels, "ANS complaints")
}


#' Dispatch financial data download
#' @noRd
.ans_data_financial <- function(year, quarter, vars,
                                cache, cache_dir,
                                lazy, backend) {
  year <- .ans_validate_year(year, "financial")
  quarter <- .validate_quarter(quarter)
  if (!is.null(vars)) .ans_validate_vars(vars, "financial")

  cache_dir_resolved <- .ans_cache_dir(cache_dir)
  lazy_filters <- list(year = year, quarter = as.integer(quarter))
  lazy_select <- if (!is.null(vars)) {
    unique(c("year", "quarter", vars))
  } else {
    NULL
  }

  # pre-download lazy check
  ds <- .try_lazy_cache(lazy, backend, cache_dir_resolved,
                        "ans_financial_data",
                        lazy_filters, lazy_select)
  if (!is.null(ds)) return(ds)

  combinations <- expand.grid(
    year = year, quarter = quarter,
    stringsAsFactors = FALSE
  )

  n_combos <- nrow(combinations)
  if (n_combos > 1) {
    cli::cli_inform(c("i" = "Downloading {n_combos} file(s)..."))
  }

  labels <- paste0(combinations$year, " Q", combinations$quarter)

  results <- .map_parallel(seq_len(n_combos), .delay = 0.5,
                            .progress = "Downloading", function(i) {
    tryCatch({
      .ans_download_financial(
        combinations$year[i], combinations$quarter[i],
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

  .data_return(data, lazy, backend, cache_dir_resolved,
               "ans_financial_data",
               lazy_filters, lazy_select, failed_labels, "ANS financial")
}


# ============================================================================
# exported functions
# ============================================================================

#' List Available ANS Years
#'
#' Returns an integer vector with years for which ANS data are available.
#'
#' @param type Character. Type of data. One of:
#'   \itemize{
#'     \item \code{"beneficiaries"}: Consolidated beneficiary counts (default).
#'     \item \code{"complaints"}: Consumer complaints (NIP).
#'     \item \code{"financial"}: Financial statements.
#'   }
#'
#' @return An integer vector of available years.
#'
#' @export
#' @family ans
#'
#' @examples
#' ans_years()
#' ans_years(type = "complaints")
#' ans_years(type = "financial")
ans_years <- function(type = "beneficiaries") {
  type <- .ans_validate_type(type)
  ans_available_years[[type]]
}


#' ANS Module Information
#'
#' Displays information about the ANS (Agencia Nacional de Saude Suplementar)
#' module, including data sources, available years, and usage guidance.
#'
#' @return A list with module information (invisibly).
#'
#' @export
#' @family ans
#'
#' @examples
#' ans_info()
ans_info <- function() {
  cli::cli_h1("ANS \u2014 Ag\u00eancia Nacional de Sa\u00fade Suplementar")

  cli::cli_text("")
  cli::cli_text("Fonte:    Ag\u00eancia Nacional de Sa\u00fade Suplementar (ANS)")
  cli::cli_text("Acesso:   Dados Abertos ANS (HTTP)")
  cli::cli_text("Conte\u00fado: Dados do setor de sa\u00fade suplementar (planos de sa\u00fade)")

  cli::cli_h2("Dados dispon\u00edveis")
  cli::cli_bullets(c(
    "*" = "{.fun ans_data}: Dados de benefici\u00e1rios, demandas e demonstra\u00e7\u00f5es cont\u00e1beis",
    "*" = "{.fun ans_operators}: Cadastro de operadoras (ativas/canceladas)",
    "*" = "{.fun ans_variables}: Lista de vari\u00e1veis dispon\u00edveis"
  ))

  cli::cli_h2("Tipos de dados")
  for (i in seq_len(nrow(ans_valid_types))) {
    cli::cli_text(
      "  {ans_valid_types$code[i]}   {ans_valid_types$name[i]} \u2014 {ans_valid_types$description[i]}"
    )
  }

  cli::cli_h2("Par\u00e2metros por tipo")
  cli::cli_text("  beneficiaries:  year, month, uf")
  cli::cli_text("  complaints:     year")
  cli::cli_text("  financial:      year, quarter")

  cli::cli_h2("Per\u00edodos dispon\u00edveis")
  cli::cli_text("  Benefici\u00e1rios:      Abr/2019\u20132025 (mensal, por UF)")
  cli::cli_text("  Demandas NIP:       2011\u20132026 (anual, nacional)")
  cli::cli_text("  Demonstra\u00e7\u00f5es:    2007\u20132025 (trimestral)")
  cli::cli_text("  Operadoras:         Instantaneo (cadastro atual)")

  cli::cli_text("")

  invisible(list(
    name = "ANS - Ag\u00eancia Nacional de Sa\u00fade Suplementar",
    source = "Dados Abertos ANS",
    years_beneficiaries = ans_available_years$beneficiaries,
    years_complaints = ans_available_years$complaints,
    years_financial = ans_available_years$financial,
    n_types = nrow(ans_valid_types),
    url = ans_base_url
  ))
}


#' List ANS Variables
#'
#' Returns a tibble with available variables in the ANS data,
#' including descriptions and value types.
#'
#' @param type Character. Type of data. One of \code{"beneficiaries"}
#'   (default), \code{"complaints"}, \code{"financial"}, or
#'   \code{"operators"}.
#' @param search Character. Optional search term to filter variables by
#'   name or description. Case-insensitive and accent-insensitive.
#'
#' @return A tibble with columns: variable, description, type, section.
#'
#' @export
#' @family ans
#'
#' @examples
#' ans_variables()
#' ans_variables(type = "complaints")
#' ans_variables(search = "operadora")
ans_variables <- function(type = "beneficiaries", search = NULL) {
  type <- tolower(type)
  result <- switch(type,
    "beneficiaries" = ans_beneficiaries_metadata,
    "complaints" = ans_complaints_metadata,
    "financial" = ans_financial_metadata,
    "operators" = ans_operators_metadata,
    {
      cli::cli_abort(c(
        "Invalid type: {.val {type}}.",
        "i" = "Valid types: {.val {c('beneficiaries', 'complaints', 'financial', 'operators')}}"
      ))
    }
  )

  .search_metadata(result, search, c("variable", "description"))
}


#' Download ANS Data
#'
#' Downloads and returns data from the ANS (Agencia Nacional de Saude
#' Suplementar) open data portal. Supports three data types: beneficiary
#' counts, consumer complaints (NIP), and financial statements.
#'
#' @param year Integer. Year(s) of the data. Required.
#' @param type Character. Type of data. One of:
#'   \itemize{
#'     \item \code{"beneficiaries"}: Consolidated beneficiary counts (default).
#'       Uses \code{year}, \code{month}, \code{uf} parameters.
#'     \item \code{"complaints"}: Consumer complaints via NIP.
#'       Uses \code{year} only (national data).
#'     \item \code{"financial"}: Financial statements.
#'       Uses \code{year}, \code{quarter} parameters.
#'   }
#' @param uf Character. Two-letter state abbreviation(s). Only used for
#'   \code{type = "beneficiaries"}. Includes \code{"XX"} for unidentified
#'   beneficiaries. If NULL (default), downloads all 27 states.
#' @param month Integer. Month(s) 1-12. Only used for
#'   \code{type = "beneficiaries"}. If NULL (default), downloads all months.
#'   Note: 2019 starts at month 4 (April).
#' @param quarter Integer. Quarter(s) 1-4. Only used for
#'   \code{type = "financial"}. If NULL (default), downloads all 4 quarters.
#' @param vars Character vector. Variables to keep. If NULL (default),
#'   returns all available variables. Use \code{\link{ans_variables}()}
#'   to see available variables per type.
#' @param cache Logical. If TRUE (default), caches downloaded data for
#'   faster future access.
#' @param cache_dir Character. Directory for caching. Default:
#'   \code{tools::R_user_dir("healthbR", "cache")}.
#' @param lazy Logical. If TRUE, returns a lazy query object instead of a
#'   tibble. Requires the \pkg{arrow} package. Default: FALSE.
#' @param backend Character. Backend for lazy evaluation: \code{"arrow"}
#'   (default) or \code{"duckdb"}. Only used when \code{lazy = TRUE}.
#'
#' @return A tibble with ANS data. Includes partition columns:
#'   \code{year} (all types), \code{month} and \code{uf_source}
#'   (beneficiaries), \code{quarter} (financial).
#'
#' @details
#' Data is downloaded from the ANS open data portal at
#' \verb{https://dadosabertos.ans.gov.br/}.
#'
#' \strong{Beneficiaries}: Monthly per-state ZIP files containing CSV data
#' with consolidated beneficiary counts by operator, plan type, sex, age
#' group, and municipality. Available from April 2019.
#'
#' \strong{Complaints}: Annual national CSV files with consumer complaints
#' filed through the NIP (Notificacao de Intermediacao Preliminar).
#' Available from 2011.
#'
#' \strong{Financial}: Quarterly ZIP files with financial statements of
#' health plan operators (balance sheets, income statements).
#' Available from 2007.
#'
#' ## Parallel downloads
#' When downloading multiple files (e.g., several months or quarters), install
#' \pkg{furrr} and \pkg{future} and set a parallel plan to speed up downloads:
#' `future::plan(future::multisession, workers = 4)`. See
#' `vignette("healthbR")` for details.
#'
#' @export
#' @family ans
#'
#' @seealso \code{\link{ans_operators}()} for the operator registry,
#'   \code{\link{ans_variables}()} for variable descriptions.
#'
#' @examplesIf interactive()
#' # beneficiary counts for Acre, December 2023
#' ac <- ans_data(year = 2023, month = 12, uf = "AC")
#'
#' # consumer complaints for 2022
#' nip <- ans_data(year = 2022, type = "complaints")
#'
#' # financial statements Q1 2023
#' fin <- ans_data(year = 2023, type = "financial", quarter = 1)
ans_data <- function(year, type = "beneficiaries",
                     uf = NULL, month = NULL, quarter = NULL,
                     vars = NULL,
                     cache = TRUE, cache_dir = NULL,
                     lazy = FALSE, backend = c("arrow", "duckdb")) {

  type <- .ans_validate_type(type)

  # warn about unused parameters
  if (type == "beneficiaries" && !is.null(quarter)) {
    cli::cli_warn("{.arg quarter} is ignored for {.val beneficiaries} type.")
  }
  if (type == "complaints") {
    if (!is.null(uf)) {
      cli::cli_warn("{.arg uf} is ignored for {.val complaints} type (national data).")
    }
    if (!is.null(month)) {
      cli::cli_warn("{.arg month} is ignored for {.val complaints} type (annual data).")
    }
    if (!is.null(quarter)) {
      cli::cli_warn("{.arg quarter} is ignored for {.val complaints} type.")
    }
  }
  if (type == "financial") {
    if (!is.null(uf)) {
      cli::cli_warn("{.arg uf} is ignored for {.val financial} type.")
    }
    if (!is.null(month)) {
      cli::cli_warn("{.arg month} is ignored for {.val financial} type.")
    }
  }

  # dispatch to type-specific handler
  switch(type,
    "beneficiaries" = .ans_data_beneficiaries(
      year, uf, month, vars, cache, cache_dir, lazy, backend
    ),
    "complaints" = .ans_data_complaints(
      year, vars, cache, cache_dir, lazy, backend
    ),
    "financial" = .ans_data_financial(
      year, quarter, vars, cache, cache_dir, lazy, backend
    )
  )
}


#' Download ANS Operators Registry
#'
#' Downloads and returns the current registry of health plan operators
#' from the ANS open data portal. This is a snapshot of the current
#' operator status (not time-series data).
#'
#' @param status Character. Filter by operator status:
#'   \itemize{
#'     \item \code{"active"}: Active operators only (default).
#'     \item \code{"cancelled"}: Cancelled operators only.
#'     \item \code{"all"}: Both active and cancelled.
#'   }
#' @param vars Character vector. Variables to keep. If NULL (default),
#'   returns all 20 variables. Use \code{ans_variables(type = "operators")}
#'   to see available variables.
#' @param cache Logical. If TRUE (default), caches downloaded data.
#' @param cache_dir Character. Directory for caching.
#'
#' @return A tibble with operator data. When \code{status = "all"},
#'   includes a \code{status} column indicating "active" or "cancelled".
#'
#' @export
#' @family ans
#'
#' @examplesIf interactive()
#' # active operators
#' ops <- ans_operators()
#'
#' # all operators (active + cancelled)
#' all_ops <- ans_operators(status = "all")
ans_operators <- function(status = "active",
                          vars = NULL,
                          cache = TRUE, cache_dir = NULL) {
  status <- match.arg(status, c("active", "cancelled", "all"))

  if (status == "all") {
    active <- .ans_download_operators("active", cache = cache,
                                     cache_dir = cache_dir)
    active$status <- "active"
    cancelled <- .ans_download_operators("cancelled", cache = cache,
                                        cache_dir = cache_dir)
    cancelled$status <- "cancelled"
    data <- dplyr::bind_rows(active, cancelled)
  } else {
    data <- .ans_download_operators(status, cache = cache,
                                   cache_dir = cache_dir)
  }

  # column selection
  if (!is.null(vars)) {
    keep_cols <- intersect(vars, names(data))
    if (status == "all" && !"status" %in% vars) {
      keep_cols <- c(keep_cols, "status")
    }
    data <- data[, keep_cols, drop = FALSE]
  }

  tibble::as_tibble(data)
}


#' Show ANS Cache Status
#'
#' Shows information about cached ANS data files.
#'
#' @param cache_dir Character. Cache directory path. Default:
#'   \code{tools::R_user_dir("healthbR", "cache")}.
#'
#' @return A tibble with cache file information (invisibly).
#'
#' @export
#' @family ans
#'
#' @examples
#' ans_cache_status()
ans_cache_status <- function(cache_dir = NULL) {
  .cache_status("ans", "ANS", .ans_cache_dir(cache_dir))
}


#' Clear ANS Cache
#'
#' Deletes cached ANS data files.
#'
#' @param cache_dir Character. Cache directory path. Default:
#'   \code{tools::R_user_dir("healthbR", "cache")}.
#'
#' @return Invisible NULL.
#'
#' @export
#' @family ans
#'
#' @examplesIf interactive()
#' ans_clear_cache()
ans_clear_cache <- function(cache_dir = NULL) {
  .clear_cache("ans", "ANS", .ans_cache_dir(cache_dir))
}
