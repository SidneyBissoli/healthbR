# Shared cache utilities for healthbR
# Provides consistent caching (parquet with RDS fallback) across all modules

# ============================================================================
# arrow availability check
# ============================================================================

#' Check if arrow package is available
#'
#' @return Logical. TRUE if arrow is installed and loadable.
#'
#' @noRd
.has_arrow <- function() {
  requireNamespace("arrow", quietly = TRUE)
}


# ============================================================================
# module cache directory
# ============================================================================

#' Get or create a module-specific cache directory
#'
#' @param module Character. Module name (e.g., "sim", "sih", "sipni").
#' @param cache_dir Character or NULL. Custom cache directory. If NULL,
#'   uses the default user cache directory under the module name.
#'
#' @return Character. Path to the module cache directory (created if needed).
#'
#' @noRd
.module_cache_dir <- function(module, cache_dir = NULL) {
  if (is.null(cache_dir)) {
    cache_dir <- file.path(tools::R_user_dir("healthbR", "cache"), module)
  }
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  cache_dir
}


# ============================================================================
# flat cache read/write (parquet > RDS)
# ============================================================================

#' Read data from cache (parquet preferred, RDS fallback)
#'
#' @param cache_dir Character. Path to the cache directory.
#' @param cache_base Character. Base name for the cache file (without extension).
#'
#' @return A tibble if cache hit, or NULL if cache miss.
#'
#' @noRd
.cache_read <- function(cache_dir, cache_base) {
  cache_parquet <- file.path(cache_dir, paste0(cache_base, ".parquet"))
  cache_rds <- file.path(cache_dir, paste0(cache_base, ".rds"))

  if (file.exists(cache_parquet) && .has_arrow()) {
    return(arrow::read_parquet(cache_parquet))
  }

  if (file.exists(cache_rds)) {
    return(readRDS(cache_rds))
  }

  NULL
}


#' Write data to cache (parquet preferred, RDS fallback)
#'
#' @param data A data frame to cache.
#' @param cache_dir Character. Path to the cache directory.
#' @param cache_base Character. Base name for the cache file (without extension).
#'
#' @return Invisible NULL. Called for side effect.
#'
#' @noRd
.cache_write <- function(data, cache_dir, cache_base) {
  cache_parquet <- file.path(cache_dir, paste0(cache_base, ".parquet"))
  cache_rds <- file.path(cache_dir, paste0(cache_base, ".rds"))

  if (.has_arrow()) {
    tryCatch(
      arrow::write_parquet(data, cache_parquet),
      error = function(e) {
        cli::cli_warn("Failed to write parquet cache: {e$message}")
        saveRDS(data, cache_rds)
      }
    )
  } else {
    saveRDS(data, cache_rds)
  }

  invisible(NULL)
}


# ============================================================================
# duckdb availability check
# ============================================================================

#' Check if duckdb package is available
#'
#' @return Logical. TRUE if duckdb is installed and loadable.
#'
#' @noRd
.has_duckdb <- function() {
  requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("dbplyr", quietly = TRUE)
}


# ============================================================================
# lazy evaluation helper
# ============================================================================

#' Open a partitioned cache as a lazy query object
#'
#' Opens a partitioned dataset for lazy evaluation. The returned object
#' supports dplyr verbs (filter, select, mutate, etc.) which are pushed
#' down to the query engine before collecting into memory.
#'
#' @param cache_dir Character. Path to the module cache directory.
#' @param dataset_name Character. Name of the dataset subdirectory.
#' @param lazy Logical. If TRUE, returns a lazy object. If FALSE, returns
#'   NULL (caller should use eager path).
#' @param backend Character. "arrow" or "duckdb". Which backend to use
#'   for lazy evaluation.
#'
#' @return An Arrow Dataset (backend="arrow"), a DuckDB lazy tbl
#'   (backend="duckdb"), or NULL if lazy=FALSE or no cache.
#'
#' @noRd
.cache_open_lazy <- function(cache_dir, dataset_name,
                             lazy = FALSE,
                             backend = c("arrow", "duckdb")) {
  if (!isTRUE(lazy)) return(NULL)

  backend <- match.arg(backend)

  if (backend == "arrow") {
    if (!.has_arrow()) {
      cli::cli_abort(c(
        "Package {.pkg arrow} is required for {.code lazy = TRUE}.",
        "i" = "Install with: {.code install.packages('arrow')}"
      ))
    }
    if (!.has_partitioned_cache(cache_dir, dataset_name)) {
      return(NULL)
    }
    return(arrow::open_dataset(file.path(cache_dir, dataset_name)))
  }

  if (backend == "duckdb") {
    if (!.has_duckdb()) {
      cli::cli_abort(c(
        "Package {.pkg duckdb} is required for {.code backend = \"duckdb\"}.",
        "i" = "Install with: {.code install.packages('duckdb')}"
      ))
    }
    if (!.has_arrow()) {
      cli::cli_abort(c(
        "Package {.pkg arrow} is required for DuckDB backend.",
        "i" = "Install with: {.code install.packages('arrow')}"
      ))
    }
    if (!.has_partitioned_cache(cache_dir, dataset_name)) {
      return(NULL)
    }

    ds <- arrow::open_dataset(file.path(cache_dir, dataset_name))
    return(arrow::to_duckdb(ds))
  }

  NULL
}


