# sinan functions for healthbR package
# functions to access notifiable diseases data from the SINAN (Sistema de
# Informacao de Agravos de Notificacao) via DATASUS FTP

# ============================================================================
# internal validation functions
# ============================================================================

#' Validate SINAN year parameter
#' @noRd
.sinan_validate_year <- function(year, status = "all") {
  .validate_year(year, sinan_years(status = status),
                 years_fn_hint = "sinan_years(status = 'all')")
}


#' Validate SINAN disease parameter
#' @noRd
.sinan_validate_disease <- function(disease) {
  disease <- toupper(disease)
  valid_codes <- sinan_valid_diseases$code

  if (!disease %in% valid_codes) {
    cli::cli_abort(c(
      "Invalid disease code: {.val {disease}}.",
      "i" = "Valid codes: {.val {valid_codes}}",
      "i" = "Use {.code sinan_diseases()} to see all available diseases."
    ))
  }

  disease
}


#' Validate SINAN vars parameter (warning only)
#' @noRd
.sinan_validate_vars <- function(vars) {
  known_vars <- sinan_variables_metadata$variable
  invalid <- vars[!vars %in% known_vars]

  if (length(invalid) > 0) {
    cli::cli_warn(c(
      "Variable(s) {.val {invalid}} not in known SINAN variables.",
      "i" = "Use {.code sinan_variables()} to see available variables.",
      "i" = "Proceeding anyway (variables will be dropped if not found)."
    ))
  }
}


# ============================================================================
# internal helper functions
# ============================================================================

#' Build FTP URL for SINAN .dbc file
#' @noRd
.sinan_build_ftp_url <- function(year, disease) {
  year <- as.integer(year)
  disease <- toupper(disease)

  if (year < 2007L) {
    cli::cli_abort(
      "Year {.val {year}} is not supported. SINAN data starts in 2007."
    )
  }

  # 2-digit year
  yy <- sprintf("%02d", year %% 100)

  # determine final vs preliminary
  if (year %in% sinan_available_years$final) {
    subdir <- "FINAIS"
  } else if (year %in% sinan_available_years$preliminary) {
    subdir <- "PRELIM"
  } else {
    cli::cli_abort("Year {.val {year}} not available in SINAN.")
  }

  stringr::str_c(
    "ftp://ftp.datasus.gov.br/dissemin/publicos/SINAN/DADOS/",
    subdir, "/", disease, "BR", yy, ".dbc"
  )
}


#' Get/create SINAN cache directory
#' @noRd
.sinan_cache_dir <- function(cache_dir = NULL) {
  .module_cache_dir("sinan", cache_dir)
}


