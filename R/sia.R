# sia functions for healthbR package
# functions to access outpatient production microdata from the SIA (Sistema de
# Informacoes Ambulatoriais) via DATASUS FTP

# ============================================================================
# internal validation functions
# ============================================================================

#' Validate SIA year parameter
#' @noRd
.sia_validate_year <- function(year, status = "all") {
  .validate_year(year, sia_years(status = status),
                 years_fn_hint = "sia_years(status = 'all')")
}

#' Validate SIA UF parameter
#' @noRd
.sia_validate_uf <- function(uf) {
  .validate_uf(uf, sia_uf_list)
}


#' Validate SIA type parameter
#' @noRd
.sia_validate_type <- function(type) {
  type <- toupper(type)
  valid_codes <- sia_valid_types$code

  if (!type %in% valid_codes) {
    cli::cli_abort(c(
      "Invalid SIA type: {.val {type}}.",
      "i" = "Valid types: {.val {valid_codes}}",
      "i" = "Use {.code sia_info()} to see type descriptions."
    ))
  }

  type
}


#' Validate SIA vars parameter (warning only)
#' @noRd
.sia_validate_vars <- function(vars) {
  known_vars <- sia_variables_metadata$variable
  invalid <- vars[!vars %in% known_vars]

  if (length(invalid) > 0) {
    cli::cli_warn(c(
      "Variable(s) {.val {invalid}} not in known SIA variables.",
      "i" = "Use {.code sia_variables()} to see available variables.",
      "i" = "Proceeding anyway (variables will be dropped if not found)."
    ))
  }
}


# ============================================================================
# internal helper functions
# ============================================================================

#' Build FTP URL for SIA .dbc file
#' @noRd
.sia_build_ftp_url <- function(year, month, uf, type = "PA") {
  if (year < 2008L) {
    cli::cli_abort(
      "Year {.val {year}} is not supported. SIA data starts in 2008."
    )
  }

  yy <- sprintf("%02d", year %% 100)
  mm <- sprintf("%02d", month)

  stringr::str_c(
    "ftp://ftp.datasus.gov.br/dissemin/publicos/SIASUS/200801_/Dados/",
    type, uf, yy, mm, ".dbc"
  )
}


#' Get/create SIA cache directory
#' @noRd
.sia_cache_dir <- function(cache_dir = NULL) {
  .module_cache_dir("sia", cache_dir)
}


