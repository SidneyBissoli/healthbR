# sipni functions for healthbR package
# functions to access vaccination data from the SI-PNI (Sistema de Informacao
# do Programa Nacional de Imunizacoes) via DATASUS FTP (1994-2019) and
# OpenDataSUS CSV bulk downloads (2020+)

# ============================================================================
# internal validation functions
# ============================================================================

#' Validate SI-PNI year parameter
#' @noRd
.sipni_validate_year <- function(year) {
  .validate_year(year, sipni_available_years,
                 years_fn_hint = "sipni_years()")
}


#' Validate SI-PNI type parameter
#' @noRd
.sipni_validate_type <- function(type) {
  type <- toupper(type)
  valid_codes <- sipni_valid_types$code

  if (!type %in% valid_codes) {
    cli::cli_abort(c(
      "Invalid SI-PNI type: {.val {type}}.",
      "i" = "Valid types: {.val {valid_codes}}",
      "i" = "DPNI = Doses aplicadas, CPNI = Cobertura vacinal, API = Microdados 2020+."
    ))
  }

  type
}


#' Validate SI-PNI UF parameter
#' @noRd
.sipni_validate_uf <- function(uf) {
  .validate_uf(uf, sipni_uf_list)
}


#' Validate SI-PNI vars parameter (warning only)
#' @noRd
.sipni_validate_vars <- function(vars, type = "DPNI") {
  meta <- switch(type,
    "CPNI" = sipni_variables_cpni,
    "API"  = sipni_variables_api,
    sipni_variables_dpni
  )
  known_vars <- meta$variable
  invalid <- vars[!vars %in% known_vars]

  if (length(invalid) > 0) {
    cli::cli_warn(c(
      "Variable(s) {.val {invalid}} not in known SI-PNI ({type}) variables.",
      "i" = "Use {.code sipni_variables(type = \"{type}\")} to see available variables.",
      "i" = "Proceeding anyway (variables will be dropped if not found)."
    ))
  }
}


# ============================================================================
# internal helper functions (FTP path, 1994-2019)
# ============================================================================

#' Build FTP URL for SI-PNI .DBF file
#' @noRd
.sipni_build_ftp_url <- function(year, uf, type = "DPNI") {
  if (year < 1994L) {
    cli::cli_abort(
      "Year {.val {year}} is not supported. SI-PNI data starts in 1994."
    )
  }

  yy <- sprintf("%02d", year %% 100)

  stringr::str_c(
    "ftp://ftp.datasus.gov.br/dissemin/publicos/PNI/DADOS/",
    type, uf, yy, ".DBF"
  )
}


#' Get/create SI-PNI cache directory
#' @noRd
.sipni_cache_dir <- function(cache_dir = NULL) {
  .module_cache_dir("sipni", cache_dir)
}


#' Read a plain .DBF file and return as tibble
#' @noRd
.sipni_read_dbf <- function(path) {
  data <- foreign::read.dbf(path, as.is = TRUE)
  data <- lapply(data, as.character)
  tibble::as_tibble(data)
}


#' Check FTP partitioned cache for SI-PNI data
#' @return Cached tibble or NULL if not found.
#' @noRd
.sipni_ftp_check_cache <- function(uf, year, type, cache, cache_dir) {
  dataset_name <- stringr::str_c("sipni_", tolower(type), "_data")
  target_year <- as.integer(year)

  if (!isTRUE(cache) || !.has_arrow() ||
      !.has_partitioned_cache(cache_dir, dataset_name)) {
    return(NULL)
  }

  ds <- arrow::open_dataset(file.path(cache_dir, dataset_name))
  cached <- ds |>
    dplyr::filter(.data$uf_source == uf,
                   .data$year == target_year) |>
    dplyr::collect()

  if (nrow(cached) > 0) cached else NULL
}


