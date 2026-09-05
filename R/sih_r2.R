# sih_r2.R -- SIH-RD access via the healthbr-data Cloudflare R2 mirror
#
# The healthbr-data project redistributes the SIH "AIH reduzida" (RD) files
# exactly as published by the Ministry of Health, as hive-partitioned Parquet:
#   sih/rd/   ano=YYYY/mes=MM/uf=XX/part-0.parquet   (1992-present)
# `ano`/`mes` is the BILLING COMPETENCE (competencia) of the AIH -- the same
# unit as the FTP file RD{UF}{yy}{mm}.dbc -- not the admission date. Every
# column is a string, exactly as read from the .dbc; each Parquet carries a
# `healthbr` provenance record in its footer and the dataset has a
# manifest.json (one entry per partition, keyed "YYYY-MM-UF") with the source
# URL, MD5 and size of the .dbc, the processing timestamp and the Parquet
# SHA-256. See the consumer contract in the healthbr-data repository.
#
# Output is shaped exactly like the FTP path (`year`, `month`, `uf_source` +
# the raw columns, all character) and shares the FTP path's local
# partitioned cache ("sih_data"): the content is identical by construction,
# only the transport differs.
# ============================================================================

#' R2 prefix and manifest path for the SIH-RD dataset
#' @noRd
sih_r2_prefix <- "sih/rd"

#' @noRd
sih_r2_manifest_path <- "sih/rd/manifest.json"


# ============================================================================
# manifest summary + provenance
# ============================================================================

#' Summarise the SIH-RD manifest as one row per partition
#'
#' @return A tibble (dataset, year, month, uf, records, processing_timestamp,
#'   source_url, source_hash_md5, source_size_bytes) or NULL when the manifest
#'   is unreachable and not cached. Never errors.
#' @noRd
.sih_r2_manifest_summary <- function(cache_dir) {
  manifest <- .r2_manifest(sih_r2_manifest_path, cache_dir)
  if (is.null(manifest) || is.null(manifest$partitions)) return(NULL)

  parts <- manifest$partitions
  keys <- names(parts)

  get_chr <- function(field) {
    vapply(parts, function(p) {
      v <- p[[field]]
      if (is.null(v) || length(v) == 0) NA_character_ else as.character(v[1])
    }, character(1), USE.NAMES = FALSE)
  }
  get_num <- function(field) {
    vapply(parts, function(p) {
      v <- p[[field]]
      if (is.null(v) || length(v) == 0) NA_real_ else as.numeric(v[1])
    }, numeric(1), USE.NAMES = FALSE)
  }

  summ <- tibble::tibble(
    dataset = "sih_rd",
    year = as.integer(substr(keys, 1, 4)),
    month = as.integer(substr(keys, 6, 7)),
    uf = substr(keys, 9, 10),
    records = get_num("total_records"),
    processing_timestamp = get_chr("processing_timestamp"),
    source_url = get_chr("source_url"),
    source_hash_md5 = get_chr("source_hash_md5"),
    source_size_bytes = get_num("source_size_bytes")
  )
  summ[order(summ$year, summ$month, summ$uf), ]
}


#' Provenance rows for the partitions a sih_data() call touched
#' @return A tibble or NULL (never errors).
#' @noRd
.sih_r2_provenance <- function(years, months, ufs, cache_dir) {
  tryCatch({
    s <- .sih_r2_manifest_summary(cache_dir)
    if (is.null(s)) return(NULL)
    out <- s[s$year %in% as.integer(years) & s$month %in% as.integer(months) &
               s$uf %in% ufs, ]
    if (nrow(out) == 0) NULL else out
  }, error = function(e) NULL)
}


# ============================================================================
# eager fetch (sih/rd/ano=YYYY/mes=MM/uf=XX/)
# ============================================================================

#' Shape one R2 read like the FTP path: year/month/uf_source in front
#' @noRd
.sih_r2_shape <- function(df, year, month) {
  df$year <- as.integer(year)
  df$month <- as.integer(month)
  df$uf_source <- as.character(df$uf)
  df$mes <- NULL
  df$uf <- NULL
  .sipni_front_cols(df, c("year", "month", "uf_source"))
}


