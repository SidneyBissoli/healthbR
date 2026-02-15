# censo functions for healthbR package
# functions to access population denominators from the IBGE SIDRA API
# covers Census data (1970-2022) and intercensitary population estimates

# ============================================================================
# internal constants and data
# ============================================================================

#' Census years available
#' @noRd
censo_available_years <- c(1970L, 1980L, 1991L, 2000L, 2010L, 2022L)

#' Intercensitary estimate years available (table 6579)
#' @noRd
censo_estimativa_years <- 2001L:2021L

#' Internal SIDRA catalog for Census tables
#' @noRd
censo_sidra_catalog_internal <- tibble::tibble(
  table_code = c(
    # population
    "200", "9514",
    # population by race
    "136", "9605",
    # intercensitary estimates
    "6579",
    # literacy
    "3540", "9543",
    # housing
    "1288", "9547",
    # sanitation
    "1394", "9560",
    # disability
    "3426", "9567",
    # indigenous
    "3175", "9573",
    # quilombola
    "9929",
    # fertility
    "2445", "9583",
    # education
    "3541", "9544",
    # labor
    "3587", "9574",
    # income
    "3548", "9575",
    # age/sex pyramids
    "1378", "9513",
    # urbanization
    "202", "9515"
  ),
  table_name = c(
    # population
    "Popula\u00e7\u00e3o residente por sexo, situa\u00e7\u00e3o e grupos de idade (1970-2010)",
    "Popula\u00e7\u00e3o residente por sexo e idade (2022)",
    # population by race
    "Popula\u00e7\u00e3o residente por cor ou ra\u00e7a (2000, 2010)",
    "Popula\u00e7\u00e3o residente por cor ou ra\u00e7a (2022)",
    # intercensitary estimates
    "Estimativas de popula\u00e7\u00e3o (2001-2021)",
    # literacy
    "Pessoas de 5 anos ou mais por alfabetiza\u00e7\u00e3o (2000, 2010)",
    "Pessoas de 5 anos ou mais por alfabetiza\u00e7\u00e3o (2022)",
    # housing
    "Domic\u00edlios particulares permanentes por tipo (2000, 2010)",
    "Domic\u00edlios particulares permanentes por tipo (2022)",
    # sanitation
    "Domic\u00edlios por forma de abastecimento de \u00e1gua (2000, 2010)",
    "Domic\u00edlios por forma de abastecimento de \u00e1gua (2022)",
    # disability
    "Pessoas com defici\u00eancia por tipo (2000, 2010)",
    "Pessoas com defici\u00eancia por tipo (2022)",
    # indigenous
    "Popula\u00e7\u00e3o ind\u00edgena por sexo e idade (2000, 2010)",
    "Popula\u00e7\u00e3o ind\u00edgena por sexo e idade (2022)",
    # quilombola
    "Popula\u00e7\u00e3o quilombola (2022)",
    # fertility
    "Mulheres de 10 anos ou mais por filhos nascidos vivos (2000, 2010)",
    "Mulheres de 10 anos ou mais por filhos nascidos vivos (2022)",
    # education
    "Pessoas de 10 anos ou mais por n\u00edvel de instru\u00e7\u00e3o (2000, 2010)",
    "Pessoas de 10 anos ou mais por n\u00edvel de instru\u00e7\u00e3o (2022)",
    # labor
    "Pessoas de 10 anos ou mais por situa\u00e7\u00e3o de ocupa\u00e7\u00e3o (2000, 2010)",
    "Pessoas de 10 anos ou mais por situa\u00e7\u00e3o de ocupa\u00e7\u00e3o (2022)",
    # income
    "Pessoas de 10 anos ou mais por classes de rendimento (2000, 2010)",
    "Pessoas de 10 anos ou mais por classes de rendimento (2022)",
    # age/sex pyramids
    "Popula\u00e7\u00e3o residente por sexo e faixa et\u00e1ria detalhada (2000, 2010)",
    "Popula\u00e7\u00e3o residente por sexo e faixa et\u00e1ria detalhada (2022)",
    # urbanization
    "Popula\u00e7\u00e3o residente por situa\u00e7\u00e3o do domic\u00edlio (1970-2010)",
    "Popula\u00e7\u00e3o residente por situa\u00e7\u00e3o do domic\u00edlio (2022)"
  ),
  theme = c(
    rep("population", 2),
    rep("race", 2),
    "estimates",
    rep("literacy", 2),
    rep("housing", 2),
    rep("sanitation", 2),
    rep("disability", 2),
    rep("indigenous", 2),
    "quilombola",
    rep("fertility", 2),
    rep("education", 2),
    rep("labor", 2),
    rep("income", 2),
    rep("age_sex", 2),
    rep("urbanization", 2)
  ),
  years = c(
    # population
    list(c("1970", "1980", "1991", "2000", "2010")),
    list(c("2022")),
    # race
    list(c("2000", "2010")),
    list(c("2022")),
    # estimates
    list(as.character(2001:2021)),
    # literacy
    list(c("2000", "2010")),
    list(c("2022")),
    # housing
    list(c("2000", "2010")),
    list(c("2022")),
    # sanitation
    list(c("2000", "2010")),
    list(c("2022")),
    # disability
    list(c("2000", "2010")),
    list(c("2022")),
    # indigenous
    list(c("2000", "2010")),
    list(c("2022")),
    # quilombola
    list(c("2022")),
    # fertility
    list(c("2000", "2010")),
    list(c("2022")),
    # education
    list(c("2000", "2010")),
    list(c("2022")),
    # labor
    list(c("2000", "2010")),
    list(c("2022")),
    # income
    list(c("2000", "2010")),
    list(c("2022")),
    # age_sex
    list(c("2000", "2010")),
    list(c("2022")),
    # urbanization
    list(c("1970", "1980", "1991", "2000", "2010")),
    list(c("2022"))
  ),
  territorial_levels = c(
    rep(list(c("1", "2", "3", "6")), 28)
  )
)

