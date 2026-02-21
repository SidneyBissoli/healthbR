# sisab functions for healthbR package
# functions to access primary care coverage data from SISAB
# (Sistema de Informacao em Saude para a Atencao Basica)
# via the relatorioaps REST API

# ============================================================================
# internal validation functions
# ============================================================================

#' Validate SISAB year parameter
#' @noRd
.sisab_validate_year <- function(year) {
  if (is.null(year) || length(year) == 0) {
    cli::cli_abort("{.arg year} is required.")
  }

  year <- as.integer(year)
  invalid <- year[is.na(year) | year < 2007L | year > as.integer(format(Sys.Date(), "%Y"))]

  if (length(invalid) > 0) {
    cli::cli_abort(c(
      "Year(s) {.val {invalid}} not available.",
      "i" = "SISAB coverage data is available from 2007 onwards.",
      "i" = "Availability depends on report type. Use {.code sisab_info()} for details."
    ))
  }

  year
}


#' Validate SISAB type parameter
#' @noRd
.sisab_validate_type <- function(type) {
  type <- tolower(type)
  valid_codes <- sisab_valid_types$code

  if (!type %in% valid_codes) {
    cli::cli_abort(c(
      "Invalid SISAB report type: {.val {type}}.",
      "i" = "Valid types: {.val {valid_codes}}",
      "i" = "aps = Cobertura APS, sb = Saude Bucal, acs = Agentes Comunitarios, pns = PNS."
    ))
  }

  type
}


#' Validate SISAB level parameter
#' @noRd
.sisab_validate_level <- function(level) {
  level <- tolower(level)
  valid_levels <- names(sisab_valid_levels)

  if (!level %in% valid_levels) {
    cli::cli_abort(c(
      "Invalid geographic level: {.val {level}}.",
      "i" = "Valid levels: {.val {valid_levels}}"
    ))
  }

  level
}


#' Validate SISAB UF parameter
#' @noRd
.sisab_validate_uf <- function(uf) {
  .validate_uf(uf, names(sisab_uf_map))
}


#' Validate SISAB vars parameter (warning only)
#' @noRd
.sisab_validate_vars <- function(vars, type = "aps") {
  meta <- .sisab_get_variables_meta(type)
  known_vars <- meta$variable
  invalid <- vars[!vars %in% known_vars]

  if (length(invalid) > 0) {
    cli::cli_warn(c(
      "Variable(s) {.val {invalid}} not in known SISAB ({type}) variables.",
      "i" = "Use {.code sisab_variables(type = \"{type}\")} to see available variables.",
      "i" = "Proceeding anyway (variables will be dropped if not found)."
    ))
  }
}


#' Get variables metadata for a given type
#' @noRd
.sisab_get_variables_meta <- function(type) {
  switch(type,
    "aps" = sisab_variables_aps,
    "sb"  = sisab_variables_sb,
    "acs" = sisab_variables_acs,
    "pns" = sisab_variables_pns,
    sisab_variables_aps
  )
}


# ============================================================================
# internal API functions
# ============================================================================

#' Build API URL for SISAB endpoint
#' @noRd
.sisab_build_url <- function(type) {
  type_row <- sisab_valid_types[sisab_valid_types$code == type, ]
  stringr::str_c(sisab_api_url, type_row$endpoint)
}


