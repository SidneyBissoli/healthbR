# vigitel functions for healthbR package
# functions to download and process VIGITEL survey data

#' Check if arrow package is available
#'
#' @return TRUE if arrow is available, FALSE otherwise
#' @keywords internal
has_arrow <- function() {
  requireNamespace("arrow", quietly = TRUE)
}

#' Check arrow availability and stop with informative message
#'
#' @param feature Character describing what feature requires arrow
#' @return NULL (invisibly), stops if arrow not available
#' @keywords internal
check_arrow <- function(feature = "Parquet file support") {
  if (!has_arrow()) {
    cli::cli_abort(
      c(
        "Package {.pkg arrow} is required for {feature}.",
        "i" = "Install it with: {.code install.packages('arrow')}"
      ),
      call = NULL
    )
  }
  invisible(NULL)
}

#' List available VIGITEL survey years
#'
#' Returns a vector of years for which VIGITEL microdata is available
#' for download from the Ministry of Health website.
#'
#' @return An integer vector of available years
#'
#' @export
#'
#' @examples
#' vigitel_years()
vigitel_years <- function() {
  # years available at https://svs.aids.gov.br/download/Vigitel/
  c(2006L:2021L, 2023L)
}

#' Get VIGITEL base URL
#'
#' @return Character string with base URL
#' @keywords internal
vigitel_base_url <- function() {
"https://svs.aids.gov.br/download/Vigitel/"
}

#' Build VIGITEL file URL for a specific year
#'
#' @param year Integer year
#' @return Character string with file URL
#' @keywords internal
vigitel_file_url <- function(year) {
  year <- as.integer(year)

  if (!year %in% vigitel_years()) {
    cli::cli_abort(
      "Year {year} is not available. Use {.fn vigitel_years} to see available years."
    )
  }

  # 2023 uses xlsx format, others use xls
  ext <- if (year == 2023L) "xlsx" else "xls"
  filename <- str_c("Vigitel-", year, "-peso-rake.", ext)

  str_c(vigitel_base_url(), filename)
}

#' Get VIGITEL cache directory
#'
#' @param cache_dir Optional custom cache directory. If NULL, uses default
#'   user cache directory.
#' @return Path to cache directory
#' @keywords internal
vigitel_cache_dir <- function(cache_dir = NULL) {
  if (is.null(cache_dir)) {
    cache_dir <- tools::R_user_dir("healthbR", which = "cache")
  }
  vigitel_dir <- file.path(cache_dir, "vigitel")

  if (!dir.exists(vigitel_dir)) {
    dir.create(vigitel_dir, recursive = TRUE)
  }

  vigitel_dir
}

#' Get path to Parquet file for a specific year
#'
#' @param year Integer year
#' @param cache_dir Optional custom cache directory
#' @return Path to parquet file
#' @keywords internal
vigitel_parquet_path <- function(year, cache_dir = NULL) {
  file.path(vigitel_cache_dir(cache_dir), str_c("vigitel_", year, ".parquet"))
}

#' Get path to Excel file for a specific year
#'
#' @param year Integer year
#' @param cache_dir Optional custom cache directory
#' @return Path to excel file
#' @keywords internal
vigitel_excel_path <- function(year, cache_dir = NULL) {
  ext <- if (year == 2023L) "xlsx" else "xls"
  file.path(vigitel_cache_dir(cache_dir), str_c("vigitel_", year, ".", ext))
}

#' Parse year argument
#'
#' Converts various year input formats to integer vector.
#'
#' @param year Year specification (integer, character, vector, or "all")
#' @return Integer vector of years
#' @keywords internal
vigitel_parse_years <- function(year) {
  available <- vigitel_years()

  # handle "all"
  if (length(year) == 1 && is.character(year) && tolower(year) == "all") {
    return(available)
  }

  # convert to integer
  years <- as.integer(year)

  # check for unavailable years
  unavailable <- years[!years %in% available]
  if (length(unavailable) > 0) {
    years_str <- toString(unavailable)
    cli::cli_warn(
      "Year(s) not available and will be skipped: {years_str}"
    )
  }

  # keep only available years
  years <- years[years %in% available]

  if (length(years) == 0) {
    cli::cli_abort(
      "No valid years provided. Use {.fn vigitel_years} to see available years."
    )
  }

  unique(years)
}

