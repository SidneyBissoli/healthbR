# vigitel functions for healthbR package
# functions to download and process VIGITEL survey data
# refactored for new Ministry of Health data structure (2006-2024 consolidated files)

# ============================================================================
# internal helper functions
# ============================================================================

#' Get VIGITEL cache directory
#'
#' Returns the path to the cache directory for VIGITEL data.
#' Creates the directory if it doesn't exist.
#'
#' @param cache_dir Optional custom cache directory. If NULL, uses default
#'   user cache directory.
#' @return Path to cache directory
#' @keywords internal
vigitel_cache_dir <- function(cache_dir = NULL) {
  .module_cache_dir("vigitel", cache_dir)
}

#' Get VIGITEL base URL
#'
#' @return Character string with base URL
#' @keywords internal
vigitel_base_url <- function() {
  "https://svs.aids.gov.br/daent/cgdnt/vigitel/"
}

#' Download VIGITEL data file
#'
#' @param format Character. "dta" or "csv".
#' @param destfile Character. Destination path for the ZIP file.
#'
#' @return Invisible NULL. Called for side effect (file download).
#'
#' @keywords internal
vigitel_download_data <- function(format, destfile) {
  filename <- str_c("vigitel-2006-2024-peso-rake-", format, ".zip")
  url <- str_c(vigitel_base_url(), filename)

  cli::cli_inform("Downloading VIGITEL data ({format} format)...")
  cli::cli_inform("URL: {.url {url}}")
  cli::cli_inform("This may take a few minutes...")

  # ensure directory exists
  dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)

  # download with progress
  tryCatch(
    {
      curl::curl_download(url, destfile, quiet = FALSE)
      cli::cli_alert_success("Download complete: {.file {destfile}}")
    },
    error = function(e) {
      if (file.exists(destfile)) file.remove(destfile)
      cli::cli_abort("Download failed: {e$message}")
    }
  )

  invisible(NULL)
}

#' Extract VIGITEL ZIP file
#'
#' @param zip_path Character. Path to the ZIP file.
#' @param exdir Character. Directory to extract to.
#'
#' @return Character. Path to the extracted file.
#'
#' @keywords internal
vigitel_extract_zip <- function(zip_path, exdir) {
  cli::cli_inform("Extracting ZIP file...")

  # list files in zip
  files_in_zip <- utils::unzip(zip_path, list = TRUE)$Name

  # extract
  utils::unzip(zip_path, exdir = exdir, overwrite = TRUE)

  # return path to extracted file
  extracted_path <- file.path(exdir, files_in_zip[1])

  cli::cli_alert_success("Extracted: {.file {extracted_path}}")

  extracted_path
}

#' Read VIGITEL data file
#'
#' @param path Character. Path to the data file (.dta or .csv).
#' @param format Character. "dta" or "csv".
#'
#' @return A tibble.
#'
#' @keywords internal
vigitel_read_data <- function(path, format) {
  cli::cli_inform("Reading {format} file (this may take a moment)...")

  if (format == "dta") {
    # stata format - preserves labels
    rlang::check_installed("haven", reason = "to read VIGITEL .dta (Stata) files")
    df <- haven::read_dta(path)
  } else {
    # csv format
    df <- readr::read_csv(path, show_col_types = FALSE)
  }

  tibble::as_tibble(df)
}

#' Identify year column in VIGITEL data
#'
#' @param df A data frame
#' @return Character. Name of the year column.
#' @keywords internal
vigitel_identify_year_column <- function(df) {
  # possible year column names
  possible_names <- c("ano", "year", "ANO", "YEAR", "Ano", "Year")

  found <- intersect(possible_names, names(df))

  if (length(found) == 0) {
    cli::cli_abort("Could not identify year column in the data.")
  }

  found[1]
}

#' Identify year column from Arrow schema
#'
#' @param dataset An Arrow Dataset
#' @return Character. Name of the year column.
#' @keywords internal
vigitel_identify_year_column_from_schema <- function(dataset) {
  possible_names <- c("ano", "year", "ANO", "YEAR", "Ano", "Year")

  # get all column names from the dataset (including partition columns)
  all_names <- names(dataset)

  found <- intersect(possible_names, all_names)

  if (length(found) == 0) {
    cli::cli_abort("Could not identify year column in the dataset schema.")
  }

  found[1]
}

#' Get all available columns from Arrow dataset
#'
#' @param dataset An Arrow Dataset
#' @return Character vector of column names.
#' @keywords internal
get_arrow_column_names <- function(dataset) {
  names(dataset)
}