#' Fetch data from SISAB API for a single year/month range
#' @noRd
.sisab_api_fetch <- function(type, level, year, months, uf = NULL) {
  url <- .sisab_build_url(type)
  api_level <- sisab_valid_levels[[level]]

  # build competencia strings (YYYYMM)
  comp_start <- sprintf("%04d%02d", year, min(months))
  comp_end <- sprintf("%04d%02d", year, max(months))

  # build query parameters
  params <- list(
    unidadeGeografica = api_level,
    nuCompInicio = comp_start,
    nuCompFim = comp_end
  )

  # add UF filter if level is UF or municipality and uf is specified
  if (!is.null(uf) && level %in% c("uf", "municipality")) {
    params$coUf <- sisab_uf_map[[uf]]
  }

  # build URL with parameters
  query_str <- paste(
    vapply(names(params), function(k) {
      stringr::str_c(k, "=", params[[k]])
    }, character(1)),
    collapse = "&"
  )
  full_url <- stringr::str_c(url, "?", query_str)

  # perform request
  temp_file <- tempfile(fileext = ".json")
  on.exit(if (file.exists(temp_file)) file.remove(temp_file), add = TRUE)

  tryCatch({
    curl::curl_download(
      full_url,
      temp_file,
      handle = curl::new_handle(
        ssl_verifypeer = FALSE,
        followlocation = TRUE,
        timeout = 120
      )
    )
  }, error = function(e) {
    cli::cli_abort(c(
      "Failed to connect to SISAB API.",
      "x" = "{e$message}",
      "i" = "Check your internet connection and try again."
    ))
  })

  # read and parse JSON
  raw <- readLines(temp_file, warn = FALSE, encoding = "UTF-8")
  content <- paste(raw, collapse = "")

  if (nchar(content) < 3 || content == "[]") {
    return(NULL)
  }

  if (grepl("Falha interna", content, fixed = TRUE)) {
    cli::cli_abort(c(
      "SISAB API returned an internal error.",
      "i" = "The requested combination of type/level/period may not be available.",
      "i" = "Try a different period or geographic level."
    ))
  }

  data <- jsonlite::fromJSON(content, flatten = TRUE)

  if (!is.data.frame(data) || nrow(data) == 0) {
    return(NULL)
  }

  tibble::as_tibble(data)
}


# ============================================================================
# internal cache functions
# ============================================================================

#' Get/create SISAB cache directory
#' @noRd
.sisab_cache_dir <- function(cache_dir = NULL) {
  .module_cache_dir("sisab", cache_dir)
}


#' Download and read SISAB data for one year (all requested months)
#' @noRd
.sisab_download_and_read <- function(year, months, type, level, uf = NULL,
                                     cache = TRUE, cache_dir = NULL) {
  cache_dir <- .sisab_cache_dir(cache_dir)

  # build cache key
  uf_part <- if (!is.null(uf)) uf else "ALL"
  month_part <- if (length(months) == 12) {
    "full"
  } else {
    paste(sprintf("%02d", months), collapse = "-")
  }
  cache_base <- stringr::str_c(
    "sisab_", type, "_", level, "_", uf_part, "_", year, "_", month_part
  )

  # check cache
  if (isTRUE(cache)) {
    cached <- .cache_read(cache_dir, cache_base)
    if (!is.null(cached)) return(cached)
  }

  # fetch from API
  cli::cli_inform(c(
    "i" = "Downloading SISAB data: {type} {level} {uf_part} {year} (months {min(months)}-{max(months)})..."
  ))

  data <- .sisab_api_fetch(type, level, year, months, uf)

  if (is.null(data) || nrow(data) == 0) {
    return(NULL)
  }

  # write to cache
  if (isTRUE(cache)) {
    .cache_write(data, cache_dir, cache_base)
  }

  data
}


# ============================================================================
# exported functions
# ============================================================================

#' List Available SISAB Years
#'
#' Returns an integer vector with years for which SISAB coverage data are
#' potentially available from the relatorioaps API. Actual availability
#' depends on the report type.
#'
#' @return An integer vector of available years.
#'
#' @details
#' Availability by report type:
#' \itemize{
#'   \item \code{aps}: APS coverage (2019--present)
#'   \item \code{sb}: Oral health coverage (2024--present)
#'   \item \code{acs}: Community health agents (2007--present)
#'   \item \code{pns}: PNS coverage (2020--2023)
#' }
#'
#' @export
#' @family sisab
#'
#' @examples
#' sisab_years()
sisab_years <- function() {
  2007L:as.integer(format(Sys.Date(), "%Y"))
}


