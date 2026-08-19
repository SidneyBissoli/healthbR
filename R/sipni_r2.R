# sipni_r2.R \u2014 SI-PNI access via the healthbr-data Cloudflare R2 mirror
#
# The healthbr-data project redistributes the SI-PNI datasets exactly as
# published by the Ministry of Health, as hive-partitioned Parquet:
#   sipni/microdados/            ano=YYYY/mes=MM/uf=XX/   (2020+, JSON origin)
#   sipni/agregados/doses/       ano=YYYY/uf=XX/          (DPNI, 1994-2019)
#   sipni/agregados/cobertura/   ano=YYYY/uf=XX/          (CPNI, 1994-2019)
#   sipni/dicionarios/           *.parquet                (flat files)
# All values are byte-identical to the source files; every Parquet carries a
# `healthbr` provenance record and each dataset has a manifest.json.
#
# NOTE: the 2020+ microdata on R2 comes from the Ministry's JSON exports
# (56 fields, names like `dt_vacina`, `ds_vacina`), NOT from the CSV exports
# healthbR <= 0.2.0 used (names like `data_vacina`, `descricao_vacina`).
# Each source returns its own column set, exactly as published.

# ============================================================================
# constants
# ============================================================================

#' R2 prefixes for the SI-PNI datasets
#' @noRd
sipni_r2_prefix_microdados <- "sipni/microdados"

#' @noRd
sipni_r2_prefix_doses <- "sipni/agregados/doses"

#' @noRd
sipni_r2_prefix_cobertura <- "sipni/agregados/cobertura"

#' @noRd
sipni_r2_prefix_dicionarios <- "sipni/dicionarios"

#' Manifest object paths (microdados manifest lives at sipni/manifest.json \u2014
#' legacy exception documented in the healthbr-data consumer contract)
#' @noRd
sipni_r2_manifest_paths <- c(
  microdados = "sipni/manifest.json",
  doses = "sipni/agregados/doses/manifest.json",
  cobertura = "sipni/agregados/cobertura/manifest.json"
)


# ============================================================================
# manifest summaries (availability + provenance)
# ============================================================================

#' Summarize one SI-PNI manifest into a partition-level tibble
#'
#' @param which One of "microdados", "doses", "cobertura".
#' @param cache_dir Resolved sipni cache directory.
#' @return A tibble (dataset, year, month, uf, records, processing_timestamp,
#'   source_url), or NULL when the manifest is unreachable and not cached.
#' @noRd
.sipni_r2_manifest_summary <- function(which, cache_dir) {
  manifest <- .r2_manifest(sipni_r2_manifest_paths[[which]], cache_dir)
  if (is.null(manifest) || is.null(manifest$partitions)) return(NULL)

  parts <- manifest$partitions
  keys <- names(parts)

  get_chr <- function(field) {
    vapply(parts, function(p) {
      v <- p[[field]]
      if (is.null(v) || length(v) == 0) NA_character_ else as.character(v[1])
    }, character(1), USE.NAMES = FALSE)
  }
  records <- vapply(parts, function(p) {
    v <- p[["total_records"]]
    if (is.null(v) || length(v) == 0) NA_real_ else as.numeric(v[1])
  }, numeric(1), USE.NAMES = FALSE)

  if (which == "microdados") {
    year <- as.integer(substr(keys, 1, 4))
    month <- as.integer(substr(keys, 6, 7))
    uf <- rep(NA_character_, length(keys))
  } else {
    year <- as.integer(substr(keys, 1, 4))
    month <- rep(NA_integer_, length(keys))
    uf <- substr(keys, 6, 7)
  }

  summ <- tibble::tibble(
    dataset = which,
    year = year,
    month = month,
    uf = uf,
    records = records,
    processing_timestamp = get_chr("processing_timestamp"),
    source_url = get_chr("source_url")
  )

  # remember microdata years for dynamic year validation this session
  if (which == "microdados") {
    .r2_env[["sipni_years"]] <- sort(unique(summ$year))
  }

  summ
}


