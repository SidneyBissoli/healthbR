# utils-parse.R — shared column type parsing utilities for DATASUS modules
#
# All DATASUS modules (SIM, SINASC, SIH, SIA, CNES, SINAN, SI-PNI) store
# columns as character. These utilities convert columns to their appropriate
# types based on metadata type specifications.


#' Build a named type spec vector from a metadata tibble
#'
#' Extracts the `variable` and `type` columns from a metadata tibble
#' into a named character vector suitable for `.parse_columns()`.
#'
#' @param metadata A tibble with `variable` and `type` columns.
#' @return A named character vector: names = variable names, values = type strings.
#' @noRd
.build_type_spec <- function(metadata) {
  spec <- metadata$type
  names(spec) <- metadata$variable
  spec
}


#' Convert a single character column to the target type
#'
#' Normalizes empty strings and whitespace-only values to NA, then converts
#' based on the target type string.
#'
#' @param x Character vector to convert.
#' @param target_type Character. One of: "character", "integer", "double",
#'   "date_dmy", "date_ymd", "date_ym", "date".
#' @return Converted vector.
#' @noRd
.convert_column <- function(x, target_type) {
  if (target_type == "character") return(x)

  # normalize empty/whitespace to NA
  x[!is.na(x) & trimws(x) == ""] <- NA_character_

  switch(target_type,
    "integer" = suppressWarnings(as.integer(x)),
    "double"  = suppressWarnings(as.double(x)),
    "date_dmy" = .parse_date_dmy(x),
    "date_ymd" = .parse_date_ymd(x),
    "date_ym"  = .parse_date_ym(x),
    "date"     = .parse_date_iso(x),
    {
      cli::cli_warn("Unknown type {.val {target_type}}, keeping as character.")
      x
    }
  )
}


#' Parse date in ddmmyyyy format
#' @noRd
.parse_date_dmy <- function(x) {
  as.Date(x, format = "%d%m%Y")
}

#' Parse date in yyyymmdd format
#' @noRd
.parse_date_ymd <- function(x) {
  as.Date(x, format = "%Y%m%d")
}

#' Parse date in yyyymm format (day set to 01)
#' @noRd
.parse_date_ym <- function(x) {
  as.Date(paste0(x, "01"), format = "%Y%m%d")
}

#' Parse date in ISO yyyy-mm-dd format
#' @noRd
.parse_date_iso <- function(x) {
  as.Date(x, format = "%Y-%m-%d")
}


#' Parse columns of a data frame using a type specification
#'
#' Merges user overrides (`col_types`) into the internal type spec, then
#' converts each column that appears in the spec.
#'
#' @param data A data frame (all character columns from DATASUS).
#' @param type_spec Named character vector from `.build_type_spec()`.
#' @param col_types Named list of user overrides. Names are column names,
#'   values are type strings (e.g., `list(PESO = "character")`).
#' @return The data frame with columns converted.
#' @noRd
.parse_columns <- function(data, type_spec, col_types = NULL) {
  # merge user overrides
  if (!is.null(col_types)) {
    for (nm in names(col_types)) {
      type_spec[nm] <- col_types[[nm]]
    }
  }

  # only process columns present in both data and spec
  cols_to_parse <- intersect(names(data), names(type_spec))

  for (col in cols_to_parse) {
    target <- type_spec[col]
    if (target != "character") {
      data[[col]] <- .convert_column(data[[col]], target)
    }
  }

  data
}