# ============================================================================
# internal helper functions
# ============================================================================

#' Validate census year parameter
#' @noRd
.censo_validate_year <- function(year) {
  if (is.null(year)) {
    cli::cli_abort("Parameter {.arg year} is required.")
  }

  year <- as.integer(year)
  invalid <- year[!year %in% censo_available_years]

  if (length(invalid) > 0) {
    cli::cli_abort(c(
      "Invalid census year{?s}: {.val {invalid}}",
      "i" = "Available years: {.val {censo_available_years}}"
    ))
  }

  year
}

#' Validate intercensitary estimate year
#' @noRd
.censo_validate_estimativa_year <- function(year) {
  if (is.null(year)) {
    cli::cli_abort("Parameter {.arg year} is required.")
  }

  year <- as.integer(year)
  invalid <- year[!year %in% censo_estimativa_years]

  if (length(invalid) > 0) {
    cli::cli_abort(c(
      "Invalid estimate year{?s}: {.val {invalid}}",
      "i" = "Available years: {.val {range(censo_estimativa_years)}}"
    ))
  }

  year
}

#' Resolve table and classifications for censo_populacao()
#'
#' Given a year and variables argument, returns the SIDRA table code
#' and any classification parameters needed.
#' @noRd
.censo_resolve_table <- function(year, variables) {
  year <- as.integer(year)

  result <- list(table = NULL, variable = "93", classifications = NULL)

  if (variables == "total") {
    if (year == 2022L) {
      result$table <- "9514"
    } else {
      result$table <- "200"
    }
  } else if (variables == "sex") {
    if (year == 2022L) {
      result$table <- "9514"
      result$classifications <- list("2" = "allxt")
    } else {
      result$table <- "200"
      result$classifications <- list("2" = "allxt")
    }
  } else if (variables == "age") {
    if (year == 2022L) {
      result$table <- "9514"
      result$classifications <- list("287" = "allxt")
    } else {
      result$table <- "200"
      result$classifications <- list("58" = "allxt")
    }
  } else if (variables == "age_sex") {
    if (year == 2022L) {
      result$table <- "9514"
      result$classifications <- list("2" = "allxt", "287" = "allxt")
    } else {
      result$table <- "200"
      result$classifications <- list("2" = "allxt", "58" = "allxt")
    }
  } else if (variables == "race") {
    if (year == 2022L) {
      result$table <- "9605"
      result$classifications <- list("86" = "allxt")
    } else if (year %in% c(2000L, 2010L)) {
      result$table <- "136"
      result$classifications <- list("86" = "allxt")
    } else {
      cli::cli_abort(c(
        "Race data is only available for years 2000, 2010, and 2022.",
        "i" = "Year requested: {.val {year}}"
      ))
    }
  } else if (variables == "situation") {
    if (year == 2022L) {
      result$table <- "9515"
      result$classifications <- list("1" = "allxt")
    } else {
      result$table <- "200"
      result$classifications <- list("1" = "allxt")
    }
  } else {
    cli::cli_abort(c(
      "Invalid {.arg variables} value: {.val {variables}}",
      "i" = "Available: {.val {c('total', 'sex', 'age', 'age_sex', 'race', 'situation')}}"
    ))
  }

  result
}