#' Download and read a SIA .dbc file for one UF/year/month/type
#'
#' Returns a tibble with `year`, `month`, and `uf_source` columns already added.
#' Uses partitioned cache (Hive-style) when arrow is available, with
#' flat cache as migration fallback.
#'
#' @noRd
.sia_download_and_read <- function(year, month, uf, type = "PA",
                                   cache = TRUE, cache_dir = NULL) {
  cache_dir <- .sia_cache_dir(cache_dir)
  dataset_name <- "sia_data"
  target_year <- as.integer(year)
  target_month <- as.integer(month)
  target_uf <- uf

  # 1. check partitioned cache first (preferred path)
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

  # 2. download from FTP
  url <- .sia_build_ftp_url(year, month, uf, type)
  temp_dbc <- tempfile(fileext = ".dbc")
  on.exit(if (file.exists(temp_dbc)) file.remove(temp_dbc), add = TRUE)

  cli::cli_inform(c(
    "i" = "Downloading SIA data: {type} {uf} {year}/{sprintf('%02d', month)}..."
  ))

  .datasus_download(url, temp_dbc)

  # check file size
  if (file.size(temp_dbc) < 100) {
    cli::cli_abort(c(
      "Downloaded file appears corrupted (too small).",
      "x" = "File size: {file.size(temp_dbc)} bytes",
      "i" = "The DATASUS FTP may be experiencing issues. Try again later."
    ))
  }

  # read .dbc
  data <- .read_dbc(temp_dbc)

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


# ============================================================================
# exported functions
# ============================================================================

#' List Available SIA Years
#'
#' Returns an integer vector with years for which outpatient production
#' microdata are available from DATASUS FTP.
#'
#' @param status Character. Filter by data status. One of:
#'   \itemize{
#'     \item \code{"final"}: Definitive data only (default).
#'     \item \code{"preliminary"}: Preliminary data only.
#'     \item \code{"all"}: All available data (definitive + preliminary).
#'   }
#'
#' @return An integer vector of available years.
#'
#' @export
#' @family sia
#'
#' @examples
#' sia_years()
#' sia_years(status = "all")
sia_years <- function(status = "final") {
  status <- match.arg(status, c("final", "preliminary", "all"))

  switch(status,
    "final" = sia_available_years$final,
    "preliminary" = sia_available_years$preliminary,
    "all" = sort(c(sia_available_years$final, sia_available_years$preliminary))
  )
}


#' SIA Module Information
#'
#' Displays information about the Outpatient Information System (SIA),
#' including data sources, available years, file types, and usage guidance.
#'
#' @return A list with module information (invisibly).
#'
#' @export
#' @family sia
#'
#' @examples
#' sia_info()
sia_info <- function() {
  final_range <- range(sia_available_years$final)
  prelim_range <- sia_available_years$preliminary

  cli::cli_h1("SIA \u2014 Sistema de Informa\u00e7\u00f5es Ambulatoriais")

  cli::cli_text("")
  cli::cli_text("Fonte:          Minist\u00e9rio da Sa\u00fade / DATASUS")
  cli::cli_text("Acesso:         FTP DATASUS")
  cli::cli_text("Documento base: Boletim de Produ\u00e7\u00e3o Ambulatorial (BPA) / APAC")
  cli::cli_text("Granularidade:  Mensal (um arquivo por tipo/UF/m\u00eas)")

  cli::cli_h2("Dados dispon\u00edveis")
  cli::cli_bullets(c(
    "*" = "{.fun sia_data}: Microdados de produ\u00e7\u00e3o ambulatorial",
    " " = "  Anos definitivos:   {final_range[1]}\u2013{final_range[2]}",
    " " = "  Anos preliminares:  {prelim_range}",
    "*" = "{.fun sia_variables}: Lista de vari\u00e1veis dispon\u00edveis",
    "*" = "{.fun sia_dictionary}: Dicion\u00e1rio completo com categorias"
  ))

  cli::cli_h2("Tipos de arquivo")
  for (i in seq_len(nrow(sia_valid_types))) {
    cli::cli_text(
      "  {sia_valid_types$code[i]}   {sia_valid_types$name[i]} \u2014 {sia_valid_types$description[i]}"
    )
  }

  cli::cli_h2("Vari\u00e1veis-chave (PA)")
  cli::cli_text("  PA_PROC_ID  Procedimento (c\u00f3digo SIGTAP)")
  cli::cli_text("  PA_CIDPRI   Diagn\u00f3stico principal (CID-10)")
  cli::cli_text("  PA_SEXO     Sexo (1=Masc, 2=Fem)")
  cli::cli_text("  PA_IDADE    Idade do paciente")
  cli::cli_text("  PA_VALAPR   Valor aprovado (R$)")

  cli::cli_text("")
  cli::cli_alert_info(
    "Dados mensais: use {.arg month} em {.fun sia_data} para selecionar meses."
  )
  cli::cli_alert_info(
    "Use {.arg type} em {.fun sia_data} para selecionar o tipo (padr\u00e3o: PA)."
  )

  invisible(list(
    name = "SIA - Sistema de Informa\u00e7\u00f5es Ambulatoriais",
    source = "DATASUS FTP",
    final_years = sia_available_years$final,
    preliminary_years = sia_available_years$preliminary,
    n_variables = nrow(sia_variables_metadata),
    n_types = nrow(sia_valid_types),
    url = "ftp://ftp.datasus.gov.br/dissemin/publicos/SIASUS/"
  ))
}


#' List SIA Variables
#'
#' Returns a tibble with available variables in the SIA microdata (PA type),
#' including descriptions and value types.
#'
#' @param type Character. File type to show variables for. Currently only
#'   \code{"PA"} is fully documented. Default: \code{"PA"}.
#' @param search Character. Optional search term to filter variables by
#'   name or description. Case-insensitive and accent-insensitive.
#'
#' @return A tibble with columns: variable, description, type, section.
#'
#' @export
#' @family sia
#'
#' @examples
#' sia_variables()
#' sia_variables(search = "sexo")
#' sia_variables(search = "procedimento")
sia_variables <- function(type = "PA", search = NULL) {
  result <- sia_variables_metadata

  result <- .search_metadata(result, search, c("variable", "description"))

  result
}


#' SIA Data Dictionary
#'
#' Returns a tibble with the complete data dictionary for the SIA,
#' including variable descriptions and category labels.
#'
#' @param variable Character. If provided, returns dictionary for a specific
#'   variable only. Default: NULL (returns all variables).
#'
#' @return A tibble with columns: variable, description, code, label.
#'
#' @export
#' @family sia
#'
#' @examples
#' sia_dictionary()
#' sia_dictionary("PA_SEXO")
#' sia_dictionary("PA_RACACOR")
sia_dictionary <- function(variable = NULL) {
  result <- sia_dictionary_data

  if (!is.null(variable)) {
    variable <- toupper(variable)
    result <- result[result$variable %in% variable, ]

    if (nrow(result) == 0) {
      cli::cli_warn(c(
        "Variable {.val {variable}} not found in SIA dictionary.",
        "i" = "Use {.code sia_dictionary()} to see all available variables."
      ))
    }
  }

  result
}


#' @noRd
.sia_download_loop <- function(year, month, target_ufs, type, cache, cache_dir) {
  combinations <- expand.grid(
    year = year, month = month, uf = target_ufs,
    stringsAsFactors = FALSE
  )

  n_combos <- nrow(combinations)
  if (n_combos > 1) {
    cli::cli_inform(c(
      "i" = "Downloading {n_combos} file(s) ({length(unique(combinations$uf))} UF(s) x {length(unique(combinations$year))} year(s) x {length(unique(combinations$month))} month(s))..."
    ))
  }

  labels <- paste(type, combinations$uf,
                  paste0(combinations$year, "/", sprintf("%02d", combinations$month)))

  results <- .map_parallel(seq_len(n_combos), .delay = 0.5, function(i) {
    yr <- combinations$year[i]
    mo <- combinations$month[i]
    st <- combinations$uf[i]

    tryCatch({
      .sia_download_and_read(yr, mo, st, type = type,
                             cache = cache, cache_dir = cache_dir)
    }, error = function(e) {
      NULL
    })
  })

  succeeded <- !vapply(results, is.null, logical(1))
  failed_labels <- labels[!succeeded]
  results <- results[succeeded]

  if (length(results) == 0) {
    cli::cli_abort(
      "No data could be downloaded for the requested year(s)/month(s)/UF(s)."
    )
  }

  list(data = dplyr::bind_rows(results), failed_labels = failed_labels)
}


#' Apply procedure and diagnosis filters to SIA data
#' @noRd
.sia_apply_filters <- function(results, procedure, diagnosis) {
  if (!is.null(procedure)) {
    proc_pattern <- stringr::str_c(
      "^(", stringr::str_c(procedure, collapse = "|"), ")"
    )
    if ("PA_PROC_ID" %in% names(results)) {
      results <- results[grepl(proc_pattern, results$PA_PROC_ID), ]
    } else {
      cli::cli_warn(
        "Column {.var PA_PROC_ID} not found in data. Cannot filter by procedure."
      )
    }
  }

  if (!is.null(diagnosis)) {
    diag_pattern <- stringr::str_c(
      "^(", stringr::str_c(diagnosis, collapse = "|"), ")"
    )
    if ("PA_CIDPRI" %in% names(results)) {
      results <- results[grepl(diag_pattern, results$PA_CIDPRI), ]
    } else {
      cli::cli_warn(
        "Column {.var PA_CIDPRI} not found in data. Cannot filter by diagnosis."
      )
    }
  }

  results
}


#' Download SIA Outpatient Production Microdata
#'
#' Downloads and returns outpatient production microdata from DATASUS FTP.
#' Each row represents one outpatient production record.
#' Data is organized monthly -- one .dbc file per type, state (UF), and month.
#'
#' @param year Integer. Year(s) of the data. Required.
#' @param type Character. File type to download. Default: \code{"PA"}
#'   (outpatient production). See \code{\link{sia_info}()} for all 13 types.
#' @param month Integer. Month(s) of the data (1-12). If NULL (default),
#'   downloads all 12 months. Example: \code{1} (January), \code{1:6}
#'   (first semester).
#' @param vars Character vector. Variables to keep. If NULL (default),
#'   returns all available variables. Use \code{\link{sia_variables}()} to see
#'   available variables.
#' @param uf Character. Two-letter state abbreviation(s) to download.
#'   If NULL (default), downloads all 27 states.
#'   Example: \code{"SP"}, \code{c("SP", "RJ")}.
#' @param procedure Character. SIGTAP procedure code pattern(s) to filter by
#'   (\code{PA_PROC_ID}). Supports partial matching (prefix).
#'   If NULL (default), returns all procedures.
#'   Example: \code{"0301"} (consultations).
#' @param diagnosis Character. CID-10 code pattern(s) to filter by principal
#'   diagnosis (\code{PA_CIDPRI}). Supports partial matching (prefix).
#'   If NULL (default), returns all diagnoses.
#'   Example: \code{"J"} (respiratory diseases).
#' @param parse Logical. If TRUE (default), converts columns to
#'   appropriate types (integer, double, Date) based on the variable
#'   metadata. Use \code{\link{sia_variables}()} to see the target type for each
#'   variable. Set to FALSE for backward-compatible all-character output.
#' @param col_types Named list. Override the default type for specific
#'   columns. Names are column names, values are type strings:
#'   \code{"character"}, \code{"integer"}, \code{"double"},
#'   \code{"date_dmy"}, \code{"date_ymd"}, \code{"date_ym"}, \code{"date"}.
#'   Example: \code{list(PA_VALAPR = "character")} to keep PA_VALAPR as character.
#' @param cache Logical. If TRUE (default), caches downloaded data for
#'   faster future access.
#' @param cache_dir Character. Directory for caching. Default:
#'   \code{tools::R_user_dir("healthbR", "cache")}.
#' @param lazy Logical. If TRUE, returns a lazy query object instead of a
#'   tibble. Requires the \pkg{arrow} package. The lazy object supports
#'   dplyr verbs (filter, select, mutate, etc.) which are pushed down
#'   to the query engine before collecting into memory. Call
#'   \code{dplyr::collect()} to materialize the result. Default: FALSE.
#' @param backend Character. Backend for lazy evaluation: \code{"arrow"}
#'   (default) or \code{"duckdb"}. Only used when \code{lazy = TRUE}.
#'   DuckDB backend requires the \pkg{duckdb} package.
#'
#' @return A tibble with outpatient production microdata. Includes columns
#'   \code{year}, \code{month}, and \code{uf_source} to identify the source
#'   when multiple years/months/states are combined.
#'
#' @details
#' Data is downloaded from DATASUS FTP as .dbc files (one per type/state/month).
#' The .dbc format is decompressed internally using vendored C code from the
#' blast library. No external dependencies are required.
#'
#' SIA data is monthly, so downloading an entire year for all states requires
#' 324 files (27 UFs x 12 months) per type. Use \code{uf} and \code{month}
#' to limit downloads.
#'
#' The SIA has 13 file types. The default \code{"PA"} (outpatient production)
#' is the most commonly used. Use \code{\link{sia_info}()} to see all types.
#'
#' ## Parallel downloads
#' When downloading multiple files (e.g., several months or states), install
#' \pkg{furrr} and \pkg{future} and set a parallel plan to speed up downloads:
#' `future::plan(future::multisession, workers = 4)`. See
#' `vignette("healthbR")` for details.
#'
#' @export
#' @family sia
#'
#' @seealso \code{\link{sia_info}()} for file type descriptions,
#'   \code{\link{censo_populacao}()} for population denominators.
#'
#' @examplesIf interactive()
#' # all outpatient production in Acre, January 2022
#' ac_jan <- sia_data(year = 2022, month = 1, uf = "AC")
#'
#' # filter by procedure code
#' consult <- sia_data(year = 2022, month = 1, uf = "AC",
#'                     procedure = "0301")
#'
#' # filter by diagnosis (CID-10)
#' resp <- sia_data(year = 2022, month = 1, uf = "AC",
#'                  diagnosis = "J")
#'
#' # only key variables
#' sia_data(year = 2022, month = 1, uf = "AC",
#'          vars = c("PA_PROC_ID", "PA_CIDPRI", "PA_SEXO",
#'                   "PA_IDADE", "PA_VALAPR"))
#'
#' # different file type (APAC Medicamentos)
#' med <- sia_data(year = 2022, month = 1, uf = "AC", type = "AM")
sia_data <- function(year, type = "PA", month = NULL, vars = NULL, uf = NULL,
                     procedure = NULL, diagnosis = NULL,
                     parse = TRUE, col_types = NULL,
                     cache = TRUE, cache_dir = NULL,
                     lazy = FALSE, backend = c("arrow", "duckdb")) {

  # validate inputs
  year <- .sia_validate_year(year)
  type <- .sia_validate_type(type)
  month <- .validate_month(month)
  if (!is.null(uf)) uf <- .sia_validate_uf(uf)
  if (!is.null(vars)) .sia_validate_vars(vars)

  # determine UFs to download
  target_ufs <- if (!is.null(uf)) toupper(uf) else sia_uf_list

  # compute lazy args once
  cache_dir_resolved <- .sia_cache_dir(cache_dir)
  lazy_filters <- list(year = year, uf_source = target_ufs)
  if (!is.null(month)) lazy_filters$month <- as.integer(month)
  lazy_select <- if (!is.null(vars)) unique(c("year", "month", "uf_source", vars)) else NULL

  # pre-download lazy check
  ds <- .try_lazy_cache(lazy, backend, cache_dir_resolved, "sia_data",
                        lazy_filters, lazy_select, parse = parse)
  if (!is.null(ds)) return(ds)

  # download, bind, and collect failures
  dl <- .sia_download_loop(year, month, target_ufs, type, cache, cache_dir)
  results <- dl$data
  failed_labels <- dl$failed_labels

  # parse column types
  if (isTRUE(parse) && !isTRUE(lazy)) {
    type_spec <- .build_type_spec(sia_variables_metadata)
    results <- .parse_columns(results, type_spec, col_types = col_types)
  }

  # apply procedure/diagnosis filters
  results <- .sia_apply_filters(results, procedure, diagnosis)

  .data_return(results, lazy, backend, cache_dir_resolved, "sia_data",
               lazy_filters, lazy_select, failed_labels, "SIA")
}


#' Show SIA Cache Status
#'
#' Shows information about cached SIA data files.
#'
#' @param cache_dir Character. Cache directory path. Default:
#'   \code{tools::R_user_dir("healthbR", "cache")}.
#'
#' @return A tibble with cache file information (invisibly).
#'
#' @export
#' @family sia
#'
#' @examples
#' sia_cache_status()
sia_cache_status <- function(cache_dir = NULL) {
  .cache_status("sia", "SIA", .sia_cache_dir(cache_dir))
}


#' Clear SIA Cache
#'
#' Deletes cached SIA data files.
#'
#' @param cache_dir Character. Cache directory path. Default:
#'   \code{tools::R_user_dir("healthbR", "cache")}.
#'
#' @return Invisible NULL.
#'
#' @export
#' @family sia
#'
#' @examplesIf interactive()
#' sia_clear_cache()
sia_clear_cache <- function(cache_dir = NULL) {
  .clear_cache("sia", "SIA", .sia_cache_dir(cache_dir))
}