#' Download VIGITEL microdata for a specific year
#'
#' Downloads the VIGITEL survey microdata file from the Ministry of Health
#' website. Files are cached locally to avoid repeated downloads.
#'
#' @param year Integer. Year of the survey (use \code{vigitel_years()} to see
#'   available years).
#' @param force Logical. If TRUE, re-download even if file exists in cache.
#'   Default is FALSE.
#' @param cache_dir Character. Optional custom cache directory. If NULL (default),
#'   uses the standard user cache directory. Use \code{tempdir()} for temporary
#'   storage that won't persist.
#'
#' @return Path to the downloaded file (invisibly)
#'
#' @export
#'
#' @examples
#' \donttest{
#' # download 2023 data (uses tempdir to avoid leaving files)
#' vigitel_download(2023, cache_dir = tempdir())
#' }
vigitel_download <- function(year, force = FALSE, cache_dir = NULL) {
  year <- as.integer(year)
  url <- vigitel_file_url(year)
  destfile <- vigitel_excel_path(year, cache_dir)

  if (file.exists(destfile) && !force) {
    cli::cli_alert_info("Using cached file: {.file {destfile}}")
    return(invisible(destfile))
  }

  cli::cli_alert_info("Downloading VIGITEL {year} from {.url {url}}")

  tryCatch(
    {
      curl::curl_download(
        url = url,
        destfile = destfile,
        quiet = FALSE
      )

      cli::cli_alert_success("Downloaded to {.file {destfile}}")
      invisible(destfile)
    },
    error = function(e) {
      if (file.exists(destfile)) file.remove(destfile)
      cli::cli_abort("Download failed: {e$message}")
    }
  )
}

#' Convert Excel file to Parquet format
#'
#' @param year Integer year
#' @param force Logical. If TRUE, reconvert even if parquet exists.
#' @param cache_dir Optional custom cache directory
#' @return Path to parquet file (invisibly)
#' @keywords internal
vigitel_convert_to_parquet <- function(year, force = FALSE, cache_dir = NULL) {
  # check if arrow is available
  check_arrow("converting to Parquet format")

  year <- as.integer(year)
  parquet_path <- vigitel_parquet_path(year, cache_dir)
  excel_path <- vigitel_excel_path(year, cache_dir)

  # return if parquet already exists
  if (file.exists(parquet_path) && !force) {
    return(invisible(parquet_path))
  }

  # ensure excel file exists
  if (!file.exists(excel_path)) {
    vigitel_download(year, cache_dir = cache_dir)
  }

  cli::cli_alert_info("Converting {year} to Parquet format...")

  # read excel
  df <- readxl::read_excel(excel_path, col_types = "text")

  # clean column names
  df <- janitor::clean_names(df)

  # convert numeric columns
  df <- df |>
    dplyr::mutate(
      dplyr::across(
        dplyr::where(\(x) all(grepl("^-?\\d+\\.?\\d*$", x, perl = TRUE) | is.na(x))),
        as.numeric
      )
    )

  # add year column (enables filtering by year in lazy mode)
  df <- df |>
    dplyr::mutate(year = year) |>
    dplyr::relocate(year)

  # write parquet
  arrow::write_parquet(df, parquet_path)

  # report size reduction
  excel_size <- file.size(excel_path) / 1024^2
  parquet_size <- file.size(parquet_path) / 1024^2

  cli::cli_alert_success(
    "Converted {year}: {.file {basename(parquet_path)}} ({round(parquet_size, 1)}MB vs {round(excel_size, 1)}MB Excel)"
  )

  invisible(parquet_path)
}