#' Fetch SIH-RD microdata from R2 for a year x month x UF grid
#'
#' Serves whatever the local partitioned cache already has, then reads the
#' missing combinations from R2 -- one arrow dataset per year (the bucket
#' layout), one collect per month with a pushdown filter on `uf`. Failed
#' combinations are labelled like the FTP path ("AC 2023/01") so the caller
#' can report them uniformly.
#'
#' @return list(results = list of tibbles, failed_labels = character).
#' @noRd
.sih_r2_fetch <- function(years, months, ufs, cache, cache_dir, creds) {
  cache_dir <- .sih_cache_dir(cache_dir)
  dataset_name <- "sih_data"
  results <- list()
  failed <- character(0)

  # 1. serve cached combos locally
  wanted <- expand.grid(year = as.integer(years), month = as.integer(months),
                        uf_source = ufs, stringsAsFactors = FALSE)
  have <- tibble::tibble(year = integer(0), month = integer(0),
                         uf_source = character(0))
  if (isTRUE(cache)) {
    combos <- .sipni_r2_cached_combos(cache_dir, dataset_name,
                                      c("year", "month", "uf_source"))
    if (nrow(combos) > 0) {
      have <- dplyr::inner_join(wanted, combos,
                                by = c("year", "month", "uf_source"))
      if (nrow(have) > 0) {
        ds <- arrow::open_dataset(file.path(cache_dir, dataset_name),
                                  unify_schemas = TRUE)
        cached <- ds |>
          dplyr::filter(.data$year %in% !!unique(have$year),
                        .data$month %in% !!unique(have$month),
                        .data$uf_source %in% !!unique(have$uf_source)) |>
          dplyr::collect()
        cached <- dplyr::semi_join(cached, wanted,
                                   by = c("year", "month", "uf_source"))
        cached <- .sipni_front_cols(cached, c("year", "month", "uf_source"))
        if (nrow(cached) > 0) results <- c(results, list(cached))
      }
    }
  }

  todo <- dplyr::anti_join(wanted, have, by = c("year", "month", "uf_source"))
  if (nrow(todo) == 0) {
    return(list(results = results, failed_labels = failed))
  }

  label <- function(uf, y, m) paste(uf, paste0(y, "/", sprintf("%02d", m)))

  # 2. read missing combos from R2, one arrow dataset per year
  for (y in sort(unique(todo$year))) {
    todo_y <- todo[todo$year == y, ]
    ds <- tryCatch(
      .r2_open_dataset(paste0(sih_r2_prefix, "/ano=", y), creds,
                       partition_cols = c("mes", "uf")),
      error = function(e) NULL
    )
    if (is.null(ds)) {
      failed <- c(failed, label(todo_y$uf_source, y, todo_y$month))
      next
    }

    for (m in sort(unique(todo_y$month))) {
      need_ufs <- todo_y$uf_source[todo_y$month == m]
      mes_chr <- sprintf("%02d", m)
      cli::cli_inform(c(
        "i" = "Reading SIH data from R2: {y}/{mes_chr} ({length(need_ufs)} UF(s))..."
      ))
      df <- tryCatch({
        ds |>
          dplyr::filter(.data$mes == !!mes_chr,
                        .data$uf %in% !!need_ufs) |>
          dplyr::collect()
      }, error = function(e) NULL)

      got_ufs <- if (is.null(df) || nrow(df) == 0) character(0) else unique(df$uf)
      missing_ufs <- setdiff(need_ufs, got_ufs)
      if (length(missing_ufs) > 0) {
        failed <- c(failed, label(missing_ufs, y, m))
      }
      if (length(got_ufs) == 0) next

      df <- .sih_r2_shape(df, y, m)
      if (isTRUE(cache)) {
        .cache_append_partitioned(df, cache_dir, dataset_name,
                                  c("uf_source", "year", "month"))
      }
      results <- c(results, list(df))
    }
  }

  list(results = results, failed_labels = failed)
}