#' SISAB Module Information
#'
#' Displays information about the Primary Care Health Information System
#' (SISAB), including data sources, available report types, and usage guidance.
#'
#' @return A list with module information (invisibly).
#'
#' @export
#' @family sisab
#'
#' @examples
#' sisab_info()
sisab_info <- function() {
  cli::cli_h1(
    "SISAB \u2014 Sistema de Informa\u00e7\u00e3o em Sa\u00fade para a Aten\u00e7\u00e3o B\u00e1sica"
  )

  cli::cli_text("")
  cli::cli_text("Fonte:          Minist\u00e9rio da Sa\u00fade / SAPS")
  cli::cli_text("Acesso:         API REST (relatorioaps.saude.gov.br)")
  cli::cli_text(
    "Dados:          Cobertura da Aten\u00e7\u00e3o Prim\u00e1ria (dados agregados)"
  )
  cli::cli_text("Granularidade:  Mensal (por compet\u00eancia CNES)")

  cli::cli_h2("Dados dispon\u00edveis")
  cli::cli_bullets(c(
    "*" = "{.fun sisab_data}: Cobertura da aten\u00e7\u00e3o prim\u00e1ria",
    " " = "  4 tipos de relat\u00f3rio, 4 n\u00edveis geogr\u00e1ficos",
    "*" = "{.fun sisab_variables}: Lista de vari\u00e1veis dispon\u00edveis"
  ))

  cli::cli_h2("Tipos de relat\u00f3rio")
  for (i in seq_len(nrow(sisab_valid_types))) {
    cli::cli_text(
      "  {sisab_valid_types$code[i]}   {sisab_valid_types$name[i]}"
    )
    cli::cli_text(
      "         {sisab_valid_types$description[i]}"
    )
  }

  cli::cli_h2("N\u00edveis geogr\u00e1ficos")
  cli::cli_text("  brazil        Total nacional")
  cli::cli_text("  region        5 macrorregi\u00f5es")
  cli::cli_text("  uf            27 estados")
  cli::cli_text("  municipality  ~5.570 munic\u00edpios")

  cli::cli_text("")
  cli::cli_alert_info(
    "Dados agregados (cobertura por munic\u00edpio/equipe/per\u00edodo), n\u00e3o microdados."
  )
  cli::cli_alert_info(
    "Dados via API REST p\u00fablica (n\u00e3o requer autentica\u00e7\u00e3o)."
  )
  cli::cli_alert_info(
    "O relat\u00f3rio de produ\u00e7\u00e3o (atendimentos) do portal SISAB est\u00e1 em manuten\u00e7\u00e3o."
  )

  invisible(list(
    name = "SISAB \u2014 Sistema de Informa\u00e7\u00e3o em Sa\u00fade para a Aten\u00e7\u00e3o B\u00e1sica",
    source = "API REST relatorioaps",
    n_types = nrow(sisab_valid_types),
    n_variables_aps = nrow(sisab_variables_aps),
    url = sisab_api_url
  ))
}


#' List SISAB Variables
#'
#' Returns a tibble with available variables in the SISAB coverage data,
#' including descriptions and value types.
#'
#' @param type Character. Report type to show variables for.
#'   \code{"aps"} (default), \code{"sb"}, \code{"acs"}, or \code{"pns"}.
#' @param search Character. Optional search term to filter variables by
#'   name or description. Case-insensitive and accent-insensitive.
#'
#' @return A tibble with columns: variable, description, type, section.
#'
#' @export
#' @family sisab
#'
#' @examples
#' sisab_variables()
#' sisab_variables(type = "sb")
#' sisab_variables(search = "cobertura")
sisab_variables <- function(type = "aps", search = NULL) {
  type <- .sisab_validate_type(type)
  result <- .sisab_get_variables_meta(type)

  result <- .search_metadata(result, search, c("variable", "description"))

  result
}


# -- internal helpers for sisab_data() ------------------------------------