#' Load single year of VIGITEL data
#'
#' @param year Integer year
#' @param vars Character vector of variables or NULL
#' @param force_download Logical
#' @param lazy Logical. If TRUE, return Arrow object for lazy evaluation.
#' @param cache_dir Optional custom cache directory
#' @return A tibble or Arrow Table (if lazy = TRUE)
#' @keywords internal
vigitel_data_single <- function(year, vars = NULL, force_download = FALSE, lazy = FALSE, cache_dir = NULL) {
  # check if arrow is available
  check_arrow("reading Parquet files")

  year <- as.integer(year)

  # ensure parquet exists (downloads and converts if needed)
  if (force_download) {
    vigitel_download(year, force = TRUE, cache_dir = cache_dir)
  }

  parquet_path <- vigitel_parquet_path(year, cache_dir)

  if (!file.exists(parquet_path) || force_download) {
    vigitel_convert_to_parquet(year, force = force_download, cache_dir = cache_dir)
  }

  # read from parquet (fast!)
  if (!is.null(vars)) {
    # select specific columns
    vars_clean <- janitor::make_clean_names(vars)

    # always include year column
    if (!"year" %in% vars_clean) {
      vars_clean <- c("year", vars_clean)
    }

    # get available columns
    schema <- arrow::read_parquet(parquet_path, as_data_frame = FALSE)$schema
    vars_available <- names(schema)
    vars_missing <- setdiff(vars_clean, vars_available)

    if (length(vars_missing) > 0) {
      n_missing <- length(vars_missing)
      cli::cli_warn("{cli::qty(n_missing)}Variable{?s} not found in {year}: {.var {vars_missing}}")
    }

    vars_select <- intersect(vars_clean, vars_available)
    df <- arrow::read_parquet(parquet_path, col_select = dplyr::all_of(vars_select), as_data_frame = !lazy)
  } else {
    df <- arrow::read_parquet(parquet_path, as_data_frame = !lazy)
  }

  if (lazy) {
    return(df)
  }

  tibble::as_tibble(df)
}

