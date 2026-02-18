# tests for vigitel functions
# updated for new consolidated data structure (2006-2024)

test_that("vigitel_years returns expected years", {
  years <- vigitel_years()

  expect_type(years, "integer")
  expect_equal(min(years), 2006L)
  expect_equal(max(years), 2024L)
  expect_equal(length(years), 19L)  # 2006 to 2024 inclusive
  expect_true(2006L %in% years)
  expect_true(2024L %in% years)
})

test_that("vigitel_base_url returns valid URL", {
  url <- vigitel_base_url()

  expect_type(url, "character")
  expect_match(url, "^https://")
  expect_match(url, "vigitel")
})

test_that("vigitel_info returns expected structure", {
  info <- vigitel_info()

  expect_type(info, "list")
  expect_true("name" %in% names(info))
  expect_true("years_available" %in% names(info))
  expect_true("weight_variable" %in% names(info))
  expect_true("data_format" %in% names(info))
  expect_equal(info$weight_variable, "pesorake")
  expect_equal(info$years_available, vigitel_years())
})

test_that("vigitel_cache_dir creates directory", {
  dir <- vigitel_cache_dir()

  expect_type(dir, "character")
  expect_true(dir.exists(dir))
})

test_that("vigitel_cache_dir respects custom cache_dir", {
  custom_dir <- file.path(tempdir(), "custom_vigitel_cache")
  on.exit(unlink(custom_dir, recursive = TRUE), add = TRUE)

  dir <- vigitel_cache_dir(custom_dir)

  expect_true(dir.exists(dir))
  expect_match(dir, "vigitel")
})

test_that("vigitel_data validates year parameter", {
  expect_error(
    vigitel_data(year = 1999, cache_dir = tempdir()),
    "not available"
  )
  expect_error(
    vigitel_data(year = 2030, cache_dir = tempdir()),
    "not available"
  )
  expect_error(
    vigitel_data(year = c(2020, 2030), cache_dir = tempdir()),
    "not available"
  )
})

test_that("vigitel_data accepts various year formats", {
  # these should not error on validation (they may fail on download if offline)
  skip_on_cran()
  skip_if_no_integration()

  # use dedicated cache
  test_cache <- file.path(tempdir(), "test_year_formats")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # single year
  expect_no_error(vigitel_data(year = 2024, cache_dir = test_cache))
})

test_that("vigitel_cache_status returns tibble", {
  status <- vigitel_cache_status()

  expect_s3_class(status, "tbl_df")
  expect_true(all(c("file_type", "exists", "size_mb") %in% names(status)))
})

test_that("vigitel_clear_cache handles empty cache", {
  # create a fresh temp directory
  temp_cache <- file.path(tempdir(), "empty_vigitel_test")
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  # should not error
  expect_no_error(vigitel_clear_cache(cache_dir = temp_cache))
})

# integration tests - skip on CRAN due to downloads
test_that("vigitel_dictionary downloads and parses correctly", {
  skip_on_cran()
  skip_if_no_integration()

  test_cache <- file.path(tempdir(), "test_dictionary")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  dict <- vigitel_dictionary(cache_dir = test_cache)

  expect_s3_class(dict, "tbl_df")
  expect_true(nrow(dict) > 0)
})

test_that("vigitel_variables returns tibble", {
  skip_on_cran()
  skip_if_no_integration()

  test_cache <- file.path(tempdir(), "test_variables")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  vars <- vigitel_variables(cache_dir = test_cache)

  expect_s3_class(vars, "tbl_df")
  expect_true(nrow(vars) > 0)
})

test_that("vigitel_data downloads and returns tibble", {
  skip_on_cran()
  skip_if_no_integration()

  # use dedicated cache to avoid interference
  test_cache <- file.path(tempdir(), "test_download_single")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # test with a single recent year
  df <- vigitel_data(year = 2024, cache_dir = test_cache)

  expect_s3_class(df, "tbl_df")
  expect_true(nrow(df) > 0)
  expect_true(ncol(df) > 0)
  # check for year column (may be "ano" or "year")
  has_year_col <- any(c("ano", "year", "ANO", "YEAR") %in% names(df))
  expect_true(has_year_col)
})