#' Create partitioned parquet cache
#'
#' @param df A data frame with VIGITEL data
#' @param cache_dir Character. Cache directory path.
#'
#' @return Invisible path to the parquet directory, or NULL if arrow not available.
#'
#' @keywords internal
create_partitioned_cache <- function(df, cache_dir) {
  if (!.has_arrow()) {
    cli::cli_warn(
      c(
        "Package {.pkg arrow} not available.",
        "Partitioned cache not created. Future reads will be slower.",
        "i" = "Install with: {.code install.packages('arrow')}"
      )
    )
    return(invisible(NULL))
  }

  year_col <- vigitel_identify_year_column(df)
  cli::cli_inform("Creating partitioned parquet cache for faster future reads...")
  result <- .cache_write_partitioned(df, cache_dir, "vigitel_data", year_col)
  cli::cli_alert_success("Partitioned cache created.")
  invisible(result)
}

#' Check if partitioned cache exists
#'
#' @param cache_dir Character. Cache directory path.
#' @return Logical. TRUE if partitioned cache exists.
#' @keywords internal
has_partitioned_cache <- function(cache_dir) {
  .has_partitioned_cache(cache_dir, "vigitel_data")
}

# ============================================================================
# public api functions
# ============================================================================

#' List available VIGITEL survey years
#'
#' Returns a vector of years for which VIGITEL microdata is available
#' for download from the Ministry of Health website.
#'
#' @return An integer vector of available years (2006-2024).
#'
#' @export
#'
#' @examples
#' vigitel_years()
vigitel_years <- function() {
  2006L:2024L
}

