# Shared accent-stripping and metadata search helpers
# Used by *_variables(), *_diseases(), *_sidra_search(), and POF dictionary parsing

# Comprehensive accent map covering Portuguese (+ Spanish ñ/Ñ, ü/Ü)
# lowercase: à á â ã ä ç è é ê ë ì í î ï ò ó ô õ ö ù ú û ü ñ = 24
# uppercase: À Á Â Ã Ä Ç È É Ê Ë Ì Í Î Ï Ò Ó Ô Õ Ö Ù Ú Û Ü Ñ = 24
.accent_from <- paste0(
  "\u00e0\u00e1\u00e2\u00e3\u00e4\u00e7\u00e8\u00e9\u00ea\u00eb\u00ec\u00ed\u00ee\u00ef",
  "\u00f2\u00f3\u00f4\u00f5\u00f6\u00f9\u00fa\u00fb\u00fc\u00f1",
  "\u00c0\u00c1\u00c2\u00c3\u00c4\u00c7\u00c8\u00c9\u00ca\u00cb\u00cc\u00cd\u00ce\u00cf",
  "\u00d2\u00d3\u00d4\u00d5\u00d6\u00d9\u00da\u00db\u00dc\u00d1"
)
.accent_to <- "aaaaaceeeeiiiiooooouuuunAAAAACEEEEIIIIOOOOOUUUUN"

#' Strip accents from text (Windows-safe, uses chartr instead of iconv)
#' @param x Character vector.
#' @return Character vector with accented characters replaced by ASCII equivalents.
#' @noRd
.strip_accents <- function(x) {
  chartr(.accent_from, .accent_to, x)
}

#' Search metadata rows by keyword with accent-insensitive matching
#'
#' Filters a data.frame by searching for a keyword across one or more
#' character columns. Matching is case-insensitive and accent-insensitive.
#'
#' @param data A data.frame to filter.
#' @param search Character string to search for, or NULL (returns data unchanged).
#' @param columns Character vector of column names to search in.
#' @return Filtered data.frame.
#' @noRd
.search_metadata <- function(data, search, columns) {
  if (is.null(search)) return(data)
  search_lower <- tolower(search)
  search_ascii <- .strip_accents(search_lower)
  match_idx <- Reduce(`|`, lapply(columns, function(col) {
    col_lower <- tolower(data[[col]])
    grepl(search_lower, col_lower, fixed = TRUE) |
      grepl(search_ascii, .strip_accents(col_lower), fixed = TRUE)
  }))
  data[match_idx, ]
}