test_that("vigitel_data handles multiple years", {
  skip_on_cran()
  skip_if_no_integration()

  # use fresh cache to avoid interference from other tests
  fresh_cache <- file.path(tempdir(), "test_multiple_years")
  # clean before AND after to ensure fresh state
  unlink(fresh_cache, recursive = TRUE)
  on.exit(unlink(fresh_cache, recursive = TRUE), add = TRUE)

  df <- vigitel_data(year = c(2023, 2024), cache_dir = fresh_cache)

  expect_s3_class(df, "tbl_df")
  # check for year column (may be "ano" or "year")
  year_col <- intersect(c("ano", "year", "ANO", "YEAR"), names(df))[1]
  expect_true(all(c(2023, 2024) %in% unique(df[[year_col]])))
})

test_that("vigitel_data handles year range", {
  skip_on_cran()
  skip_if_no_integration()

  # use fresh cache to avoid interference from other tests
  fresh_cache <- file.path(tempdir(), "test_year_range")
  # clean before AND after to ensure fresh state
  unlink(fresh_cache, recursive = TRUE)
  on.exit(unlink(fresh_cache, recursive = TRUE), add = TRUE)

  # test with recent years that are definitely available
  df <- vigitel_data(year = 2020:2024, cache_dir = fresh_cache)

  expect_s3_class(df, "tbl_df")
  # check for year column (may be "ano" or "year")
  year_col <- intersect(c("ano", "year", "ANO", "YEAR"), names(df))[1]
  # verify we got multiple years (at least 2)
  years_returned <- unique(df[[year_col]])
  expect_gte(length(years_returned), 2)
  # verify the years are within our requested range
  expect_true(all(years_returned %in% 2020:2024))
})

test_that("vigitel_data selects specific variables", {
  skip_on_cran()
  skip_if_no_integration()

  # use fresh cache to avoid interference from other tests
  fresh_cache <- file.path(tempdir(), "test_select_vars")
  # clean before AND after to ensure fresh state
  unlink(fresh_cache, recursive = TRUE)
  on.exit(unlink(fresh_cache, recursive = TRUE), add = TRUE)

  # first get the full data to know what columns exist
  df_full <- vigitel_data(year = 2024, cache_dir = fresh_cache)
  available_vars <- names(df_full)

  # select a subset of actual available columns (excluding year column)
  year_cols <- c("ano", "year", "ANO", "YEAR")
  non_year_vars <- setdiff(available_vars, year_cols)
  vars_to_select <- head(non_year_vars, 3)

  df <- vigitel_data(
    year = 2024,
    vars = vars_to_select,
    cache_dir = fresh_cache
  )

  expect_s3_class(df, "tbl_df")
  # year column should be included
  has_year_col <- any(year_cols %in% names(df))
  expect_true(has_year_col)
  # selected variables should be present
  expect_true(all(vars_to_select %in% names(df)))
  # should have fewer columns than full data
  expect_lt(ncol(df), ncol(df_full))
})

test_that("vigitel_data format parameter works", {
  skip_on_cran()
  skip_if_no_integration()

  test_cache <- file.path(tempdir(), "test_csv_format")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # test csv format
  df_csv <- vigitel_data(year = 2024, format = "csv", cache_dir = test_cache)

  expect_s3_class(df_csv, "tbl_df")
  expect_true(nrow(df_csv) > 0)
})


# ============================================================================
# additional unit tests (no HTTP downloads)
# ============================================================================

# --- vigitel_info ---

test_that("vigitel_info returns a list visibly", {
  result <- withVisible(vigitel_info())
  expect_true(result$visible)
  expect_type(result$value, "list")
})