#' Download VIGITEL microdata
#'
#' Downloads and returns VIGITEL survey microdata from the Ministry of Health.
#' Data is cached locally to avoid repeated downloads. When the `arrow` package
#' is installed, data is cached in partitioned parquet format for faster
#' subsequent reads.
#'
#' @param year Integer or vector of integers. Years to return (2006-2024).
#'   Use NULL to return all years. Default is NULL.
#' @param format Character. File format to download: "dta" (Stata, default)
#'   or "csv". Stata format preserves variable labels.
#' @param vars Character vector. Variables to select. Use NULL for all variables.
#'   Default is NULL.
#' @param cache_dir Character. Directory for caching downloaded files.
#'   Default uses `tools::R_user_dir("healthbR", "cache")`.
#' @param force Logical. If TRUE, re-download even if file exists in cache.
#'   Default is FALSE.
#'
#' @param lazy Logical. If TRUE, returns a lazy query object instead of a
#'   tibble. Requires the \pkg{arrow} package. The lazy object supports
#'   dplyr verbs (filter, select, mutate, etc.) which are pushed down
#'   to the query engine before collecting into memory. Call
#'   \code{dplyr::collect()} to materialize the result. Default: FALSE.
#' @param backend Character. Backend for lazy evaluation: \code{"arrow"}
#'   (default) or \code{"duckdb"}. Only used when \code{lazy = TRUE}.
#'   DuckDB backend requires the \pkg{duckdb} package.
#'
#' @return A tibble with VIGITEL microdata.
#'
#' @details
#' The VIGITEL survey (Vigilância de Fatores de Risco e Proteção para Doenças
#' Crônicas por Inquérito Telefônico) is conducted annually by the Brazilian
#' Ministry of Health in all state capitals and the Federal District.
#'
#' Data includes information on:
#' - Demographics (age, sex, education, race)
#' - Health behaviors (smoking, alcohol, diet, physical activity)
#' - Health conditions (hypertension, diabetes, obesity)
#' - Healthcare utilization
#'
#' The survey uses post-stratification weights (variable `pesorake`) to produce
#' population estimates. Always use these weights for statistical inference.
#'
#' ## Performance
#'
#' When the `arrow` package is installed, data is cached in partitioned parquet
#' format. This allows the function to read only the requested years without
#' loading the entire dataset into memory. If you frequently work with VIGITEL
#' data, installing `arrow` is highly recommended:
#'
#' ```r
#' install.packages("arrow")
#' ```
#'
#' @section Data source:
#' Data is downloaded from the Ministry of Health website:
#' \verb{https://svs.aids.gov.br/daent/cgdnt/vigitel/}
#'
#' @export
#'
#' @examplesIf interactive()
#' # download all years (uses tempdir to avoid leaving files)
#' df <- vigitel_data(cache_dir = tempdir())
#'
#' # download specific year
#' df_2024 <- vigitel_data(year = 2024, cache_dir = tempdir())
#'
#' # download multiple years
#' df_recent <- vigitel_data(year = 2020:2024, cache_dir = tempdir())
#'
#' # select specific variables
#' df_subset <- vigitel_data(
#'   year = 2024,
#'   vars = c("ano", "cidade", "sexo", "idade", "pesorake"),
#'   cache_dir = tempdir()
#' )
vigitel_data <- function(year = NULL,
                         format = c("dta", "csv"),
                         vars = NULL,
                         cache_dir = NULL,
                         force = FALSE,
                         lazy = FALSE, backend = c("arrow", "duckdb")) {

  format <- match.arg(format)
  cache_dir <- vigitel_cache_dir(cache_dir)

  # validate year parameter
  available_years <- vigitel_years()
  if (!is.null(year)) {
    # accepts integer, vector, or sequence
    year <- as.integer(year)
    invalid_years <- setdiff(year, available_years)
    if (length(invalid_years) > 0) {
      cli::cli_abort(
        c(
          "Year{?s} {.val {invalid_years}} not available.",
          "i" = "Available years: {.val {min(available_years)}}-{.val {max(available_years)}}.",
          "i" = "Use {.fn vigitel_years} to see all available years."
        )
      )
    }
  }

  # paths
  parquet_dir <- file.path(cache_dir, "vigitel_data")
  zip_filename <- str_c("vigitel-2006-2024-peso-rake-", format, ".zip")
  zip_path <- file.path(cache_dir, zip_filename)
  data_filename <- str_c("vigitel-2006-2024-peso-rake.", format)
  data_path <- file.path(cache_dir, data_filename)

  # check cache status
  use_arrow <- .has_arrow()
  cache_exists <- has_partitioned_cache(cache_dir)

  # lazy evaluation: return lazy query object if available
  if (isTRUE(lazy) && !force) {
    backend_choice <- match.arg(backend)
    ds <- .lazy_return(cache_dir, "vigitel_data", backend_choice,
                       filters = if (!is.null(year)) list(ano = as.integer(year)) else list(),
                       select_cols = vars)
    if (!is.null(ds)) return(ds)
  }

  # FAST PATH: read from partitioned cache if available
  if (!force && cache_exists && use_arrow) {
    cli::cli_inform("Reading from partitioned cache...")

    ds <- arrow::open_dataset(parquet_dir)

    # identify year column
    year_col <- vigitel_identify_year_column_from_schema(ds)

    # filter by year BEFORE loading into memory
    if (!is.null(year)) {
      ds <- ds |> dplyr::filter(.data[[year_col]] %in% !!year)
    }

    # select variables BEFORE loading (if specified)
    if (!is.null(vars)) {
      # always include year column for consistency
      vars_to_select <- unique(c(year_col, vars))
      available_vars <- names(ds)
      missing_vars <- setdiff(vars_to_select, available_vars)
      if (length(missing_vars) > 0) {
        cli::cli_warn("Variable{?s} not found: {.val {missing_vars}}")
        vars_to_select <- intersect(vars_to_select, available_vars)
      }
      if (length(vars_to_select) > 0) {
        ds <- ds |> dplyr::select(dplyr::all_of(vars_to_select))
      }
    }

    # collect filtered data
    df <- ds |> dplyr::collect()

  } else {
    # FULL PATH: download and process

    # download if necessary
    if (force || !file.exists(data_path)) {
      if (force || !file.exists(zip_path)) {
        vigitel_download_data(format, zip_path)
      }
      vigitel_extract_zip(zip_path, cache_dir)
    }

    # read full file
    df <- vigitel_read_data(data_path, format)

    # create partitioned cache for future reads
    if (use_arrow) {
      create_partitioned_cache(df, cache_dir)

      # optionally delete source file to save space
      # unlink(data_path)
    }

    # if lazy was requested, return from cache after creation
    if (isTRUE(lazy)) {
      backend_choice <- match.arg(backend)
      ds <- .lazy_return(cache_dir, "vigitel_data", backend_choice,
                         filters = if (!is.null(year)) list(ano = as.integer(year)) else list(),
                         select_cols = vars)
      if (!is.null(ds)) return(ds)
    }

    # filter by year
    if (!is.null(year)) {
      year_col <- vigitel_identify_year_column(df)
      df <- df |> dplyr::filter(.data[[year_col]] %in% !!year)
    }

    # select variables
    if (!is.null(vars)) {
      year_col <- vigitel_identify_year_column(df)
      vars_to_select <- unique(c(year_col, vars))
      missing_vars <- setdiff(vars_to_select, names(df))
      if (length(missing_vars) > 0) {
        cli::cli_warn("Variable{?s} not found: {.val {missing_vars}}")
      }
      vars_to_select <- intersect(vars_to_select, names(df))
      df <- df |> dplyr::select(dplyr::all_of(vars_to_select))
    }
  }

  # inform user about the result
  result_df <- tibble::as_tibble(df)

  # try to identify year column for reporting
  tryCatch(
    {
      year_col <- vigitel_identify_year_column(result_df)
      years_in_data <- sort(unique(result_df[[year_col]]))
      cli::cli_alert_success(
        "Loaded {.val {nrow(result_df)}} observations from {.val {length(years_in_data)}} year{?s}: {.val {years_in_data}}"
      )
    },
    error = function(e) {
      cli::cli_alert_success(
        "Loaded {.val {nrow(result_df)}} observations"
      )
    }
  )

  result_df
}