# ============================================================================
# lazy return helper (filter + select on lazy dataset)
# ============================================================================

#' Open partitioned cache lazily and apply filters
#'
#' Convenience wrapper: opens a partitioned cache, applies partition-level
#' filters, optionally selects columns, and returns the lazy query object.
#'
#' @param cache_dir Character. Module cache directory.
#' @param dataset_name Character. Name of the dataset subdirectory.
#' @param backend Character. "arrow" or "duckdb".
#' @param filters Named list. Each name is a partition column, each value
#'   is a vector to filter on (using `%in%`).
#' @param select_cols Character vector or NULL. Columns to select (pushed down).
#'
#' @return A lazy query object (Arrow Dataset or DuckDB tbl), or NULL
#'   if no partitioned cache exists.
#'
#' @noRd
.lazy_return <- function(cache_dir, dataset_name, backend,
                         filters = list(), select_cols = NULL) {
  ds <- .cache_open_lazy(cache_dir, dataset_name, lazy = TRUE, backend = backend)
  if (is.null(ds)) return(NULL)

  for (col_name in names(filters)) {
    values <- filters[[col_name]]
    if (!is.null(values)) {
      ds <- ds |> dplyr::filter(.data[[col_name]] %in% !!values)
    }
  }

  if (!is.null(select_cols)) {
    select_cols <- intersect(select_cols, names(ds))
    if (length(select_cols) > 0) {
      ds <- ds |> dplyr::select(dplyr::all_of(select_cols))
    }
  }

  ds
}


# ============================================================================
# shared lazy/eager return helpers
# ============================================================================

#' Try returning from lazy cache (pre-download check)
#'
#' Convenience wrapper for the pre-download lazy check that every DATASUS
#' module performs. Returns a lazy query object if cache exists, or NULL
#' to signal the caller should proceed with eager download.
#'
#' @param lazy Logical. If FALSE, returns NULL immediately.
#' @param backend Character. "arrow" or "duckdb".
#' @param cache_dir Character. Module cache directory.
#' @param dataset_name Character. Name of the dataset subdirectory.
#' @param filters Named list. Partition-level filters.
#' @param select_cols Character vector or NULL. Columns to select.
#' @param parse Logical. If TRUE and lazy is TRUE, emits an informational
#'   message that parse is ignored.
#'
#' @return A lazy query object, or NULL.
#'
#' @noRd
.try_lazy_cache <- function(lazy, backend, cache_dir, dataset_name,
                            filters, select_cols, parse = FALSE) {
  if (!isTRUE(lazy)) return(NULL)
  if (isTRUE(parse)) {
    cli::cli_inform("{.arg parse} is ignored when {.arg lazy} is TRUE.")
  }
  backend <- match.arg(backend, c("arrow", "duckdb"))
  .lazy_return(cache_dir, dataset_name, backend,
               filters = filters, select_cols = select_cols)
}


