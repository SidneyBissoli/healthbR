# sim functions for healthbR package
# functions to access mortality microdata from the SIM (Sistema de
# Informacoes sobre Mortalidade) via DATASUS FTP

# ============================================================================
# internal validation functions
# ============================================================================

#' Validate SIM year parameter
#' @noRd
.sim_validate_year <- function(year, status = "all") {
  .validate_year(year, sim_years(status = status),
                 years_fn_hint = "sim_years(status = 'all')")
}

#' Validate SIM UF parameter
#' @noRd
.sim_validate_uf <- function(uf) {
  .validate_uf(uf, sim_uf_list)
}


#' Validate SIM vars parameter (warning only)
#' @noRd
.sim_validate_vars <- function(vars) {
  known_vars <- sim_variables_metadata$variable
  invalid <- vars[!vars %in% known_vars]

  if (length(invalid) > 0) {
    cli::cli_warn(c(
      "Variable(s) {.val {invalid}} not in known SIM variables.",
      "i" = "Use {.code sim_variables()} to see available variables.",
      "i" = "Proceeding anyway (variables will be dropped if not found)."
    ))
  }
}


# ============================================================================
# internal helper functions
# ============================================================================

#' Convert UF abbreviation to IBGE code
#' @noRd
.sim_uf_to_code <- function(uf) {
  uf <- toupper(uf)
  invalid <- uf[!uf %in% names(sim_uf_codes)]

  if (length(invalid) > 0) {
    cli::cli_abort(c(
      "Invalid UF abbreviation(s): {.val {invalid}}.",
      "i" = "Valid values: {.val {names(sim_uf_codes)}}"
    ))
  }

  unname(sim_uf_codes[uf])
}


#' Build FTP URL for SIM .dbc file
#' @noRd
.sim_build_ftp_url <- function(year, uf) {
  if (year >= 1996) {
    # CID-10: DO{UF}{YYYY}.dbc
    stringr::str_c(
      "ftp://ftp.datasus.gov.br/dissemin/publicos/SIM/CID10/DORES/",
      "DO", uf, year, ".dbc"
    )
  } else {
    cli::cli_abort(
      "Year {.val {year}} is not supported. SIM CID-10 data starts in 1996."
    )
  }
}


#' Get/create SIM cache directory
#' @noRd
.sim_cache_dir <- function(cache_dir = NULL) {
  .module_cache_dir("sim", cache_dir)
}


#' Decode SIM IDADE variable to years
#'
#' The IDADE variable is a 3-digit code where the first digit encodes the
#' unit (0=minutes, 1=hours, 2=days, 3=months, 4=years, 5=100+ years)
#' and the last two digits encode the value.
#'
#' @param idade Character vector. The raw IDADE values.
#'
#' @return Numeric vector. Age in years (fractions for < 1 year).
#'
#' @noRd
.sim_decode_age <- function(idade) {
  # handle NA and empty strings
  idade <- ifelse(idade == "" | is.na(idade), NA_character_, idade)

  # extract unit (1st digit) and value (2nd-3rd digits)
  unit <- as.integer(substr(idade, 1, 1))
  value <- as.integer(substr(idade, 2, 3))

  dplyr::case_when(
    is.na(unit) | is.na(value) ~ NA_real_,
    unit == 0L ~ value / (365.25 * 24 * 60),   # minutes to years
    unit == 1L ~ value / (365.25 * 24),         # hours to years
    unit == 2L ~ value / 365.25,                # days to years
    unit == 3L ~ value / 12,                    # months to years
    unit == 4L ~ as.double(value),              # years (0-99)
    unit == 5L ~ 100 + as.double(value),        # 100+ years
    TRUE ~ NA_real_
  )
}