#' Get VIGITEL variable dictionary
#'
#' Downloads and returns the VIGITEL data dictionary containing variable
#' descriptions, codes, and categories.
#'
#' @param cache_dir Character. Directory for caching downloaded files.
#'   Default uses `tools::R_user_dir("healthbR", "cache")`.
#' @param force Logical. If TRUE, re-download even if file exists in cache.
#'   Default is FALSE.
#'
#' @return A tibble with variable dictionary.
#'
#' @export
#'
#' @examplesIf interactive()
#' dict <- vigitel_dictionary(cache_dir = tempdir())
#' head(dict)
vigitel_dictionary <- function(cache_dir = NULL,
                               force = FALSE) {

  cache_dir <- vigitel_cache_dir(cache_dir)
  dict_url <- str_c(vigitel_base_url(), "dicionario-vigitel-2006-2024.xlsx")
  dict_path <- file.path(cache_dir, "dicionario-vigitel-2006-2024.xlsx")

  # download if needed
  if (force || !file.exists(dict_path)) {
    cli::cli_inform("Downloading VIGITEL dictionary...")
    tryCatch(
      {
        curl::curl_download(dict_url, dict_path, quiet = FALSE)
        cli::cli_alert_success("Dictionary downloaded: {.file {dict_path}}")
      },
      error = function(e) {
        if (file.exists(dict_path)) file.remove(dict_path)
        cli::cli_abort("Download failed: {e$message}")
      }
    )
  }

  # read excel
  rlang::check_installed("readxl", reason = "to read VIGITEL dictionary files")
  df <- readxl::read_excel(dict_path)

  # clean column names
  names(df) <- .clean_names(names(df))

  tibble::as_tibble(df)
}

#' List VIGITEL variables
#'
#' Returns a tibble with information about available variables in the
#' VIGITEL dataset.
#'
#' @inheritParams vigitel_dictionary
#'
#' @return A tibble with variable information from the dictionary.
#'
#' @export
#'
#' @examplesIf interactive()
#' vars <- vigitel_variables(cache_dir = tempdir())
#' head(vars)
vigitel_variables <- function(cache_dir = NULL,
                              force = FALSE) {

  dict <- vigitel_dictionary(cache_dir = cache_dir, force = force)

  # return dictionary (structure depends on actual dictionary format)
  # adjust column selection based on actual dictionary structure
  dict
}

#' Get VIGITEL survey information
#'
#' Returns metadata about the VIGITEL survey.
#'
#' @return A list with survey information
#'
#' @export
#'
#' @examples
#' vigitel_info()
vigitel_info <- function() {
  list(
    name = "VIGITEL",
    full_name = paste0(
      "Vigilancia de Fatores de Risco e Protecao ",
      "para Doencas Cronicas por Inquerito Telefonico"
    ),
    institution = "Ministerio da Saude",
    description = paste0(
      "Telephone survey monitoring risk and protective factors ",
      "for chronic diseases in Brazilian state capitals."
    ),
    years_available = vigitel_years(),
    url = "https://www.gov.br/saude/pt-br/composicao/svsa/inqueritos-de-saude/vigitel",
    download_url = vigitel_base_url(),
    weight_variable = "pesorake",
    geographic_coverage = "26 state capitals + Federal District",
    sample_size = "~54,000 adults per year (18+ years)",
    data_format = c("Stata (.dta)", "CSV (.csv)"),
    topics = c(
      "chronic diseases",
      "risk factors",
      "tobacco use",
      "alcohol consumption",
      "physical activity",
      "diet and nutrition",
      "obesity",
      "diabetes",
      "hypertension",
      "preventive exams"
    )
  )
}