test_that("vigitel_info list has all expected fields", {
  info <- vigitel_info()
  expected_fields <- c(
    "name", "full_name", "institution", "description",
    "years_available", "url", "download_url", "weight_variable",
    "geographic_coverage", "sample_size", "data_format", "topics"
  )
  for (f in expected_fields) {
    expect_true(f %in% names(info), info = paste("Missing field:", f))
  }
})

test_that("vigitel_info topics is character vector", {
  info <- vigitel_info()
  expect_type(info$topics, "character")
  expect_gt(length(info$topics), 1)
})

test_that("vigitel_info data_format contains dta and csv", {
  info <- vigitel_info()
  expect_true(any(grepl("dta|Stata", info$data_format, ignore.case = TRUE)))
  expect_true(any(grepl("csv|CSV", info$data_format, ignore.case = TRUE)))
})

# --- vigitel_years ---

test_that("vigitel_years returns consecutive integers", {
  years <- vigitel_years()
  expect_equal(years, 2006L:2024L)
  # verify consecutive (no gaps)
  expect_equal(diff(years), rep(1L, length(years) - 1))
})

# --- .vigitel_validate_year ---

test_that(".vigitel_validate_year accepts NULL", {
  result <- healthbR:::.vigitel_validate_year(NULL)
  expect_null(result)
})

test_that(".vigitel_validate_year accepts valid single year", {
  result <- healthbR:::.vigitel_validate_year(2010)
  expect_equal(result, 2010L)
})

test_that(".vigitel_validate_year accepts valid year range", {
  result <- healthbR:::.vigitel_validate_year(2010:2015)
  expect_equal(result, 2010L:2015L)
})

test_that(".vigitel_validate_year coerces numeric to integer", {
  result <- healthbR:::.vigitel_validate_year(2020.0)
  expect_type(result, "integer")
  expect_equal(result, 2020L)
})

test_that(".vigitel_validate_year errors on year before range", {
  expect_error(healthbR:::.vigitel_validate_year(2000), "not available")
  expect_error(healthbR:::.vigitel_validate_year(2005), "not available")
})

test_that(".vigitel_validate_year errors on year after range", {
  expect_error(healthbR:::.vigitel_validate_year(2025), "not available")
  expect_error(healthbR:::.vigitel_validate_year(2050), "not available")
})

test_that(".vigitel_validate_year errors on mixed valid/invalid", {
  expect_error(
    healthbR:::.vigitel_validate_year(c(2010, 2050)),
    "not available"
  )
})

# --- vigitel_identify_year_column ---

test_that("vigitel_identify_year_column finds 'ano' column", {
  df <- tibble::tibble(ano = 2020, sexo = "M")
  result <- vigitel_identify_year_column(df)
  expect_equal(result, "ano")
})

test_that("vigitel_identify_year_column finds 'year' column", {
  df <- tibble::tibble(year = 2020, sexo = "M")
  result <- vigitel_identify_year_column(df)
  expect_equal(result, "year")
})

test_that("vigitel_identify_year_column finds uppercase 'ANO'", {
  df <- tibble::tibble(ANO = 2020, sexo = "M")
  result <- vigitel_identify_year_column(df)
  expect_equal(result, "ANO")
})

test_that("vigitel_identify_year_column errors when no year column", {
  df <- tibble::tibble(nome = "test", valor = 1)
  expect_error(vigitel_identify_year_column(df), "year column")
})

test_that("vigitel_identify_year_column returns first match", {
  # if both "ano" and "year" exist, returns the first in the priority list
  df <- tibble::tibble(year = 2020, ano = 2020, sexo = "M")
  result <- vigitel_identify_year_column(df)
  expect_equal(result, "ano")  # "ano" comes first in possible_names
})

# --- .vigitel_try_lazy ---

test_that(".vigitel_try_lazy returns NULL when lazy=FALSE", {
  result <- healthbR:::.vigitel_try_lazy(
    lazy = FALSE, force = FALSE, backend = "arrow",
    cache_dir = tempdir(), year = 2020, vars = NULL
  )
  expect_null(result)
})