#' Provenance rows for the partitions a sipni_data() call touched
#' @return A tibble or NULL (never errors).
#' @noRd
.sipni_r2_provenance <- function(ftp_source, api_source, params, cache_dir) {
  out <- list()
  tryCatch({
    if (identical(api_source, "r2") && length(params$api_years) > 0) {
      s <- .sipni_r2_manifest_summary("microdados", cache_dir)
      if (!is.null(s)) {
        out <- c(out, list(s[s$year %in% params$api_years &
                               s$month %in% params$month_vals, ]))
      }
    }
    if (identical(ftp_source, "r2") && length(params$ftp_years) > 0) {
      which <- if (toupper(params$type) == "CPNI") "cobertura" else "doses"
      s <- .sipni_r2_manifest_summary(which, cache_dir)
      if (!is.null(s)) {
        out <- c(out, list(s[s$year %in% params$ftp_years &
                               s$uf %in% params$target_ufs, ]))
      }
    }
    if (length(out) == 0) return(NULL)
    dplyr::bind_rows(out)
  }, error = function(e) NULL)
}


#' Years available in the R2 microdata (session-cached), or NULL
#' @noRd
.sipni_r2_microdados_years <- function() {
  .r2_env[["sipni_years"]]
}


# ============================================================================
# local cache helpers for the R2 paths
# ============================================================================

#' Distinct partition combos already present in a local partitioned cache
#'
#' @param cache_dir Resolved cache directory.
#' @param dataset_name Cache dataset name.
#' @param cols Character vector of partition columns to read.
#' @return A tibble of distinct combos (possibly empty).
#' @noRd
.sipni_r2_cached_combos <- function(cache_dir, dataset_name, cols) {
  proto <- list(year = integer(0), month = integer(0),
                uf_source = character(0))
  empty <- tibble::as_tibble(proto[cols])
  if (!.has_arrow() || !.has_partitioned_cache(cache_dir, dataset_name)) {
    return(empty)
  }
  tryCatch({
    ds <- arrow::open_dataset(file.path(cache_dir, dataset_name))
    ds |>
      dplyr::select(dplyr::all_of(cols)) |>
      dplyr::distinct() |>
      dplyr::collect()
  }, error = function(e) empty)
}


# ============================================================================
# microdata fetch (2020+, sipni/microdados/)
# ============================================================================

#' Standardize a collected R2 microdata chunk to module conventions
#'
#' Adds `year`, `month` (integer) and `uf_source` from the hive partition
#' values and drops the raw partition columns. Data columns are untouched.
#' @noRd
.sipni_r2_shape_microdados <- function(df, year) {
  df$year <- as.integer(year)
  df$month <- as.integer(df$mes)
  df$uf_source <- as.character(df$uf)
  df$mes <- NULL
  df$uf <- NULL
  cols <- names(df)
  df[, c("year", "month", "uf_source",
         setdiff(cols, c("year", "month", "uf_source")))]
}