#' Clear VIGITEL cache
#'
#' Removes all cached VIGITEL data files.
#'
#' @param keep_parquet Logical. If TRUE, keep parquet cache and only remove
#'   source files (ZIP, DTA, CSV). Default is FALSE (remove all).
#' @param cache_dir Character. Optional custom cache directory. If NULL (default),
#'   uses the standard user cache directory.
#'
#' @return NULL (invisibly)
#'
#' @export
#'
#' @examples
#' # remove all cached files from default cache
#' vigitel_clear_cache()
vigitel_clear_cache <- function(keep_parquet = FALSE, cache_dir = NULL) {
  cache_dir <- vigitel_cache_dir(cache_dir)

  if (keep_parquet) {
    # remove only source files
    files <- list.files(cache_dir, pattern = "\\.(zip|dta|csv|xlsx?)$",
                        full.names = TRUE, ignore.case = TRUE)
  } else {
    # remove all files and directories
    files <- list.files(cache_dir, full.names = TRUE)
    dirs <- list.dirs(cache_dir, full.names = TRUE, recursive = FALSE)
    # remove directories first
    for (d in dirs) {
      unlink(d, recursive = TRUE)
    }
  }

  if (length(files) == 0 && (!keep_parquet || length(list.dirs(cache_dir, recursive = FALSE)) == 0)) {
    cli::cli_alert_info("Cache is already empty")
    return(invisible(NULL))
  }

  if (length(files) > 0) {
    file.remove(files)
  }

  cli::cli_alert_success("Cache cleared")

  invisible(NULL)
}

#' Get VIGITEL cache status
#'
#' Shows cache status including downloaded files and their sizes.
#'
#' @param cache_dir Character. Optional custom cache directory. If NULL (default),
#'   uses the standard user cache directory.
#'
#' @return A tibble with cache information
#'
#' @export
#'
#' @examples
#' # check cache status
#' vigitel_cache_status()
vigitel_cache_status <- function(cache_dir = NULL) {
  cache_dir <- vigitel_cache_dir(cache_dir)

  # check for various file types
  zip_dta <- file.path(cache_dir, "vigitel-2006-2024-peso-rake-dta.zip")
  zip_csv <- file.path(cache_dir, "vigitel-2006-2024-peso-rake-csv.zip")
  data_dta <- file.path(cache_dir, "vigitel-2006-2024-peso-rake.dta")
  data_csv <- file.path(cache_dir, "vigitel-2006-2024-peso-rake.csv")
  dict_path <- file.path(cache_dir, "dicionario-vigitel-2006-2024.xlsx")
  parquet_dir <- file.path(cache_dir, "vigitel_data")

  # helper to get file size in MB
  get_size_mb <- function(path) {
    if (file.exists(path)) {
      round(file.size(path) / 1024^2, 1)
    } else {
      NA_real_
    }
  }

  # helper to get directory size in MB
  get_dir_size_mb <- function(path) {
    if (dir.exists(path)) {
      files <- list.files(path, recursive = TRUE, full.names = TRUE)
      if (length(files) > 0) {
        round(sum(file.size(files)) / 1024^2, 1)
      } else {
        0
      }
    } else {
      NA_real_
    }
  }

  # count parquet partitions (years)
  parquet_years <- if (dir.exists(parquet_dir)) {
    length(list.dirs(parquet_dir, recursive = FALSE))
  } else {
    0
  }

  tibble::tibble(
    file_type = c("ZIP (Stata)", "ZIP (CSV)", "Data (Stata)", "Data (CSV)",
                  "Dictionary", "Parquet cache"),
    exists = c(
      file.exists(zip_dta),
      file.exists(zip_csv),
      file.exists(data_dta),
      file.exists(data_csv),
      file.exists(dict_path),
      dir.exists(parquet_dir) && parquet_years > 0
    ),
    size_mb = c(
      get_size_mb(zip_dta),
      get_size_mb(zip_csv),
      get_size_mb(data_dta),
      get_size_mb(data_csv),
      get_size_mb(dict_path),
      get_dir_size_mb(parquet_dir)
    ),
    details = c(
      NA_character_,
      NA_character_,
      NA_character_,
      NA_character_,
      NA_character_,
      if (parquet_years > 0) str_c(parquet_years, " year partitions") else NA_character_
    )
  )
}