#' Fetch data from SIDRA API for Census
#' @noRd
.censo_fetch_sidra <- function(table, territorial_level, geo_code,
                               variable, period, classifications) {
  # validate territorial level
  if (!territorial_level %in% names(sidra_level_map)) {
    cli::cli_abort(c(
      "Invalid territorial_level: {.val {territorial_level}}",
      "i" = "Available: {.val {names(sidra_level_map)}}"
    ))
  }
  level_code <- sidra_level_map[[territorial_level]]

  # build SIDRA API URL
  base_url <- "https://apisidra.ibge.gov.br/values"

  url <- stringr::str_c(base_url, "/t/", table)
  url <- stringr::str_c(url, "/n", level_code, "/", geo_code)

  if (!is.null(variable)) {
    url <- stringr::str_c(url, "/v/", stringr::str_c(variable, collapse = ","))
  } else {
    url <- stringr::str_c(url, "/v/allxp")
  }

  if (!is.null(period)) {
    url <- stringr::str_c(url, "/p/", stringr::str_c(period, collapse = ","))
  } else {
    url <- stringr::str_c(url, "/p/all")
  }

  if (!is.null(classifications)) {
    for (class_id in names(classifications)) {
      class_values <- classifications[[class_id]]
      url <- stringr::str_c(
        url, "/c", class_id, "/",
        stringr::str_c(class_values, collapse = ",")
      )
    }
  }

  # make API request
  cli::cli_alert_info("Querying SIDRA API for table {.val {table}}...")

  response <- tryCatch(
    {
      curl::curl_fetch_memory(url, handle = curl::new_handle(timeout = 60))
    },
    error = function(e) {
      cli::cli_abort(c(
        "SIDRA API request failed",
        "i" = "Error: {e$message}",
        "i" = "Check your internet connection and try again."
      ))
    }
  )

  if (response$status_code != 200) {
    cli::cli_abort(c(
      "SIDRA API request failed with status {.val {response$status_code}}",
      "i" = "URL: {.url {url}}",
      "i" = "Check table code and parameters."
    ))
  }

  # parse JSON response
  content <- rawToChar(response$content)
  Encoding(content) <- "UTF-8"
  data_raw <- jsonlite::fromJSON(content)

  if (is.null(data_raw) || length(data_raw) == 0) {
    cli::cli_alert_warning("No data returned for the specified parameters.")
    return(tibble::tibble())
  }

  tibble::as_tibble(data_raw)
}

#' Clean population response to standard columns
#' @noRd
.censo_clean_populacao <- function(data_raw, table_code) {
  result <- clean_sidra_response(data_raw, table_code)

  if (nrow(result) == 0) {
    return(result)
  }

  result
}

#' Clean estimates response to standard columns
#' @noRd
.censo_clean_estimativa <- function(data_raw, table_code) {
  result <- clean_sidra_response(data_raw, table_code)

  if (nrow(result) == 0) {
    return(result)
  }

  result
}

# ============================================================================
# public API - info
# ============================================================================

#' List available Census years
#'
#' Returns a character vector with available Census years.
#'
#' @return A character vector of available years.
#'
#' @export
#'
#' @examples
#' censo_years()
censo_years <- function() {
  as.character(censo_available_years)
}

