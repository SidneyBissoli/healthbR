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
  requireNamespace("duckdb", quietly = TRUE)
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