#' Validate and resolve all sisab_data parameters
#' @noRd
.sisab_resolve_params <- function(year, type, level, month, uf, vars) {
  year  <- .sisab_validate_year(year)
  type  <- .sisab_validate_type(type)
  level <- .sisab_validate_level(level)
  month <- .validate_month(month)
  if (!is.null(uf))   uf <- .sisab_validate_uf(uf)
  if (!is.null(vars))  .sisab_validate_vars(vars, type = type)

  if (level == "municipality" && is.null(uf) && length(month) > 3) {
    cli::cli_warn(c(
      "!" = "Downloading municipality-level data for all UFs may be slow.",
      "i" = "Consider specifying {.arg uf} to filter by state."
    ))
  }

  if (!is.null(uf) && level %in% c("uf", "municipality")) {
    target_ufs <- as.list(uf)
  } else {
    target_ufs <- list(NULL)
  }

  list(year = year, type = type, level = level,
       month = month, uf = uf, target_ufs = target_ufs)
}

#' Download loop for sisab_data: expand grid, download, bind
#' @noRd
.sisab_download_loop <- function(year, type, level, month,
                                 target_ufs, cache, cache_dir) {
  combinations <- expand.grid(
    year = year, uf_idx = seq_along(target_ufs),
    stringsAsFactors = FALSE
  )

  n_combos <- nrow(combinations)
  if (n_combos > 1 || length(year) > 1) {
    cli::cli_inform(c(
      "i" = "Downloading {n_combos} request(s) ({length(year)} year(s))..."
    ))
  }

  labels <- vapply(seq_len(n_combos), function(i) {
    uf_val  <- target_ufs[[combinations$uf_idx[i]]]
    uf_part <- if (!is.null(uf_val)) uf_val else "ALL"
    paste(type, level, uf_part, combinations$year[i])
  }, character(1))

  results <- .map_parallel(seq_len(n_combos), .delay = 0.5,
                            .progress = "Downloading", function(i) {
    yr     <- combinations$year[i]
    uf_val <- target_ufs[[combinations$uf_idx[i]]]
    tryCatch({
      data <- .sisab_download_and_read(
        yr, month, type, level, uf = uf_val,
        cache = cache, cache_dir = cache_dir
      )
      if (is.null(data) || nrow(data) == 0) return(NULL)
      data$year <- as.integer(yr)
      data$type <- type
      cols <- names(data)
      data <- data[, c("year", "type", setdiff(cols, c("year", "type")))]
      data
    }, error = function(e) NULL)
  })

  succeeded     <- !vapply(results, is.null, logical(1))
  failed_labels <- labels[!succeeded]
  results       <- results[succeeded]

  if (length(results) == 0) {
    cli::cli_abort(
      "No data could be downloaded for the requested parameters."
    )
  }

  list(data = dplyr::bind_rows(results), failed_labels = failed_labels)
}

# -- main orchestrator ----------------------------------------------------

