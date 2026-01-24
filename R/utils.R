#' Utility Functions for healthbR
#'
#' @name utils
NULL

#' List Available Data Sources
#'
#' Returns information about all data sources available in healthbR.
#'
#' @return A tibble with columns:
#'   \itemize{
#'     \item \code{source}: Source code (e.g., "vigitel", "sim")
#'     \item \code{name}: Full name of the data source
#'     \item \code{description}: Brief description
#'     \item \code{years}: Range of available years
#'     \item \code{status}: Implementation status ("available", "planned")
#'   }
#'
#' @export
#'
#' @examples
#' list_sources()
list_sources <- function() {

  tibble::tibble(
    source = c(
      "vigitel",
      "pns",
      "pnad",
      "pof",
      "censo",
      "sim",
      "sinasc",
      "sih",
      "sia",
      "sinan",
      "cnes"
    ),
    name = c(
      "VIGITEL",
      "PNS - Pesquisa Nacional de Saude",
      "PNAD Continua",
      "POF - Pesquisa de Orcamentos Familiares",
      "Censo Demografico",
      "SIM - Sistema de Informacoes sobre Mortalidade",
      "SINASC - Sistema de Informacoes sobre Nascidos Vivos",
      "SIH - Sistema de Informacoes Hospitalares",
      "SIA - Sistema de Informacoes Ambulatoriais",
      "SINAN - Sistema de Informacao de Agravos de Notificacao",
      "CNES - Cadastro Nacional de Estabelecimentos de Saude"
    ),
    description = c(
      "Telephone survey on chronic disease risk factors",
      "National health survey (IBGE)",
      "Continuous national household survey (IBGE)",
      "Household budget survey - nutrition data (IBGE)",
      "Demographic census - population denominators (IBGE)",
      "Mortality data from death certificates",
      "Live birth data",
      "Hospital admissions (AIH)",
      "Outpatient procedures",
      "Notifiable diseases surveillance",
      "Health facilities registry"
    ),
    years = c(
      "2006-2023",
      "2013, 2019",
      "2012-2023",
      "2008-2009, 2017-2018",
      "1991, 2000, 2010, 2022",
      "1979-2023",
      "1994-2023",
      "1992-2023",
      "1994-2023",
      "2001-2023",
      "2005-2023"
    ),
    status = c(
      "available",
      "planned",
      "planned",
      "planned",
      "planned",
      "planned",
      "planned",
      "planned",
      "planned",
      "planned",
      "planned"
    )
  )
}


#' Clean Column Names to Snake Case
#'
#' Internal function to standardize column names to snake_case.
#'
#' @param names Character vector of column names.
#'
#' @return Character vector of cleaned column names.
#'
#' @noRd
.clean_names <- function(names) {
  names |>
    tolower() |>
    gsub("[^a-z0-9]", "_", x = _) |>
    gsub("_+", "_", x = _) |>
    gsub("^_|_$", "", x = _)
}


#' Get Cache Directory
#'
#' Returns the path to the healthbR cache directory.
#'
#' @return Character. Path to cache directory.
#'
#' @noRd
.get_cache_dir <- function() {
  cache_dir <- tools::R_user_dir("healthbR", which = "cache")

  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }

  cache_dir
}


#' Check Internet Connection
#'
#' Internal function to verify internet connectivity before downloads.
#'
#' @return Logical. TRUE if connected, FALSE otherwise.
#'
#' @noRd
.check_internet <- function() {
  tryCatch(
    {
      con <- url("https://www.google.com", open = "r")
      close(con)
      TRUE
    },
    error = function(e) FALSE
  )
}
