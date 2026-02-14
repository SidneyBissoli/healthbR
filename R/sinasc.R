# sinasc functions for healthbR package
# functions to access live birth microdata from the SINASC (Sistema de
# Informacoes sobre Nascidos Vivos) via DATASUS FTP

# ============================================================================
# internal validation functions
# ============================================================================

#' Validate SINASC year parameter
#' @noRd
.sinasc_validate_year <- function(year, status = "all") {
  if (is.null(year) || length(year) == 0) {
    cli::cli_abort("{.arg year} is required.")
  }

  year <- as.integer(year)
  available <- sinasc_years(status = status)
  invalid <- year[!year %in% available]

  if (length(invalid) > 0) {
    cli::cli_abort(c(
      "Year(s) {.val {invalid}} not available.",
      "i" = "Available years: {.val {range(available)[[1]]}}--{.val {range(available)[[2]]}}",
      "i" = "Use {.code sinasc_years(status = 'all')} to see all options."
    ))
  }

  year
}


#' Validate SINASC UF parameter
#' @noRd
.sinasc_validate_uf <- function(uf) {
  uf <- toupper(uf)
  invalid <- uf[!uf %in% sinasc_uf_list]

  if (length(invalid) > 0) {
    cli::cli_abort(c(
      "Invalid UF abbreviation(s): {.val {invalid}}.",
      "i" = "Valid values: {.val {sinasc_uf_list}}"
    ))
  }

  uf
}


#' Validate SINASC vars parameter (warning only)
#' @noRd
.sinasc_validate_vars <- function(vars) {
  known_vars <- sinasc_variables_metadata$variable
  invalid <- vars[!vars %in% known_vars]

  if (length(invalid) > 0) {
    cli::cli_warn(c(
      "Variable(s) {.val {invalid}} not in known SINASC variables.",
      "i" = "Use {.code sinasc_variables()} to see available variables.",
      "i" = "Proceeding anyway (variables will be dropped if not found)."
    ))
  }
}


# ============================================================================
# internal helper functions
# ============================================================================

#' Build FTP URL for SINASC .dbc file
#' @noRd
.sinasc_build_ftp_url <- function(year, uf) {
  if (year >= 1996) {
    # DN{UF}{YYYY}.dbc
    stringr::str_c(
      "ftp://ftp.datasus.gov.br/dissemin/publicos/SINASC/1996_/Dados/DNRES/",
      "DN", uf, year, ".dbc"
    )
  } else {
    cli::cli_abort(
      "Year {.val {year}} is not supported. SINASC data starts in 1996."
    )
  }
}


#' Get/create SINASC cache directory
#' @noRd
.sinasc_cache_dir <- function(cache_dir = NULL) {
  .module_cache_dir("sinasc", cache_dir)
}


#' Download and read a SINASC .dbc file for one UF/year
#'
#' Returns a tibble with `year` and `uf_source` columns already added.
#' Uses partitioned cache when arrow is available.
#' @noRd
.sinasc_download_and_read <- function(year, uf, cache = TRUE, cache_dir = NULL) {
  cache_dir <- .sinasc_cache_dir(cache_dir)
  dataset_name <- "sinasc_data"
  target_year <- as.integer(year)
  target_uf <- uf

  # 1. check partitioned cache
  if (isTRUE(cache) && .has_arrow() &&
      .has_partitioned_cache(cache_dir, dataset_name)) {
    ds <- arrow::open_dataset(file.path(cache_dir, dataset_name))
    cached <- ds |>
      dplyr::filter(.data$uf_source == target_uf,
                     .data$year == target_year) |>
      dplyr::collect()
    if (nrow(cached) > 0) return(cached)
  }

  # 2. flat cache fallback
  if (isTRUE(cache)) {
    flat_base <- stringr::str_c("sinasc_", uf, "_", year)
    flat_cached <- .cache_read(cache_dir, flat_base)
    if (!is.null(flat_cached)) {
      flat_cached$year <- target_year
      flat_cached$uf_source <- target_uf
      cols <- names(flat_cached)
      flat_cached <- flat_cached[, c("year", "uf_source",
                                      setdiff(cols, c("year", "uf_source")))]
      return(flat_cached)
    }
  }

  # 3. download from FTP
  url <- .sinasc_build_ftp_url(year, uf)
  temp_dbc <- tempfile(fileext = ".dbc")
  on.exit(if (file.exists(temp_dbc)) file.remove(temp_dbc), add = TRUE)

  cli::cli_inform(c(
    "i" = "Downloading SINASC data: {uf} {year}..."
  ))

  .datasus_download(url, temp_dbc)

  if (file.size(temp_dbc) < 100) {
    cli::cli_abort(c(
      "Downloaded file appears corrupted (too small).",
      "x" = "File size: {file.size(temp_dbc)} bytes",
      "i" = "The DATASUS FTP may be experiencing issues. Try again later."
    ))
  }

  data <- .read_dbc(temp_dbc)

  # add partition columns
  data$year <- target_year
  data$uf_source <- target_uf
  cols <- names(data)
  data <- data[, c("year", "uf_source", setdiff(cols, c("year", "uf_source")))]

  # 4. write to partitioned cache
  if (isTRUE(cache)) {
    .cache_append_partitioned(data, cache_dir, dataset_name,
                              c("uf_source", "year"))
  }

  data
}