test_that(".vigitel_try_lazy returns NULL when force=TRUE", {
  result <- healthbR:::.vigitel_try_lazy(
    lazy = TRUE, force = TRUE, backend = "arrow",
    cache_dir = tempdir(), year = 2020, vars = NULL
  )
  expect_null(result)
})

test_that(".vigitel_try_lazy returns NULL when no cache", {
  temp_dir <- withr::local_tempdir()
  result <- healthbR:::.vigitel_try_lazy(
    lazy = TRUE, force = FALSE, backend = "arrow",
    cache_dir = temp_dir, year = 2020, vars = NULL
  )
  expect_null(result)
})

# --- .vigitel_read_from_cache ---

test_that(".vigitel_read_from_cache errors when no cache dir", {
  temp_dir <- withr::local_tempdir()
  # no vigitel_data subfolder exists, so open_dataset will error
  expect_error(
    healthbR:::.vigitel_read_from_cache(2020, NULL, temp_dir)
  )
})

# --- .vigitel_filter_and_select ---

test_that(".vigitel_filter_and_select filters by year", {
  df <- tibble::tibble(
    ano = c(2020L, 2020L, 2021L, 2022L),
    sexo = c("M", "F", "M", "F"),
    idade = c(30, 40, 50, 60)
  )

  result <- healthbR:::.vigitel_filter_and_select(df, year = 2020, vars = NULL)
  expect_equal(nrow(result), 2)
  expect_true(all(result$ano == 2020L))
})

test_that(".vigitel_filter_and_select filters by multiple years", {
  df <- tibble::tibble(
    ano = c(2020L, 2021L, 2022L, 2023L),
    sexo = c("M", "F", "M", "F"),
    idade = c(30, 40, 50, 60)
  )

  result <- healthbR:::.vigitel_filter_and_select(
    df, year = c(2020, 2022), vars = NULL
  )
  expect_equal(nrow(result), 2)
  expect_equal(sort(result$ano), c(2020L, 2022L))
})

test_that(".vigitel_filter_and_select selects variables", {
  df <- tibble::tibble(
    ano = c(2020L, 2021L),
    sexo = c("M", "F"),
    idade = c(30, 40),
    cidade = c("SP", "RJ")
  )

  result <- healthbR:::.vigitel_filter_and_select(df, year = NULL, vars = "sexo")
  expect_equal(names(result), c("ano", "sexo"))
})

test_that(".vigitel_filter_and_select selects multiple variables", {
  df <- tibble::tibble(
    ano = c(2020L, 2021L),
    sexo = c("M", "F"),
    idade = c(30, 40),
    cidade = c("SP", "RJ")
  )

  result <- healthbR:::.vigitel_filter_and_select(
    df, year = NULL, vars = c("sexo", "idade")
  )
  expect_true(all(c("ano", "sexo", "idade") %in% names(result)))
  expect_false("cidade" %in% names(result))
})

test_that(".vigitel_filter_and_select warns on missing variables", {
  df <- tibble::tibble(
    ano = c(2020L, 2021L),
    sexo = c("M", "F")
  )

  expect_warning(
    healthbR:::.vigitel_filter_and_select(
      df, year = NULL, vars = c("sexo", "nonexistent")
    ),
    "not found"
  )
})

test_that(".vigitel_filter_and_select with no filter/select returns unchanged", {
  df <- tibble::tibble(
    ano = c(2020L, 2021L),
    sexo = c("M", "F"),
    idade = c(30, 40)
  )

  result <- healthbR:::.vigitel_filter_and_select(df, year = NULL, vars = NULL)
  expect_equal(nrow(result), 2)
  expect_equal(ncol(result), 3)
})