#' Census information
#'
#' Displays information about the Brazilian Census and returns metadata.
#'
#' @param year Numeric. Year to get specific information about.
#'   NULL shows general info.
#'
#' @return Invisibly returns a list with Census metadata.
#'
#' @export
#'
#' @examples
#' censo_info()
#' censo_info(2022)
censo_info <- function(year = NULL) {

  info <- list(
    name = "Censo Demogr\u00e1fico",
    name_en = "Demographic Census",
    institution = "IBGE - Instituto Brasileiro de Geografia e Estat\u00edstica",
    available_years = censo_years(),
    description = paste0(
      "O Censo Demogr\u00e1fico \u00e9 a principal pesquisa do IBGE, ",
      "realizada a cada 10 anos, que recenseou a popula\u00e7\u00e3o brasileira. ",
      "Fornece denominadores populacionais essenciais para o c\u00e1lculo de ",
      "taxas de mortalidade, incid\u00eancia e outros indicadores epidemiol\u00f3gicos."
    ),
    url = "https://www.ibge.gov.br/estatisticas/sociais/populacao/22827-censo-demografico-2022.html",
    sidra_url = "https://sidra.ibge.gov.br/pesquisa/censo-demografico",
    citation = paste0(
      "IBGE - Instituto Brasileiro de Geografia e Estat\u00edstica. ",
      "Censo Demogr\u00e1fico. Rio de Janeiro: IBGE."
    )
  )

  year_info <- list(
    "1970" = list(population = "93,134,846", notes = "Primeiro censo digitalizado"),
    "1980" = list(population = "119,002,706", notes = "Fase de urbaniza\u00e7\u00e3o acelerada"),
    "1991" = list(population = "146,825,475", notes = "Inclui dados de ra\u00e7a/cor"),
    "2000" = list(population = "169,799,170", notes = "Primeiro com coleta eletr\u00f4nica parcial"),
    "2010" = list(population = "190,755,799", notes = "Inclui dados detalhados de defici\u00eancia"),
    "2022" = list(population = "203,080,756", notes = "Primeiro com dados quilombolas, realizado ap\u00f3s adiamento pela pandemia")
  )

  # display information
  cli::cli_h1("Censo Demogr\u00e1fico")
  cli::cli_text("")
  cli::cli_text(info$description)
  cli::cli_text("")
  cli::cli_alert_info("Institution: {info$institution}")
  cli::cli_alert_info("Available years: {stringr::str_c(info$available_years, collapse = ', ')}")
  cli::cli_text("")
  cli::cli_h2("Data access")
  cli::cli_alert("Population by sex/age/race: {.fn censo_populacao}")
  cli::cli_alert("Intercensitary estimates: {.fn censo_estimativa}")
  cli::cli_alert("Any SIDRA table: {.fn censo_sidra_data}")
  cli::cli_text("")
  cli::cli_text("URL: {.url {info$url}}")
  cli::cli_text("SIDRA: {.url {info$sidra_url}}")

  if (!is.null(year)) {
    year_char <- as.character(year)
    if (year_char %in% names(year_info)) {
      yi <- year_info[[year_char]]
      cli::cli_text("")
      cli::cli_h2("Censo {year}")
      cli::cli_alert_info("Population: {yi$population}")
      if (!is.null(yi$notes)) {
        cli::cli_alert_info("Notes: {yi$notes}")
      }
      info$year_details <- yi
    }
  }

  invisible(info)
}

# ============================================================================
# public API - high-level population data
# ============================================================================

