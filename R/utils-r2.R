# utils-r2.R -- shared Cloudflare R2 backend utilities for healthbR
#
# The healthbr-data project (https://github.com/SidneyBissoli/healthbr-data)
# redistributes DATASUS/OpenDataSUS datasets exactly as published by the
# Ministry of Health, as hive-partitioned Parquet on a public Cloudflare R2
# bucket (free egress, public read-only token). These helpers give modules a
# common way to open those datasets with arrow and to read the per-dataset
# `manifest.json` provenance files. Currently used by the SI-PNI module;
# designed to be shared by SIM/SINASC/SIH when their R2 backends land.

# ============================================================================
# constants (public infrastructure of the healthbr-data bucket)
# ============================================================================

#' healthbr-data R2 S3 endpoint
#' @noRd
healthbr_r2_endpoint <- "https://5c499208eebced4e34bd98ffa204f2fb.r2.cloudflarestorage.com"

#' healthbr-data R2 bucket name
#' @noRd
healthbr_r2_bucket <- "healthbr-data"

# The access token below is read-only and intentionally public: it is
# published in the healthbr-data README and Hugging Face dataset cards.
# It only allows reading objects from the healthbr-data bucket.

#' healthbr-data public read-only access key
#' @noRd
healthbr_r2_access_key <- "28c72d4b3e1140fa468e367ae472b522"

#' healthbr-data public read-only secret key
#' @noRd
healthbr_r2_secret_key <- "2937b2106736e2ba64e24e92f2be4e6c312bba3355586e41ce634b14c1482951"

#' healthbr-data public HTTP base URL (single-object reads, e.g. manifests)
#' @noRd
healthbr_r2_pub_base <- "https://pub-99d9e1a3f5c542178d04efbddf1bba97.r2.dev"

#' Session-level memoization environment for R2 handles and manifests
#' @noRd
.r2_env <- new.env(parent = emptyenv())


# ============================================================================
# source parameter resolution (shared by *_data() functions)
# ============================================================================

#' Resolve the `source` parameter into an ordered priority vector
#'
#' `source` is a character vector of data sources in priority order. The
#' default `c("r2", "datasus")` means "try the R2 mirror first, fall back to
#' DATASUS automatically". A single value disables the fallback.
#'
#' @param source Character vector. Subset of c("r2", "datasus") in priority
#'   order.
#' @return Validated character vector (deduplicated, order preserved).
#' @noRd
.resolve_sources <- function(source) {
  valid <- c("r2", "datasus")
  source <- unique(as.character(source))
  invalid <- source[!source %in% valid]
  if (length(invalid) > 0 || length(source) == 0) {
    cli::cli_abort(c(
      "Invalid {.arg source}: {.val {invalid}}.",
      "i" = "Valid values: {.val {valid}} (a vector sets the fallback order)."
    ))
  }
  source
}


# ============================================================================
# credentials and filesystem
# ============================================================================

#' Resolve R2 credentials (public read-only token by default)
#'
#' @param r2_credentials NULL (use the public healthbr-data token) or a named
#'   list with `access_key_id` and `secret_access_key` (and optionally
#'   `endpoint` and `bucket`) to point at another bucket.
#' @return A list with endpoint, bucket, access_key_id, secret_access_key.
#' @noRd
.r2_credentials <- function(r2_credentials = NULL) {
  if (is.null(r2_credentials)) {
    return(list(
      endpoint = healthbr_r2_endpoint,
      bucket = healthbr_r2_bucket,
      access_key_id = healthbr_r2_access_key,
      secret_access_key = healthbr_r2_secret_key
    ))
  }

  required <- c("access_key_id", "secret_access_key")
  missing <- setdiff(required, names(r2_credentials))
  if (!is.list(r2_credentials) || length(missing) > 0) {
    cli::cli_abort(c(
      "{.arg r2_credentials} must be a named list with {.val {required}}.",
      "i" = "Optional entries: {.val endpoint}, {.val bucket}."
    ))
  }

  list(
    endpoint = r2_credentials$endpoint %||% healthbr_r2_endpoint,
    bucket = r2_credentials$bucket %||% healthbr_r2_bucket,
    access_key_id = r2_credentials$access_key_id,
    secret_access_key = r2_credentials$secret_access_key
  )
}


#' Abort with a friendly message if arrow is not installed
#' @noRd
.r2_check_arrow <- function() {
  if (!.has_arrow()) {
    cli::cli_abort(c(
      "Package {.pkg arrow} is required to read from the R2 backend.",
      "i" = "Install with: {.code install.packages('arrow')}",
      "i" = "Or use {.code source = \"datasus\"} to download from DATASUS directly."
    ))
  }
}


#' Create (or reuse) an arrow S3FileSystem for an R2 endpoint
#'
#' The filesystem handle is memoized per endpoint + access key for the
#' session, so repeated calls do not re-negotiate the connection.
#'
#' @param creds A credentials list from `.r2_credentials()`.
#' @return An arrow S3FileSystem object.
#' @noRd
.r2_filesystem <- function(creds = NULL) {
  .r2_check_arrow()
  creds <- creds %||% .r2_credentials()

  key <- paste0("fs:", creds$endpoint, ":", creds$access_key_id)
  if (!is.null(.r2_env[[key]])) return(.r2_env[[key]])

  fs <- arrow::S3FileSystem$create(
    endpoint_override = creds$endpoint,
    access_key = creds$access_key_id,
    secret_key = creds$secret_access_key,
    region = "auto"
  )
  .r2_env[[key]] <- fs
  fs
}


