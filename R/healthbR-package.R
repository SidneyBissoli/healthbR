#' @keywords internal
"_PACKAGE"

#' healthbR: Access Brazilian Public Health Data
#'
#' The healthbR package provides easy access to Brazilian public health data
#' from multiple sources. Data is returned in tidy format following tidyverse
#' conventions.
#'
#' @section Data Sources:
#' Currently supported:
#' \itemize{
#'   \item \strong{VIGITEL}: Surveillance of Risk Factors for Chronic Diseases
#'     by Telephone Survey (2006-2023)
#' }
#'
#' Planned for future versions:
#' \itemize{
#'   \item \strong{PNS}: National Health Survey (IBGE)
#'   \item \strong{PNAD}: National Household Sample Survey (IBGE)
#'   \item \strong{SIM}: Mortality Information System
#'   \item \strong{SINASC}: Live Birth Information System
#'   \item \strong{SIH}: Hospital Information System
#'   \item \strong{SINAN}: Notifiable Diseases Information System
#' }
#'
#' @section Functions:
#' VIGITEL functions:
#' \itemize{
#'   \item \code{\link{vigitel_years}}: List available years
#'   \item \code{\link{vigitel_variables}}: List available variables
#'   \item \code{\link{vigitel_dictionary}}: Get variable dictionary
#'   \item \code{\link{vigitel_data}}: Download data
#' }
#'
#' @docType package
#' @name healthbR-package
NULL
