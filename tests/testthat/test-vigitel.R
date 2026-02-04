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
  skip_if_offline()

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
  skip_if_offline()

  test_cache <- file.path(tempdir(), "test_dictionary")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  dict <- vigitel_dictionary(cache_dir = test_cache)

  expect_s3_class(dict, "tbl_df")
  expect_true(nrow(dict) > 0)
})

test_that("vigitel_variables returns tibble", {
  skip_on_cran()
  skip_if_offline()

  test_cache <- file.path(tempdir(), "test_variables")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  vars <- vigitel_variables(cache_dir = test_cache)

  expect_s3_class(vars, "tbl_df")
  expect_true(nrow(vars) > 0)
})

test_that("vigitel_data downloads and returns tibble", {
  skip_on_cran()
  skip_if_offline()

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
  skip_if_offline()

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
  skip_if_offline()

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
  skip_if_offline()

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
  skip_if_offline()

  test_cache <- file.path(tempdir(), "test_csv_format")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # test csv format
  df_csv <- vigitel_data(year = 2024, format = "csv", cache_dir = test_cache)

  expect_s3_class(df_csv, "tbl_df")
  expect_true(nrow(df_csv) > 0)
})