#' Get Census population data
#'
#' Retrieves population data from the Brazilian Demographic Census via SIDRA API.
#' Automatically selects the correct SIDRA table based on year and requested
#' variables.
#'
#' @param year Numeric. Census year (1970, 1980, 1991, 2000, 2010, or 2022).
#' @param variables Character. Type of breakdown:
#'   \itemize{
#'     \item \code{"total"}: Total population only
#'     \item \code{"sex"}: By sex (male/female)
#'     \item \code{"age"}: By age groups
#'     \item \code{"age_sex"}: By age groups and sex
#'     \item \code{"race"}: By race/color (only 2000, 2010, 2022)
#'     \item \code{"situation"}: By urban/rural situation
#'   }
#'   Default is \code{"total"}.
#' @param territorial_level Character. Geographic level:
#'   \code{"brazil"}, \code{"region"}, \code{"state"}, or \code{"municipality"}.
#'   Default is \code{"state"}.
#' @param geo_code Character. IBGE code(s) for specific localities.
#'   \code{"all"} returns all localities at the chosen level. Default is \code{"all"}.
#' @param raw Logical. If TRUE, returns raw API output without cleaning.
#'   Default is FALSE.
#'
#' @return A tibble with population data.
#'
#' @details
#' This function provides an easy interface for the most common Census queries.
#' It automatically resolves the correct SIDRA table:
#' \itemize{
#'   \item Table 200: Historical population 1970-2010 (by sex, age, situation)
#'   \item Table 9514: Census 2022 population by sex and age
#'   \item Table 136: Population by race 2000-2010
#'   \item Table 9605: Population by race 2022
#'   \item Table 9515: Population by urban/rural 2022
#' }
#'
#' For more flexibility, use \code{\link{censo_sidra_data}} to query any table
#' with custom parameters.
#'
#' @section Data source:
#' Data is retrieved from IBGE SIDRA API:
#' \verb{https://sidra.ibge.gov.br/}
#'
#' @export
#'
#' @examplesIf interactive()
#' # total population by state, 2022
#' censo_populacao(year = 2022)
#'
#' # population by sex, Brazil level
#' censo_populacao(year = 2022, variables = "sex", territorial_level = "brazil")
#'
#' # population by age and sex, 2010
#' censo_populacao(year = 2010, variables = "age_sex")
#'
#' # population by race, 2022
#' censo_populacao(year = 2022, variables = "race")
censo_populacao <- function(year,
                            variables = "total",
                            territorial_level = "state",
                            geo_code = "all",
                            raw = FALSE) {

  # validate year
  year <- .censo_validate_year(year)
  if (length(year) > 1) {
    cli::cli_abort(c(
      "Only one year at a time is supported by {.fn censo_populacao}.",
      "i" = "Use a loop or {.fn purrr::map} for multiple years."
    ))
  }

  # validate variables
  valid_vars <- c("total", "sex", "age", "age_sex", "race", "situation")
  variables <- tolower(variables)
  if (!variables %in% valid_vars) {
    cli::cli_abort(c(
      "Invalid {.arg variables} value: {.val {variables}}",
      "i" = "Available: {.val {valid_vars}}"
    ))
  }

  # resolve table and classifications
  resolved <- .censo_resolve_table(year, variables)

  # fetch data
  data_raw <- .censo_fetch_sidra(
    table = resolved$table,
    territorial_level = territorial_level,
    geo_code = geo_code,
    variable = resolved$variable,
    period = as.character(year),
    classifications = resolved$classifications
  )

  if (nrow(data_raw) == 0) {
    return(tibble::tibble())
  }

  if (raw) {
    return(data_raw)
  }

  result <- .censo_clean_populacao(data_raw, resolved$table)

  cli::cli_alert_success(
    "Retrieved {.val {nrow(result)}} rows: Census {year}, {variables} level"
  )

  result
}

