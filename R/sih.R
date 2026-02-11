# sih functions for healthbR package
# functions to access hospital admission microdata from the SIH (Sistema de
# Informacoes Hospitalares) via DATASUS FTP

# ============================================================================
# internal validation functions
# ============================================================================

#' Validate SIH year parameter
#' @noRd
.sih_validate_year <- function(year, status = "all") {
  if (is.null(year) || length(year) == 0) {
    cli::cli_abort("{.arg year} is required.")
  }

  year <- as.integer(year)
  available <- sih_years(status = status)
  invalid <- year[!year %in% available]

  if (length(invalid) > 0) {
    cli::cli_abort(c(
      "Year(s) {.val {invalid}} not available.",
      "i" = "Available years: {.val {range(available)[[1]]}}--{.val {range(available)[[2]]}}",
      "i" = "Use {.code sih_years(status = 'all')} to see all options."
    ))
  }

  year
}


#' Validate SIH month parameter
#' @noRd
.sih_validate_month <- function(month) {
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


#' Validate SIH UF parameter
#' @noRd
.sih_validate_uf <- function(uf) {
  uf <- toupper(uf)
  invalid <- uf[!uf %in% sih_uf_list]

  if (length(invalid) > 0) {
    cli::cli_abort(c(
      "Invalid UF abbreviation(s): {.val {invalid}}.",
      "i" = "Valid values: {.val {sih_uf_list}}"
    ))
  }

  uf
}


#' Validate SIH vars parameter (warning only)
#' @noRd
.sih_validate_vars <- function(vars) {
  known_vars <- sih_variables_metadata$variable
  invalid <- vars[!vars %in% known_vars]

  if (length(invalid) > 0) {
    cli::cli_warn(c(
      "Variable(s) {.val {invalid}} not in known SIH variables.",
      "i" = "Use {.code sih_variables()} to see available variables.",
      "i" = "Proceeding anyway (variables will be dropped if not found)."
    ))
  }
}


# ============================================================================
# internal helper functions
# ============================================================================

#' Build FTP URL for SIH .dbc file
#' @noRd
.sih_build_ftp_url <- function(year, month, uf) {
  if (year < 2008L) {
    cli::cli_abort(
      "Year {.val {year}} is not supported. SIH data starts in 2008."
    )
  }

  yy <- sprintf("%02d", year %% 100)
  mm <- sprintf("%02d", month)

  stringr::str_c(
    "ftp://ftp.datasus.gov.br/dissemin/publicos/SIHSUS/200801_/Dados/",
    "RD", uf, yy, mm, ".dbc"
  )
}


#' Get/create SIH cache directory
#' @noRd
.sih_cache_dir <- function(cache_dir = NULL) {
  if (is.null(cache_dir)) {
    cache_dir <- file.path(tools::R_user_dir("healthbR", "cache"), "sih")
  }
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  cache_dir
}


#' Download and read a SIH .dbc file for one UF/year/month
#' @noRd
.sih_download_and_read <- function(year, month, uf, cache = TRUE,
                                   cache_dir = NULL) {
  cache_dir <- .sih_cache_dir(cache_dir)

  # determine cache file path (includes month)
  cache_base <- stringr::str_c("sih_", uf, "_", year, sprintf("%02d", month))
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
  url <- .sih_build_ftp_url(year, month, uf)
  temp_dbc <- tempfile(fileext = ".dbc")
  on.exit(if (file.exists(temp_dbc)) file.remove(temp_dbc), add = TRUE)

  cli::cli_inform(c(
    "i" = "Downloading SIH data: {uf} {year}/{sprintf('%02d', month)}..."
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
# exported functions
# ============================================================================

#' List Available SIH Years
#'
#' Returns an integer vector with years for which hospital admission microdata
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
#' @family sih
#'
#' @examples
#' sih_years()
#' sih_years(status = "all")
sih_years <- function(status = "final") {
  status <- match.arg(status, c("final", "preliminary", "all"))

  switch(status,
    "final" = sih_available_years$final,
    "preliminary" = sih_available_years$preliminary,
    "all" = sort(c(sih_available_years$final, sih_available_years$preliminary))
  )
}


#' SIH Module Information
#'
#' Displays information about the Hospital Information System (SIH),
#' including data sources, available years, and usage guidance.
#'
#' @return A list with module information (invisibly).
#'
#' @export
#' @family sih
#'
#' @examples
#' sih_info()
sih_info <- function() {
  final_range <- range(sih_available_years$final)
  prelim_range <- sih_available_years$preliminary

  cli::cli_h1("SIH \u2014 Sistema de Informa\u00e7\u00f5es Hospitalares")

  cli::cli_text("")
  cli::cli_text("Fonte:          Minist\u00e9rio da Sa\u00fade / DATASUS")
  cli::cli_text("Acesso:         FTP DATASUS")
  cli::cli_text("Documento base: Autoriza\u00e7\u00e3o de Interna\u00e7\u00e3o Hospitalar (AIH)")
  cli::cli_text("Granularidade:  Mensal (um arquivo por UF/m\u00eas)")

  cli::cli_h2("Dados dispon\u00edveis")
  cli::cli_bullets(c(
    "*" = "{.fun sih_data}: Microdados de interna\u00e7\u00f5es hospitalares",
    " " = "  Anos definitivos:   {final_range[1]}\u2013{final_range[2]}",
    " " = "  Anos preliminares:  {prelim_range}",
    "*" = "{.fun sih_variables}: Lista de vari\u00e1veis dispon\u00edveis",
    "*" = "{.fun sih_dictionary}: Dicion\u00e1rio completo com categorias"
  ))

  cli::cli_h2("Vari\u00e1veis-chave")
  cli::cli_text("  DIAG_PRINC  Diagn\u00f3stico principal (CID-10)")
  cli::cli_text("  DT_INTER    Data de interna\u00e7\u00e3o")
  cli::cli_text("  MUNIC_RES   Munic\u00edpio de resid\u00eancia (IBGE)")
  cli::cli_text("  SEXO        Sexo (0=Ign, 1=Masc, 3=Fem)")
  cli::cli_text("  MORTE       \u00d3bito hospitalar (0=N\u00e3o, 1=Sim)")
  cli::cli_text("  VAL_TOT     Valor total da AIH")

  cli::cli_text("")
  cli::cli_alert_info(
    "Dados mensais: use {.arg month} em {.fun sih_data} para selecionar meses."
  )

  invisible(list(
    name = "SIH - Sistema de Informa\u00e7\u00f5es Hospitalares",
    source = "DATASUS FTP",
    final_years = sih_available_years$final,
    preliminary_years = sih_available_years$preliminary,
    n_variables = nrow(sih_variables_metadata),
    url = "ftp://ftp.datasus.gov.br/dissemin/publicos/SIHSUS/"
  ))
}


#' List SIH Variables
#'
#' Returns a tibble with available variables in the SIH microdata,
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
#' @family sih
#'
#' @examples
#' sih_variables()
#' sih_variables(search = "diag")
#' sih_variables(search = "valor")
sih_variables <- function(year = NULL, search = NULL) {
  result <- sih_variables_metadata

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


#' SIH Data Dictionary
#'
#' Returns a tibble with the complete data dictionary for the SIH,
#' including variable descriptions and category labels.
#'
#' @param variable Character. If provided, returns dictionary for a specific
#'   variable only. Default: NULL (returns all variables).
#'
#' @return A tibble with columns: variable, description, code, label.
#'
#' @export
#' @family sih
#'
#' @examples
#' sih_dictionary()
#' sih_dictionary("SEXO")
#' sih_dictionary("CAR_INT")
sih_dictionary <- function(variable = NULL) {
  result <- sih_dictionary_data

  if (!is.null(variable)) {
    variable <- toupper(variable)
    result <- result[result$variable %in% variable, ]

    if (nrow(result) == 0) {
      cli::cli_warn(c(
        "Variable {.val {variable}} not found in SIH dictionary.",
        "i" = "Use {.code sih_dictionary()} to see all available variables."
      ))
    }
  }

  result
}


#' Download SIH Hospital Admission Microdata
#'
#' Downloads and returns hospital admission microdata from DATASUS FTP.
#' Each row represents one hospital admission record (AIH).
#' Data is organized monthly -- one .dbc file per state (UF) per month.
#'
#' @param year Integer. Year(s) of the data. Required.
#' @param month Integer. Month(s) of the data (1-12). If NULL (default),
#'   downloads all 12 months. Example: `1` (January), `1:6` (first semester).
#' @param vars Character vector. Variables to keep. If NULL (default),
#'   returns all available variables. Use [sih_variables()] to see
#'   available variables.
#' @param uf Character. Two-letter state abbreviation(s) to download.
#'   If NULL (default), downloads all 27 states.
#'   Example: `"SP"`, `c("SP", "RJ")`.
#' @param diagnosis Character. CID-10 code pattern(s) to filter by principal
#'   diagnosis (`DIAG_PRINC`). Supports partial matching (prefix).
#'   If NULL (default), returns all diagnoses.
#'   Example: `"I21"` (acute myocardial infarction), `"J"` (respiratory).
#' @param cache Logical. If TRUE (default), caches downloaded data for
#'   faster future access.
#' @param cache_dir Character. Directory for caching. Default:
#'   `tools::R_user_dir("healthbR", "cache")`.
#'
#' @return A tibble with hospital admission microdata. Includes columns
#'   `year`, `month`, and `uf_source` to identify the source when multiple
#'   years/months/states are combined.
#'
#' @details
#' Data is downloaded from DATASUS FTP as .dbc files (one per state per month).
#' The .dbc format is decompressed internally using vendored C code from the
#' blast library. No external dependencies are required.
#'
#' SIH data is monthly, so downloading an entire year for all states requires
#' 324 files (27 UFs x 12 months). Use `uf` and `month` to limit downloads.
#'
#' @export
#' @family sih
#'
#' @seealso [censo_populacao()] for population denominators to calculate
#'   hospitalization rates.
#'
#' @examples
#' \donttest{
#' # all admissions in Acre, January 2022
#' ac_jan <- sih_data(year = 2022, month = 1, uf = "AC")
#'
#' # heart attacks in Sao Paulo, first semester 2022
#' infarct_sp <- sih_data(year = 2022, month = 1:6, uf = "SP",
#'                         diagnosis = "I21")
#'
#' # only key variables, Rio de Janeiro, March 2022
#' sih_data(year = 2022, month = 3, uf = "RJ",
#'          vars = c("DIAG_PRINC", "DT_INTER", "SEXO",
#'                   "IDADE", "MORTE", "VAL_TOT"))
#' }
sih_data <- function(year, month = NULL, vars = NULL, uf = NULL,
                     diagnosis = NULL, cache = TRUE, cache_dir = NULL) {

  # validate inputs
  year <- .sih_validate_year(year)
  month <- .sih_validate_month(month)
  if (!is.null(uf)) uf <- .sih_validate_uf(uf)
  if (!is.null(vars)) .sih_validate_vars(vars)

  # determine UFs to download
  target_ufs <- if (!is.null(uf)) toupper(uf) else sih_uf_list

  # build all year x month x UF combinations
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

  # download and read each combination
  results <- purrr::map(seq_len(n_combos), function(i) {
    yr <- combinations$year[i]
    mo <- combinations$month[i]
    st <- combinations$uf[i]

    tryCatch({
      data <- .sih_download_and_read(yr, mo, st, cache = cache,
                                     cache_dir = cache_dir)
      data$year <- as.integer(yr)
      data$month <- as.integer(mo)
      data$uf_source <- st
      # move year, month, and uf_source to front
      cols <- names(data)
      data <- data[, c("year", "month", "uf_source",
                        setdiff(cols, c("year", "month", "uf_source")))]
      data
    }, error = function(e) {
      cli::cli_warn(c(
        "!" = "Failed to download/read SIH data for {st} {yr}/{sprintf('%02d', mo)}.",
        "x" = "{e$message}"
      ))
      NULL
    })
  })

  # remove NULLs and bind
  results <- results[!vapply(results, is.null, logical(1))]

  if (length(results) == 0) {
    cli::cli_abort("No data could be downloaded for the requested year(s)/month(s)/UF(s).")
  }

  results <- dplyr::bind_rows(results)

  # filter by diagnosis if requested
  if (!is.null(diagnosis)) {
    diag_pattern <- stringr::str_c(
      "^(", stringr::str_c(diagnosis, collapse = "|"), ")"
    )
    if ("DIAG_PRINC" %in% names(results)) {
      results <- results[grepl(diag_pattern, results$DIAG_PRINC), ]
    } else {
      cli::cli_warn(
        "Column {.var DIAG_PRINC} not found in data. Cannot filter by diagnosis."
      )
    }
  }

  # select variables if requested
  if (!is.null(vars)) {
    keep_cols <- unique(c("year", "month", "uf_source", vars))
    keep_cols <- intersect(keep_cols, names(results))
    results <- results[, keep_cols, drop = FALSE]
  }

  tibble::as_tibble(results)
}


#' Show SIH Cache Status
#'
#' Shows information about cached SIH data files.
#'
#' @param cache_dir Character. Cache directory path. Default:
#'   `tools::R_user_dir("healthbR", "cache")`.
#'
#' @return A tibble with cache file information (invisibly).
#'
#' @export
#' @family sih
#'
#' @examples
#' sih_cache_status()
sih_cache_status <- function(cache_dir = NULL) {
  cache_dir <- .sih_cache_dir(cache_dir)

  files <- list.files(cache_dir, pattern = "^sih_.*\\.(parquet|rds)$",
                      full.names = TRUE)

  if (length(files) == 0) {
    cli::cli_inform("No cached SIH files found.")
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
    "i" = "SIH cache: {nrow(result)} file(s), {sum(result$size_mb)} MB total",
    "i" = "Cache directory: {.file {cache_dir}}"
  ))

  invisible(result)
}


#' Clear SIH Cache
#'
#' Deletes cached SIH data files.
#'
#' @param cache_dir Character. Cache directory path. Default:
#'   `tools::R_user_dir("healthbR", "cache")`.
#'
#' @return Invisible NULL.
#'
#' @export
#' @family sih
#'
#' @examples
#' \donttest{
#' sih_clear_cache()
#' }
sih_clear_cache <- function(cache_dir = NULL) {
  cache_dir <- .sih_cache_dir(cache_dir)

  files <- list.files(cache_dir, pattern = "^sih_.*\\.(parquet|rds)$",
                      full.names = TRUE)

  if (length(files) == 0) {
    cli::cli_inform("No cached SIH files to clear.")
    return(invisible(NULL))
  }

  removed <- file.remove(files)
  n_removed <- sum(removed)

  cli::cli_inform(c(
    "v" = "Removed {n_removed} cached SIH file(s)."
  ))

  invisible(NULL)
}