test_that(".vigitel_filter_and_select combines year filter and var select", {
  df <- tibble::tibble(
    ano = c(2020L, 2020L, 2021L, 2021L),
    sexo = c("M", "F", "M", "F"),
    idade = c(30, 40, 50, 60),
    cidade = c("SP", "RJ", "BH", "SA")
  )

  result <- healthbR:::.vigitel_filter_and_select(
    df, year = 2020, vars = "sexo"
  )
  expect_equal(nrow(result), 2)
  expect_equal(names(result), c("ano", "sexo"))
})

# --- .vigitel_download_and_cache (mocked) ---

test_that(".vigitel_download_and_cache calls download for new data", {
  temp_dir <- withr::local_tempdir()

  download_called <- FALSE
  extract_called <- FALSE
  read_called <- FALSE

  local_mocked_bindings(
    vigitel_download_data = function(format, destfile) {
      download_called <<- TRUE
      # create a fake zip file
      writeLines("fake", destfile)
      invisible(NULL)
    },
    vigitel_extract_zip = function(zip_path, exdir) {
      extract_called <<- TRUE
      # create a fake data file
      data_path <- file.path(exdir, "vigitel-2006-2024-peso-rake.dta")
      writeLines("fake", data_path)
      data_path
    },
    vigitel_read_data = function(path, format) {
      read_called <<- TRUE
      tibble::tibble(ano = 2020L:2024L, sexo = rep("M", 5))
    },
    .has_arrow = function() FALSE
  )

  result <- healthbR:::.vigitel_download_and_cache("dta", temp_dir, force = FALSE)

  expect_true(download_called)
  expect_true(extract_called)
  expect_true(read_called)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 5)
})

test_that(".vigitel_download_and_cache skips download when data file exists", {
  temp_dir <- withr::local_tempdir()

  # pre-create the data file
  data_path <- file.path(temp_dir, "vigitel-2006-2024-peso-rake.dta")
  writeLines("fake data", data_path)

  download_called <- FALSE

  local_mocked_bindings(
    vigitel_download_data = function(format, destfile) {
      download_called <<- TRUE
      invisible(NULL)
    },
    vigitel_read_data = function(path, format) {
      tibble::tibble(ano = 2020L:2024L, sexo = rep("M", 5))
    },
    .has_arrow = function() FALSE
  )

  result <- healthbR:::.vigitel_download_and_cache("dta", temp_dir, force = FALSE)

  expect_false(download_called)
  expect_s3_class(result, "tbl_df")
})

test_that(".vigitel_download_and_cache force re-downloads", {
  temp_dir <- withr::local_tempdir()

  # pre-create the data file
  data_path <- file.path(temp_dir, "vigitel-2006-2024-peso-rake.csv")
  writeLines("fake data", data_path)

  download_called <- FALSE

  local_mocked_bindings(
    vigitel_download_data = function(format, destfile) {
      download_called <<- TRUE
      writeLines("fake zip", destfile)
      invisible(NULL)
    },
    vigitel_extract_zip = function(zip_path, exdir) {
      extracted <- file.path(exdir, "vigitel-2006-2024-peso-rake.csv")
      writeLines("fake extracted", extracted)
      extracted
    },
    vigitel_read_data = function(path, format) {
      tibble::tibble(ano = 2020L, sexo = "M")
    },
    .has_arrow = function() FALSE
  )

  result <- healthbR:::.vigitel_download_and_cache("csv", temp_dir, force = TRUE)
  expect_true(download_called)
})

# --- vigitel_cache_status (unit) ---

test_that("vigitel_cache_status with custom empty temp dir", {
  temp_dir <- withr::local_tempdir()

  status <- vigitel_cache_status(cache_dir = temp_dir)

  expect_s3_class(status, "tbl_df")
  expect_equal(nrow(status), 6)
  expect_true(all(c("file_type", "exists", "size_mb", "details") %in% names(status)))
  # nothing should exist

  expect_true(all(!status$exists))
})

