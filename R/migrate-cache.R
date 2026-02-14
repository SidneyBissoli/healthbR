# Migration from flat cache to partitioned parquet datasets

# Internal specs for each module's flat cache format
.migration_specs <- list(
  sim = list(
    regex = "^sim_([A-Z]{2})_(\\d{4})\\.(parquet|rds)$",
    dataset_name = "sim_data",
    partitioning = c("uf_source", "year"),
    extract = function(m) list(uf_source = m[2], year = as.integer(m[3]))
  ),
  sinasc = list(
    regex = "^sinasc_([A-Z]{2})_(\\d{4})\\.(parquet|rds)$",
    dataset_name = "sinasc_data",
    partitioning = c("uf_source", "year"),
    extract = function(m) list(uf_source = m[2], year = as.integer(m[3]))
  ),
  sih = list(
    regex = "^sih_([A-Z]{2})_(\\d{4})(\\d{2})\\.(parquet|rds)$",
    dataset_name = "sih_data",
    partitioning = c("uf_source", "year", "month"),
    extract = function(m) list(
      uf_source = m[2], year = as.integer(m[3]), month = as.integer(m[4])
    )
  ),
  sia = list(
    regex = "^sia_[A-Z]{2}_([A-Z]{2})_(\\d{4})(\\d{2})\\.(parquet|rds)$",
    dataset_name = "sia_data",
    partitioning = c("uf_source", "year", "month"),
    extract = function(m) list(
      uf_source = m[2], year = as.integer(m[3]), month = as.integer(m[4])
    )
  ),
  sinan = list(
    regex = "^sinan_([A-Z]+)_(\\d{4})\\.(parquet|rds)$",
    dataset_name = "sinan_data",
    partitioning = c("disease", "year"),
    extract = function(m) list(disease = m[2], year = as.integer(m[3]))
  ),
  cnes = list(
    regex = "^cnes_[A-Z]{2}_([A-Z]{2})_(\\d{4})(\\d{2})\\.(parquet|rds)$",
    dataset_name = "cnes_data",
    partitioning = c("uf_source", "year", "month"),
    extract = function(m) list(
      uf_source = m[2], year = as.integer(m[3]), month = as.integer(m[4])
    )
  ),
  sipni_ftp = list(
    regex = "^sipni_(DPNI|CPNI)_([A-Z]{2})_(\\d{4})\\.(parquet|rds)$",
    dataset_name = "sipni_ftp_data",
    partitioning = c("uf_source", "year"),
    extract = function(m) list(uf_source = m[3], year = as.integer(m[4]))
  ),
  sipni_csv = list(
    regex = "^sipni_API_([A-Z]{2})_(\\d{4})(\\d{2})\\.(parquet|rds)$",
    dataset_name = "sipni_csv_data",
    partitioning = c("uf_source", "year", "month"),
    extract = function(m) list(
      uf_source = m[2], year = as.integer(m[3]), month = as.integer(m[4])
    )
  ),
  pns = list(
    regex = "^pns_(\\d{4})\\.(parquet|rds)$",
    dataset_name = "pns_data",
    partitioning = c("year"),
    extract = function(m) list(year = as.integer(m[2]))
  ),
  pnadc = list(
    regex = "^pnadc_([a-z_]+)_(\\d{4})\\.(parquet|rds)$",
    dataset_name = "pnadc_data",
    partitioning = c("year"),
    extract = function(m) list(year = as.integer(m[3]))
  ),
  pof = list(
    regex = "^pof_(\\d{4}(?:-\\d{4})?)_([a-z_]+)\\.(parquet|rds)$",
    dataset_name = NULL, # dynamic: pof_{register}_data
    partitioning = c("year"),
    extract = function(m) list(year = m[2], .register = m[3])
  )
)