# ============================================================================
# exported functions
# ============================================================================

#' List Available SINASC Years
#'
#' Returns an integer vector with years for which live birth microdata are
#' available from DATASUS FTP.
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
#' @family sinasc
#'
#' @examples
#' sinasc_years()
#' sinasc_years(status = "all")
sinasc_years <- function(status = "final") {
  status <- match.arg(status, c("final", "preliminary", "all"))

  switch(status,
    "final" = sinasc_available_years$final,
    "preliminary" = sinasc_available_years$preliminary,
    "all" = sort(c(sinasc_available_years$final, sinasc_available_years$preliminary))
  )
}


#' SINASC Module Information
#'
#' Displays information about the Live Birth Information System (SINASC),
#' including data sources, available years, and usage guidance.
#'
#' @return A list with module information (invisibly).
#'
#' @export
#' @family sinasc
#'
#' @examples
#' sinasc_info()
sinasc_info <- function() {
  final_range <- range(sinasc_available_years$final)
  prelim_range <- range(sinasc_available_years$preliminary)

  cli::cli_h1("SINASC \u2014 Sistema de Informa\u00e7\u00f5es sobre Nascidos Vivos")

  cli::cli_text("")
  cli::cli_text("Fonte:          Minist\u00e9rio da Sa\u00fade / DATASUS")
  cli::cli_text("Acesso:         FTP DATASUS")
  cli::cli_text("Documento base: Declara\u00e7\u00e3o de Nascido Vivo (DN)")

  cli::cli_h2("Dados dispon\u00edveis")
  cli::cli_bullets(c(
    "*" = "{.fun sinasc_data}: Microdados de nascidos vivos",
    " " = "  Anos definitivos:   {final_range[1]}\u2013{final_range[2]}",
    " " = "  Anos preliminares:  {prelim_range[1]}\u2013{prelim_range[2]}",
    "*" = "{.fun sinasc_variables}: Lista de vari\u00e1veis dispon\u00edveis",
    "*" = "{.fun sinasc_dictionary}: Dicion\u00e1rio completo com categorias"
  ))

  cli::cli_h2("Vari\u00e1veis-chave")
  cli::cli_text("  DTNASC      Data de nascimento")
  cli::cli_text("  CODMUNRES   Munic\u00edpio de resid\u00eancia da m\u00e3e (IBGE)")
  cli::cli_text("  SEXO        Sexo")
  cli::cli_text("  PESO        Peso ao nascer (gramas)")
  cli::cli_text("  IDADEMAE    Idade da m\u00e3e")
  cli::cli_text("  GESTACAO    Semanas de gesta\u00e7\u00e3o")
  cli::cli_text("  PARTO       Tipo de parto")
  cli::cli_text("  CONSULTAS   Consultas pr\u00e9-natal")
  cli::cli_text("  CODANOMAL   Anomalia cong\u00eanita (CID-10)")

  cli::cli_text("")
  cli::cli_alert_info(
    "Use com {.fun censo_populacao} para calcular taxas de natalidade."
  )

  invisible(list(
    name = "SINASC - Sistema de Informa\u00e7\u00f5es sobre Nascidos Vivos",
    source = "DATASUS FTP",
    final_years = sinasc_available_years$final,
    preliminary_years = sinasc_available_years$preliminary,
    n_variables = nrow(sinasc_variables_metadata),
    url = "ftp://ftp.datasus.gov.br/dissemin/publicos/SINASC/"
  ))
}