test_that("vigitel_cache_status detects source files", {
  temp_dir <- withr::local_tempdir()
  cache_dir <- vigitel_cache_dir(temp_dir)

  # create fake files
  writeLines("data", file.path(cache_dir, "vigitel-2006-2024-peso-rake.dta"))
  writeLines("data", file.path(cache_dir, "dicionario-vigitel-2006-2024.xlsx"))

  status <- vigitel_cache_status(cache_dir = temp_dir)

  # DTA should be detected
  dta_row <- status[status$file_type == "Data (Stata)", ]
  expect_true(dta_row$exists)
  expect_false(is.na(dta_row$size_mb))

  # Dictionary should be detected
  dict_row <- status[status$file_type == "Dictionary", ]
  expect_true(dict_row$exists)
})

# --- vigitel_clear_cache ---

test_that("vigitel_clear_cache removes files from cache", {
  temp_dir <- withr::local_tempdir()
  cache_dir <- vigitel_cache_dir(temp_dir)

  # create fake source files
  writeLines("data", file.path(cache_dir, "vigitel-2006-2024-peso-rake.dta"))
  writeLines("zip", file.path(cache_dir, "vigitel-2006-2024-peso-rake-dta.zip"))
  writeLines("dict", file.path(cache_dir, "dicionario-vigitel-2006-2024.xlsx"))

  expect_gt(length(list.files(cache_dir)), 0)

  vigitel_clear_cache(cache_dir = temp_dir)

  # everything should be removed
  expect_equal(length(list.files(cache_dir)), 0)
})

test_that("vigitel_clear_cache keep_parquet removes only source files", {
  temp_dir <- withr::local_tempdir()
  cache_dir <- vigitel_cache_dir(temp_dir)

  # create fake source file
  writeLines("data", file.path(cache_dir, "vigitel-2006-2024-peso-rake.dta"))
  writeLines("zip", file.path(cache_dir, "vigitel-2006-2024-peso-rake-dta.zip"))

  # create fake parquet directory
  parquet_dir <- file.path(cache_dir, "vigitel_data", "ano=2020")
  dir.create(parquet_dir, recursive = TRUE)
  writeLines("parquet", file.path(parquet_dir, "part-0.parquet"))

  vigitel_clear_cache(keep_parquet = TRUE, cache_dir = temp_dir)

  # source files should be removed
  expect_false(file.exists(file.path(cache_dir, "vigitel-2006-2024-peso-rake.dta")))
  expect_false(file.exists(file.path(cache_dir, "vigitel-2006-2024-peso-rake-dta.zip")))
  # parquet should still exist
  expect_true(dir.exists(file.path(cache_dir, "vigitel_data")))
})

# --- has_partitioned_cache ---

test_that("has_partitioned_cache returns FALSE when no cache", {
  temp_dir <- withr::local_tempdir()
  cache_dir <- vigitel_cache_dir(temp_dir)
  expect_false(has_partitioned_cache(cache_dir))
})

test_that("has_partitioned_cache returns TRUE with subdirectories", {
  temp_dir <- withr::local_tempdir()
  cache_dir <- vigitel_cache_dir(temp_dir)
  dir.create(file.path(cache_dir, "vigitel_data", "ano=2020"), recursive = TRUE)
  expect_true(has_partitioned_cache(cache_dir))
})

# --- create_partitioned_cache (mocked) ---

test_that("create_partitioned_cache warns when arrow not available", {
  local_mocked_bindings(.has_arrow = function() FALSE)

  df <- tibble::tibble(ano = 2020L, sexo = "M")
  temp_dir <- withr::local_tempdir()

  expect_warning(
    create_partitioned_cache(df, temp_dir),
    "arrow"
  )
})

# --- vigitel_data mocked download path ---

test_that("vigitel_data returns tibble via mocked download path", {
  temp_dir <- withr::local_tempdir()

  local_mocked_bindings(
    has_partitioned_cache = function(cache_dir) FALSE,
    .has_arrow = function() FALSE,
    .vigitel_download_and_cache = function(format, cache_dir, force) {
      tibble::tibble(
        ano = c(2020L, 2020L, 2021L, 2021L),
        sexo = c("M", "F", "M", "F"),
        pesorake = c(1.0, 1.1, 0.9, 1.2)
      )
    }
  )

  result <- vigitel_data(year = 2020, cache_dir = temp_dir)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_true(all(result$ano == 2020L))
})

