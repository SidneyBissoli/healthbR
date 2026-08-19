# data-raw/sipni-dictionaries.R
#
# Regenerates R/sipni_dictionary_data.R (the built-in offline fallback for
# sipni_dictionary(source = "datasus") and sipni_label_maps) from the
# authoritative dictionaries published on the healthbr-data R2 mirror —
# which are direct conversions of the Ministry's original .cnv/.dbf files
# (ftp://ftp.datasus.gov.br/dissemin/publicos/PNI/AUXILIARES/).
#
# The tables are stored as DATA-code lookups: `code` is the value exactly
# as it appears in the .dbf data files (the .cnv `source_codes`, expanded),
# so they can be joined directly against sipni_data() results.
#
# Run from the package root:
#   Rscript data-raw/sipni-dictionaries.R
#
# History: the hand-written 0.2.0 dictionary was wrong (it mislabeled 19 of
# 20 IMUNO codes — e.g. data code "09" is Hib per the official .cnv, not
# BCG) and used DOSE/FX_ETARIA codes that do not occur in the data at all.

devtools::load_all(".", quiet = TRUE)

dict <- sipni_dictionary(source = "r2", cache = FALSE)
lookup <- healthbR:::.sipni_expand_dict_lookup(dict)

message("Lookup rows: ", nrow(lookup),
        " (overlaps resolved by specificity: explicit codes beat ranges)")

esc <- function(x) {
  vapply(x, function(s) {
    ints <- utf8ToInt(s)
    paste(ifelse(ints > 127L, sprintf("\\u%04x", ints),
                 vapply(ints, function(i) {
                   ch <- intToUtf8(i)
                   if (ch == "\\") "\\\\" else if (ch == "\"") "\\\"" else ch
                 }, character(1))),
          collapse = "")
  }, character(1), USE.NAMES = FALSE)
}

vec_lines <- function(x, indent = "    ") {
  paste0(indent, "\"", esc(x), "\"", c(rep(",", length(x) - 1), ""))
}

named_vec_lines <- function(codes, labels, indent = "    ") {
  paste0(indent, "\"", esc(codes), "\" = \"", esc(labels), "\"",
         c(rep(",", length(codes) - 1), ""))
}

out <- c(
  "# sipni_dictionary_data / sipni_label_maps — GENERATED FILE, DO NOT EDIT",
  "# Regenerate with: Rscript data-raw/sipni-dictionaries.R",
  paste0("# Generated on ", format(Sys.Date()), " from the healthbr-data R2"),
  "# dictionaries (converted from the Ministry's original .cnv/.dbf files).",
  "# `code` holds DATA codes (the .cnv source_codes, expanded), so these",
  "# tables join directly against sipni_data() results. Overlapping .cnv",
  "# categories are resolved by specificity (explicit codes beat range",
  "# catch-alls), so residuals like FX_ETARIA 'Idade ignorada' (00-99) only",
  "# label codes no specific category claimed.",
  "",
  "#' SI-PNI data dictionary tibble (offline fallback, data-code lookup)",
  "#' @noRd",
  "sipni_dictionary_data <- tibble::tibble(",
  "  variable = c(",
  vec_lines(lookup$variable),
  "  ),",
  "  description = c(",
  vec_lines(lookup$description),
  "  ),",
  "  code = c(",
  vec_lines(lookup$code),
  "  ),",
  "  label = c(",
  vec_lines(lookup$label),
  "  )",
  ")",
  "",
  "#' Label maps for SI-PNI categorical variables (data-code -> label)",
  "#' @noRd",
  "sipni_label_maps <- list("
)

map_specs <- list(
  IMUNO = lookup[lookup$variable == "IMUNO" &
                   grepl("doses", lookup$description), ],
  DOSE = lookup[lookup$variable == "DOSE", ],
  FX_ETARIA = lookup[lookup$variable == "FX_ETARIA", ]
)
for (i in seq_along(map_specs)) {
  m <- map_specs[[i]]
  out <- c(out,
           paste0("  ", names(map_specs)[i], " = c("),
           named_vec_lines(m$code, m$label),
           paste0("  )", if (i < length(map_specs)) ","))
}
out <- c(out, ")")

writeLines(out, "R/sipni_dictionary_data.R")
message("Wrote R/sipni_dictionary_data.R: ", nrow(lookup),
        " dictionary rows; label maps: ",
        paste(vapply(map_specs, nrow, integer(1)), collapse = "/"))