#' Get intercensitary population estimates
#'
#' Retrieves population estimates for intercensitary years (2001-2021) from
#' SIDRA table 6579. These estimates provide population denominators for years
#' between censuses.
#'
#' @param year Numeric or vector. Year(s) between 2001 and 2021.
#' @param territorial_level Character. Geographic level:
#'   \code{"brazil"}, \code{"region"}, \code{"state"}, or \code{"municipality"}.
#'   Default is \code{"state"}.
#' @param geo_code Character. IBGE code(s) for specific localities.
#'   \code{"all"} returns all localities at the chosen level. Default is \code{"all"}.
#' @param raw Logical. If TRUE, returns raw API output without cleaning.
#'   Default is FALSE.
#'
#' @return A tibble with population estimates.
#'
#' @details
#' Table 6579 provides total population estimates (no sex/age breakdown).
#' These estimates are published annually by IBGE and are widely used as
#' denominators for health indicator calculations.
#'
#' For census years with full demographic breakdowns, use
#' \code{\link{censo_populacao}} instead.
#'
#' @section Data source:
#' Data is retrieved from IBGE SIDRA API, table 6579:
#' \verb{https://sidra.ibge.gov.br/tabela/6579}
#'
#' @export
#'
#' @examplesIf interactive()
#' # estimates for 2020 by state
#' censo_estimativa(year = 2020)
#'
#' # estimates for multiple years, Brazil level
#' censo_estimativa(year = 2015:2020, territorial_level = "brazil")
#'
#' # estimates by municipality
#' censo_estimativa(year = 2021, territorial_level = "municipality")
censo_estimativa <- function(year,
                             territorial_level = "state",
                             geo_code = "all",
                             raw = FALSE) {

  # validate year
  year <- .censo_validate_estimativa_year(year)

  # fetch from table 6579 (variable 9324 = populacao residente estimada)
  data_raw <- .censo_fetch_sidra(
    table = "6579",
    territorial_level = territorial_level,
    geo_code = geo_code,
    variable = "9324",
    period = as.character(year),
    classifications = NULL
  )

  if (nrow(data_raw) == 0) {
    return(tibble::tibble())
  }

  if (raw) {
    return(data_raw)
  }

  result <- .censo_clean_estimativa(data_raw, "6579")

  cli::cli_alert_success(
    "Retrieved {.val {nrow(result)}} rows: Population estimates for {length(year)} year{?s}"
  )

  result
}

# ============================================================================
# public API - SIDRA generic
# ============================================================================

#' List Census SIDRA tables
#'
#' Returns a catalog of available SIDRA tables for the Census, organized by
#' theme.
#'
#' @param theme Character. Filter by theme. NULL returns all themes.
#'   Available themes: \code{"population"}, \code{"race"}, \code{"estimates"},
#'   \code{"literacy"}, \code{"housing"}, \code{"sanitation"},
#'   \code{"disability"}, \code{"indigenous"}, \code{"quilombola"},
#'   \code{"fertility"}, \code{"education"}, \code{"labor"},
#'   \code{"income"}, \code{"age_sex"}, \code{"urbanization"}.
#' @param year Character or numeric. Filter tables that contain data for
#'   this year. NULL returns tables for all years.
#'
#' @return A tibble with columns: table_code, table_name, theme, years,
#'   territorial_levels.
#'
#' @export
#'
#' @examples
#' # list all Census tables
#' censo_sidra_tables()
#'
#' # filter by theme
#' censo_sidra_tables(theme = "population")
#'
#' # tables with 2022 data
#' censo_sidra_tables(year = 2022)
censo_sidra_tables <- function(theme = NULL, year = NULL) {

  catalog <- censo_sidra_catalog_internal

  # validate and filter by theme
  if (!is.null(theme)) {
    available_themes <- unique(catalog$theme)
    theme <- tolower(theme)
    invalid <- theme[!theme %in% available_themes]
    if (length(invalid) > 0) {
      cli::cli_abort(c(
        "Invalid theme{?s}: {.val {invalid}}",
        "i" = "Available themes: {.val {sort(available_themes)}}"
      ))
    }
    catalog <- catalog[catalog$theme %in% theme, ]
  }

  # filter by year
  if (!is.null(year)) {
    year_char <- as.character(year)
    keep <- purrr::map_lgl(catalog$years, ~ any(year_char %in% .x))
    catalog <- catalog[keep, ]
  }

  catalog |>
    dplyr::select("table_code", "table_name", "theme", "years", "territorial_levels") |>
    dplyr::arrange(.data$theme, .data$table_code)
}