test_that("vigitel_data selects vars via mocked download", {
  temp_dir <- withr::local_tempdir()

  local_mocked_bindings(
    has_partitioned_cache = function(cache_dir) FALSE,
    .has_arrow = function() FALSE,
    .vigitel_download_and_cache = function(format, cache_dir, force) {
      tibble::tibble(
        ano = c(2020L, 2020L),
        sexo = c("M", "F"),
        pesorake = c(1.0, 1.1),
        cidade = c("SP", "RJ")
      )
    }
  )

  result <- vigitel_data(year = 2020, vars = "sexo", cache_dir = temp_dir)

  expect_true("sexo" %in% names(result))
  expect_true("ano" %in% names(result))
  expect_false("cidade" %in% names(result))
})

test_that("vigitel_data with NULL year returns all years via mock", {
  temp_dir <- withr::local_tempdir()

  local_mocked_bindings(
    has_partitioned_cache = function(cache_dir) FALSE,
    .has_arrow = function() FALSE,
    .vigitel_download_and_cache = function(format, cache_dir, force) {
      tibble::tibble(
        ano = c(2020L, 2021L, 2022L),
        sexo = c("M", "F", "M")
      )
    }
  )

  result <- vigitel_data(year = NULL, cache_dir = temp_dir)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3)
})

test_that("vigitel_data format='csv' is passed through", {
  temp_dir <- withr::local_tempdir()
  used_format <- NULL

  local_mocked_bindings(
    has_partitioned_cache = function(cache_dir) FALSE,
    .has_arrow = function() FALSE,
    .vigitel_download_and_cache = function(format, cache_dir, force) {
      used_format <<- format
      tibble::tibble(ano = 2020L, sexo = "M")
    }
  )

  vigitel_data(year = 2020, format = "csv", cache_dir = temp_dir)
  expect_equal(used_format, "csv")
})

test_that("vigitel_data invalid format errors", {
  temp_dir <- withr::local_tempdir()
  expect_error(
    vigitel_data(year = 2020, format = "xlsx", cache_dir = temp_dir),
    "arg"
  )
})

# --- get_arrow_column_names ---

test_that("get_arrow_column_names returns names from a data frame", {
  df <- tibble::tibble(a = 1, b = 2, c = 3)
  result <- get_arrow_column_names(df)
  expect_equal(result, c("a", "b", "c"))
})

# --- vigitel_download_data (mocked error) ---

test_that("vigitel_download_data errors on download failure", {
  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      stop("Connection refused")
    },
    .package = "curl"
  )

  temp_file <- tempfile(fileext = ".zip")
  on.exit(if (file.exists(temp_file)) file.remove(temp_file), add = TRUE)

  expect_error(
    vigitel_download_data("dta", temp_file),
    "Download failed"
  )
})

# --- vigitel_extract_zip ---

test_that("vigitel_extract_zip extracts file from zip", {
  temp_dir <- withr::local_tempdir()

  # create a real zip for extraction
  data_file <- file.path(temp_dir, "test_data.csv")
  writeLines("a,b\n1,2", data_file)
  zip_path <- file.path(temp_dir, "test.zip")
  utils::zip(zip_path, data_file, flags = "-j")

  exdir <- file.path(temp_dir, "extracted")
  dir.create(exdir)

  result <- vigitel_extract_zip(zip_path, exdir)
  expect_true(file.exists(result))
})

# --- vigitel_read_data ---

test_that("vigitel_read_data reads CSV format", {
  temp_dir <- withr::local_tempdir()
  csv_path <- file.path(temp_dir, "test.csv")
  writeLines("ano,sexo\n2020,M\n2021,F", csv_path)

  result <- vigitel_read_data(csv_path, "csv")
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_true("ano" %in% names(result))
})