#' Fetch SI-PNI microdata (2020+) from R2
#'
#' Serves whatever is already in the local partitioned cache and reads the
#' remaining (year, month, uf) combos from the bucket, opening one dataset
#' per year (`ano=YYYY/` subtree) so no bucket-wide listing is needed.
#'
#' @return list(results = list of tibbles, failed_labels = character).
#' @noRd
.sipni_r2_fetch_microdados <- function(years, months, ufs,
                                       cache, cache_dir, creds) {
  cache_dir <- .sipni_cache_dir(cache_dir)
  dataset_name <- "sipni_r2_data"
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
        ds <- arrow::open_dataset(file.path(cache_dir, dataset_name))
        cached <- ds |>
          dplyr::filter(.data$year %in% !!unique(have$year),
                        .data$month %in% !!unique(have$month),
                        .data$uf_source %in% !!unique(have$uf_source)) |>
          dplyr::collect()
        # the coarse filter may bring extra combos; trim to the wanted set
        cached <- dplyr::semi_join(cached, wanted,
                                   by = c("year", "month", "uf_source"))
        if (nrow(cached) > 0) results <- c(results, list(cached))
      }
    }
  }

  todo <- dplyr::anti_join(wanted, have, by = c("year", "month", "uf_source"))
  if (nrow(todo) == 0) {
    return(list(results = results, failed_labels = failed))
  }

  # 2. read missing combos from R2, one arrow dataset per year
  for (y in sort(unique(todo$year))) {
    todo_y <- todo[todo$year == y, ]
    ds <- tryCatch(
      .r2_open_dataset(paste0(sipni_r2_prefix_microdados, "/ano=", y), creds,
                       partition_cols = c("mes", "uf")),
      error = function(e) NULL
    )
    if (is.null(ds)) {
      failed <- c(failed, paste0("R2 ", y, "-",
                                 sprintf("%02d", sort(unique(todo_y$month)))))
      next
    }

    for (m in sort(unique(todo_y$month))) {
      need_ufs <- todo_y$uf_source[todo_y$month == m]
      mes_chr <- sprintf("%02d", m)
      cli::cli_inform(c(
        "i" = "Reading SI-PNI microdata from R2: {y}-{mes_chr} ({length(need_ufs)} UF(s))..."
      ))
      df <- tryCatch({
        ds |>
          dplyr::filter(.data$mes == !!mes_chr,
                        .data$uf %in% !!need_ufs) |>
          dplyr::collect()
      }, error = function(e) NULL)

      if (is.null(df) || nrow(df) == 0) {
        failed <- c(failed, paste0("R2 ", y, "-", mes_chr))
        next
      }

      df <- .sipni_r2_shape_microdados(df, y)
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
# aggregated fetch (1994-2019, sipni/agregados/{doses,cobertura}/)
# ============================================================================

#' Fetch SI-PNI aggregated data (DPNI/CPNI, 1994-2019) from R2
#'
#' Output is shaped exactly like the FTP path (`year` + `uf_source` + the
#' original DBF columns, CPNI `COBERT` decimal comma fixed), and shares the
#' FTP path's local partitioned cache \u2014 the content is identical by
#' construction, only the transport differs.
#'
#' @return list(results = list of tibbles, failed_labels = character).
#' @noRd
.sipni_r2_fetch_agregados <- function(type, years, ufs,
                                      cache, cache_dir, creds) {
  cache_dir <- .sipni_cache_dir(cache_dir)
  type <- toupper(type)
  prefix <- if (type == "CPNI") sipni_r2_prefix_cobertura else sipni_r2_prefix_doses
  dataset_name <- stringr::str_c("sipni_", tolower(type), "_data")
  results <- list()
  failed <- character(0)

  # 1. serve cached combos locally (cache shared with the FTP path)
  wanted <- expand.grid(year = as.integer(years), uf_source = ufs,
                        stringsAsFactors = FALSE)
  have <- tibble::tibble(year = integer(0), uf_source = character(0))
  if (isTRUE(cache)) {
    combos <- .sipni_r2_cached_combos(cache_dir, dataset_name,
                                      c("year", "uf_source"))
    if (nrow(combos) > 0) {
      have <- dplyr::inner_join(wanted, combos, by = c("year", "uf_source"))
      if (nrow(have) > 0) {
        ds <- arrow::open_dataset(file.path(cache_dir, dataset_name))
        cached <- ds |>
          dplyr::filter(.data$year %in% !!unique(have$year),
                        .data$uf_source %in% !!unique(have$uf_source)) |>
          dplyr::collect()
        cached <- dplyr::semi_join(cached, wanted,
                                   by = c("year", "uf_source"))
        if (nrow(cached) > 0) results <- c(results, list(cached))
      }
    }
  }

  todo <- dplyr::anti_join(wanted, have, by = c("year", "uf_source"))
  if (nrow(todo) == 0) {
    return(list(results = results, failed_labels = failed))
  }

  # 2. read missing combos from R2, one arrow dataset per year
  for (y in sort(unique(todo$year))) {
    need_ufs <- todo$uf_source[todo$year == y]
    cli::cli_inform(c(
      "i" = "Reading SI-PNI {type} from R2: {y} ({length(need_ufs)} UF(s))..."
    ))
    df <- tryCatch({
      ds <- .r2_open_dataset(paste0(prefix, "/ano=", y), creds,
                             partition_cols = "uf")
      ds |>
        dplyr::filter(.data$uf %in% !!need_ufs) |>
        dplyr::collect()
    }, error = function(e) NULL)

    if (is.null(df) || nrow(df) == 0) {
      failed <- c(failed, paste("R2", type, y))
      next
    }

    df$year <- as.integer(y)
    df$uf_source <- as.character(df$uf)
    df$uf <- NULL
    # same fix the FTP path applies before caching (decimal comma)
    if (type == "CPNI" && "COBERT" %in% names(df)) {
      df$COBERT <- gsub(",", ".", df$COBERT)
    }
    cols <- names(df)
    df <- df[, c("year", "uf_source", setdiff(cols, c("year", "uf_source")))]

    if (isTRUE(cache)) {
      .cache_append_partitioned(df, cache_dir, dataset_name,
                                c("uf_source", "year"))
    }
    results <- c(results, list(df))
  }

  list(results = results, failed_labels = failed)
}


# ============================================================================
# lazy access (remote arrow dataset, no download)
# ============================================================================

#' Lazy query over the remote R2 dataset (single era only)
#'
#' Returns the remote dataset filtered by the request. Column layout is the
#' bucket contract layout (partition columns `ano`, `mes`, `uf` as strings),
#' not the eager `year`/`month`/`uf_source` convention \u2014 dplyr verbs are
#' pushed down to R2, so only the touched row groups are transferred.
#'
#' @return An arrow Dataset query, a duckdb tbl, or NULL if the request
#'   spans both eras (mixed FTP + microdata years).
#' @noRd
.sipni_r2_lazy <- function(params, backend, creds) {
  has_ftp <- length(params$ftp_years) > 0
  has_api <- length(params$api_years) > 0
  if (has_ftp && has_api) return(NULL)

  if (has_api) {
    ds <- .r2_open_dataset(sipni_r2_prefix_microdados, creds,
                           partition_cols = c("ano", "mes", "uf"))
    ds <- ds |>
      dplyr::filter(.data$ano %in% !!as.character(params$api_years),
                    .data$uf %in% !!params$target_ufs)
    if (length(params$month_vals) < 12) {
      ds <- ds |>
        dplyr::filter(.data$mes %in% !!sprintf("%02d", params$month_vals))
    }
  } else {
    prefix <- if (toupper(params$type) == "CPNI") {
      sipni_r2_prefix_cobertura
    } else {
      sipni_r2_prefix_doses
    }
    # aggregates change layout across years (schema per source file, per
    # the healthbr-data contract) -> union the schemas; costs one footer
    # read per file in the prefix
    ds <- .r2_open_dataset(prefix, creds, partition_cols = c("ano", "uf"),
                           unify_schemas = TRUE)
    ds <- ds |>
      dplyr::filter(.data$ano %in% !!as.character(params$ftp_years),
                    .data$uf %in% !!params$target_ufs)
  }

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
# dictionaries (sipni/dicionarios/)
# ============================================================================

#' Mapping between R2 dictionary files and sipni variable names
#' @noRd
sipni_r2_dict_files <- tibble::tibble(
  file = c("imuno", "imunocob", "dose", "fxet", "ano", "mes"),
  variable = c("IMUNO", "IMUNO", "DOSE", "FX_ETARIA", "ANO", "MES"),
  description = c(
    "C\u00f3digo do imunobiol\u00f3gico (doses aplicadas)",
    "C\u00f3digo do imunobiol\u00f3gico (cobertura vacinal)",
    "Tipo de dose",
    "Faixa et\u00e1ria",
    "Ano de refer\u00eancia",
    "M\u00eas"
  )
)


#' Read the SI-PNI dictionaries from R2 (with flat local cache)
#'
#' @return A tibble (variable, description, code, label, source_codes).
#' @noRd
.sipni_r2_dictionary <- function(cache = TRUE, cache_dir = NULL, creds = NULL) {
  cache_dir <- .sipni_cache_dir(cache_dir)
  cache_base <- "sipni_r2_dictionary"

  if (isTRUE(cache)) {
    cached <- .cache_read(cache_dir, cache_base)
    if (!is.null(cached)) return(tibble::as_tibble(cached))
  }

  creds <- creds %||% .r2_credentials()
  fs <- .r2_filesystem(creds)

  parts <- lapply(seq_len(nrow(sipni_r2_dict_files)), function(i) {
    row <- sipni_r2_dict_files[i, ]
    path <- paste0(creds$bucket, "/", sipni_r2_prefix_dicionarios, "/",
                   row$file, ".parquet")
    d <- arrow::read_parquet(fs$path(path))
    if (row$file == "imunocob") {
      tibble::tibble(
        variable = row$variable,
        description = row$description,
        code = as.character(d$imuno),
        label = as.character(d$nome),
        source_codes = NA_character_
      )
    } else {
      tibble::tibble(
        variable = row$variable,
        description = row$description,
        code = as.character(d$code),
        label = as.character(d$label),
        source_codes = if ("source_codes" %in% names(d)) {
          as.character(d$source_codes)
        } else {
          NA_character_
        }
      )
    }
  })
  result <- dplyr::bind_rows(parts)

  if (isTRUE(cache)) {
    .cache_write(result, cache_dir, cache_base)
  }
  result
}


# ============================================================================
# exported: sipni_status()
# ============================================================================

#' SI-PNI Data Availability on the R2 Mirror
#'
#' Reads the `manifest.json` provenance files of the healthbr-data R2 mirror
#' and returns, for each published partition, when it was processed, from
#' which Ministry source file, and how many records it holds. Use it to see
#' which years/months are actually available before calling
#' \code{\link{sipni_data}()}, and to audit the provenance of the mirror.
#'
#' @param dataset Character. Which dataset(s) to report:
#'   \code{"microdados"} (individual-level 2020+, monthly partitions),
#'   \code{"doses"} (DPNI aggregates 1994--2019, year x UF partitions),
#'   \code{"cobertura"} (CPNI aggregates 1994--2019). Default: all three.
#' @param cache_dir Character. Cache directory (manifests are cached locally
#'   and revalidated by ETag). Default:
#'   \code{tools::R_user_dir("healthbR", "cache")}.
#'
#' @return A tibble with columns: \code{dataset}, \code{year}, \code{month}
#'   (NA for aggregates), \code{uf} (NA for microdata \u2014 partitions are
#'   monthly and national), \code{records}, \code{processing_timestamp}
#'   (as recorded by the pipeline, no timezone), \code{source_url} (the
#'   Ministry file the partition was derived from).
#'
#' @details
#' The manifests are the mirror's source of truth: they record the source
#' file's URL, size and hash, the processing timestamp, and the SHA-256 of
#' every published Parquet. Data on the mirror are byte-identical to the
#' Ministry's files; see the healthbr-data reproducibility policy for the
#' full audit recipe.
#'
#' @export
#' @family sipni
#'
#' @examplesIf interactive()
#' # everything the mirror currently holds
#' sipni_status()
#'
#' # which 2026 microdata months are published?
#' dplyr::filter(sipni_status("microdados"), year == 2026)
sipni_status <- function(dataset = c("microdados", "doses", "cobertura"),
                         cache_dir = NULL) {
  datasets <- match.arg(dataset, several.ok = TRUE)
  cache_dir <- .sipni_cache_dir(cache_dir)

  out <- list()
  unreachable <- character(0)
  for (d in datasets) {
    s <- .sipni_r2_manifest_summary(d, cache_dir)
    if (is.null(s)) {
      unreachable <- c(unreachable, d)
    } else {
      out <- c(out, list(s))
    }
  }

  if (length(unreachable) > 0) {
    cli::cli_warn(c(
      "!" = "Could not read the manifest(s) for {.val {unreachable}}.",
      "i" = "The R2 mirror may be unreachable and no local copy was cached."
    ))
  }
  if (length(out) == 0) {
    return(tibble::tibble(
      dataset = character(0), year = integer(0), month = integer(0),
      uf = character(0), records = numeric(0),
      processing_timestamp = character(0), source_url = character(0)
    ))
  }

  dplyr::bind_rows(out)
}