#' Download and read a SI-PNI .DBF file for one UF/year/type (FTP, 1994-2019)
#' @noRd
.sipni_download_and_read <- function(year, uf, type = "DPNI",
                                     cache = TRUE, cache_dir = NULL) {
  cache_dir <- .sipni_cache_dir(cache_dir)
  dataset_name <- stringr::str_c("sipni_", tolower(type), "_data")
  target_year <- as.integer(year)
  target_uf <- uf

  # 1. check partitioned cache first (preferred path)
  cached <- .sipni_ftp_check_cache(uf, year, type, cache, cache_dir)
  if (!is.null(cached)) return(cached)

  # 2. download from FTP
  url <- .sipni_build_ftp_url(year, uf, type)
  temp_dbf <- tempfile(fileext = ".DBF")
  on.exit(if (file.exists(temp_dbf)) file.remove(temp_dbf), add = TRUE)

  cli::cli_inform(c(
    "i" = "Downloading SI-PNI data: {type} {uf} {year}..."
  ))

  # try with .DBF extension first, fall back to .dbf
  download_ok <- tryCatch({
    .datasus_download(url, temp_dbf)
    TRUE
  }, error = function(e) {
    FALSE
  })

  if (!download_ok) {
    url_lower <- sub("\\.DBF$", ".dbf", url)
    .datasus_download(url_lower, temp_dbf)
  }

  # check file exists and size
  if (!file.exists(temp_dbf) || file.size(temp_dbf) < 100) {
    size_info <- if (file.exists(temp_dbf)) file.size(temp_dbf) else 0
    cli::cli_abort(c(
      "Downloaded file appears corrupted (too small).",
      "x" = "File size: {size_info} bytes",
      "i" = "The DATASUS FTP may be experiencing issues. Try again later."
    ))
  }

  # read .DBF directly (no DBC decompression needed)
  data <- .sipni_read_dbf(temp_dbf)

  # fix CPNI coverage decimal separator (comma -> dot)
  if (type == "CPNI" && "COBERT" %in% names(data)) {
    data$COBERT <- gsub(",", ".", data$COBERT)
  }

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
# internal helper functions (CSV path, 2020+)
# ============================================================================

#' Build OpenDataSUS CSV ZIP URL for a given year and month
#' @noRd
.sipni_csv_build_url <- function(year, month) {
  month_name <- sipni_month_names[month]
  stringr::str_c(
    sipni_csv_base_url, "/vacinacao_", month_name, "_", year, "_csv.zip"
  )
}


#' Check partitioned cache for SI-PNI CSV data
#' @return Cached tibble or NULL if not found.
#' @noRd
.sipni_csv_check_cache <- function(uf, year, month, cache, cache_dir) {
  dataset_name <- "sipni_csv_data"
  target_year <- as.integer(year)
  target_month <- as.integer(month)

  if (!isTRUE(cache) || !.has_arrow() ||
      !.has_partitioned_cache(cache_dir, dataset_name)) {
    return(NULL)
  }

  ds <- arrow::open_dataset(file.path(cache_dir, dataset_name))
  cached <- ds |>
    dplyr::filter(.data$uf_source == uf,
                   .data$year == target_year,
                   .data$month == target_month) |>
    dplyr::collect()

  if (nrow(cached) > 0) cached else NULL
}


#' Download ZIP and extract CSV for SI-PNI
#' @return A list with csv_path and temp_dir (caller must clean up temp_dir).
#' @noRd
.sipni_csv_download_zip <- function(year, month, zip_path) {
  month_name <- sipni_month_names[month]
  own_zip <- is.null(zip_path)

  if (own_zip) {
    url <- .sipni_csv_build_url(year, month)
    cli::cli_inform(c(
      "i" = "Downloading SI-PNI CSV: {month_name} {year} (national file)..."
    ))
    zip_path <- tempfile(fileext = ".zip")
    .http_download_resumable(url, zip_path, retries = 3L, timeout = 600L)
  }

  temp_dir <- tempfile("sipni_csv")
  dir.create(temp_dir, recursive = TRUE)

  utils::unzip(zip_path, exdir = temp_dir)
  # remove ZIP immediately to free disk space (only if we own it)
  if (own_zip && file.exists(zip_path)) file.remove(zip_path)

  csv_files <- list.files(temp_dir, pattern = "\\.csv$",
                          full.names = TRUE, recursive = TRUE)
  if (length(csv_files) == 0) {
    cli::cli_abort("No CSV file found inside the downloaded ZIP.")
  }

  list(csv_path = csv_files[1], temp_dir = temp_dir, own_zip = own_zip,
       zip_path = zip_path)
}


#' Read SI-PNI CSV in chunks, splitting by UF
#' @return A named list of chunk lists, keyed by UF code.
#' @noRd
.sipni_csv_read_chunked <- function(csv_path, month_name, year) {
  cli::cli_inform(c(
    "i" = "Reading and caching all UFs for {month_name} {year}..."
  ))

  uf_buffers <- list()

  callback <- readr::SideEffectChunkCallback$new(function(chunk, pos) {
    if ("sigla_uf_estabelecimento" %in% names(chunk)) {
      uf_col <- chunk$sigla_uf_estabelecimento
    } else if ("uf_estabelecimento" %in% names(chunk)) {
      uf_col <- chunk$uf_estabelecimento
    } else {
      # no UF column — buffer everything under "ALL"
      uf_buffers[["ALL"]] <<- c(uf_buffers[["ALL"]], list(chunk))
      return(invisible(NULL))
    }

    for (u in unique(uf_col)) {
      rows <- chunk[uf_col == u, , drop = FALSE]
      if (nrow(rows) > 0) {
        uf_buffers[[u]] <<- c(uf_buffers[[u]], list(rows))
      }
    }
  })

  readr::read_delim_chunked(
    csv_path,
    callback = callback,
    delim = ";",
    chunk_size = 100000L,
    locale = readr::locale(encoding = "latin1"),
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE,
    progress = FALSE
  )

  uf_buffers
}


#' Bind UF buffers, cache all UFs, and extract the requested UF
#' @return A tibble for the requested UF, or an empty tibble with a warning.
#' @noRd
.sipni_csv_cache_and_extract <- function(uf_buffers, uf, year, month,
                                         cache, cache_dir) {
  dataset_name <- "sipni_csv_data"
  target_year <- as.integer(year)
  target_month <- as.integer(month)
  month_name <- sipni_month_names[month]
  requested_data <- NULL

  for (u in names(uf_buffers)) {
    uf_data <- dplyr::bind_rows(uf_buffers[[u]])
    if (nrow(uf_data) == 0) next

    uf_data$year <- target_year
    uf_data$month <- target_month
    uf_data$uf_source <- u
    cols <- names(uf_data)
    uf_data <- uf_data[, c("year", "month", "uf_source",
                            setdiff(cols, c("year", "month", "uf_source")))]

    if (isTRUE(cache)) {
      .cache_append_partitioned(uf_data, cache_dir, dataset_name,
                                c("uf_source", "year", "month"))
    }

    if (u == uf) {
      requested_data <- uf_data
    }
  }

  if (is.null(requested_data) || nrow(requested_data) == 0) {
    cli::cli_warn(c(
      "!" = "No data found for UF={uf} in {month_name} {year}.",
      "i" = "The CSV may not contain data for this UF/month."
    ))
    return(tibble::tibble())
  }

  requested_data
}


#' Process national SI-PNI CSV for one month, caching ALL UFs
#'
#' Downloads the national monthly CSV ZIP from OpenDataSUS, reads it in
#' chunks splitting by UF, and caches ALL 27 states. This means a second
#' request for a different UF from the same month is instant from cache.
#'
#' @param year Integer. Year.
#' @param month Integer. Month (1-12).
#' @param uf Character. The UF to return (all 27 are cached regardless).
#' @param cache Logical. Whether to use caching.
#' @param cache_dir Character or NULL. Cache directory.
#' @param zip_path Character or NULL. Path to an already-downloaded ZIP file.
#'   If provided, skips downloading. Used by `.sipni_csv_download_months()`
#'   for concurrent download + sequential processing.
#'
#' @return A tibble with data for the requested UF.
#' @noRd
.sipni_csv_process_national <- function(year, month, uf,
                                        cache = TRUE, cache_dir = NULL,
                                        zip_path = NULL) {
  cache_dir <- .sipni_cache_dir(cache_dir)
  month_name <- sipni_month_names[month]

  # 1. check partitioned cache first (preferred path)
  cached <- .sipni_csv_check_cache(uf, year, month, cache, cache_dir)
  if (!is.null(cached)) return(cached)

  # 2. download ZIP and extract CSV
  zip_info <- .sipni_csv_download_zip(year, month, zip_path)
  if (zip_info$own_zip) {
    on.exit(if (file.exists(zip_info$zip_path)) file.remove(zip_info$zip_path),
            add = TRUE)
  }
  on.exit(unlink(zip_info$temp_dir, recursive = TRUE), add = TRUE)

  # 3. read CSV in chunks, buffering ALL UFs
  uf_buffers <- .sipni_csv_read_chunked(zip_info$csv_path, month_name, year)

  # 4. bind, cache all UFs, and extract the requested one
  result <- .sipni_csv_cache_and_extract(uf_buffers, uf, year, month,
                                          cache, cache_dir)
  rm(uf_buffers)

  result
}


#' Check cache for multiple months, return cached results and months needing download
#' @return A list with cached_results (list of tibbles) and needs_download (integer).
#' @noRd
.sipni_csv_collect_cached <- function(months, uf, year, cache, cache_dir) {
  needs_download <- integer(0)
  cached_results <- list()

  for (m in months) {
    cached <- .sipni_csv_check_cache(uf, year, m, cache, cache_dir)
    if (!is.null(cached)) {
      cached_results <- c(cached_results, list(cached))
    } else {
      needs_download <- c(needs_download, m)
    }
  }

  list(cached_results = cached_results, needs_download = needs_download)
}


#' Download and process months that are not cached
#' @return A list of tibbles with downloaded data.
#' @noRd
.sipni_csv_fetch_needed <- function(needs_download, year, uf,
                                     cache, cache_dir) {
  downloaded_results <- list()
  if (length(needs_download) == 0) return(downloaded_results)

  if (length(needs_download) > 1) {
    urls <- vapply(needs_download, function(m) {
      .sipni_csv_build_url(year, m)
    }, character(1))

    zip_paths <- vapply(needs_download, function(m) {
      tempfile(fileext = ".zip")
    }, character(1))

    cli::cli_inform(c(
      "i" = "Downloading {length(needs_download)} SI-PNI CSV file(s) concurrently..."
    ))
    dl_results <- .multi_download(urls, zip_paths, max_concurrent = 6L,
                                   timeout = 600L)

    for (idx in seq_along(needs_download)) {
      m <- needs_download[idx]
      if (dl_results$success[idx]) {
        tryCatch({
          data <- .sipni_csv_process_national(
            year, m, uf, cache = cache, cache_dir = cache_dir,
            zip_path = zip_paths[idx]
          )
          if (nrow(data) > 0) {
            downloaded_results <- c(downloaded_results, list(data))
          }
        }, error = function(e) {
          NULL
        })
      }
      # clean up ZIP
      if (file.exists(zip_paths[idx])) file.remove(zip_paths[idx])
    }
  } else {
    # single month: use .sipni_csv_process_national directly (it downloads)
    tryCatch({
      data <- .sipni_csv_process_national(
        year, needs_download[1], uf, cache = cache, cache_dir = cache_dir
      )
      if (nrow(data) > 0) {
        downloaded_results <- c(downloaded_results, list(data))
      }
    }, error = function(e) {
      NULL
    })
  }

  downloaded_results
}


#' Download multiple month ZIPs concurrently, then process each
#'
#' Uses `.multi_download()` to fetch all month ZIPs in parallel, then
#' processes each sequentially with `.sipni_csv_process_national()`.
#'
#' @param year Integer. Year.
#' @param months Integer vector. Months to download.
#' @param uf Character. UF to return.
#' @param cache Logical. Whether to use caching.
#' @param cache_dir Character or NULL. Cache directory.
#'
#' @return A tibble with data for the requested UF across all months.
#' @noRd
.sipni_csv_download_months <- function(year, months, uf,
                                       cache = TRUE, cache_dir = NULL) {
  cache_dir <- .sipni_cache_dir(cache_dir)

  # check which months are cached vs need downloading
  cache_info <- .sipni_csv_collect_cached(months, uf, year, cache, cache_dir)

  # download months that are not cached
  downloaded_results <- .sipni_csv_fetch_needed(
    cache_info$needs_download, year, uf, cache, cache_dir
  )

  all_results <- c(cache_info$cached_results, downloaded_results)

  if (length(all_results) == 0) {
    return(tibble::tibble())
  }

  dplyr::bind_rows(all_results)
}


#' Download and read SI-PNI data from OpenDataSUS CSV for one UF/year
#' @noRd
.sipni_api_download_and_read <- function(year, uf, month = 1L:12L,
                                         cache = TRUE, cache_dir = NULL) {
  .sipni_csv_download_months(year, month, uf, cache = cache,
                              cache_dir = cache_dir)
}


# ============================================================================
# exported functions
# ============================================================================

#' List Available SI-PNI Years
#'
#' Returns an integer vector with years for which vaccination data are
#' available.
#'
#' @return An integer vector of available years (1994--2025).
#'
#' @details
#' SI-PNI data is available from two sources:
#' \itemize{
#'   \item **FTP (1994--2019)**: Aggregated data (doses applied and coverage)
#'     from DATASUS FTP as plain .DBF files.
#'   \item **CSV (2020--2025)**: Individual-level microdata from
#'     OpenDataSUS as monthly CSV bulk downloads (one row per vaccination dose).
#' }
#'
#' @export
#' @family sipni
#'
#' @examples
#' sipni_years()
sipni_years <- function() {
  sipni_available_years
}


#' SI-PNI Module Information
#'
#' Displays information about the National Immunization Program Information
#' System (SI-PNI), including data sources, available years, file types,
#' and usage guidance.
#'
#' @return A list with module information (invisibly).
#'
#' @export
#' @family sipni
#'
#' @examples
#' sipni_info()
sipni_info <- function() {
  yr_range <- range(sipni_available_years)

  cli::cli_h1(
    "SI-PNI \u2014 Sistema de Informa\u00e7\u00e3o do Programa Nacional de Imuniza\u00e7\u00f5es"
  )

  cli::cli_text("")
  cli::cli_text("Fonte:          Minist\u00e9rio da Sa\u00fade / DATASUS")
  cli::cli_text(
    "Acesso:         FTP DATASUS (1994-2019) + OpenDataSUS CSV (2020+)"
  )
  cli::cli_text(
    "Dados:          Agregados (FTP) e microdados individuais (CSV)"
  )
  cli::cli_text("Granularidade:  Anual/UF (FTP), Mensal/UF (CSV)")

  cli::cli_h2("Fontes de dados")
  cli::cli_bullets(c(
    "*" = "FTP DATASUS (1994\u20132019): Dados agregados (DPNI/CPNI) em .DBF",
    "*" = "OpenDataSUS CSV (2020\u20132025): Microdados individuais (1 linha por dose)"
  ))

  cli::cli_h2("Dados dispon\u00edveis")
  cli::cli_bullets(c(
    "*" = "{.fun sipni_data}: Dados de vacina\u00e7\u00e3o (doses, cobertura ou microdados)",
    " " = "  Anos: {yr_range[1]}\u2013{yr_range[2]}",
    "*" = "{.fun sipni_variables}: Lista de vari\u00e1veis dispon\u00edveis",
    "*" = "{.fun sipni_dictionary}: Dicion\u00e1rio com categorias (FTP)"
  ))

  cli::cli_h2("Tipos de arquivo")
  for (i in seq_len(nrow(sipni_valid_types))) {
    cli::cli_text(
      "  {sipni_valid_types$code[i]}   {sipni_valid_types$name[i]} \u2014 {sipni_valid_types$description[i]}"
    )
  }

  cli::cli_h2("Vari\u00e1veis-chave (DPNI)")
  cli::cli_text("  IMUNO      C\u00f3digo do imunobiol\u00f3gico")
  cli::cli_text("  QT_DOSE    Quantidade de doses aplicadas")
  cli::cli_text("  DOSE       Tipo de dose (1\u00aa, 2\u00aa, Refor\u00e7o, etc.)")
  cli::cli_text("  FX_ETARIA  Faixa et\u00e1ria")
  cli::cli_text("  MUNIC      Munic\u00edpio (IBGE 6 d\u00edgitos)")

  cli::cli_h2("Vari\u00e1veis-chave (API 2020+)")
  cli::cli_text("  descricao_vacina       Nome da vacina")
  cli::cli_text("  descricao_dose_vacina  Descri\u00e7\u00e3o da dose")
  cli::cli_text("  tipo_sexo_paciente     Sexo do paciente (M/F)")
  cli::cli_text("  numero_idade_paciente  Idade do paciente")
  cli::cli_text("  data_vacina            Data da vacina\u00e7\u00e3o")

  cli::cli_text("")
  cli::cli_alert_info(
    "1994-2019: Dados agregados (contagens por munic\u00edpio/vacina/faixa)."
  )
  cli::cli_alert_info(
    "2020+: Microdados individuais (1 linha por dose aplicada) via CSV."
  )
  cli::cli_alert_info(
    "Use {.arg month} em {.fun sipni_data} para filtrar meses (CSV 2020+)."
  )

  invisible(list(
    name = "SI-PNI - Sistema de Informa\u00e7\u00e3o do Programa Nacional de Imuniza\u00e7\u00f5es",
    source = "DATASUS FTP + OpenDataSUS CSV",
    years = sipni_available_years,
    n_types = nrow(sipni_valid_types),
    n_variables_dpni = nrow(sipni_variables_dpni),
    n_variables_cpni = nrow(sipni_variables_cpni),
    n_variables_api = nrow(sipni_variables_api),
    url_ftp = "ftp://ftp.datasus.gov.br/dissemin/publicos/PNI/",
    url_csv = sipni_csv_base_url
  ))
}


#' List SI-PNI Variables
#'
#' Returns a tibble with available variables in the SI-PNI data,
#' including descriptions and value types.
#'
#' @param type Character. File type to show variables for.
#'   \code{"DPNI"} (default) for doses applied (FTP, 1994-2019),
#'   \code{"CPNI"} for coverage (FTP, 1994-2019), or \code{"API"} for
#'   individual-level microdata (OpenDataSUS, 2020+).
#' @param search Character. Optional search term to filter variables by
#'   name or description. Case-insensitive and accent-insensitive.
#'
#' @return A tibble with columns: variable, description, type, section.
#'
#' @export
#' @family sipni
#'
#' @examples
#' sipni_variables()
#' sipni_variables(type = "CPNI")
#' sipni_variables(type = "API")
#' sipni_variables(search = "dose")
sipni_variables <- function(type = "DPNI", search = NULL) {
  type <- .sipni_validate_type(type)
  result <- switch(type,
    "CPNI" = sipni_variables_cpni,
    "API"  = sipni_variables_api,
    sipni_variables_dpni
  )

  result <- .search_metadata(result, search, c("variable", "description"))

  result
}


#' SI-PNI Data Dictionary
#'
#' Returns a tibble with the data dictionary for the SI-PNI FTP data
#' (1994--2019), including variable descriptions and category labels.
#'
#' @param variable Character. If provided, returns dictionary for a specific
#'   variable only. Default: NULL (returns all variables).
#'
#' @return A tibble with columns: variable, description, code, label.
#'
#' @details
#' The dictionary covers FTP data variables (DPNI/CPNI, 1994--2019).
#' API microdata (2020+) has description fields embedded in the data
#' itself (e.g., \code{descricao_vacina}, \code{nome_raca_cor_paciente}),
#' so a separate dictionary is not needed.
#'
#' @export
#' @family sipni
#'
#' @examples
#' sipni_dictionary()
#' sipni_dictionary("IMUNO")
#' sipni_dictionary("DOSE")
sipni_dictionary <- function(variable = NULL) {
  result <- sipni_dictionary_data

  if (!is.null(variable)) {
    variable <- toupper(variable)
    result <- result[result$variable %in% variable, ]

    if (nrow(result) == 0) {
      cli::cli_warn(c(
        "Variable {.val {variable}} not found in SI-PNI dictionary.",
        "i" = "Use {.code sipni_dictionary()} to see all available variables.",
        "i" = "Note: API data (2020+) has descriptions embedded in the data."
      ))
    }
  }

  result
}


# ============================================================================
# internal subfunctions for sipni_data (cyclomatic complexity reduction)
# ============================================================================

#' Resolve and validate all sipni_data parameters
#' @return Named list with ftp_years, api_years, type, month_vals,
#'   target_ufs, effective_type
#' @noRd
.sipni_resolve_params <- function(year, type, uf, month, vars, missing_type) {
  year <- .sipni_validate_year(year)
  if (!is.null(uf)) uf <- .sipni_validate_uf(uf)

  ftp_years <- year[year %in% sipni_ftp_years]
  api_years <- year[year %in% sipni_api_years]

  if (length(ftp_years) > 0) {
    type <- .sipni_validate_type(type)
  }

  if (length(api_years) > 0 && !missing_type && toupper(type) %in%
      c("DPNI", "CPNI")) {
    cli::cli_warn(c(
      "!" = "{.arg type} is ignored for years >= 2020 (API microdata).",
      "i" = "API data is always individual-level microdata (no DPNI/CPNI)."
    ))
  }

  month_vals <- .validate_month(month)

  effective_type <- if (length(api_years) > 0) "API" else type
  if (!is.null(vars)) {
    .sipni_validate_vars(vars, type = effective_type)
  }

  target_ufs <- if (!is.null(uf)) toupper(uf) else sipni_uf_list

  list(
    year = year, ftp_years = ftp_years, api_years = api_years,
    type = type, month_vals = month_vals, target_ufs = target_ufs,
    uf = uf
  )
}


#' Try lazy return from FTP partitioned cache
#' @return Lazy query object or NULL.
#' @noRd
.sipni_lazy_ftp <- function(ftp_years, type, target_ufs, backend, cache_dir) {
  if (length(ftp_years) == 0) return(NULL)

  ftp_ds_name <- stringr::str_c("sipni_", tolower(type), "_data")
  .lazy_return(cache_dir, ftp_ds_name, backend,
               filters = list(year = ftp_years, uf_source = target_ufs),
               select_cols = NULL)
}


#' Try lazy return from CSV partitioned cache
#' @return Lazy query object or NULL.
#' @noRd
.sipni_lazy_csv <- function(api_years, target_ufs, month_vals,
                             backend, cache_dir) {
  if (length(api_years) == 0) return(NULL)

  csv_filters <- list(year = api_years, uf_source = target_ufs)
  if (!is.null(month_vals) && length(month_vals) < 12) {
    csv_filters$month <- as.integer(month_vals)
  }
  .lazy_return(cache_dir, "sipni_csv_data", backend,
               filters = csv_filters, select_cols = NULL)
}


#' Pre-download lazy evaluation check for sipni_data
#' @return Lazy query object or NULL
#' @noRd
.sipni_try_lazy_pre <- function(params, lazy, backend, cache_dir, parse) {
  if (!isTRUE(lazy)) return(NULL)

  if (isTRUE(parse)) {
    cli::cli_inform("{.arg parse} is ignored when {.arg lazy} is TRUE.")
  }

  cache_dir_resolved <- .sipni_cache_dir(cache_dir)

  # try FTP partitioned cache (years <= 2019)
  ftp_ds <- .sipni_lazy_ftp(params$ftp_years, params$type,
                             params$target_ufs, backend, cache_dir_resolved)
  if (!is.null(ftp_ds) && length(params$api_years) == 0) return(ftp_ds)

  # try CSV partitioned cache (years >= 2020)
  csv_ds <- .sipni_lazy_csv(params$api_years, params$target_ufs,
                             params$month_vals, backend, cache_dir_resolved)
  if (!is.null(csv_ds) && length(params$ftp_years) == 0) return(csv_ds)

  NULL
}


#' Download FTP batch for sipni_data
#' @return Named list with results (list of tibbles) and failed_labels (char)
#' @noRd
.sipni_download_ftp <- function(ftp_years, target_ufs, type,
                                cache, cache_dir) {
  if (length(ftp_years) == 0) {
    return(list(results = list(), failed_labels = character(0)))
  }

  ftp_combos <- expand.grid(
    year = ftp_years, uf = target_ufs,
    stringsAsFactors = FALSE
  )

  n_ftp <- nrow(ftp_combos)
  if (n_ftp > 1) {
    cli::cli_inform(c(
      "i" = "Downloading {n_ftp} FTP file(s) ({length(unique(ftp_combos$uf))} UF(s) x {length(unique(ftp_combos$year))} year(s))..."
    ))
  }

  ftp_labels <- paste(ftp_combos$uf, ftp_combos$year)

  ftp_results <- .map_parallel(seq_len(n_ftp), .delay = 0.5, function(i) {
    tryCatch({
      .sipni_download_and_read(ftp_combos$year[i], ftp_combos$uf[i],
                               type = type,
                               cache = cache, cache_dir = cache_dir)
    }, error = function(e) NULL)
  })

  ftp_succeeded <- !vapply(ftp_results, is.null, logical(1))

  list(
    results = ftp_results[ftp_succeeded],
    failed_labels = ftp_labels[!ftp_succeeded]
  )
}


#' Download API/CSV batch for sipni_data
#' @return Named list with results (list of tibbles) and failed_labels (char)
#' @noRd
.sipni_download_api <- function(api_years, target_ufs, month_vals,
                                cache, cache_dir) {
  if (length(api_years) == 0) {
    return(list(results = list(), failed_labels = character(0)))
  }

  api_combos <- expand.grid(
    year = api_years, uf = target_ufs,
    stringsAsFactors = FALSE
  )

  n_api <- nrow(api_combos)
  if (n_api > 0) {
    cli::cli_inform(c(
      "i" = "Downloading {n_api} CSV request(s) ({length(unique(api_combos$uf))} UF(s) x {length(unique(api_combos$year))} year(s))..."
    ))
  }

  api_labels <- paste(api_combos$uf, api_combos$year)

  api_results <- .map_parallel(seq_len(n_api), function(i) {
    tryCatch({
      data <- .sipni_api_download_and_read(
        api_combos$year[i], api_combos$uf[i], month = month_vals,
        cache = cache, cache_dir = cache_dir
      )
      if (nrow(data) == 0) return(NULL)
      data
    }, error = function(e) NULL)
  })

  api_succeeded <- !vapply(api_results, is.null, logical(1))

  list(
    results = api_results[api_succeeded],
    failed_labels = api_labels[!api_succeeded]
  )
}


#' Bind FTP and API results separately then combine
#' @return Combined tibble
#' @noRd
.sipni_bind_results <- function(ftp_results, api_results) {
  all_results <- c(ftp_results, api_results)

  if (length(all_results) == 0) {
    cli::cli_abort(
      "No data could be downloaded for the requested year(s)/UF(s)."
    )
  }

  # bind within groups (same schema), then across groups if both present
  bound_parts <- list()
  if (length(ftp_results) > 0) {
    bound_parts <- c(bound_parts, list(dplyr::bind_rows(ftp_results)))
  }
  if (length(api_results) > 0) {
    bound_parts <- c(bound_parts, list(dplyr::bind_rows(api_results)))
  }

  dplyr::bind_rows(bound_parts)
}


#' Post-download lazy return for sipni_data
#' @return Lazy query object or NULL
#' @noRd
.sipni_try_lazy_post <- function(lazy, backend, year, type, uf, month, vars,
                                 cache_dir) {
  if (!isTRUE(lazy)) return(NULL)

  cache_dir_resolved <- .sipni_cache_dir(cache_dir)
  target_ufs <- if (!is.null(uf)) toupper(uf) else sipni_uf_list

  if (all(year <= 2019)) {
    ds_name <- stringr::str_c("sipni_", tolower(type), "_data")
    select_cols <- if (!is.null(vars)) unique(c("year", "uf_source", vars)) else NULL
    ds <- .lazy_return(cache_dir_resolved, ds_name, backend,
                       filters = list(year = year, uf_source = target_ufs),
                       select_cols = select_cols)
    if (!is.null(ds)) return(ds)
  } else if (all(year > 2019)) {
    csv_filters <- list(year = year, uf_source = target_ufs)
    if (!is.null(month)) csv_filters$month <- as.integer(month)
    select_cols <- if (!is.null(vars)) unique(c("year", "month", "uf_source", vars)) else NULL
    ds <- .lazy_return(cache_dir_resolved, "sipni_csv_data", backend,
                       filters = csv_filters, select_cols = select_cols)
    if (!is.null(ds)) return(ds)
  }

  NULL
}


#' Apply type parsing for sipni_data
#' @return Parsed tibble
#' @noRd
.sipni_apply_parsing <- function(combined, has_ftp, has_api, type,
                                 parse, col_types, lazy) {
  if (!isTRUE(parse) || isTRUE(lazy)) return(combined)

  all_specs <- c()
  if (has_ftp) {
    ftp_meta <- if (toupper(type) == "CPNI") sipni_variables_cpni else sipni_variables_dpni
    all_specs <- c(all_specs, .build_type_spec(ftp_meta))
  }
  if (has_api) {
    all_specs <- c(all_specs, .build_type_spec(sipni_variables_api))
  }
  if (length(all_specs) > 0) {
    combined <- .parse_columns(combined, all_specs, col_types = col_types)
  }

  combined
}


#' Download SI-PNI Vaccination Data
#'
#' Downloads and returns vaccination data from SI-PNI. For years 1994--2019,
#' data is downloaded from DATASUS FTP (aggregated doses/coverage). For years
#' 2020+, data is downloaded from OpenDataSUS as monthly CSV bulk files
#' (individual-level microdata with one row per vaccination dose).
#'
#' @param year Integer. Year(s) of the data. Required.
#' @param type Character. File type for FTP data (1994--2019). Default:
#'   \code{"DPNI"} (doses applied). Use \code{"CPNI"} for vaccination coverage.
#'   Ignored for years >= 2020 (API data is always microdata).
#' @param uf Character. Two-letter state abbreviation(s) to download.
#'   If NULL (default), downloads all 27 states.
#'   Example: \code{"SP"}, \code{c("SP", "RJ")}.
#' @param month Integer. Month(s) to download (1--12). For years >= 2020
#'   (CSV), selects which monthly CSV files to download. For years <= 2019
#'   (FTP), this parameter is ignored (FTP files are annual).
#'   If NULL (default), downloads all 12 months.
#' @param vars Character vector. Variables to keep. If NULL (default),
#'   returns all available variables. Use \code{\link{sipni_variables}()} to see
#'   available variables.
#' @param parse Logical. If TRUE (default), converts columns to
#'   appropriate types (integer, double, Date) based on the variable
#'   metadata. Use \code{\link{sipni_variables}()} to see the target type for
#'   each variable. Set to FALSE for backward-compatible all-character output.
#' @param col_types Named list. Override the default type for specific
#'   columns. Names are column names, values are type strings:
#'   \code{"character"}, \code{"integer"}, \code{"double"},
#'   \code{"date_dmy"}, \code{"date_ymd"}, \code{"date_ym"}, \code{"date"}.
#'   Example: \code{list(QT_DOSE = "character")} to keep QT_DOSE as character.
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
#' @return A tibble with vaccination data. Includes columns
#'   \code{year} and \code{uf_source} to identify the source
#'   when multiple years/states are combined.
#'
#'   **Output differs by year range:**
#'   \itemize{
#'     \item **1994--2019 (FTP)**: Aggregated data with DPNI (12 vars) or
#'       CPNI (7 vars) columns, all character.
#'     \item **2020+ (CSV)**: Individual-level microdata with ~47 columns
#'       (snake_case Portuguese), all character. Use
#'       \code{sipni_variables(type = "API")} to see the full list.
#'   }
#'
#' @details
#' **FTP data (1994--2019):**
#' Downloaded as plain .DBF files. SI-PNI FTP data is **aggregated** (dose
#' counts and coverage rates per municipality, vaccine, and age group).
#' Two file types: DPNI (doses) and CPNI (coverage).
#'
#' **CSV data (2020+):**
#' Downloaded from OpenDataSUS as monthly CSV bulk files (national,
#' semicolon-delimited, latin1 encoding). Each monthly ZIP is ~1.4 GB.
#' This is **individual-level microdata** (one row per vaccination dose,
#' ~47 fields per record). The \code{type} parameter is ignored for CSV
#' years. Data is filtered by UF during chunked reading to avoid loading
#' the full national file into memory.
#'
#' @export
#' @family sipni
#'
#' @seealso \code{\link{sipni_info}()} for type descriptions,
#'   \code{\link{censo_populacao}()} for population denominators.
#'
#' @examplesIf interactive()
#' # FTP: doses applied in Acre, 2019
#' ac_doses <- sipni_data(year = 2019, uf = "AC")
#'
#' # FTP: vaccination coverage in Acre, 2019
#' ac_cob <- sipni_data(year = 2019, type = "CPNI", uf = "AC")
#'
#' # API: microdata for Acre, January 2024
#' ac_api <- sipni_data(year = 2024, uf = "AC", month = 1)
#'
#' # API: select specific variables
#' sipni_data(year = 2024, uf = "AC", month = 1,
#'            vars = c("descricao_vacina", "tipo_sexo_paciente",
#'                     "data_vacina"))
sipni_data <- function(year, type = "DPNI", uf = NULL, month = NULL,
                       vars = NULL,
                       parse = TRUE, col_types = NULL,
                       cache = TRUE, cache_dir = NULL,
                       lazy = FALSE, backend = c("arrow", "duckdb")) {

  # 1. resolve and validate all parameters
  params <- .sipni_resolve_params(year, type, uf, month, vars,
                                  missing_type = missing(type))
  backend <- match.arg(backend)

  # 2. try lazy return (pre-download)
  lazy_result <- .sipni_try_lazy_pre(params, lazy, backend, cache_dir, parse)
  if (!is.null(lazy_result)) return(lazy_result)

  # 3. download FTP data (1994-2019)
  ftp <- .sipni_download_ftp(params$ftp_years, params$target_ufs,
                             params$type, cache, cache_dir)

  # 4. download API data (2020+)
  api <- .sipni_download_api(params$api_years, params$target_ufs,
                             params$month_vals, cache, cache_dir)

  # 5. bind results (FTP + API separately, then combine)
  combined <- .sipni_bind_results(ftp$results, api$results)

  # 6. try lazy return (post-download)
  lazy_result <- .sipni_try_lazy_post(lazy, backend, params$year, params$type,
                                      params$uf, month, vars, cache_dir)
  if (!is.null(lazy_result)) return(lazy_result)

  # 7. parse column types
  combined <- .sipni_apply_parsing(
    combined, has_ftp = length(ftp$results) > 0,
    has_api = length(api$results) > 0,
    type = params$type, parse = parse, col_types = col_types, lazy = lazy
  )

  # 8. select variables if requested
  if (!is.null(vars)) {
    keep_cols <- unique(c("year", "uf_source", vars))
    keep_cols <- intersect(keep_cols, names(combined))
    combined <- combined[, keep_cols, drop = FALSE]
  }

  # 9. report failures and return
  all_failed <- c(ftp$failed_labels, api$failed_labels)
  combined <- .report_download_failures(combined, all_failed, "SI-PNI")

  tibble::as_tibble(combined)
}


#' Show SI-PNI Cache Status
#'
#' Shows information about cached SI-PNI data files.
#'
#' @param cache_dir Character. Cache directory path. Default:
#'   \code{tools::R_user_dir("healthbR", "cache")}.
#'
#' @return A tibble with cache file information (invisibly).
#'
#' @export
#' @family sipni
#'
#' @examples
#' sipni_cache_status()
sipni_cache_status <- function(cache_dir = NULL) {
  .cache_status("sipni", "SI-PNI", .sipni_cache_dir(cache_dir))
}


#' Clear SI-PNI Cache
#'
#' Deletes cached SI-PNI data files.
#'
#' @param cache_dir Character. Cache directory path. Default:
#'   \code{tools::R_user_dir("healthbR", "cache")}.
#'
#' @return Invisible NULL.
#'
#' @export
#' @family sipni
#'
#' @examplesIf interactive()
#' sipni_clear_cache()
sipni_clear_cache <- function(cache_dir = NULL) {
  .clear_cache("sipni", "SI-PNI", .sipni_cache_dir(cache_dir))
}