#' Open a hive-partitioned dataset under a bucket prefix
#'
#' Opens `bucket/prefix` as an arrow Dataset. Pass the partition columns
#' below the prefix via `partition_cols` so they are read as strings --
#' the healthbr-data contract is all-string columns, and arrow's automatic
#' hive inference would otherwise turn e.g. `mes=01` into an integer.
#'
#' @param prefix Character. Prefix inside the bucket, no leading slash
#'   (e.g. "sipni/microdados/ano=2024").
#' @param creds A credentials list from `.r2_credentials()`, or NULL.
#' @param partition_cols Character vector. Names of the hive partition
#'   directories below the prefix, in order (e.g. c("mes", "uf")), all
#'   read as utf8. NULL lets arrow autodetect.
#' @param unify_schemas Logical. TRUE inspects every file and unions the
#'   schemas (required when the prefix spans years with different layouts --
#'   the healthbr-data contract publishes schema per source file); FALSE
#'   (default) uses the first file's schema.
#' @return An arrow Dataset.
#' @noRd
.r2_open_dataset <- function(prefix, creds = NULL, partition_cols = NULL,
                             unify_schemas = FALSE, schema = NULL) {
  creds <- creds %||% .r2_credentials()
  fs <- .r2_filesystem(creds)

  partitioning <- NULL
  if (!is.null(partition_cols)) {
    fields <- rep(list(arrow::utf8()), length(partition_cols))
    names(fields) <- partition_cols
    partitioning <- do.call(arrow::hive_partition, fields)
  }

  args <- list(
    sources = fs$path(paste0(creds$bucket, "/", prefix)),
    format = "parquet",
    # dataset roots also hold README.md / manifest.json -- not data files
    factory_options = list(
      selector_ignore_prefixes = c(".", "_", "README", "manifest")
    )
  )
  if (!is.null(partitioning)) args$partitioning <- partitioning
  if (isTRUE(unify_schemas)) args$unify_schemas <- TRUE
  # an explicit schema (partition fields included) lets a prefix with several
  # historical schemas be opened without reading every footer
  if (!is.null(schema)) args$schema <- schema
  do.call(arrow::open_dataset, args)
}


# ============================================================================
# manifest.json access (provenance + availability)
# ============================================================================

#' Fetch (with ETag-validated local cache) and parse a manifest.json
#'
#' Manifests are read over plain HTTPS from the bucket's public URL. A local
#' copy is kept in `cache_dir` and revalidated by ETag, so the (potentially
#' large) file is only re-downloaded when the dataset actually changed.
#' When offline, the local copy is used if present.
#'
#' @param manifest_path Character. Object path inside the bucket
#'   (e.g. "sipni/manifest.json").
#' @param cache_dir Character. Directory for the local copy.
#' @return Parsed manifest (list from jsonlite), or NULL if the manifest is
#'   unreachable and no local copy exists.
#' @noRd
.r2_manifest <- function(manifest_path, cache_dir) {
  url <- paste0(healthbr_r2_pub_base, "/", manifest_path)
  slug <- gsub("[^a-z0-9]+", "_", tolower(manifest_path))
  json_path <- file.path(cache_dir, paste0("r2_", slug))
  etag_path <- paste0(json_path, ".etag")

  local_etag <- if (file.exists(etag_path)) readLines(etag_path, warn = FALSE)[1] else NA_character_
  remote_etag <- .r2_head_etag(url)

  # session memo: same manifest + same etag -> reuse parsed object
  memo_key <- paste0("manifest:", manifest_path)
  memo <- .r2_env[[memo_key]]
  if (!is.null(memo) && !is.null(remote_etag) &&
      identical(memo$etag, remote_etag)) {
    return(memo$parsed)
  }

  fresh_local <- file.exists(json_path) && !is.na(local_etag) &&
    !is.null(remote_etag) && identical(local_etag, remote_etag)

  if (!fresh_local && !is.null(remote_etag)) {
    ok <- tryCatch({
      curl::curl_download(url, json_path, quiet = TRUE)
      writeLines(remote_etag, etag_path)
      TRUE
    }, error = function(e) FALSE)
    if (!ok && !file.exists(json_path)) return(NULL)
  }

  if (!file.exists(json_path)) return(NULL)

  parsed <- tryCatch(
    jsonlite::fromJSON(json_path, simplifyVector = TRUE),
    error = function(e) NULL
  )
  if (is.null(parsed)) return(NULL)

  .r2_env[[memo_key]] <- list(
    etag = remote_etag %||% local_etag,
    parsed = parsed
  )
  parsed
}


#' HEAD an URL and return its ETag (NULL if unreachable)
#' @noRd
.r2_head_etag <- function(url) {
  tryCatch({
    h <- curl::new_handle(nobody = TRUE, timeout = 30, followlocation = TRUE)
    r <- curl::curl_fetch_memory(url, handle = h)
    if (r$status_code != 200) return(NULL)
    headers <- curl::parse_headers_list(r$headers)
    etag <- headers[["etag"]]
    if (is.null(etag)) NULL else etag
  }, error = function(e) NULL)
}


#' Null-coalescing helper
#' @noRd
`%||%` <- function(a, b) if (is.null(a)) b else a