#' List SINASC Variables
#'
#' Returns a tibble with available variables in the SINASC microdata,
#' including descriptions and value types.
#'
#' @param year Integer. If provided, returns variables available for that
#'   specific year (reserved for future use). Default: NULL.
#' @param search Character. Optional search term to filter variables by
#'   name or description. Case-insensitive.
#'
#' @return A tibble with columns: variable, description, type, section.
#'
#' @export
#' @family sinasc
#'
#' @examples
#' sinasc_variables()
#' sinasc_variables(search = "mae")
#' sinasc_variables(search = "parto")
sinasc_variables <- function(year = NULL, search = NULL) {
  result <- sinasc_variables_metadata

  if (!is.null(search)) {
    search_lower <- tolower(search)
    # strip accents for search matching
    search_ascii <- chartr(
      "\u00e0\u00e1\u00e2\u00e3\u00e4\u00e7\u00e8\u00e9\u00ea\u00eb\u00ec\u00ed\u00ee\u00ef\u00f2\u00f3\u00f4\u00f5\u00f6\u00f9\u00fa\u00fb\u00fc",
      "aaaaaceeeeiiiiooooouuuu",
      search_lower
    )
    match_idx <- grepl(search_lower, tolower(result$variable), fixed = TRUE) |
      grepl(search_lower, tolower(result$description), fixed = TRUE) |
      grepl(search_ascii, chartr(
        "\u00e0\u00e1\u00e2\u00e3\u00e4\u00e7\u00e8\u00e9\u00ea\u00eb\u00ec\u00ed\u00ee\u00ef\u00f2\u00f3\u00f4\u00f5\u00f6\u00f9\u00fa\u00fb\u00fc",
        "aaaaaceeeeiiiiooooouuuu",
        tolower(result$description)
      ), fixed = TRUE)
    result <- result[match_idx, ]
  }

  result
}


#' SINASC Data Dictionary
#'
#' Returns a tibble with the complete data dictionary for the SINASC,
#' including variable descriptions and category labels.
#'
#' @param variable Character. If provided, returns dictionary for a specific
#'   variable only. Default: NULL (returns all variables).
#'
#' @return A tibble with columns: variable, description, code, label.
#'
#' @export
#' @family sinasc
#'
#' @examples
#' sinasc_dictionary()
#' sinasc_dictionary("SEXO")
#' sinasc_dictionary("PARTO")
sinasc_dictionary <- function(variable = NULL) {
  result <- sinasc_dictionary_data

  if (!is.null(variable)) {
    variable <- toupper(variable)
    result <- result[result$variable %in% variable, ]

    if (nrow(result) == 0) {
      cli::cli_warn(c(
        "Variable {.val {variable}} not found in SINASC dictionary.",
        "i" = "Use {.code sinasc_dictionary()} to see all available variables."
      ))
    }
  }

  result
}


