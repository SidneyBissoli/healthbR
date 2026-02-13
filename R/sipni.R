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
  if (is.null(year) || length(year) == 0) {
    cli::cli_abort("{.arg year} is required.")
  }

  year <- as.integer(year)
  available <- sipni_available_years
  invalid <- year[!year %in% available]

  if (length(invalid) > 0) {
    cli::cli_abort(c(
      "Year(s) {.val {invalid}} not available.",
      "i" = "Available years: {.val {range(available)[[1]]}}--{.val {range(available)[[2]]}}",
      "i" = "Use {.code sipni_years()} to see all options.",
      "i" = "SI-PNI: FTP 1994-2019 (aggregated), CSV 2020-2025 (microdata)."
    ))
  }

  year
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


#' Validate SI-PNI month parameter
#' @noRd
.sipni_validate_month <- function(month) {
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


#' Validate SI-PNI UF parameter
#' @noRd
.sipni_validate_uf <- function(uf) {
  uf <- toupper(uf)
  invalid <- uf[!uf %in% sipni_uf_list]

  if (length(invalid) > 0) {
    cli::cli_abort(c(
      "Invalid UF abbreviation(s): {.val {invalid}}.",
      "i" = "Valid values: {.val {sipni_uf_list}}"
    ))
  }

  uf
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
  if (is.null(cache_dir)) {
    cache_dir <- file.path(tools::R_user_dir("healthbR", "cache"), "sipni")
  }
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  cache_dir
}


#' Read a plain .DBF file and return as tibble
#' @noRd
.sipni_read_dbf <- function(path) {
  data <- foreign::read.dbf(path, as.is = TRUE)
  data <- lapply(data, as.character)
  tibble::as_tibble(data)
}


#' Download and read a SI-PNI .DBF file for one UF/year/type (FTP, 1994-2019)
#' @noRd
.sipni_download_and_read <- function(year, uf, type = "DPNI",
                                     cache = TRUE, cache_dir = NULL) {
  cache_dir <- .sipni_cache_dir(cache_dir)

  # determine cache file path
  cache_base <- stringr::str_c("sipni_", type, "_", uf, "_", year)
  cache_parquet <- file.path(cache_dir, stringr::str_c(cache_base, ".parquet"))
  cache_rds <- file.path(cache_dir, stringr::str_c(cache_base, ".rds"))

  # check cache
  if (isTRUE(cache)) {
    if (file.exists(cache_parquet) &&
        requireNamespace("arrow", quietly = TRUE)) {
      return(arrow::read_parquet(cache_parquet))
    }
    if (file.exists(cache_rds)) {
      return(readRDS(cache_rds))
    }
  }

  # build URL and download
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

  # check file size
  if (file.size(temp_dbf) < 100) {
    cli::cli_abort(c(
      "Downloaded file appears corrupted (too small).",
      "x" = "File size: {file.size(temp_dbf)} bytes",
      "i" = "The DATASUS FTP may be experiencing issues. Try again later."
    ))
  }

  # read .DBF directly (no DBC decompression needed)
  data <- .sipni_read_dbf(temp_dbf)

  # fix CPNI coverage decimal separator (comma -> dot)
  if (type == "CPNI" && "COBERT" %in% names(data)) {
    data$COBERT <- gsub(",", ".", data$COBERT)
  }

  # write to cache
  if (isTRUE(cache)) {
    if (requireNamespace("arrow", quietly = TRUE)) {
      tryCatch(
        arrow::write_parquet(data, cache_parquet),
        error = function(e) {
          cli::cli_warn("Failed to write parquet cache: {e$message}")
          saveRDS(data, cache_rds)
        }
      )
    } else {
      saveRDS(data, cache_rds)
    }
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


#' Download and read SI-PNI CSV data for one UF, one month
#'
#' Downloads the national monthly CSV ZIP from OpenDataSUS, reads it in
#' chunks filtering by UF to avoid loading the full file into memory,
#' and caches the result per UF/month.
#' @noRd
.sipni_csv_download_and_read_month <- function(year, month, uf,
                                               cache = TRUE,
                                               cache_dir = NULL) {
  cache_dir <- .sipni_cache_dir(cache_dir)
  mm <- sprintf("%02d", month)

  # check cache first
  cache_base <- stringr::str_c("sipni_API_", uf, "_", year, mm)
  cache_parquet <- file.path(cache_dir,
                             stringr::str_c(cache_base, ".parquet"))
  cache_rds <- file.path(cache_dir, stringr::str_c(cache_base, ".rds"))

  if (isTRUE(cache)) {
    if (file.exists(cache_parquet) &&
        requireNamespace("arrow", quietly = TRUE)) {
      return(arrow::read_parquet(cache_parquet))
    }
    if (file.exists(cache_rds)) {
      return(readRDS(cache_rds))
    }
  }

  # download ZIP
  url <- .sipni_csv_build_url(year, month)
  month_name <- sipni_month_names[month]

  cli::cli_inform(c(
    "i" = "Downloading SI-PNI CSV: {month_name} {year} (national file)..."
  ))

  temp_zip <- tempfile(fileext = ".zip")
  on.exit(if (file.exists(temp_zip)) file.remove(temp_zip), add = TRUE)

  tryCatch(
    curl::curl_download(url, temp_zip),
    error = function(e) {
      cli::cli_abort(c(
        "Failed to download SI-PNI CSV file.",
        "i" = "URL: {.url {url}}",
        "x" = "{e$message}"
      ))
    }
  )

  # extract CSV from ZIP
  temp_dir <- tempfile("sipni_csv")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  utils::unzip(temp_zip, exdir = temp_dir)
  # remove ZIP immediately to free disk space
  file.remove(temp_zip)

  csv_files <- list.files(temp_dir, pattern = "\\.csv$",
                          full.names = TRUE, recursive = TRUE)
  if (length(csv_files) == 0) {
    cli::cli_abort("No CSV file found inside the downloaded ZIP.")
  }
  csv_path <- csv_files[1]

  # read CSV in chunks, filtering by UF to avoid loading full file
  cli::cli_inform(c(
    "i" = "Reading and filtering by UF={uf}..."
  ))

  filtered_chunks <- list()
  chunk_idx <- 1L

  callback <- readr::SideEffectChunkCallback$new(function(chunk, pos) {
    if ("sigla_uf_estabelecimento" %in% names(chunk)) {
      match <- chunk[chunk$sigla_uf_estabelecimento == uf, ]
    } else if ("uf_estabelecimento" %in% names(chunk)) {
      match <- chunk[chunk$uf_estabelecimento == uf, ]
    } else {
      match <- chunk
    }
    if (nrow(match) > 0) {
      filtered_chunks[[chunk_idx]] <<- match
      chunk_idx <<- chunk_idx + 1L
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

  if (length(filtered_chunks) == 0) {
    cli::cli_warn(c(
      "!" = "No data found for UF={uf} in {month_name} {year}.",
      "i" = "The CSV may not contain data for this UF/month."
    ))
    return(tibble::tibble())
  }

  data <- dplyr::bind_rows(filtered_chunks)

  # write to cache
  if (isTRUE(cache)) {
    if (requireNamespace("arrow", quietly = TRUE)) {
      tryCatch(
        arrow::write_parquet(data, cache_parquet),
        error = function(e) {
          cli::cli_warn("Failed to write parquet cache: {e$message}")
          saveRDS(data, cache_rds)
        }
      )
    } else {
      saveRDS(data, cache_rds)
    }
  }

  data
}


#' Download and read SI-PNI data from OpenDataSUS CSV for one UF/year
#' @noRd
.sipni_api_download_and_read <- function(year, uf, month = 1L:12L,
                                         cache = TRUE, cache_dir = NULL) {
  results <- purrr::map(month, function(m) {
    tryCatch(
      .sipni_csv_download_and_read_month(year, m, uf,
                                         cache = cache,
                                         cache_dir = cache_dir),
      error = function(e) {
        cli::cli_warn(c(
          "!" = "Failed to download SI-PNI CSV for {uf} {sipni_month_names[m]} {year}.",
          "x" = "{e$message}"
        ))
        NULL
      }
    )
  })

  results <- results[!vapply(results, is.null, logical(1))]

  if (length(results) == 0) {
    return(tibble::tibble())
  }

  dplyr::bind_rows(results)
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
#' @param cache Logical. If TRUE (default), caches downloaded data for
#'   faster future access.
#' @param cache_dir Character. Directory for caching. Default:
#'   \code{tools::R_user_dir("healthbR", "cache")}.
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
                       vars = NULL, cache = TRUE, cache_dir = NULL) {

  # validate inputs
  year <- .sipni_validate_year(year)
  if (!is.null(uf)) uf <- .sipni_validate_uf(uf)

  # split years into FTP and API groups
  ftp_years <- year[year %in% sipni_ftp_years]
  api_years <- year[year %in% sipni_api_years]

  # validate type for FTP years
  if (length(ftp_years) > 0) {
    type <- .sipni_validate_type(type)
  }

  # warn if type specified for API years
  if (length(api_years) > 0 && !missing(type) && toupper(type) %in%
      c("DPNI", "CPNI")) {
    cli::cli_warn(c(
      "!" = "{.arg type} is ignored for years >= 2020 (API microdata).",
      "i" = "API data is always individual-level microdata (no DPNI/CPNI)."
    ))
  }

  # validate month (applies to API years; ignored for FTP)
  month_vals <- .sipni_validate_month(month)

  # validate vars
  if (!is.null(vars)) {
    effective_type <- if (length(api_years) > 0) "API" else type
    .sipni_validate_vars(vars, type = effective_type)
  }

  # determine UFs to download
  target_ufs <- if (!is.null(uf)) toupper(uf) else sipni_uf_list

  results <- list()

  # --- FTP path (1994-2019) ---
  if (length(ftp_years) > 0) {
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

    ftp_results <- purrr::map(seq_len(n_ftp), function(i) {
      yr <- ftp_combos$year[i]
      st <- ftp_combos$uf[i]

      tryCatch({
        data <- .sipni_download_and_read(yr, st, type = type,
                                         cache = cache, cache_dir = cache_dir)
        data$year <- as.integer(yr)
        data$uf_source <- st
        cols <- names(data)
        data <- data[, c("year", "uf_source",
                          setdiff(cols, c("year", "uf_source")))]
        data
      }, error = function(e) {
        cli::cli_warn(c(
          "!" = "Failed to download/read SI-PNI data for {type} {st} {yr}.",
          "x" = "{e$message}"
        ))
        NULL
      })
    })

    results <- c(results, ftp_results[!vapply(ftp_results, is.null,
                                              logical(1))])
  }

  # --- API path (2020+) ---
  if (length(api_years) > 0) {
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

    api_results <- purrr::map(seq_len(n_api), function(i) {
      yr <- api_combos$year[i]
      st <- api_combos$uf[i]

      tryCatch({
        data <- .sipni_api_download_and_read(
          yr, st, month = month_vals,
          cache = cache, cache_dir = cache_dir
        )
        if (nrow(data) == 0) return(NULL)
        data$year <- as.integer(yr)
        data$uf_source <- st
        cols <- names(data)
        data <- data[, c("year", "uf_source",
                          setdiff(cols, c("year", "uf_source")))]
        data
      }, error = function(e) {
        cli::cli_warn(c(
          "!" = "Failed to download SI-PNI CSV data for {st} {yr}.",
          "x" = "{e$message}"
        ))
        NULL
      })
    })

    results <- c(results, api_results[!vapply(api_results, is.null,
                                              logical(1))])
  }

  # combine results
  if (length(results) == 0) {
    cli::cli_abort(
      "No data could be downloaded for the requested year(s)/UF(s)."
    )
  }

  # bind FTP and API results separately to avoid column mismatch issues
  ftp_count <- length(ftp_years) * length(target_ufs)
  ftp_results_final <- if (ftp_count > 0 && length(results) > 0) {
    results[seq_len(min(ftp_count, length(results)))]
  } else {
    list()
  }
  ftp_results_final <- ftp_results_final[!vapply(ftp_results_final, is.null,
                                                  logical(1))]

  api_start <- ftp_count + 1
  api_results_final <- if (api_start <= length(results)) {
    results[api_start:length(results)]
  } else {
    list()
  }
  api_results_final <- api_results_final[!vapply(api_results_final, is.null,
                                                  logical(1))]

  # bind within groups (same schema), then across groups if both present
  bound_parts <- list()
  if (length(ftp_results_final) > 0) {
    bound_parts <- c(bound_parts, list(dplyr::bind_rows(ftp_results_final)))
  }
  if (length(api_results_final) > 0) {
    bound_parts <- c(bound_parts, list(dplyr::bind_rows(api_results_final)))
  }

  combined <- dplyr::bind_rows(bound_parts)

  # select variables if requested
  if (!is.null(vars)) {
    keep_cols <- unique(c("year", "uf_source", vars))
    keep_cols <- intersect(keep_cols, names(combined))
    combined <- combined[, keep_cols, drop = FALSE]
  }

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
  cache_dir <- .sipni_cache_dir(cache_dir)

  files <- list.files(cache_dir, pattern = "^sipni_.*\\.(parquet|rds)$",
                      full.names = TRUE)

  if (length(files) == 0) {
    cli::cli_inform("No cached SI-PNI files found.")
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
    "i" = "SI-PNI cache: {nrow(result)} file(s), {sum(result$size_mb)} MB total",
    "i" = "Cache directory: {.file {cache_dir}}"
  ))

  invisible(result)
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
  cache_dir <- .sipni_cache_dir(cache_dir)

  files <- list.files(cache_dir, pattern = "^sipni_.*\\.(parquet|rds)$",
                      full.names = TRUE)

  if (length(files) == 0) {
    cli::cli_inform("No cached SI-PNI files to clear.")
    return(invisible(NULL))
  }

  removed <- file.remove(files)
  n_removed <- sum(removed)

  cli::cli_inform(c(
    "v" = "Removed {n_removed} cached SI-PNI file(s)."
  ))

  invisible(NULL)
}