#' Search Census SIDRA tables
#'
#' Searches Census SIDRA tables by keyword in the table name.
#' Supports partial matching, case-insensitive, and accent-insensitive search.
#'
#' @param keyword Character. Search term (minimum 2 characters).
#' @param year Character or numeric. Filter tables containing data for this
#'   year. NULL returns all.
#'
#' @return A tibble with matching tables (same structure as
#'   \code{\link{censo_sidra_tables}}).
#'
#' @export
#'
#' @examples
#' censo_sidra_search("deficiencia")
#' censo_sidra_search("raca")
#' censo_sidra_search("indigena")
censo_sidra_search <- function(keyword, year = NULL) {

  # validate keyword
  if (missing(keyword) || is.null(keyword) || nchar(keyword) < 2) {
    cli::cli_abort("Please provide a keyword with at least 2 characters.")
  }

  catalog <- censo_sidra_catalog_internal

  keyword_norm <- .strip_accents(tolower(keyword))

  # search in table names
  table_names_norm <- .strip_accents(tolower(catalog$table_name))
  matches <- grepl(keyword_norm, table_names_norm, fixed = TRUE)
  catalog <- catalog[matches, ]

  # filter by year
  if (!is.null(year)) {
    year_char <- as.character(year)
    keep <- purrr::map_lgl(catalog$years, ~ any(year_char %in% .x))
    catalog <- catalog[keep, ]
  }

  # inform results
  if (nrow(catalog) == 0) {
    cli::cli_alert_warning("No tables found for keyword: '{keyword}'")
  } else {
    cli::cli_alert_info("Found {nrow(catalog)} table(s) matching '{keyword}'")
  }

  catalog |>
    dplyr::select("table_code", "table_name", "theme", "years", "territorial_levels") |>
    dplyr::arrange(.data$table_code)
}

#' Get Census data from SIDRA API
#'
#' Queries the IBGE SIDRA API to retrieve any Census table. This is the
#' most flexible function, allowing full control over SIDRA query parameters.
#'
#' @param table Numeric or character. SIDRA table code.
#'   Use \code{\link{censo_sidra_tables}} or \code{\link{censo_sidra_search}}
#'   to find codes.
#' @param territorial_level Character. Geographic level:
#'   \code{"brazil"} (N1), \code{"region"} (N2), \code{"state"} (N3),
#'   \code{"municipality"} (N6). Default \code{"brazil"}.
#' @param geo_code Character. IBGE code(s) for specific localities.
#'   \code{"all"} returns all localities at the chosen level. Default
#'   \code{"all"}.
#' @param year Numeric or character. Year(s) to query. NULL returns all
#'   available periods.
#' @param variable Numeric or character. SIDRA variable ID(s).
#'   NULL returns all variables excluding metadata. Default NULL.
#' @param classifications Named list. SIDRA classification filters.
#'   Example: \code{list("2" = "allxt")} for sex breakdown.
#'   NULL returns default aggregation. Default NULL.
#' @param raw Logical. If TRUE, returns raw API output without cleaning.
#'   Default FALSE.
#'
#' @return A tibble with queried data.
#'
#' @export
#'
#' @examplesIf interactive()
#' # population by state from 2022 Census
#' censo_sidra_data(
#'   table = 9514,
#'   territorial_level = "state",
#'   year = 2022,
#'   variable = 93
#' )
#'
#' # population by race, Brazil level
#' censo_sidra_data(
#'   table = 9605,
#'   territorial_level = "brazil",
#'   year = 2022,
#'   variable = 93,
#'   classifications = list("86" = "allxt")
#' )
censo_sidra_data <- function(table,
                             territorial_level = "brazil",
                             geo_code = "all",
                             year = NULL,
                             variable = NULL,
                             classifications = NULL,
                             raw = FALSE) {

  table <- as.character(table)

  # check if table exists in catalog (soft warning)
  if (!table %in% censo_sidra_catalog_internal$table_code) {
    cli::cli_alert_warning(
      "Table {.val {table}} not found in internal catalog. Proceeding with API call."
    )
  }

  # build period parameter
  period <- if (!is.null(year)) as.character(year) else NULL

  # fetch data
  data_raw <- .censo_fetch_sidra(
    table = table,
    territorial_level = territorial_level,
    geo_code = geo_code,
    variable = if (!is.null(variable)) as.character(variable) else NULL,
    period = period,
    classifications = classifications
  )

  if (is.null(data_raw) || nrow(data_raw) == 0) {
    cli::cli_alert_warning("No data returned for the specified parameters.")
    return(tibble::tibble())
  }

  if (raw) {
    return(data_raw)
  }

  result <- clean_sidra_response(data_raw, table)

  cli::cli_alert_success(
    "Retrieved {.val {nrow(result)}} rows from SIDRA table {.val {table}}"
  )

  result
}