#' Return data with optional lazy fallback, column selection, and reporting
#'
#' Unified return path for DATASUS modules. Handles:
#' 1. Post-download lazy return (if lazy=TRUE and cache exists)
#' 2. Column selection (vars)
#' 3. Download failure reporting
#' 4. Conversion to tibble
#'
#' @param data A data frame (the downloaded + processed results).
#' @param lazy Logical. If TRUE, attempts lazy return from cache first.
#' @param backend Character. "arrow" or "duckdb".
#' @param cache_dir Character or NULL. Module cache directory.
#' @param dataset_name Character or NULL. Dataset subdirectory name.
#' @param filters Named list. Partition-level filters for lazy return.
#' @param select_cols Character vector or NULL. Columns to select.
#' @param failed_labels Character vector. Labels of failed downloads.
#' @param module_name Character. Module name for failure reporting.
#'
#' @return A tibble (eager) or lazy query object.
#'
#' @noRd
.data_return <- function(data, lazy = FALSE, backend = "arrow",
                         cache_dir = NULL, dataset_name = NULL,
                         filters = list(), select_cols = NULL,
                         failed_labels = character(0), module_name = "") {
  # post-download lazy return
  if (isTRUE(lazy) && !is.null(cache_dir) && !is.null(dataset_name)) {
    backend <- match.arg(backend, c("arrow", "duckdb"))
    ds <- .lazy_return(cache_dir, dataset_name, backend,
                       filters = filters, select_cols = select_cols)
    if (!is.null(ds)) return(ds)
  }

  # column selection
  if (!is.null(select_cols)) {
    keep_cols <- intersect(select_cols, names(data))
    data <- data[, keep_cols, drop = FALSE]
  }

  # report failures and return as tibble
  data <- .report_download_failures(data, failed_labels, module_name)
  tibble::as_tibble(data)
}


# ============================================================================
# partitioned cache read/write (Hive-style directories)
# ============================================================================

#' Write data to a Hive-style partitioned cache
#'
#' Uses `arrow::write_dataset()` to write data partitioned by the specified
#' columns. Falls back to a flat parquet/RDS write if arrow is unavailable.
#'
#' @param data A data frame to cache.
#' @param cache_dir Character. Path to the module cache directory.
#' @param dataset_name Character. Name for the dataset subdirectory
#'   (e.g., "sim_data", "sih_data").
#' @param partitioning Character vector. Column names to partition by
#'   (e.g., c("uf_source", "year")).
#'
#' @return Invisible path to the partitioned dataset directory, or NULL
#'   if arrow is not available and RDS fallback was used.
#'
#' @noRd
.cache_write_partitioned <- function(data, cache_dir, dataset_name,
                                     partitioning) {
  dataset_dir <- file.path(cache_dir, dataset_name)

  if (!.has_arrow()) {
    # fallback: save as flat RDS
    rds_path <- file.path(cache_dir, paste0(dataset_name, ".rds"))
    saveRDS(data, rds_path)
    return(invisible(NULL))
  }

  # ensure directory exists (remove old if present to avoid stale partitions)
  if (dir.exists(dataset_dir)) {
    unlink(dataset_dir, recursive = TRUE)
  }

  tryCatch({
    arrow::write_dataset(
      data,
      path = dataset_dir,
      format = "parquet",
      partitioning = partitioning
    )
    invisible(dataset_dir)
  }, error = function(e) {
    cli::cli_warn("Failed to write partitioned cache: {e$message}")
    rds_path <- file.path(cache_dir, paste0(dataset_name, ".rds"))
    saveRDS(data, rds_path)
    invisible(NULL)
  })
}


#' Check if a partitioned cache directory exists and has content
#'
#' @param cache_dir Character. Path to the module cache directory.
#' @param dataset_name Character. Name of the dataset subdirectory.
#'
#' @return Logical. TRUE if the partitioned cache exists with subdirectories.
#'
#' @noRd
.has_partitioned_cache <- function(cache_dir, dataset_name) {
  dataset_dir <- file.path(cache_dir, dataset_name)
  dir.exists(dataset_dir) &&
    length(list.dirs(dataset_dir, recursive = FALSE)) > 0
}