#' Download and read a SIM .dbc file for one UF/year
#'
#' Returns a tibble with `year` and `uf_source` columns already added.
#' Uses partitioned cache (Hive-style) when arrow is available, with
#' flat cache as migration fallback.
#'
#' @noRd
.sim_download_and_read <- function(year, uf, cache = TRUE, cache_dir = NULL) {
  cache_dir <- .sim_cache_dir(cache_dir)
  dataset_name <- "sim_data"
  target_year <- as.integer(year)
  target_uf <- uf

  # 1. check partitioned cache first (preferred path)
  if (isTRUE(cache) && .has_arrow() &&
      .has_partitioned_cache(cache_dir, dataset_name)) {
    ds <- arrow::open_dataset(file.path(cache_dir, dataset_name))
    cached <- ds |>
      dplyr::filter(.data$uf_source == target_uf,
                     .data$year == target_year) |>
      dplyr::collect()
    if (nrow(cached) > 0) return(cached)
  }

  # 2. fall back to flat cache (migration from old format)
  if (isTRUE(cache)) {
    flat_base <- stringr::str_c("sim_", uf, "_", year)
    flat_cached <- .cache_read(cache_dir, flat_base)
    if (!is.null(flat_cached)) {
      .warn_flat_cache("sim")
      flat_cached$year <- target_year
      flat_cached$uf_source <- target_uf
      cols <- names(flat_cached)
      flat_cached <- flat_cached[, c("year", "uf_source",
                                      setdiff(cols, c("year", "uf_source")))]
      return(flat_cached)
    }
  }

  # 3. download from FTP
  url <- .sim_build_ftp_url(year, uf)
  temp_dbc <- tempfile(fileext = ".dbc")
  on.exit(if (file.exists(temp_dbc)) file.remove(temp_dbc), add = TRUE)

  cli::cli_inform(c(
    "i" = "Downloading SIM data: {uf} {year}..."
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

#' List Available SIM Years
#'
#' Returns an integer vector with years for which mortality microdata are
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
#' @family sim
#'
#' @examples
#' sim_years()
#' sim_years(status = "all")
sim_years <- function(status = "final") {
  status <- match.arg(status, c("final", "preliminary", "all"))

  switch(status,
    "final" = sim_available_years$final,
    "preliminary" = sim_available_years$preliminary,
    "all" = sort(c(sim_available_years$final, sim_available_years$preliminary))
  )
}


#' SIM Module Information
#'
#' Displays information about the Mortality Information System (SIM),
#' including data sources, available years, and usage guidance.
#'
#' @return A list with module information (invisibly).
#'
#' @export
#' @family sim
#'
#' @examples
#' sim_info()
sim_info <- function() {
  final_range <- range(sim_available_years$final)
  prelim_range <- range(sim_available_years$preliminary)

  cli::cli_h1("SIM \u2014 Sistema de Informa\u00e7\u00f5es sobre Mortalidade")

  cli::cli_text("")
  cli::cli_text("Fonte:          Minist\u00e9rio da Sa\u00fade / DATASUS")
  cli::cli_text("Acesso:         FTP DATASUS")
  cli::cli_text("Documento base: Declara\u00e7\u00e3o de \u00d3bito (DO)")

  cli::cli_h2("Dados dispon\u00edveis")
  cli::cli_bullets(c(
    "*" = "{.fun sim_data}: Microdados de mortalidade",
    " " = "  Anos definitivos:   {final_range[1]}\u2013{final_range[2]}",
    " " = "  Anos preliminares:  {prelim_range[1]}\u2013{prelim_range[2]}",
    "*" = "{.fun sim_variables}: Lista de vari\u00e1veis dispon\u00edveis",
    "*" = "{.fun sim_dictionary}: Dicion\u00e1rio completo com categorias"
  ))

  cli::cli_h2("Vari\u00e1veis-chave")
  cli::cli_text("  CAUSABAS    Causa b\u00e1sica do \u00f3bito (CID-10)")
  cli::cli_text("  DTOBITO     Data do \u00f3bito")
  cli::cli_text("  CODMUNRES   Munic\u00edpio de resid\u00eancia (IBGE)")
  cli::cli_text("  SEXO        Sexo")
  cli::cli_text("  IDADE       Idade (codificada)")
  cli::cli_text("  RACACOR     Ra\u00e7a/cor")

  cli::cli_text("")
  cli::cli_alert_info(
    "Use com {.fun censo_populacao} para calcular taxas de mortalidade."
  )

  invisible(list(
    name = "SIM - Sistema de Informa\u00e7\u00f5es sobre Mortalidade",
    source = "DATASUS FTP",
    final_years = sim_available_years$final,
    preliminary_years = sim_available_years$preliminary,
    n_variables = nrow(sim_variables_metadata),
    url = "ftp://ftp.datasus.gov.br/dissemin/publicos/SIM/"
  ))
}


#' List SIM Variables
#'
#' Returns a tibble with available variables in the SIM microdata,
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
#' @family sim
#'
#' @examples
#' sim_variables()
#' sim_variables(search = "causa")
#' sim_variables(search = "mae")
sim_variables <- function(year = NULL, search = NULL) {
  result <- sim_variables_metadata

  result <- .search_metadata(result, search, c("variable", "description"))

  result
}


#' SIM Data Dictionary
#'
#' Returns a tibble with the complete data dictionary for the SIM,
#' including variable descriptions and category labels.
#'
#' @param variable Character. If provided, returns dictionary for a specific
#'   variable only. Default: NULL (returns all variables).
#'
#' @return A tibble with columns: variable, description, code, label.
#'
#' @export
#' @family sim
#'
#' @examples
#' sim_dictionary()
#' sim_dictionary("SEXO")
#' sim_dictionary("RACACOR")
sim_dictionary <- function(variable = NULL) {
  result <- sim_dictionary_data

  if (!is.null(variable)) {
    variable <- toupper(variable)
    result <- result[result$variable %in% variable, ]

    if (nrow(result) == 0) {
      cli::cli_warn(c(
        "Variable {.val {variable}} not found in SIM dictionary.",
        "i" = "Use {.code sim_dictionary()} to see all available variables."
      ))
    }
  }

  result
}


#' Download SIM Mortality Microdata
#'
#' Downloads and returns mortality microdata from DATASUS FTP.
#' Each row represents one death record (Declaracao de Obito).
#' Data is downloaded per state (UF) as compressed .dbc files, decompressed
#' internally, and returned as a tibble.
#'
#' @param year Integer. Year(s) of the data. Required.
#' @param vars Character vector. Variables to keep. If NULL (default),
#'   returns all available variables. Use [sim_variables()] to see
#'   available variables.
#' @param uf Character. Two-letter state abbreviation(s) to download.
#'   If NULL (default), downloads all 27 states.
#'   Example: `"SP"`, `c("SP", "RJ")`.
#' @param cause Character. CID-10 code pattern(s) to filter by cause of
#'   death (`CAUSABAS`). Supports partial matching (prefix).
#'   If NULL (default), returns all causes.
#'   Example: `"I21"` (infarct), `"C"` (all neoplasms).
#' @param decode_age Logical. If TRUE (default), adds a numeric column
#'   `age_years` with age in years decoded from the `IDADE` variable.
#' @param parse Logical. If TRUE (default), converts columns to
#'   appropriate types (integer, double, Date) based on the variable
#'   metadata. Use [sim_variables()] to see the target type for each
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
#' @return A tibble with mortality microdata. Includes columns `year`
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
#' @family sim
#'
#' @seealso [censo_populacao()] for population denominators to calculate
#'   mortality rates.
#'
#' @examplesIf interactive()
#' # all deaths in Acre, 2022
#' ac_2022 <- sim_data(year = 2022, uf = "AC")
#'
#' # deaths by infarct in Sao Paulo, 2020-2022
#' infarct_sp <- sim_data(year = 2020:2022, uf = "SP", cause = "I21")
#'
#' # only key variables, Rio de Janeiro, 2022
#' sim_data(year = 2022, uf = "RJ",
#'          vars = c("DTOBITO", "SEXO", "IDADE",
#'                   "RACACOR", "CODMUNRES", "CAUSABAS"))
sim_data <- function(year, vars = NULL, uf = NULL, cause = NULL,
                     decode_age = TRUE,
                     parse = TRUE, col_types = NULL,
                     cache = TRUE, cache_dir = NULL,
                     lazy = FALSE, backend = c("arrow", "duckdb")) {

  # validate inputs
  year <- .sim_validate_year(year)
  if (!is.null(uf)) uf <- .sim_validate_uf(uf)
  if (!is.null(vars)) .sim_validate_vars(vars)

  # determine UFs to download
  target_ufs <- if (!is.null(uf)) toupper(uf) else sim_uf_list

  # compute lazy args once
  cache_dir_resolved <- .sim_cache_dir(cache_dir)
  lazy_filters <- list(year = year, uf_source = target_ufs)
  lazy_select <- if (!is.null(vars)) unique(c("year", "uf_source", vars)) else NULL

  # pre-download lazy check
  ds <- .try_lazy_cache(lazy, backend, cache_dir_resolved, "sim_data",
                        lazy_filters, lazy_select, parse = parse)
  if (!is.null(ds)) return(ds)

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

  results <- .map_parallel(seq_len(n_combos), .delay = 0.5, function(i) {
    yr <- combinations$year[i]
    st <- combinations$uf[i]

    tryCatch({
      .sim_download_and_read(yr, st, cache = cache, cache_dir = cache_dir)
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

  # filter by cause if requested
  if (!is.null(cause)) {
    cause_pattern <- stringr::str_c("^(", stringr::str_c(cause, collapse = "|"), ")")
    if ("CAUSABAS" %in% names(results)) {
      results <- results[grepl(cause_pattern, results$CAUSABAS), ]
    } else {
      cli::cli_warn("Column {.var CAUSABAS} not found in data. Cannot filter by cause.")
    }
  }

  # parse column types
  if (isTRUE(parse) && !isTRUE(lazy)) {
    type_spec <- .build_type_spec(sim_variables_metadata)
    results <- .parse_columns(results, type_spec, col_types = col_types)
  }

  # decode age if requested
  if (isTRUE(decode_age) && "IDADE" %in% names(results)) {
    age_col <- .sim_decode_age(results$IDADE)
    # insert after IDADE column
    idade_pos <- which(names(results) == "IDADE")
    if (length(idade_pos) == 1) {
      results <- tibble::add_column(results, age_years = age_col,
                                    .after = idade_pos)
    } else {
      results$age_years <- age_col
    }
  }

  # include age_years in select_cols for eager path
  if (isTRUE(decode_age) && "IDADE" %in% (vars %||% character(0))) {
    lazy_select <- unique(c(lazy_select, "age_years"))
  }

  .data_return(results, lazy, backend, cache_dir_resolved, "sim_data",
               lazy_filters, lazy_select, failed_labels, "SIM")
}


#' Show SIM Cache Status
#'
#' Shows information about cached SIM data files.
#'
#' @param cache_dir Character. Cache directory path. Default:
#'   `tools::R_user_dir("healthbR", "cache")`.
#'
#' @return A tibble with cache file information (invisibly).
#'
#' @export
#' @family sim
#'
#' @examples
#' sim_cache_status()
sim_cache_status <- function(cache_dir = NULL) {
  .cache_status("sim", "SIM", .sim_cache_dir(cache_dir))
}


#' Clear SIM Cache
#'
#' Deletes cached SIM data files.
#'
#' @param cache_dir Character. Cache directory path. Default:
#'   `tools::R_user_dir("healthbR", "cache")`.
#'
#' @return Invisible NULL.
#'
#' @export
#' @family sim
#'
#' @examplesIf interactive()
#' sim_clear_cache()
sim_clear_cache <- function(cache_dir = NULL) {
  .clear_cache("sim", "SIM", .sim_cache_dir(cache_dir))
}