#' Load VIGITEL microdata
#'
#' Downloads (if necessary) and loads VIGITEL survey microdata into R.
#' Data is automatically converted to Parquet format for faster subsequent
#' loading. The data includes survey weights for proper statistical analysis.
#'
#' @param year Year(s) of the survey. Can be:
#'   \itemize{
#'     \item Single year: \code{2023}
#'     \item Range: \code{2021:2023}
#'     \item Vector: \code{c(2021, 2023)}
#'     \item Character: \code{c("2021", "2023")}
#'     \item All years: \code{"all"}
#'   }
#' @param vars Character vector. Variable names to select, or NULL for all
#'   variables. Default is NULL.
#' @param force_download Logical. If TRUE, re-download and reconvert data.
#'   Default is FALSE.
#' @param parallel Logical. If TRUE, download and process multiple years in
#'   parallel. Default is TRUE when multiple years are requested.
#' @param lazy Logical. If TRUE, return an Arrow Dataset for lazy evaluation
#'   instead of loading all data into memory. Useful for filtering large
#'   datasets before collecting. Use \code{collect()} to retrieve results.
#'   Default is FALSE.
#' @param cache_dir Character. Optional custom cache directory. If NULL (default),
#'   uses the standard user cache directory. Use \code{tempdir()} for temporary
#'   storage that won't persist.
#'
#' @return A tibble with the VIGITEL microdata. When multiple years are
#'   requested, a \code{year} column is added to identify the source year.
#'   If \code{lazy = TRUE}, returns an Arrow Dataset that can be queried
#'   with dplyr verbs before calling \code{collect()}.
#'
#' @details
#' On first access, data is downloaded from the Ministry of Health and
#' converted to Parquet format. Subsequent loads read directly from the
#' Parquet file, which is significantly faster.
#'
#' The \code{arrow} package is required for Parquet file support. If not
#' installed, an informative error message will be shown with installation
#' instructions.
#'
#' For parallel downloads, the function uses the \code{furrr} and \code{future}
#' packages if installed. Install them with \code{install.packages(c("furrr", "future"))}
#' to enable parallel processing. The number of workers is automatically set
#' based on available CPU cores. If these packages are not installed, processing
#' falls back to sequential mode.
#'
#' When \code{lazy = TRUE}, the function returns an Arrow Dataset that supports
#' dplyr operations (filter, select, mutate, etc.) without loading data into
#' memory. This is useful for working with large datasets or when you only
#' need a subset of the data. Call \code{collect()} to retrieve the results
#' as a tibble.
#'
#' The VIGITEL survey uses complex sampling weights. For proper statistical
#' analysis, use survey packages like \code{survey} or \code{srvyr}.
#' The weight variable is named \code{pesorake}.
#'
#' @export
#'
#' @examples
#' \donttest{
#' # single year (uses tempdir to avoid leaving files on system)
#' df <- vigitel_data(2023, cache_dir = tempdir())
#'
#' # specific variables
#' df <- vigitel_data(2023, vars = c("cidade", "sexo", "idade", "pesorake"),
#'                    cache_dir = tempdir())
#' }
vigitel_data <- function(year, vars = NULL, force_download = FALSE, parallel = TRUE,
                         lazy = FALSE, cache_dir = NULL) {
  # check if arrow is available
  check_arrow("loading VIGITEL data")

  # parse years
  years <- vigitel_parse_years(year)

  # ensure all parquet files exist before proceeding
  for (y in years) {
    parquet_path <- vigitel_parquet_path(y, cache_dir)
    if (!file.exists(parquet_path) || force_download) {
      if (force_download) {
        vigitel_download(y, force = TRUE, cache_dir = cache_dir)
      }
      vigitel_convert_to_parquet(y, force = force_download, cache_dir = cache_dir)
    }
  }

  # lazy mode - return Arrow Dataset
  if (lazy) {
    parquet_files <- purrr::map_chr(years, \(y) vigitel_parquet_path(y, cache_dir))

    # open dataset (supports multiple files, year column already in parquet)
    ds <- arrow::open_dataset(parquet_files, unify_schemas = TRUE)

    # select specific columns if requested
    if (!is.null(vars)) {
      vars_clean <- janitor::make_clean_names(vars)
      # always include year for filtering
      if (!"year" %in% vars_clean) {
        vars_clean <- c("year", vars_clean)
      }
      available_cols <- names(ds$schema)
      vars_select <- intersect(vars_clean, available_cols)

      vars_missing <- setdiff(vars_clean, available_cols)
      if (length(vars_missing) > 0) {
        n_missing <- length(vars_missing)
        cli::cli_warn("{cli::qty(n_missing)}Variable{?s} not found: {.var {vars_missing}}")
      }

      ds <- ds |> dplyr::select(dplyr::all_of(vars_select))
    }

    cli::cli_alert_success(
      "Opened Arrow Dataset with {length(years)} year{?s} (use {.fn collect} to load into memory)"
    )
    return(ds)
  }

  # single year - simple case
  if (length(years) == 1) {
    cli::cli_alert_info("Reading VIGITEL {years} data...")
    df <- vigitel_data_single(years, vars = vars, force_download = FALSE, cache_dir = cache_dir)
    cli::cli_alert_success("Loaded {nrow(df)} observations and {ncol(df)} variables")
    return(df)
  }

  # multiple years - eager loading
  cli::cli_alert_info("Processing {length(years)} years: {.val {years}}")


  # check if parallel packages are available

  has_parallel_pkgs <- requireNamespace("furrr", quietly = TRUE) &&
    requireNamespace("future", quietly = TRUE)

  # use parallel only if requested, packages available, and multiple years
  use_parallel <- parallel && has_parallel_pkgs && length(years) > 1

  if (parallel && !has_parallel_pkgs) {
    cli::cli_alert_info(
      "Install {.pkg furrr} and {.pkg future} for parallel processing"
    )
  }

  if (use_parallel) {
    # setup parallel processing
    n_workers <- min(length(years), future::availableCores() - 1, 4)
    cli::cli_alert_info("Using {n_workers} parallel workers")

    oplan <- future::plan(future::multisession, workers = n_workers)
    on.exit(future::plan(oplan), add = TRUE)

    # process in parallel (year column already in parquet files)
    df_list <- furrr::future_map(
      years,
      \(y) vigitel_data_single(y, vars = vars, force_download = FALSE, cache_dir = cache_dir),
      .options = furrr::furrr_options(seed = TRUE),
      .progress = TRUE
    )
  } else {
    # sequential processing
    df_list <- purrr::map(
      years,
      \(y) {
        cli::cli_alert_info("Processing {y}...")
        vigitel_data_single(y, vars = vars, force_download = FALSE, cache_dir = cache_dir)
      }
    )
  }

  # combine all years (year column already present)
  df <- dplyr::bind_rows(df_list)

  cli::cli_alert_success(
    "Loaded {nrow(df)} observations and {ncol(df)} variables from {length(years)} years"
  )

  df
}

#' Download VIGITEL data dictionary
#'
#' Downloads the official VIGITEL data dictionary from the Ministry of Health.
#'
#' @param force Logical. If TRUE, re-download even if cached.
#' @param cache_dir Optional custom cache directory
#'
#' @return Path to the downloaded file (invisibly)
#'
#' @keywords internal
vigitel_download_dictionary <- function(force = FALSE, cache_dir = NULL) {
  url <- str_c(vigitel_base_url(), "Dicionario-de-dados-Vigitel.xls")
  destfile <- file.path(vigitel_cache_dir(cache_dir), "vigitel_dictionary.xls")

  if (file.exists(destfile) && !force) {
    return(invisible(destfile))
  }

  cli::cli_alert_info("Downloading VIGITEL dictionary...")

  tryCatch(
    curl::curl_download(url = url, destfile = destfile, quiet = FALSE),
    error = function(e) {
      if (file.exists(destfile)) file.remove(destfile)
      cli::cli_abort("Download failed: {e$message}")
    }
  )

  invisible(destfile)
}

