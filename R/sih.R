# sih functions for healthbR package
# functions to access hospital admission microdata from the SIH (Sistema de
# Informacoes Hospitalares) via DATASUS FTP

# ============================================================================
# internal validation functions
# ============================================================================

#' Validate SIH year parameter
#' @noRd
.sih_validate_year <- function(year, status = "all") {
  .validate_year(year, sih_years(status = status),
                 years_fn_hint = "sih_years(status = 'all')")
}

#' Validate SIH UF parameter
#' @noRd
.sih_validate_uf <- function(uf) {
  .validate_uf(uf, sih_uf_list)
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
  .module_cache_dir("sih", cache_dir)
}


#' Download and read a SIH .dbc file for one UF/year/month
#'
#' Returns a tibble with `year`, `month`, and `uf_source` columns already added.
#' Uses partitioned cache (Hive-style) when arrow is available, with
#' flat cache as migration fallback.
#'
#' @noRd
.sih_download_and_read <- function(year, month, uf, cache = TRUE,
                                   cache_dir = NULL) {
  cache_dir <- .sih_cache_dir(cache_dir)
  dataset_name <- "sih_data"
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
  cli::cli_text("Acesso:         Espelho R2 healthbr-data (padr\u00e3o) com fallback FTP DATASUS")
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

  cli::cli_h2("Fontes de dados")
  cli::cli_bullets(c(
    "*" = "R2 healthbr-data (padr\u00e3o): Parquet id\u00eantico ao .dbc do FTP, 1992\u2013presente, com proveni\u00eancia (URL, MD5 e data de download do arquivo de origem)",
    "*" = "FTP DATASUS (fallback): arquivos RD{{UF}}{{aa}}{{mm}}.dbc, 2008\u2013presente",
    " " = "  Use {.arg source} em {.fun sih_data} para fixar uma fonte."
  ))

  cli::cli_text("")
  cli::cli_alert_info(
    "Dados mensais: use {.arg month} em {.fun sih_data} para selecionar meses."
  )
  cli::cli_alert_info(
    "{.fun sih_status} lista as compet\u00eancias publicadas no espelho, com hash e data de cada arquivo."
  )

  invisible(list(
    name = "SIH - Sistema de Informa\u00e7\u00f5es Hospitalares",
    source = "healthbr-data R2 (Parquet) + DATASUS FTP",
    final_years = sih_available_years$final,
    preliminary_years = sih_available_years$preliminary,
    n_variables = nrow(sih_variables_metadata),
    url_r2 = "https://github.com/SidneyBissoli/healthbr-data",
    url_ftp = "ftp://ftp.datasus.gov.br/dissemin/publicos/SIHSUS/",
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

  result <- .search_metadata(result, search, c("variable", "description"))

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


#' @noRd
.sih_download_loop <- function(year, month, target_ufs, cache, cache_dir) {
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

  labels <- paste(combinations$uf,
                  paste0(combinations$year, "/", sprintf("%02d", combinations$month)))

  results <- .map_parallel(seq_len(n_combos), .delay = 0.5,
                            .progress = "Downloading", function(i) {
    yr <- combinations$year[i]
    mo <- combinations$month[i]
    st <- combinations$uf[i]

    tryCatch({
      .sih_download_and_read(yr, mo, st, cache = cache,
                             cache_dir = cache_dir)
    }, error = function(e) {
      NULL
    })
  })

  succeeded <- !vapply(results, is.null, logical(1))
  failed_labels <- labels[!succeeded]
  results <- results[succeeded]

  if (length(results) == 0) {
    cli::cli_abort("No data could be downloaded for the requested year(s)/month(s)/UF(s).")
  }

  list(data = dplyr::bind_rows(results), failed_labels = failed_labels)
}


#' Fetch SIH data through the source priority chain
#'
#' Tries each source in order ("r2" = healthbr-data mirror, "datasus" = FTP)
#' and returns the first that yields rows, warning about the fallback.
#'
#' @return list(data = tibble, failed_labels = character, source = character
#'   or NA if every source failed).
#' @noRd
.sih_fetch <- function(sources, year, month, target_ufs, cache, cache_dir,
                       creds) {
  empty <- list(data = tibble::tibble(), failed_labels = character(0),
                source = NA_character_)
  last <- empty
  for (i in seq_along(sources)) {
    s <- sources[i]
    res <- tryCatch({
      if (s == "r2") {
        r <- .sih_r2_fetch(year, month, target_ufs, cache, cache_dir, creds)
        list(data = dplyr::bind_rows(r$results), failed_labels = r$failed_labels)
      } else {
        .sih_download_loop(year, month, target_ufs, cache, cache_dir)
      }
    }, error = function(e) {
      cli::cli_warn("Source {.val {s}} failed: {conditionMessage(e)}")
      NULL
    })

    if (!is.null(res) && nrow(res$data) > 0) {
      res$source <- s
      return(res)
    }
    if (!is.null(res)) last <- res
    if (i < length(sources)) {
      cli::cli_warn(c(
        "!" = "No data from source {.val {s}}; falling back to {.val {sources[i + 1]}}."
      ))
    }
  }
  if (nrow(last$data) == 0) {
    cli::cli_abort("No data could be downloaded for the requested year(s)/month(s)/UF(s).")
  }
  last$source <- NA_character_
  last
}


#' Download SIH Hospital Admission Microdata
#'
#' Returns hospital admission microdata (SIH-RD, "AIH reduzida").
#' Each row represents one hospital admission record (AIH).
#' Data is organized monthly -- one file per state (UF) per billing
#' competence (month).
#'
#' By default data are read from the **healthbr-data R2 mirror** (Parquet on
#' Cloudflare R2, values byte-identical to the Ministry's `.dbc` files, with
#' provenance metadata for every file) and the package falls back to the
#' DATASUS FTP if the mirror is unreachable -- see `source`. Both transports
#' share the same local cache, because the content is the same by
#' construction.
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
#' @param parse Logical. If TRUE (default), converts columns to
#'   appropriate types (integer, double, Date) based on the variable
#'   metadata. Use [sih_variables()] to see the target type for each
#'   variable. Set to FALSE for backward-compatible all-character output.
#' @param col_types Named list. Override the default type for specific
#'   columns. Names are column names, values are type strings:
#'   \code{"character"}, \code{"integer"}, \code{"double"},
#'   \code{"date_dmy"}, \code{"date_ymd"}, \code{"date_ym"}, \code{"date"}.
#'   Example: \code{list(VAL_TOT = "character")} to keep VAL_TOT as character.
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
#' @param source Character. Source priority: \code{c("r2", "datasus")}
#'   (default) reads from the healthbr-data R2 mirror and falls back to the
#'   DATASUS FTP if the mirror yields nothing; \code{"r2"} or
#'   \code{"datasus"} alone pins a source. The R2 source requires the
#'   \pkg{arrow} package; without it the package uses the FTP directly.
#' @param r2_credentials List or NULL. Credentials for the R2 bucket
#'   (\code{access_key_id}, \code{secret_access_key}, optionally
#'   \code{endpoint} and \code{bucket}). NULL (default) uses the public
#'   read-only token of the healthbr-data mirror.
#'
#' @return A tibble with hospital admission microdata. Includes columns
#'   `year`, `month`, and `uf_source` to identify the source file when
#'   multiple years/months/states are combined: `year`/`month` are the
#'   BILLING COMPETENCE of the AIH (the month the account was processed),
#'   not the admission date, which is `DT_INTER`; `uf_source` is the state
#'   of the hospital, not of the patient's residence (`MUNIC_RES`).
#'   Two attributes record where the data came from:
#'   \code{attr(x, "healthbr_source")} (\code{"r2"} or \code{"datasus"}) and,
#'   for the mirror, \code{attr(x, "healthbr_provenance")}, a tibble with one
#'   row per source file read (competence, UF, DATASUS URL, MD5, size,
#'   record count and processing timestamp) -- see [sih_status()].
#'
#' @details
#' ## Sources
#' The mirror stores each DATASUS file `RD{UF}{yy}{mm}.dbc` as one Parquet
#' partition `sih/rd/ano=YYYY/mes=MM/uf=XX/`, all columns as character, and
#' publishes a manifest with the MD5 and size of every source file. Reading
#' from it needs no decompression and transfers only the columns actually
#' used. The FTP path downloads the `.dbc` (decompressed internally with
#' vendored C code from the blast library; no external dependencies).
#'
#' ## Competence versus admission date
#' A file of competence `2023-01` holds the admissions billed in January
#' 2023, including admissions that started months earlier; conversely the
#' admissions of December 2023 are spread over the competences of December
#' 2023 to April 2024. Measured on the whole mirror (2016-2026), the four
#' competences following a year close 99.7-99.9% of that year's admissions.
#' To count admissions by the date they started, filter on `DT_INTER` after
#' reading a window of competences.
#'
#' ## Lazy evaluation with R2
#' With \code{lazy = TRUE} and the R2 source first, the returned object is a
#' remote dataset over the mirror: nothing is downloaded until
#' \code{dplyr::collect()}, and filters/column selections are pushed down to
#' the Parquet files. Listing the mirror takes a few seconds. With
#' \code{source = "datasus"}, lazy evaluation works over the local cache as
#' before.
#'
#' SIH data is monthly, so an entire year for all states means 324 files
#' (27 UFs x 12 months). Use `uf` and `month` to limit reads.
#'
#' ## Parallel downloads
#' When downloading multiple files (e.g., several months or states), install
#' \pkg{furrr} and \pkg{future} and set a parallel plan to speed up downloads:
#' `future::plan(future::multisession, workers = 4)`. See
#' `vignette("healthbR")` for details.
#'
#' @export
#' @family sih
#'
#' @seealso [censo_populacao()] for population denominators to calculate
#'   hospitalization rates.
#'
#' @examplesIf interactive()
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
sih_data <- function(year, month = NULL, vars = NULL, uf = NULL,
                     diagnosis = NULL,
                     parse = TRUE, col_types = NULL,
                     cache = TRUE, cache_dir = NULL,
                     lazy = FALSE, backend = c("arrow", "duckdb"),
                     source = c("r2", "datasus"), r2_credentials = NULL) {

  # validate inputs
  year <- .sih_validate_year(year)
  month <- .validate_month(month)
  if (!is.null(uf)) uf <- .sih_validate_uf(uf)
  if (!is.null(vars)) .sih_validate_vars(vars)
  backend <- match.arg(backend)

  # resolve sources; without arrow the mirror cannot be read
  sources <- .resolve_sources(source)
  if ("r2" %in% sources && !.has_arrow()) {
    if (length(sources) > 1) {
      cli::cli_inform(c(
        "i" = "Package {.pkg arrow} is not installed; using DATASUS directly.",
        "i" = "Install {.pkg arrow} to enable the (faster) R2 backend."
      ))
      sources <- setdiff(sources, "r2")
    } else {
      .r2_check_arrow()
    }
  }
  creds <- if ("r2" %in% sources) .r2_credentials(r2_credentials) else NULL

  # determine UFs to download
  target_ufs <- if (!is.null(uf)) toupper(uf) else sih_uf_list

  # compute lazy args once
  cache_dir_resolved <- .sih_cache_dir(cache_dir)
  lazy_filters <- list(year = year, uf_source = target_ufs)
  if (!is.null(month)) lazy_filters$month <- as.integer(month)
  lazy_select <- if (!is.null(vars)) unique(c("year", "month", "uf_source", vars)) else NULL

  # lazy return: remote R2 dataset (nothing downloaded), else local cache
  if (isTRUE(lazy) && sources[1] == "r2") {
    ds <- tryCatch(.sih_r2_lazy(year, month, target_ufs, backend, creds),
                   error = function(e) {
                     cli::cli_warn("Could not open the R2 mirror lazily: {conditionMessage(e)}")
                     NULL
                   })
    if (!is.null(ds)) {
      if (isTRUE(parse)) {
        cli::cli_inform("{.arg parse} is ignored when {.arg lazy} is TRUE.")
      }
      if (!is.null(lazy_select)) {
        ds <- dplyr::select(ds, dplyr::any_of(lazy_select))
      }
      return(ds)
    }
  }
  ds <- .try_lazy_cache(lazy, backend, cache_dir_resolved, "sih_data",
                        lazy_filters, lazy_select, parse = parse)
  if (!is.null(ds)) return(ds)

  # fetch through the source chain, bind, and collect failures
  dl <- .sih_fetch(sources, year, month, target_ufs, cache, cache_dir, creds)
  results <- dl$data
  failed_labels <- dl$failed_labels

  # parse column types
  if (isTRUE(parse) && !isTRUE(lazy)) {
    type_spec <- .build_type_spec(sih_variables_metadata)
    results <- .parse_columns(results, type_spec, col_types = col_types)
  }

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

  out <- .data_return(results, lazy, backend, cache_dir_resolved, "sih_data",
                      lazy_filters, lazy_select, failed_labels, "SIH")

  # record the source that served the data + manifest provenance (mirror)
  if (is.data.frame(out)) {
    attr(out, "healthbr_source") <- dl$source
    if (identical(dl$source, "r2")) {
      prov <- .sih_r2_provenance(year, month, target_ufs, cache_dir_resolved)
      if (!is.null(prov)) attr(out, "healthbr_provenance") <- prov
    }
  }
  out
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
  .cache_status("sih", "SIH", .sih_cache_dir(cache_dir))
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
#' @examplesIf interactive()
#' sih_clear_cache()
sih_clear_cache <- function(cache_dir = NULL) {
  .clear_cache("sih", "SIH", .sih_cache_dir(cache_dir))
}