#' Download and read a SINAN .dbc file for one disease/year
#'
#' Returns a tibble with `year` and `disease` columns already added.
#' Uses partitioned cache (Hive-style) when arrow is available, with
#' flat cache as migration fallback.
#'
#' @noRd
.sinan_download_and_read <- function(year, disease, cache = TRUE,
                                     cache_dir = NULL) {
  cache_dir <- .sinan_cache_dir(cache_dir)
  dataset_name <- "sinan_data"
  target_year <- as.integer(year)
  target_disease <- disease

  # 1. check partitioned cache first (preferred path)
  if (isTRUE(cache) && .has_arrow() &&
      .has_partitioned_cache(cache_dir, dataset_name)) {
    ds <- arrow::open_dataset(file.path(cache_dir, dataset_name))
    cached <- ds |>
      dplyr::filter(.data$disease == target_disease,
                     .data$year == target_year) |>
      dplyr::collect()
    if (nrow(cached) > 0) return(cached)
  }

  # 2. download from FTP
  url <- .sinan_build_ftp_url(year, disease)
  temp_dbc <- tempfile(fileext = ".dbc")
  on.exit(if (file.exists(temp_dbc)) file.remove(temp_dbc), add = TRUE)

  cli::cli_inform(c(
    "i" = "Downloading SINAN data: {disease} {year}..."
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
  data$disease <- target_disease
  cols <- names(data)
  data <- data[, c("year", "disease", setdiff(cols, c("year", "disease")))]

  # 4. write to partitioned cache
  if (isTRUE(cache)) {
    .cache_append_partitioned(data, cache_dir, dataset_name,
                              c("disease", "year"))
  }

  data
}


# ============================================================================
# exported functions
# ============================================================================

#' List Available SINAN Years
#'
#' Returns an integer vector with years for which notifiable diseases microdata
#' are available from DATASUS FTP.
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
#' @family sinan
#'
#' @examples
#' sinan_years()
#' sinan_years(status = "all")
sinan_years <- function(status = "final") {
  status <- match.arg(status, c("final", "preliminary", "all"))

  switch(status,
    "final" = sinan_available_years$final,
    "preliminary" = sinan_available_years$preliminary,
    "all" = sort(c(sinan_available_years$final, sinan_available_years$preliminary))
  )
}


#' SINAN Module Information
#'
#' Displays information about the Notifiable Diseases Information System (SINAN),
#' including data sources, available years, diseases, and usage guidance.
#'
#' @return A list with module information (invisibly).
#'
#' @export
#' @family sinan
#'
#' @examples
#' sinan_info()
sinan_info <- function() {
  final_range <- range(sinan_available_years$final)
  prelim_range <- range(sinan_available_years$preliminary)
  n_diseases <- nrow(sinan_valid_diseases)

  cli::cli_h1("SINAN \u2014 Sistema de Informa\u00e7\u00e3o de Agravos de Notifica\u00e7\u00e3o")

  cli::cli_text("")
  cli::cli_text("Fonte:          Minist\u00e9rio da Sa\u00fade / DATASUS")
  cli::cli_text("Acesso:         FTP DATASUS")
  cli::cli_text("Cobertura:      Nacional (um arquivo por agravo por ano)")
  cli::cli_text("Agravos:        {n_diseases} doen\u00e7as de notifica\u00e7\u00e3o compuls\u00f3ria")

  cli::cli_h2("Dados dispon\u00edveis")
  cli::cli_bullets(c(
    "*" = "{.fun sinan_data}: Microdados de agravos notific\u00e1veis",
    " " = "  Anos definitivos:   {final_range[1]}\u2013{final_range[2]}",
    " " = "  Anos preliminares:  {prelim_range[1]}\u2013{prelim_range[2]}",
    "*" = "{.fun sinan_diseases}: Lista de agravos dispon\u00edveis",
    "*" = "{.fun sinan_variables}: Lista de vari\u00e1veis dispon\u00edveis",
    "*" = "{.fun sinan_dictionary}: Dicion\u00e1rio completo com categorias"
  ))

  cli::cli_h2("Agravos mais comuns")
  cli::cli_text("  DENG    Dengue")
  cli::cli_text("  CHIK    Chikungunya")
  cli::cli_text("  ZIKA    Zika")
  cli::cli_text("  TUBE    Tuberculose")
  cli::cli_text("  HANS    Hansen\u00edase")
  cli::cli_text("  HEPA    Hepatites virais")
  cli::cli_text("  SIFA    S\u00edfilis adquirida")

  cli::cli_h2("Vari\u00e1veis-chave")
  cli::cli_text("  DT_NOTIFIC  Data da notifica\u00e7\u00e3o")
  cli::cli_text("  ID_AGRAVO   C\u00f3digo do agravo (CID-10)")
  cli::cli_text("  ID_MUNICIP  Munic\u00edpio de notifica\u00e7\u00e3o (IBGE)")
  cli::cli_text("  CS_SEXO     Sexo")
  cli::cli_text("  NU_IDADE_N  Idade (codificada)")
  cli::cli_text("  CS_RACA     Ra\u00e7a/cor")
  cli::cli_text("  CLASSI_FIN  Classifica\u00e7\u00e3o final")
  cli::cli_text("  EVOLUCAO    Evolu\u00e7\u00e3o do caso")

  cli::cli_text("")
  cli::cli_alert_info(
    "Arquivos s\u00e3o nacionais. Filtre por UF usando SG_UF_NOT ou ID_MUNICIP."
  )

  invisible(list(
    name = "SINAN - Sistema de Informa\u00e7\u00e3o de Agravos de Notifica\u00e7\u00e3o",
    source = "DATASUS FTP",
    final_years = sinan_available_years$final,
    preliminary_years = sinan_available_years$preliminary,
    n_diseases = n_diseases,
    n_variables = nrow(sinan_variables_metadata),
    url = "ftp://ftp.datasus.gov.br/dissemin/publicos/SINAN/"
  ))
}


#' List Available SINAN Diseases
#'
#' Returns a tibble with all notifiable diseases (agravos) available in SINAN,
#' including codes, names, and descriptions.
#'
#' @param search Character. Optional search term to filter diseases by
#'   code, name, or description. Case-insensitive and accent-insensitive.
#'
#' @return A tibble with columns: code, name, description.
#'
#' @export
#' @family sinan
#'
#' @examples
#' sinan_diseases()
#' sinan_diseases(search = "dengue")
#' sinan_diseases(search = "sifilis")
sinan_diseases <- function(search = NULL) {
  result <- sinan_valid_diseases

  result <- .search_metadata(result, search, c("code", "name", "description"))

  result
}


#' List SINAN Variables
#'
#' Returns a tibble with available variables in the SINAN microdata,
#' including descriptions and value types.
#'
#' @param disease Character. Disease code (e.g., "DENG"). Currently not used
#'   for filtering but reserved for future disease-specific variables.
#'   Default: "DENG".
#' @param search Character. Optional search term to filter variables by
#'   name or description. Case-insensitive and accent-insensitive.
#'
#' @return A tibble with columns: variable, description, type, section.
#'
#' @export
#' @family sinan
#'
#' @examples
#' sinan_variables()
#' sinan_variables(search = "sexo")
#' sinan_variables(search = "municipio")
sinan_variables <- function(disease = "DENG", search = NULL) {
  result <- sinan_variables_metadata

  result <- .search_metadata(result, search, c("variable", "description"))

  result
}


#' SINAN Data Dictionary
#'
#' Returns a tibble with the complete data dictionary for the SINAN,
#' including variable descriptions and category labels.
#'
#' @param variable Character. If provided, returns dictionary for a specific
#'   variable only. Default: NULL (returns all variables).
#'
#' @return A tibble with columns: variable, description, code, label.
#'
#' @export
#' @family sinan
#'
#' @examples
#' sinan_dictionary()
#' sinan_dictionary("CS_SEXO")
#' sinan_dictionary("EVOLUCAO")
sinan_dictionary <- function(variable = NULL) {
  result <- sinan_dictionary_data

  if (!is.null(variable)) {
    variable <- toupper(variable)
    result <- result[result$variable %in% variable, ]

    if (nrow(result) == 0) {
      cli::cli_warn(c(
        "Variable {.val {variable}} not found in SINAN dictionary.",
        "i" = "Use {.code sinan_dictionary()} to see all available variables."
      ))
    }
  }

  result
}


#' Download SINAN Notifiable Disease Microdata
#'
#' Downloads and returns notifiable disease microdata from DATASUS FTP.
#' Each row represents one notification record (Ficha de Notificacao).
#' Data is downloaded as national .dbc files (one file per disease per year),
#' decompressed internally, and returned as a tibble.
#'
#' @param year Integer. Year(s) of the data. Required.
#' @param disease Character. Disease code to download. Default: `"DENG"`
#'   (Dengue). Use [sinan_diseases()] to see all available codes.
#' @param vars Character vector. Variables to keep. If NULL (default),
#'   returns all available variables. Use [sinan_variables()] to see
#'   available variables.
#' @param parse Logical. If TRUE (default), converts columns to
#'   appropriate types (integer, double, Date) based on the variable
#'   metadata. Use [sinan_variables()] to see the target type for each
#'   variable. Set to FALSE for backward-compatible all-character output.
#' @param col_types Named list. Override the default type for specific
#'   columns. Names are column names, values are type strings:
#'   \code{"character"}, \code{"integer"}, \code{"double"},
#'   \code{"date_dmy"}, \code{"date_ymd"}, \code{"date_ym"}, \code{"date"}.
#'   Example: \code{list(DT_NOTIFIC = "character")} to keep DT_NOTIFIC as character.
#' @param cache Logical. If TRUE (default), caches downloaded data for
#'   faster future access.
#' @param cache_dir Character. Directory for caching. Default:
#'   `tools::R_user_dir("healthbR", "cache")`.
#' @param lazy Logical. If TRUE, returns a lazy query object instead of a
#'   tibble. Requires the \pkg{arrow} package. The lazy object supports
#'   dplyr verbs (filter, select, mutate, etc.) which are pushed down
#'   to the query engine before collecting into memory. Call
#'   \code{dplyr::collect()} to materialize the result. Default: FALSE.
#' @param backend Character. Backend for lazy evaluation: \code{"arrow"}
#'   (default) or \code{"duckdb"}. Only used when \code{lazy = TRUE}.
#'   DuckDB backend requires the \pkg{duckdb} package.
#'
#' @return A tibble with notifiable disease microdata. Includes columns
#'   `year` and `disease` to identify the source when multiple years are
#'   combined.
#'
#' @details
#' SINAN files are national (not per-state). Each file contains all
#' notifications for a given disease in a given year across all of Brazil.
#' To filter by state, use the `SG_UF_NOT` (UF of notification) or
#' `ID_MUNICIP` (municipality code) columns after download.
#'
#' Data is downloaded from DATASUS FTP as .dbc files. The .dbc format is
#' decompressed internally using vendored C code from the blast library.
#' No external dependencies are required.
#'
#' @export
#' @family sinan
#'
#' @examplesIf interactive()
#' # dengue notifications, 2022
#' dengue_2022 <- sinan_data(year = 2022)
#'
#' # tuberculosis, 2020-2022
#' tb <- sinan_data(year = 2020:2022, disease = "TUBE")
#'
#' # only key variables
#' sinan_data(year = 2022, disease = "DENG",
#'            vars = c("DT_NOTIFIC", "CS_SEXO", "NU_IDADE_N",
#'                     "CS_RACA", "ID_MUNICIP", "CLASSI_FIN"))
sinan_data <- function(year, disease = "DENG", vars = NULL,
                       parse = TRUE, col_types = NULL,
                       cache = TRUE, cache_dir = NULL,
                       lazy = FALSE, backend = c("arrow", "duckdb")) {

  # validate inputs
  year <- .sinan_validate_year(year)
  disease <- .sinan_validate_disease(disease)
  if (!is.null(vars)) .sinan_validate_vars(vars)

  # compute lazy args once
  cache_dir_resolved <- .sinan_cache_dir(cache_dir)
  lazy_filters <- list(year = year, disease = toupper(disease))
  lazy_select <- if (!is.null(vars)) unique(c("year", "disease", vars)) else NULL

  # pre-download lazy check
  ds <- .try_lazy_cache(lazy, backend, cache_dir_resolved, "sinan_data",
                        lazy_filters, lazy_select, parse = parse)
  if (!is.null(ds)) return(ds)

  n_years <- length(year)
  if (n_years > 1) {
    cli::cli_inform(c(
      "i" = "Downloading {n_years} file(s) ({disease}, {n_years} year(s))..."
    ))
  }

  # download and read each year
  labels <- paste(disease, year)

  results <- .map_parallel(year, .delay = 0.5, function(yr) {
    tryCatch({
      .sinan_download_and_read(yr, disease, cache = cache,
                               cache_dir = cache_dir)
    }, error = function(e) {
      NULL
    })
  })

  # remove NULLs and bind
  succeeded <- !vapply(results, is.null, logical(1))
  failed_labels <- labels[!succeeded]
  results <- results[succeeded]

  if (length(results) == 0) {
    cli::cli_abort(
      "No data could be downloaded for the requested year(s)/disease."
    )
  }

  results <- dplyr::bind_rows(results)

  # parse column types
  if (isTRUE(parse) && !isTRUE(lazy)) {
    type_spec <- .build_type_spec(sinan_variables_metadata)
    results <- .parse_columns(results, type_spec, col_types = col_types)
  }

  .data_return(results, lazy, backend, cache_dir_resolved, "sinan_data",
               lazy_filters, lazy_select, failed_labels, "SINAN")
}


#' Show SINAN Cache Status
#'
#' Shows information about cached SINAN data files.
#'
#' @param cache_dir Character. Cache directory path. Default:
#'   `tools::R_user_dir("healthbR", "cache")`.
#'
#' @return A tibble with cache file information (invisibly).
#'
#' @export
#' @family sinan
#'
#' @examples
#' sinan_cache_status()
sinan_cache_status <- function(cache_dir = NULL) {
  .cache_status("sinan", "SINAN", .sinan_cache_dir(cache_dir))
}


#' Clear SINAN Cache
#'
#' Deletes cached SINAN data files.
#'
#' @param cache_dir Character. Cache directory path. Default:
#'   `tools::R_user_dir("healthbR", "cache")`.
#'
#' @return Invisible NULL.
#'
#' @export
#' @family sinan
#'
#' @examplesIf interactive()
#' sinan_clear_cache()
sinan_clear_cache <- function(cache_dir = NULL) {
  .clear_cache("sinan", "SINAN", .sinan_cache_dir(cache_dir))
}