# ============================================================================
# lazy access (remote dataset, nothing downloaded)
# ============================================================================

#' Lazy SIH-RD dataset over the R2 mirror
#'
#' The bucket spans 14 historical schemas (35 to 113 columns), so the whole
#' prefix cannot be opened with an inferred schema: the first file arrow
#' meets is from 1992. Instead the schema is taken from the newest requested
#' year and imposed on the whole prefix; partition pruning on `ano` then
#' guarantees only the requested years are ever read. Listing the prefix
#' costs a few seconds (one object per UF-month since 1992).
#'
#' @return An arrow Dataset (or duckdb tbl) with `year`, `month`, `uf_source`
#'   in front of the raw columns, or NULL if the mirror cannot be opened.
#' @noRd
.sih_r2_lazy <- function(years, months, ufs, backend, creds) {
  years <- sort(as.integer(years))
  newest <- .r2_open_dataset(paste0(sih_r2_prefix, "/ano=", max(years)), creds,
                             partition_cols = c("mes", "uf"))
  sch <- newest$schema$AddField(0L, arrow::field("ano", arrow::utf8()))

  ds <- .r2_open_dataset(sih_r2_prefix, creds,
                         partition_cols = c("ano", "mes", "uf"), schema = sch)
  ds <- ds |>
    dplyr::filter(.data$ano %in% !!as.character(years),
                  .data$uf %in% !!ufs)
  if (length(months) < 12) {
    ds <- ds |> dplyr::filter(.data$mes %in% !!sprintf("%02d", months))
  }
  raw_cols <- setdiff(names(newest$schema), c("mes", "uf"))
  ds <- ds |>
    dplyr::mutate(year = as.integer(.data$ano),
                  month = as.integer(.data$mes),
                  uf_source = .data$uf) |>
    dplyr::select(dplyr::all_of(c("year", "month", "uf_source", raw_cols)))

  if (backend == "duckdb") {
    if (!.has_duckdb()) {
      cli::cli_abort(c(
        "Package {.pkg duckdb} is required for {.code backend = \"duckdb\"}.",
        "i" = "Install with: {.code install.packages('duckdb')}"
      ))
    }
    ds <- arrow::to_duckdb(ds)
  }
  ds
}


# ============================================================================
# status (exported)
# ============================================================================

#' Status of the SIH-RD dataset on the healthbr-data R2 mirror
#'
#' Reads the mirror's `manifest.json` (revalidated by ETag, cached locally)
#' and returns one row per published partition (billing competence x state
#' of the hospital), with the DATASUS source file it came from, its MD5 and
#' size, the record count and the processing timestamp. This is what
#' [sih_data()] reads by default; use it to see which competences are
#' published and to detect a re-issued file (the MD5 changes).
#'
#' @param cache_dir Character. Cache directory for the local copy of the
#'   manifest. Default: the SIH module cache.
#'
#' @return A tibble with columns `dataset`, `year`, `month`, `uf`, `records`,
#'   `processing_timestamp`, `source_url`, `source_hash_md5` and
#'   `source_size_bytes`. Empty (with a warning) if the manifest cannot be
#'   read and no local copy exists.
#'
#' @export
#' @family sih
#'
#' @examplesIf interactive()
#' st <- sih_status()
#' # competences published for Roraima in 2024
#' st[st$uf == "RR" & st$year == 2024, ]
sih_status <- function(cache_dir = NULL) {
  cache_dir <- .sih_cache_dir(cache_dir)
  s <- .sih_r2_manifest_summary(cache_dir)
  if (is.null(s)) {
    cli::cli_warn(c(
      "!" = "Could not read the SIH-RD manifest from the healthbr-data mirror.",
      "i" = "The R2 mirror may be unreachable and no local copy was cached."
    ))
    return(tibble::tibble(
      dataset = character(0), year = integer(0), month = integer(0),
      uf = character(0), records = numeric(0),
      processing_timestamp = character(0), source_url = character(0),
      source_hash_md5 = character(0), source_size_bytes = numeric(0)
    ))
  }
  s
}