#' Get VIGITEL variable dictionary
#'
#' Returns the data dictionary with variable descriptions, labels, and
#' coding information for VIGITEL surveys.
#'
#' @param force_download Logical. If TRUE, re-download the dictionary.
#' @param cache_dir Character. Optional custom cache directory. If NULL (default),
#'   uses the standard user cache directory. Use \code{tempdir()} for temporary
#'   storage that won't persist.
#'
#' @return A tibble with variable metadata
#'
#' @export
#'
#' @examples
#' \donttest{
#' # get the dictionary (uses tempdir to avoid leaving files)
#' dict <- vigitel_dictionary(cache_dir = tempdir())
#'
#' # view column names
#' names(dict)
#' }
vigitel_dictionary <- function(force_download = FALSE, cache_dir = NULL) {
  filepath <- vigitel_download_dictionary(force = force_download, cache_dir = cache_dir)

  # read dictionary, skipping first row (real headers are in row 2)
  df <- readxl::read_excel(filepath, skip = 1)
  df <- janitor::clean_names(df)

  # convert variable_name column to machine-readable format (matching the data)
  if ("variable_name" %in% names(df)) {
    df <- dplyr::mutate(df, variable_name = janitor::make_clean_names(.data$variable_name))
  }

  tibble::as_tibble(df)
}

#' List VIGITEL variables
#'
#' Returns a character vector of variable names available in a VIGITEL
#' survey year.
#'
#' @param year Integer. Year of the survey.
#' @param cache_dir Character. Optional custom cache directory. If NULL (default),
#'   uses the standard user cache directory. Use \code{tempdir()} for temporary
#'   storage that won't persist.
#'
#' @return A character vector of variable names
#'
#' @export
#'
#' @examples
#' \donttest{
#' # list variables for 2023 (uses tempdir to avoid leaving files)
#' vigitel_variables(2023, cache_dir = tempdir())
#' }
vigitel_variables <- function(year, cache_dir = NULL) {
  year <- as.integer(year)
  parquet_path <- vigitel_parquet_path(year, cache_dir)

  # if parquet exists and arrow is available, read schema (fast)
  if (file.exists(parquet_path) && has_arrow()) {
    schema <- arrow::read_parquet(parquet_path, as_data_frame = FALSE)$schema
    return(names(schema))
  }

  # otherwise download and read excel header
  filepath <- vigitel_download(year, force = FALSE, cache_dir = cache_dir)
  df <- readxl::read_excel(filepath, n_max = 0)
  janitor::make_clean_names(names(df))
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
#' Removes all cached VIGITEL data files (Excel and Parquet).
#'
#' @param keep_parquet Logical. If TRUE, keep Parquet files and only remove
#'   Excel files. Default is FALSE (remove all).
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
    files <- list.files(cache_dir, pattern = "\\.(xls|xlsx)$", full.names = TRUE)
  } else {
    files <- list.files(cache_dir, full.names = TRUE)
  }

  if (length(files) == 0) {
    cli::cli_alert_info("Cache is already empty")
    return(invisible(NULL))
  }

  file.remove(files)
  cli::cli_alert_success("Removed {length(files)} cached file{?s}")

  invisible(NULL)
}

#' Get VIGITEL cache status
#'
#' Shows which years are cached and file sizes.
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
  cache_dir_path <- vigitel_cache_dir(cache_dir)
  years <- vigitel_years()

  status <- purrr::map_dfr(years, function(year) {
    excel_path <- vigitel_excel_path(year, cache_dir)
    parquet_path <- vigitel_parquet_path(year, cache_dir)

    tibble::tibble(
      year = year,
      excel_cached = file.exists(excel_path),
      parquet_cached = file.exists(parquet_path),
      excel_size_mb = if (file.exists(excel_path)) round(file.size(excel_path) / 1024^2, 1) else NA_real_,
      parquet_size_mb = if (file.exists(parquet_path)) round(file.size(parquet_path) / 1024^2, 1) else NA_real_
    )
  })

  status
}