#' Download SISAB Coverage Data
#'
#' Downloads and returns primary care coverage data from the SISAB
#' relatorioaps API. Data is aggregated (coverage indicators per
#' geographic unit and period), not individual-level microdata.
#'
#' @param year Integer. Year(s) of the data. Required.
#' @param type Character. Report type to download. Default: \code{"aps"}
#'   (APS coverage). See \code{\link{sisab_info}()} for all types.
#' @param level Character. Geographic aggregation level. Default:
#'   \code{"uf"}. One of: \code{"brazil"}, \code{"region"}, \code{"uf"},
#'   \code{"municipality"}.
#' @param month Integer. Month(s) to download (1--12). If NULL (default),
#'   downloads all 12 months.
#' @param uf Character. Two-letter state abbreviation to filter by when
#'   \code{level} is \code{"uf"} or \code{"municipality"}.
#'   If NULL (default), returns all states.
#'   Example: \code{"SP"}, \code{c("SP", "RJ")}.
#' @param vars Character vector. Variables to keep. If NULL (default),
#'   returns all available variables. Use \code{\link{sisab_variables}()}
#'   to see available variables.
#' @param cache Logical. If TRUE (default), caches downloaded data for
#'   faster future access.
#' @param cache_dir Character. Directory for caching. Default:
#'   \code{tools::R_user_dir("healthbR", "cache")}.
#'
#' @return A tibble with coverage data. Includes columns \code{year} and
#'   \code{type} to identify the source when multiple years/types are
#'   combined. Column names are preserved from the API (camelCase).
#'
#' @details
#' Data is fetched from the relatorioaps REST API
#' (\verb{https://relatorioaps.saude.gov.br}), the public reporting portal
#' for primary care in Brazil.
#'
#' Four report types are available:
#' \itemize{
#'   \item \code{"aps"} (default): APS coverage -- number of primary care
#'     teams (eSF, eAP, eSFR, eCR, eAPP) and estimated coverage percentage.
#'     Available from 2019.
#'   \item \code{"sb"}: Oral health coverage -- dental care teams and
#'     coverage. Available from 2024.
#'   \item \code{"acs"}: Community health agents -- number of active ACS
#'     and population coverage. Available from 2007.
#'   \item \code{"pns"}: PNS coverage -- coverage estimates from the
#'     National Health Survey. Available 2020--2023.
#' }
#'
#' For municipality-level data, it is recommended to filter by UF using the
#' \code{uf} parameter to avoid large downloads.
#'
#' ## Parallel downloads
#' When downloading multiple months, install \pkg{furrr} and \pkg{future} and
#' set a parallel plan to speed up downloads:
#' `future::plan(future::multisession, workers = 4)`. See
#' `vignette("healthbR")` for details.
#'
#' @export
#' @family sisab
#'
#' @seealso \code{\link{sisab_info}()} for report type descriptions,
#'   \code{\link{censo_populacao}()} for population denominators.
#'
#' @examplesIf interactive()
#' # APS coverage by state, January 2024
#' sisab_data(year = 2024, month = 1)
#'
#' # National total, full year 2023
#' sisab_data(year = 2023, level = "brazil")
#'
#' # Oral health coverage by UF
#' sisab_data(year = 2024, type = "sb", month = 6)
#'
#' # Municipality level for Sao Paulo
#' sisab_data(year = 2024, level = "municipality", uf = "SP", month = 1)
sisab_data <- function(year, type = "aps", level = "uf", month = NULL,
                       uf = NULL, vars = NULL,
                       cache = TRUE, cache_dir = NULL) {

  params <- .sisab_resolve_params(year, type, level, month, uf, vars)

  dl <- .sisab_download_loop(
    year       = params$year,
    type       = params$type,
    level      = params$level,
    month      = params$month,
    target_ufs = params$target_ufs,
    cache      = cache,
    cache_dir  = cache_dir
  )

  lazy_select <- if (!is.null(vars)) unique(c("year", "type", vars)) else NULL

  .data_return(dl$data, select_cols = lazy_select,
               failed_labels = dl$failed_labels, module_name = "SISAB")
}


#' Show SISAB Cache Status
#'
#' Shows information about cached SISAB data files.
#'
#' @param cache_dir Character. Cache directory path. Default:
#'   \code{tools::R_user_dir("healthbR", "cache")}.
#'
#' @return A tibble with cache file information (invisibly).
#'
#' @export
#' @family sisab
#'
#' @examples
#' sisab_cache_status()
sisab_cache_status <- function(cache_dir = NULL) {
  .cache_status("sisab", "SISAB", .sisab_cache_dir(cache_dir))
}


#' Clear SISAB Cache
#'
#' Deletes cached SISAB data files.
#'
#' @param cache_dir Character. Cache directory path. Default:
#'   \code{tools::R_user_dir("healthbR", "cache")}.
#'
#' @return Invisible NULL.
#'
#' @export
#' @family sisab
#'
#' @examplesIf interactive()
#' sisab_clear_cache()
sisab_clear_cache <- function(cache_dir = NULL) {
  .clear_cache("sisab", "SISAB", .sisab_cache_dir(cache_dir))
}