#' Download SINASC Live Birth Microdata
#'
#' Downloads and returns live birth microdata from DATASUS FTP.
#' Each row represents one live birth record (Declaracao de Nascido Vivo).
#' Data is downloaded per state (UF) as compressed .dbc files, decompressed
#' internally, and returned as a tibble.
#'
#' @param year Integer. Year(s) of the data. Required.
#' @param vars Character vector. Variables to keep. If NULL (default),
#'   returns all available variables. Use [sinasc_variables()] to see
#'   available variables.
#' @param uf Character. Two-letter state abbreviation(s) to download.
#'   If NULL (default), downloads all 27 states.
#'   Example: `"SP"`, `c("SP", "RJ")`.
#' @param anomaly Character. CID-10 code pattern(s) to filter by congenital
#'   anomaly (`CODANOMAL`). Supports partial matching (prefix).
#'   If NULL (default), returns all records.
#'   Example: `"Q90"` (Down syndrome), `"Q"` (all anomalies).
#' @param parse Logical. If TRUE (default), converts columns to
#'   appropriate types (integer, double, Date) based on the variable
#'   metadata. Use [sinasc_variables()] to see the target type for each
#'   variable. Set to FALSE for backward-compatible all-character output.
#' @param col_types Named list. Override the default type for specific
#'   columns. Names are column names, values are type strings:
#'   \code{"character"}, \code{"integer"}, \code{"double"},
#'   \code{"date_dmy"}, \code{"date_ymd"}, \code{"date_ym"}, \code{"date"}.
#'   Example: \code{list(PESO = "character")} to keep PESO as character.
#' @param cache Logical. If TRUE (default), caches downloaded data for
#'   faster future access.
#' @param cache_dir Character. Directory for caching. Default:
#'   `tools::R_user_dir("healthbR", "cache")`.
#'
#' @param lazy Logical. If TRUE, returns a lazy query object instead of a
#'   tibble. Requires the \pkg{arrow} package. The lazy object supports
#'   dplyr verbs (filter, select, mutate, etc.) which are pushed down
#'   to the query engine before collecting into memory. Call
#'   \code{dplyr::collect()} to materialize the result. Default: FALSE.
#' @param backend Character. Backend for lazy evaluation: \code{"arrow"}
#'   (default) or \code{"duckdb"}. Only used when \code{lazy = TRUE}.
#'   DuckDB backend requires the \pkg{duckdb} package.
#'
#' @return A tibble with live birth microdata. Includes columns `year`
#'   and `uf_source` to identify the source when multiple years/states
#'   are combined.
#'
#' @details
#' Data is downloaded from DATASUS FTP as .dbc files (one per state per year).
#' The .dbc format is decompressed internally using vendored C code from the
#' blast library. No external dependencies are required.
#'
#' When `uf` is specified, only the requested state(s) are downloaded,
#' making the operation much faster than downloading the entire country.
#'
#' @export
#' @family sinasc
#'
#' @seealso [censo_populacao()] for population denominators to calculate
#'   birth rates.
#'
#' @examplesIf interactive()
#' # all births in Acre, 2022
#' ac_2022 <- sinasc_data(year = 2022, uf = "AC")
#'
#' # births with anomalies in Sao Paulo, 2020-2022
#' anomalies_sp <- sinasc_data(year = 2020:2022, uf = "SP", anomaly = "Q")
#'
#' # only key variables, Rio de Janeiro, 2022
#' sinasc_data(year = 2022, uf = "RJ",
#'             vars = c("DTNASC", "SEXO", "PESO",
#'                      "IDADEMAE", "PARTO", "CONSULTAS"))
sinasc_data <- function(year, vars = NULL, uf = NULL, anomaly = NULL,
                        parse = TRUE, col_types = NULL,
                        cache = TRUE, cache_dir = NULL,
                        lazy = FALSE, backend = c("arrow", "duckdb")) {

  # validate inputs
  year <- .sinasc_validate_year(year)
  if (!is.null(uf)) uf <- .sinasc_validate_uf(uf)
  if (!is.null(vars)) .sinasc_validate_vars(vars)

  # determine UFs to download
  target_ufs <- if (!is.null(uf)) toupper(uf) else sinasc_uf_list

  # lazy evaluation: return from partitioned cache if available
  if (isTRUE(lazy)) {
    if (isTRUE(parse)) {
      cli::cli_inform("{.arg parse} is ignored when {.arg lazy} is TRUE.")
    }
    backend <- match.arg(backend)
    cache_dir_resolved <- .sinasc_cache_dir(cache_dir)
    select_cols <- if (!is.null(vars)) unique(c("year", "uf_source", vars)) else NULL
    ds <- .lazy_return(cache_dir_resolved, "sinasc_data", backend,
                       filters = list(year = year, uf_source = target_ufs),
                       select_cols = select_cols)
    if (!is.null(ds)) return(ds)
    # cache not available — fall through to eager download
  }

  # build all year x UF combinations
  combinations <- expand.grid(
    year = year, uf = target_ufs,
    stringsAsFactors = FALSE
  )

  n_combos <- nrow(combinations)
  if (n_combos > 1) {
    cli::cli_inform(c(
      "i" = "Downloading {n_combos} file(s) ({length(unique(combinations$uf))} UF(s) x {length(unique(combinations$year))} year(s))..."
    ))
  }

  # download and read each combination
  labels <- paste(combinations$uf, combinations$year)

  results <- .map_parallel(seq_len(n_combos), function(i) {
    yr <- combinations$year[i]
    st <- combinations$uf[i]

    tryCatch({
      .sinasc_download_and_read(yr, st, cache = cache, cache_dir = cache_dir)
    }, error = function(e) {
      NULL
    })
  })

  # remove NULLs and bind
  succeeded <- !vapply(results, is.null, logical(1))
  failed_labels <- labels[!succeeded]
  results <- results[succeeded]

  if (length(results) == 0) {
    cli::cli_abort("No data could be downloaded for the requested year(s)/UF(s).")
  }

  results <- dplyr::bind_rows(results)

  # if lazy was requested, return from cache after download
  if (isTRUE(lazy)) {
    backend <- match.arg(backend)
    cache_dir_resolved <- .sinasc_cache_dir(cache_dir)
    select_cols <- if (!is.null(vars)) unique(c("year", "uf_source", vars)) else NULL
    ds <- .lazy_return(cache_dir_resolved, "sinasc_data", backend,
                       filters = list(year = year, uf_source = target_ufs),
                       select_cols = select_cols)
    if (!is.null(ds)) return(ds)
  }

  # parse column types
  if (isTRUE(parse) && !isTRUE(lazy)) {
    type_spec <- .build_type_spec(sinasc_variables_metadata)
    results <- .parse_columns(results, type_spec, col_types = col_types)
  }

  # filter by anomaly if requested
  if (!is.null(anomaly)) {
    anomaly_pattern <- stringr::str_c("^(", stringr::str_c(anomaly, collapse = "|"), ")")
    if ("CODANOMAL" %in% names(results)) {
      results <- results[grepl(anomaly_pattern, results$CODANOMAL), ]
    } else {
      cli::cli_warn("Column {.var CODANOMAL} not found in data. Cannot filter by anomaly.")
    }
  }

  # select variables if requested
  if (!is.null(vars)) {
    keep_cols <- unique(c("year", "uf_source", vars))
    keep_cols <- intersect(keep_cols, names(results))
    results <- results[, keep_cols, drop = FALSE]
  }

  results <- .report_download_failures(results, failed_labels, "SINASC")

  tibble::as_tibble(results)
}