#' Migrate flat cache files to partitioned parquet datasets
#'
#' Converts legacy flat cache files (`.parquet` or `.rds`) to Hive-style
#' partitioned parquet datasets. This is a one-time operation that prepares
#' your cache for faster lazy queries and future versions of healthbR.
#'
#' @param cache_dir Character or NULL. Custom cache directory. If NULL
#'   (default), uses the standard healthbR cache location
#'   (`tools::R_user_dir("healthbR", "cache")`).
#' @param dry_run Logical. If TRUE, lists files that would be migrated
#'   without actually modifying anything. Default: FALSE.
#'
#' @return Invisible list with migration summary: number of files migrated
#'   and skipped per module.
#'
#' @examplesIf interactive()
#' # Preview what would be migrated
#' healthbR_migrate_cache(dry_run = TRUE)
#'
#' # Run the migration
#' healthbR_migrate_cache()
#'
#' @export
healthbR_migrate_cache <- function(cache_dir = NULL, dry_run = FALSE) {
  if (!.has_arrow()) {
    cli::cli_abort(c(
      "Package {.pkg arrow} is required for cache migration.",
      "i" = "Install with: {.code install.packages('arrow')}"
    ))
  }

  base_dir <- if (is.null(cache_dir)) {
    tools::R_user_dir("healthbR", "cache")
  } else {
    cache_dir
  }

  if (!dir.exists(base_dir)) {
    cli::cli_inform("No cache directory found at {.path {base_dir}}. Nothing to migrate.")
    return(invisible(list(migrated = 0L, skipped = 0L)))
  }

  # Scan all module subdirectories for flat files
  module_dirs <- list.dirs(base_dir, recursive = FALSE, full.names = TRUE)
  if (length(module_dirs) == 0) {
    cli::cli_inform("No module cache directories found. Nothing to migrate.")
    return(invisible(list(migrated = 0L, skipped = 0L)))
  }

  total_migrated <- 0L
  total_skipped <- 0L
  results <- list()

  for (mod_dir in module_dirs) {
    mod_name <- basename(mod_dir)

    # List only flat files in top-level (not in dataset subdirs)
    all_files <- list.files(mod_dir, pattern = "\\.(parquet|rds)$",
                            full.names = FALSE, recursive = FALSE)
    if (length(all_files) == 0) next

    # Try each spec against the files
    for (spec_name in names(.migration_specs)) {
      spec <- .migration_specs[[spec_name]]
      matches <- regmatches(all_files, regexec(spec$regex, all_files))
      matched_idx <- which(vapply(matches, length, integer(1)) > 0)

      if (length(matched_idx) == 0) next

      for (i in matched_idx) {
        fname <- all_files[i]
        m <- matches[[i]]
        parts <- spec$extract(m)
        fpath <- file.path(mod_dir, fname)

        if (dry_run) {
          ds_name <- spec$dataset_name
          if (is.null(ds_name)) {
            ds_name <- paste0("pof_", parts$.register, "_data")
          }
          cli::cli_inform(c(
            "i" = "Would migrate: {.file {fname}} -> {.path {ds_name}/}"
          ))
          total_migrated <- total_migrated + 1L
          next
        }

        # Read the flat file
        data <- tryCatch({
          ext <- tools::file_ext(fname)
          if (ext == "parquet") {
            arrow::read_parquet(fpath)
          } else {
            readRDS(fpath)
          }
        }, error = function(e) {
          cli::cli_warn("Failed to read {.file {fname}}: {e$message}")
          NULL
        })

        if (is.null(data)) {
          total_skipped <- total_skipped + 1L
          next
        }

        # Add partition columns
        for (col_name in names(parts)) {
          if (!startsWith(col_name, ".")) {
            data[[col_name]] <- parts[[col_name]]
          }
        }

        # Determine dataset name
        ds_name <- spec$dataset_name
        if (is.null(ds_name)) {
          ds_name <- paste0("pof_", parts$.register, "_data")
        }

        # Write to partitioned dataset
        dataset_dir <- file.path(mod_dir, ds_name)
        tryCatch({
          arrow::write_dataset(
            data,
            path = dataset_dir,
            format = "parquet",
            partitioning = spec$partitioning,
            existing_data_behavior = "overwrite"
          )
          # Remove the flat file
          file.remove(fpath)
          total_migrated <- total_migrated + 1L
        }, error = function(e) {
          cli::cli_warn(
            "Failed to migrate {.file {fname}}: {e$message}"
          )
          total_skipped <- total_skipped + 1L
        })
      }
    }
  }

  if (dry_run) {
    if (total_migrated == 0) {
      cli::cli_inform("No flat cache files found to migrate.")
    } else {
      cli::cli_inform(c(
        "i" = "Found {total_migrated} file{?s} to migrate.",
        "i" = "Run {.code healthbR_migrate_cache()} to proceed."
      ))
    }
  } else {
    cli::cli_inform(c(
      "v" = "Migration complete: {total_migrated} file{?s} migrated, {total_skipped} skipped."
    ))
  }

  invisible(list(migrated = total_migrated, skipped = total_skipped))
}
