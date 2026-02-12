# sipni functions for healthbR package
# functions to access vaccination data from the SI-PNI (Sistema de Informacao
# do Programa Nacional de Imunizacoes) via DATASUS FTP

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
      "i" = "SI-PNI data on DATASUS FTP is available from 1994 to 2019."
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
      "i" = "DPNI = Doses aplicadas, CPNI = Cobertura vacinal."
    ))
  }

  type
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
  meta <- if (type == "CPNI") sipni_variables_cpni else sipni_variables_dpni
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
# internal helper functions
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


#' Download and read a SI-PNI .DBF file for one UF/year/type
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
# exported functions
# ============================================================================

#' List Available SI-PNI Years
#'
#' Returns an integer vector with years for which vaccination data are
#' available from DATASUS FTP.
#'
#' @return An integer vector of available years (1994--2019).
#'
#' @details
#' SI-PNI data on the DATASUS FTP is available from 1994 to 2019.
#' All data is definitive (no preliminary/final distinction).
#' Post-2019 data requires the SI-PNI web API (not yet supported).
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
  cli::cli_text("Acesso:         FTP DATASUS")
  cli::cli_text(
    "Dados:          Doses aplicadas e cobertura vacinal (dados agregados)"
  )
  cli::cli_text("Granularidade:  Anual (um arquivo por tipo/UF/ano)")

  cli::cli_h2("Dados dispon\u00edveis")
  cli::cli_bullets(c(
    "*" = "{.fun sipni_data}: Dados de vacina\u00e7\u00e3o (doses ou cobertura)",
    " " = "  Anos: {yr_range[1]}\u2013{yr_range[2]}",
    "*" = "{.fun sipni_variables}: Lista de vari\u00e1veis dispon\u00edveis",
    "*" = "{.fun sipni_dictionary}: Dicion\u00e1rio com categorias"
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

  cli::cli_text("")
  cli::cli_alert_info(
    "Dados agregados (contagens por munic\u00edpio/vacina/faixa), n\u00e3o microdados."
  )
  cli::cli_alert_info(
    "Use {.arg type} em {.fun sipni_data}: DPNI (doses) ou CPNI (cobertura)."
  )
  cli::cli_alert_info(
    "Dados no FTP dispon\u00edveis at\u00e9 2019. P\u00f3s-2019 requer API web (futuro)."
  )

  invisible(list(
    name = "SI-PNI - Sistema de Informa\u00e7\u00e3o do Programa Nacional de Imuniza\u00e7\u00f5es",
    source = "DATASUS FTP",
    years = sipni_available_years,
    n_types = nrow(sipni_valid_types),
    n_variables_dpni = nrow(sipni_variables_dpni),
    n_variables_cpni = nrow(sipni_variables_cpni),
    url = "ftp://ftp.datasus.gov.br/dissemin/publicos/PNI/"
  ))
}


#' List SI-PNI Variables
#'
#' Returns a tibble with available variables in the SI-PNI data,
#' including descriptions and value types.
#'
#' @param type Character. File type to show variables for.
#'   \code{"DPNI"} (default) for doses applied, \code{"CPNI"} for coverage.
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
#' sipni_variables(search = "dose")
sipni_variables <- function(type = "DPNI", search = NULL) {
  type <- .sipni_validate_type(type)
  result <- if (type == "CPNI") sipni_variables_cpni else sipni_variables_dpni

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
#' Returns a tibble with the data dictionary for the SI-PNI,
#' including variable descriptions and category labels.
#'
#' @param variable Character. If provided, returns dictionary for a specific
#'   variable only. Default: NULL (returns all variables).
#'
#' @return A tibble with columns: variable, description, code, label.
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
        "i" = "Use {.code sipni_dictionary()} to see all available variables."
      ))
    }
  }

  result
}


#' Download SI-PNI Vaccination Data
#'
#' Downloads and returns vaccination data (doses applied or coverage) from
#' DATASUS FTP. Data is aggregated (counts per municipality/vaccine/age group),
#' not individual-level microdata.
#'
#' @param year Integer. Year(s) of the data. Required.
#' @param type Character. File type to download. Default: \code{"DPNI"}
#'   (doses applied). Use \code{"CPNI"} for vaccination coverage.
#'   See \code{\link{sipni_info}()} for details.
#' @param uf Character. Two-letter state abbreviation(s) to download.
#'   If NULL (default), downloads all 27 states.
#'   Example: \code{"SP"}, \code{c("SP", "RJ")}.
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
#' @details
#' Data is downloaded from DATASUS FTP as plain .DBF files (one per
#' type/state/year). Unlike other DATASUS modules, SI-PNI files are not
#' DBC-compressed.
#'
#' SI-PNI data is **aggregated** (dose counts and coverage rates per
#' municipality, vaccine, and age group), not individual-level microdata.
#'
#' Two file types are available:
#' \itemize{
#'   \item \code{"DPNI"} (default): Doses applied -- monthly data within each
#'     annual file, with age group and dose type breakdowns.
#'   \item \code{"CPNI"}: Vaccination coverage -- annual rates including
#'     target population and coverage percentage.
#' }
#'
#' Data on DATASUS FTP is available from 1994 to 2019. Post-2019 data
#' requires the SI-PNI web API (not yet supported).
#'
#' @export
#' @family sipni
#'
#' @seealso \code{\link{sipni_info}()} for type descriptions,
#'   \code{\link{censo_populacao}()} for population denominators.
#'
#' @examplesIf interactive()
#' # doses applied in Acre, 2019
#' ac_doses <- sipni_data(year = 2019, uf = "AC")
#'
#' # vaccination coverage in Acre, 2019
#' ac_cob <- sipni_data(year = 2019, type = "CPNI", uf = "AC")
#'
#' # only key variables
#' sipni_data(year = 2019, uf = "AC",
#'            vars = c("IMUNO", "QT_DOSE", "DOSE", "FX_ETARIA"))
sipni_data <- function(year, type = "DPNI", uf = NULL, vars = NULL,
                       cache = TRUE, cache_dir = NULL) {

  # validate inputs
  year <- .sipni_validate_year(year)
  type <- .sipni_validate_type(type)
  if (!is.null(uf)) uf <- .sipni_validate_uf(uf)
  if (!is.null(vars)) .sipni_validate_vars(vars, type = type)

  # determine UFs to download
  target_ufs <- if (!is.null(uf)) toupper(uf) else sipni_uf_list

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
  results <- purrr::map(seq_len(n_combos), function(i) {
    yr <- combinations$year[i]
    st <- combinations$uf[i]

    tryCatch({
      data <- .sipni_download_and_read(yr, st, type = type,
                                       cache = cache, cache_dir = cache_dir)
      data$year <- as.integer(yr)
      data$uf_source <- st
      # move year and uf_source to front
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

  # remove NULLs and bind
  results <- results[!vapply(results, is.null, logical(1))]

  if (length(results) == 0) {
    cli::cli_abort(
      "No data could be downloaded for the requested year(s)/UF(s)."
    )
  }

  results <- dplyr::bind_rows(results)

  # select variables if requested
  if (!is.null(vars)) {
    keep_cols <- unique(c("year", "uf_source", vars))
    keep_cols <- intersect(keep_cols, names(results))
    results <- results[, keep_cols, drop = FALSE]
  }

  tibble::as_tibble(results)
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