#' Show SINASC Cache Status
#'
#' Shows information about cached SINASC data files.
#'
#' @param cache_dir Character. Cache directory path. Default:
#'   `tools::R_user_dir("healthbR", "cache")`.
#'
#' @return A tibble with cache file information (invisibly).
#'
#' @export
#' @family sinasc
#'
#' @examples
#' sinasc_cache_status()
sinasc_cache_status <- function(cache_dir = NULL) {
  cache_dir <- .sinasc_cache_dir(cache_dir)

  files <- list.files(cache_dir, pattern = "^sinasc_.*\\.(parquet|rds)$",
                      full.names = TRUE)

  if (length(files) == 0) {
    cli::cli_inform("No cached SINASC files found.")
    return(invisible(tibble::tibble(
      file = character(), size_mb = numeric(), modified = as.POSIXct(character())
    )))
  }

  info <- file.info(files)
  result <- tibble::tibble(
    file = basename(files),
    size_mb = round(info$size / 1e6, 2),
    modified = info$mtime
  )

  cli::cli_inform(c(
    "i" = "SINASC cache: {nrow(result)} file(s), {sum(result$size_mb)} MB total",
    "i" = "Cache directory: {.file {cache_dir}}"
  ))

  invisible(result)
}


#' Clear SINASC Cache
#'
#' Deletes cached SINASC data files.
#'
#' @param cache_dir Character. Cache directory path. Default:
#'   `tools::R_user_dir("healthbR", "cache")`.
#'
#' @return Invisible NULL.
#'
#' @export
#' @family sinasc
#'
#' @examplesIf interactive()
#' sinasc_clear_cache()
sinasc_clear_cache <- function(cache_dir = NULL) {
  cache_dir <- .sinasc_cache_dir(cache_dir)

  files <- list.files(cache_dir, pattern = "^sinasc_.*\\.(parquet|rds)$",
                      full.names = TRUE)

  if (length(files) == 0) {
    cli::cli_inform("No cached SINASC files to clear.")
    return(invisible(NULL))
  }

  removed <- file.remove(files)
  n_removed <- sum(removed)

  cli::cli_inform(c(
    "v" = "Removed {n_removed} cached SINASC file(s)."
  ))

  invisible(NULL)
}