#' Open a partitioned cache as an Arrow Dataset (lazy)
#'
#' Returns an Arrow Dataset object that supports lazy evaluation —
#' filter/select operations are pushed down before reading data into memory.
#' Falls back to reading the flat RDS if arrow is not available.
#'
#' @param cache_dir Character. Path to the module cache directory.
#' @param dataset_name Character. Name of the dataset subdirectory.
#'
#' @return An Arrow Dataset (if arrow available and partitioned cache exists),
#'   a tibble (if only flat RDS exists), or NULL (no cache).
#'
#' @noRd
.cache_open_dataset <- function(cache_dir, dataset_name) {
  dataset_dir <- file.path(cache_dir, dataset_name)

  if (.has_arrow() && .has_partitioned_cache(cache_dir, dataset_name)) {
    return(arrow::open_dataset(dataset_dir))
  }

  # fallback: try flat RDS
  rds_path <- file.path(cache_dir, paste0(dataset_name, ".rds"))
  if (file.exists(rds_path)) {
    return(readRDS(rds_path))
  }

  NULL
}


#' Append new data to an existing partitioned cache
#'
#' Writes new partition files without removing existing ones. Useful when
#' downloading data incrementally (e.g., one UF at a time).
#'
#' @param data A data frame to append.
#' @param cache_dir Character. Path to the module cache directory.
#' @param dataset_name Character. Name of the dataset subdirectory.
#' @param partitioning Character vector. Column names to partition by.
#'
#' @return Invisible path to the dataset directory, or NULL.
#'
#' @noRd
.cache_append_partitioned <- function(data, cache_dir, dataset_name,
                                      partitioning) {
  dataset_dir <- file.path(cache_dir, dataset_name)

  if (!.has_arrow()) {
    # fallback: append to flat RDS
    rds_path <- file.path(cache_dir, paste0(dataset_name, ".rds"))
    if (file.exists(rds_path)) {
      existing <- readRDS(rds_path)
      data <- dplyr::bind_rows(existing, data)
    }
    saveRDS(data, rds_path)
    return(invisible(NULL))
  }

  # ensure base directory exists
  dir.create(dataset_dir, recursive = TRUE, showWarnings = FALSE)

  tryCatch({
    arrow::write_dataset(
      data,
      path = dataset_dir,
      format = "parquet",
      partitioning = partitioning,
      existing_data_behavior = "overwrite"
    )
    invisible(dataset_dir)
  }, error = function(e) {
    cli::cli_warn("Failed to append partitioned cache: {e$message}")
    invisible(NULL)
  })
}


# ============================================================================
# Shared cache status / clear helpers (DATASUS modules)
# ============================================================================

#' Report cache status for a module
#' @param module_name Lowercase prefix used in filenames (e.g. "sim", "sih").
#' @param module_label Display label for messages (e.g. "SIM", "SIH").
#' @param cache_dir Resolved cache directory path.
#' @return Invisible tibble with file, size_mb, modified columns.
#' @noRd
.cache_status <- function(module_name, module_label, cache_dir) {
  files <- list.files(cache_dir,
                      pattern = paste0("^", module_name, "_.*\\.(parquet|rds)$"),
                      full.names = TRUE)

  if (length(files) == 0) {
    cli::cli_inform("No cached {module_label} files found.")
    return(invisible(tibble::tibble(
      file = character(), size_mb = numeric(), modified = as.POSIXct(character())
    )))
  }

  info <- file.info(files)
  result <- tibble::tibble(
    file = basename(files),
    size_mb = round(info$size / 1e6, 2),
    modified = info$mtime
  )

  cli::cli_inform(c(
    "i" = "{module_label} cache: {nrow(result)} file(s), {sum(result$size_mb)} MB total",
    "i" = "Cache directory: {.file {cache_dir}}"
  ))

  invisible(result)
}

#' Clear cached files for a module
#' @param module_name Lowercase prefix used in filenames (e.g. "sim", "sih").
#' @param module_label Display label for messages (e.g. "SIM", "SIH").
#' @param cache_dir Resolved cache directory path.
#' @return Invisible NULL.
#' @noRd
.clear_cache <- function(module_name, module_label, cache_dir) {
  files <- list.files(cache_dir,
                      pattern = paste0("^", module_name, "_.*\\.(parquet|rds)$"),
                      full.names = TRUE)

  if (length(files) == 0) {
    cli::cli_inform("No cached {module_label} files to clear.")
    return(invisible(NULL))
  }

  removed <- file.remove(files)
  n_removed <- sum(removed)

  cli::cli_inform(c(
    "v" = "Removed {n_removed} cached {module_label} file(s)."
  ))

  invisible(NULL)
}
