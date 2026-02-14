# cnes functions for healthbR package
# functions to access health facility registry data from the CNES (Cadastro
# Nacional de Estabelecimentos de Saude) via DATASUS FTP

# ============================================================================
# internal validation functions
# ============================================================================

#' Validate CNES year parameter
#' @noRd
.cnes_validate_year <- function(year, status = "all") {
  if (is.null(year) || length(year) == 0) {
    cli::cli_abort("{.arg year} is required.")
  }

  year <- as.integer(year)
  available <- cnes_years(status = status)
  invalid <- year[!year %in% available]

  if (length(invalid) > 0) {
    cli::cli_abort(c(
      "Year(s) {.val {invalid}} not available.",
      "i" = "Available years: {.val {range(available)[[1]]}}--{.val {range(available)[[2]]}}",
      "i" = "Use {.code cnes_years(status = 'all')} to see all options."
    ))
  }

  year
}


#' Validate CNES month parameter
#' @noRd
.cnes_validate_month <- function(month) {
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


#' Validate CNES UF parameter
#' @noRd
.cnes_validate_uf <- function(uf) {
  uf <- toupper(uf)
  invalid <- uf[!uf %in% cnes_uf_list]

  if (length(invalid) > 0) {
    cli::cli_abort(c(
      "Invalid UF abbreviation(s): {.val {invalid}}.",
      "i" = "Valid values: {.val {cnes_uf_list}}"
    ))
  }

  uf
}


#' Validate CNES type parameter
#' @noRd
.cnes_validate_type <- function(type) {
  type <- toupper(type)
  valid_codes <- cnes_valid_types$code

  if (!type %in% valid_codes) {
    cli::cli_abort(c(
      "Invalid CNES type: {.val {type}}.",
      "i" = "Valid types: {.val {valid_codes}}",
      "i" = "Use {.code cnes_info()} to see type descriptions."
    ))
  }

  type
}


#' Validate CNES vars parameter (warning only)
#' @noRd
.cnes_validate_vars <- function(vars) {
  known_vars <- cnes_variables_metadata$variable
  invalid <- vars[!vars %in% known_vars]

  if (length(invalid) > 0) {
    cli::cli_warn(c(
      "Variable(s) {.val {invalid}} not in known CNES variables.",
      "i" = "Use {.code cnes_variables()} to see available variables.",
      "i" = "Proceeding anyway (variables will be dropped if not found)."
    ))
  }
}


# ============================================================================
# internal helper functions
# ============================================================================

#' Build FTP URL for CNES .dbc file
#' @noRd
.cnes_build_ftp_url <- function(year, month, uf, type = "ST") {
  if (year < 2005L) {
    cli::cli_abort(
      "Year {.val {year}} is not supported. CNES data starts in 2005."
    )
  }

  yy <- sprintf("%02d", year %% 100)
  mm <- sprintf("%02d", month)

  stringr::str_c(
    "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/",
    type, "/", type, uf, yy, mm, ".dbc"
  )
}


#' Get/create CNES cache directory
#' @noRd
.cnes_cache_dir <- function(cache_dir = NULL) {
  .module_cache_dir("cnes", cache_dir)
}


#' Download and read a CNES .dbc file for one UF/year/month/type
#'
#' Returns a tibble with `year`, `month`, and `uf_source` columns already added.
#' Uses partitioned cache (Hive-style) when arrow is available, with
#' flat cache as migration fallback.
#'
#' @noRd
.cnes_download_and_read <- function(year, month, uf, type = "ST",
                                    cache = TRUE, cache_dir = NULL) {
  cache_dir <- .cnes_cache_dir(cache_dir)
  dataset_name <- "cnes_data"
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

  # 2. fall back to flat cache (migration from old format)
  if (isTRUE(cache)) {
    flat_base <- stringr::str_c(
      "cnes_", type, "_", uf, "_", year, sprintf("%02d", month)
    )
    flat_cached <- .cache_read(cache_dir, flat_base)
    if (!is.null(flat_cached)) {
      flat_cached$year <- target_year
      flat_cached$month <- target_month
      flat_cached$uf_source <- target_uf
      cols <- names(flat_cached)
      flat_cached <- flat_cached[, c("year", "month", "uf_source",
                                      setdiff(cols, c("year", "month", "uf_source")))]
      return(flat_cached)
    }
  }

  # 3. download from FTP
  url <- .cnes_build_ftp_url(year, month, uf, type)
  temp_dbc <- tempfile(fileext = ".dbc")
  on.exit(if (file.exists(temp_dbc)) file.remove(temp_dbc), add = TRUE)

  cli::cli_inform(c(
    "i" = "Downloading CNES data: {type} {uf} {year}/{sprintf('%02d', month)}..."
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

#' List Available CNES Years
#'
#' Returns an integer vector with years for which health facility registry
#' data are available from DATASUS FTP.
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
#' @family cnes
#'
#' @examples
#' cnes_years()
#' cnes_years(status = "all")
cnes_years <- function(status = "final") {
  status <- match.arg(status, c("final", "preliminary", "all"))

  switch(status,
    "final" = cnes_available_years$final,
    "preliminary" = cnes_available_years$preliminary,
    "all" = sort(c(cnes_available_years$final, cnes_available_years$preliminary))
  )
}


#' CNES Module Information
#'
#' Displays information about the National Health Facility Registry (CNES),
#' including data sources, available years, file types, and usage guidance.
#'
#' @return A list with module information (invisibly).
#'
#' @export
#' @family cnes
#'
#' @examples
#' cnes_info()
cnes_info <- function() {
  final_range <- range(cnes_available_years$final)
  prelim_range <- cnes_available_years$preliminary

  cli::cli_h1("CNES \u2014 Cadastro Nacional de Estabelecimentos de Sa\u00fade")

  cli::cli_text("")
  cli::cli_text("Fonte:          Minist\u00e9rio da Sa\u00fade / DATASUS")
  cli::cli_text("Acesso:         FTP DATASUS")
  cli::cli_text("Documento base: Cadastro Nacional de Estabelecimentos de Sa\u00fade")
  cli::cli_text("Granularidade:  Mensal (um arquivo por tipo/UF/m\u00eas)")

  cli::cli_h2("Dados dispon\u00edveis")
  cli::cli_bullets(c(
    "*" = "{.fun cnes_data}: Dados cadastrais de estabelecimentos de sa\u00fade",
    " " = "  Anos definitivos:   {final_range[1]}\u2013{final_range[2]}",
    " " = "  Anos preliminares:  {prelim_range}",
    "*" = "{.fun cnes_variables}: Lista de vari\u00e1veis dispon\u00edveis",
    "*" = "{.fun cnes_dictionary}: Dicion\u00e1rio completo com categorias"
  ))

  cli::cli_h2("Tipos de arquivo")
  for (i in seq_len(nrow(cnes_valid_types))) {
    cli::cli_text(
      "  {cnes_valid_types$code[i]}   {cnes_valid_types$name[i]} \u2014 {cnes_valid_types$description[i]}"
    )
  }

  cli::cli_h2("Vari\u00e1veis-chave (ST)")
  cli::cli_text("  CNES       C\u00f3digo CNES do estabelecimento")
  cli::cli_text("  CODUFMUN   Munic\u00edpio (UF + IBGE 6 d\u00edgitos)")
  cli::cli_text("  TP_UNID    Tipo de unidade")
  cli::cli_text("  VINC_SUS   V\u00ednculo SUS (0=N\u00e3o, 1=Sim)")
  cli::cli_text("  TP_GESTAO  Tipo de gest\u00e3o (M/E/D/S)")

  cli::cli_text("")
  cli::cli_alert_info(
    "Dados mensais: use {.arg month} em {.fun cnes_data} para selecionar meses."
  )
  cli::cli_alert_info(
    "Use {.arg type} em {.fun cnes_data} para selecionar o tipo (padr\u00e3o: ST)."
  )

  invisible(list(
    name = "CNES - Cadastro Nacional de Estabelecimentos de Sa\u00fade",
    source = "DATASUS FTP",
    final_years = cnes_available_years$final,
    preliminary_years = cnes_available_years$preliminary,
    n_variables = nrow(cnes_variables_metadata),
    n_types = nrow(cnes_valid_types),
    url = "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/"
  ))
}


#' List CNES Variables
#'
#' Returns a tibble with available variables in the CNES data (ST type),
#' including descriptions and value types.
#'
#' @param type Character. File type to show variables for. Currently only
#'   \code{"ST"} is fully documented. Default: \code{"ST"}.
#' @param search Character. Optional search term to filter variables by
#'   name or description. Case-insensitive and accent-insensitive.
#'
#' @return A tibble with columns: variable, description, type, section.
#'
#' @export
#' @family cnes
#'
#' @examples
#' cnes_variables()
#' cnes_variables(search = "tipo")
#' cnes_variables(search = "gestao")
cnes_variables <- function(type = "ST", search = NULL) {
  result <- cnes_variables_metadata

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


#' CNES Data Dictionary
#'
#' Returns a tibble with the complete data dictionary for the CNES,
#' including variable descriptions and category labels.
#'
#' @param variable Character. If provided, returns dictionary for a specific
#'   variable only. Default: NULL (returns all variables).
#'
#' @return A tibble with columns: variable, description, code, label.
#'
#' @export
#' @family cnes
#'
#' @examples
#' cnes_dictionary()
#' cnes_dictionary("TP_UNID")
#' cnes_dictionary("ESFERA_A")
cnes_dictionary <- function(variable = NULL) {
  result <- cnes_dictionary_data

  if (!is.null(variable)) {
    variable <- toupper(variable)
    result <- result[result$variable %in% variable, ]

    if (nrow(result) == 0) {
      cli::cli_warn(c(
        "Variable {.val {variable}} not found in CNES dictionary.",
        "i" = "Use {.code cnes_dictionary()} to see all available variables."
      ))
    }
  }

  result
}


#' Download CNES Health Facility Registry Data
#'
#' Downloads and returns health facility registry data from DATASUS FTP.
#' Each row represents one health facility record (for the ST type).
#' Data is organized monthly -- one .dbc file per type, state (UF), and month.
#'
#' @param year Integer. Year(s) of the data. Required.
#' @param type Character. File type to download. Default: \code{"ST"}
#'   (establishments). See \code{\link{cnes_info}()} for all 13 types.
#' @param month Integer. Month(s) of the data (1-12). If NULL (default),
#'   downloads all 12 months. Example: \code{1} (January), \code{1:6}
#'   (first semester).
#' @param vars Character vector. Variables to keep. If NULL (default),
#'   returns all available variables. Use \code{\link{cnes_variables}()} to see
#'   available variables.
#' @param uf Character. Two-letter state abbreviation(s) to download.
#'   If NULL (default), downloads all 27 states.
#'   Example: \code{"SP"}, \code{c("SP", "RJ")}.
#' @param parse Logical. If TRUE (default), converts columns to
#'   appropriate types (integer, double, Date) based on the variable
#'   metadata. Use \code{\link{cnes_variables}()} to see the target type for
#'   each variable. Set to FALSE for backward-compatible all-character output.
#' @param col_types Named list. Override the default type for specific
#'   columns. Names are column names, values are type strings:
#'   \code{"character"}, \code{"integer"}, \code{"double"},
#'   \code{"date_dmy"}, \code{"date_ymd"}, \code{"date_ym"}, \code{"date"}.
#'   Example: \code{list(COMPETEN = "character")} to keep COMPETEN as character.
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
#' @return A tibble with health facility data. Includes columns
#'   \code{year}, \code{month}, and \code{uf_source} to identify the source
#'   when multiple years/months/states are combined.
#'
#' @details
#' Data is downloaded from DATASUS FTP as .dbc files (one per type/state/month).
#' The .dbc format is decompressed internally using vendored C code from the
#' blast library. No external dependencies are required.
#'
#' CNES data is monthly, so downloading an entire year for all states requires
#' 324 files (27 UFs x 12 months) per type. Use \code{uf} and \code{month}
#' to limit downloads.
#'
#' The CNES has 13 file types. The default \code{"ST"} (establishments) is
#' the most commonly used. Use \code{\link{cnes_info}()} to see all types.
#'
#' @export
#' @family cnes
#'
#' @seealso \code{\link{cnes_info}()} for file type descriptions,
#'   \code{\link{censo_populacao}()} for population denominators.
#'
#' @examplesIf interactive()
#' # all establishments in Acre, January 2023
#' ac_jan <- cnes_data(year = 2023, month = 1, uf = "AC")
#'
#' # only key variables
#' cnes_data(year = 2023, month = 1, uf = "AC",
#'           vars = c("CNES", "CODUFMUN", "TP_UNID", "VINC_SUS"))
#'
#' # hospital beds
#' leitos <- cnes_data(year = 2023, month = 1, uf = "AC", type = "LT")
#'
#' # health professionals
#' prof <- cnes_data(year = 2023, month = 1, uf = "AC", type = "PF")
cnes_data <- function(year, type = "ST", month = NULL, vars = NULL, uf = NULL,
                      parse = TRUE, col_types = NULL,
                      cache = TRUE, cache_dir = NULL,
                      lazy = FALSE, backend = c("arrow", "duckdb")) {

  # validate inputs
  year <- .cnes_validate_year(year)
  type <- .cnes_validate_type(type)
  month <- .cnes_validate_month(month)
  if (!is.null(uf)) uf <- .cnes_validate_uf(uf)
  if (!is.null(vars)) .cnes_validate_vars(vars)

  # determine UFs to download
  target_ufs <- if (!is.null(uf)) toupper(uf) else cnes_uf_list

  # compute lazy args once
  cache_dir_resolved <- .cnes_cache_dir(cache_dir)
  lazy_filters <- list(year = year, uf_source = target_ufs)
  if (!is.null(month)) lazy_filters$month <- as.integer(month)
  lazy_select <- if (!is.null(vars)) unique(c("year", "month", "uf_source", vars)) else NULL

  # pre-download lazy check
  ds <- .try_lazy_cache(lazy, backend, cache_dir_resolved, "cnes_data",
                        lazy_filters, lazy_select, parse = parse)
  if (!is.null(ds)) return(ds)

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
  labels <- paste(type, combinations$uf,
                  paste0(combinations$year, "/", sprintf("%02d", combinations$month)))

  results <- .map_parallel(seq_len(n_combos), .delay = 0.5, function(i) {
    yr <- combinations$year[i]
    mo <- combinations$month[i]
    st <- combinations$uf[i]

    tryCatch({
      .cnes_download_and_read(yr, mo, st, type = type,
                              cache = cache, cache_dir = cache_dir)
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
      "No data could be downloaded for the requested year(s)/month(s)/UF(s)."
    )
  }

  results <- dplyr::bind_rows(results)

  # parse column types
  if (isTRUE(parse) && !isTRUE(lazy)) {
    type_spec <- .build_type_spec(cnes_variables_metadata)
    results <- .parse_columns(results, type_spec, col_types = col_types)
  }

  .data_return(results, lazy, backend, cache_dir_resolved, "cnes_data",
               lazy_filters, lazy_select, failed_labels, "CNES")
}


#' Show CNES Cache Status
#'
#' Shows information about cached CNES data files.
#'
#' @param cache_dir Character. Cache directory path. Default:
#'   \code{tools::R_user_dir("healthbR", "cache")}.
#'
#' @return A tibble with cache file information (invisibly).
#'
#' @export
#' @family cnes
#'
#' @examples
#' cnes_cache_status()
cnes_cache_status <- function(cache_dir = NULL) {
  cache_dir <- .cnes_cache_dir(cache_dir)

  files <- list.files(cache_dir, pattern = "^cnes_.*\\.(parquet|rds)$",
                      full.names = TRUE)

  if (length(files) == 0) {
    cli::cli_inform("No cached CNES files found.")
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
    "i" = "CNES cache: {nrow(result)} file(s), {sum(result$size_mb)} MB total",
    "i" = "Cache directory: {.file {cache_dir}}"
  ))

  invisible(result)
}


#' Clear CNES Cache
#'
#' Deletes cached CNES data files.
#'
#' @param cache_dir Character. Cache directory path. Default:
#'   \code{tools::R_user_dir("healthbR", "cache")}.
#'
#' @return Invisible NULL.
#'
#' @export
#' @family cnes
#'
#' @examplesIf interactive()
#' cnes_clear_cache()
cnes_clear_cache <- function(cache_dir = NULL) {
  cache_dir <- .cnes_cache_dir(cache_dir)

  files <- list.files(cache_dir, pattern = "^cnes_.*\\.(parquet|rds)$",
                      full.names = TRUE)

  if (length(files) == 0) {
    cli::cli_inform("No cached CNES files to clear.")
    return(invisible(NULL))
  }

  removed <- file.remove(files)
  n_removed <- sum(removed)

  cli::cli_inform(c(
    "v" = "Removed {n_removed} cached CNES file(s)."
  ))

  invisible(NULL)
}
