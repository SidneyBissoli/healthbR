# shared SIDRA API utilities
# used by PNS and Census modules

#' SIDRA territorial level mapping
#' @noRd
sidra_level_map <- c(
  "brazil" = "1",
  "region" = "2",
  "state" = "3",
  "municipality" = "6"
)

#' Clean SIDRA API response
#' @noRd
clean_sidra_response <- function(data_raw, table_code) {
  # the first row from SIDRA API contains column metadata
  # actual data starts from row 2
  if (nrow(data_raw) <= 1) {
    cli::cli_alert_warning("No data rows returned from SIDRA API.")
    return(tibble::tibble())
  }

  # remove header row
  data_clean <- data_raw[-1, ]

  # convert value column to numeric (SIDRA uses "," as decimal separator)
  if ("V" %in% names(data_clean)) {
    data_clean <- data_clean |>
      dplyr::mutate(
        V = stringr::str_replace_all(.data$V, "\\.", ""),
        V = stringr::str_replace(.data$V, ",", "."),
        V = suppressWarnings(as.numeric(.data$V))
      )
  }

  # clean column names to snake_case
  names(data_clean) <- .clean_names(names(data_clean))
  data_clean
}
