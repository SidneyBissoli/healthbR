# tests for vigitel functions

test_that("vigitel_years returns expected years", {

years <- vigitel_years()

  expect_type(years, "integer")
  expect_true(2006L %in% years)
  expect_true(2023L %in% years)
  expect_false(2022L %in% years)  # 2022 is not available
})

test_that("vigitel_base_url returns valid URL", {
  url <- vigitel_base_url()

  expect_type(url, "character")
  expect_match(url, "^https://")
  expect_match(url, "Vigitel")
})

test_that("vigitel_file_url builds correct URLs", {
  url_2023 <- vigitel_file_url(2023)
  url_2021 <- vigitel_file_url(2021)

  expect_match(url_2023, "\\.xlsx$")
  expect_match(url_2021, "\\.xls$")
  expect_match(url_2023, "2023")
})

test_that("vigitel_file_url errors for invalid years", {
  expect_error(vigitel_file_url(2022))
  expect_error(vigitel_file_url(2005))
  expect_error(vigitel_file_url(2030))
})

test_that("vigitel_info returns expected structure", {
  info <- vigitel_info()

  expect_type(info, "list")
  expect_true("name" %in% names(info))
  expect_true("years_available" %in% names(info))
  expect_true("weight_variable" %in% names(info))
  expect_equal(info$weight_variable, "pesorake")
})

test_that("vigitel_cache_dir creates directory", {
  dir <- vigitel_cache_dir()

  expect_type(dir, "character")
  expect_true(dir.exists(dir))
})

# tests for vigitel_parse_years
test_that("vigitel_parse_years handles single year", {
  result <- vigitel_parse_years(2023)
  expect_equal(result, 2023L)
})

test_that("vigitel_parse_years handles vector of years", {
  result <- vigitel_parse_years(c(2021, 2023))
  expect_equal(result, c(2021L, 2023L))
})

test_that("vigitel_parse_years handles range", {
  expect_warning(
    result <- vigitel_parse_years(2020:2023),
    "not available"
  )
  expect_equal(result, c(2020L, 2021L, 2023L))  # 2022 excluded
})

test_that("vigitel_parse_years warns for partially unavailable years", {
  # when some years are valid, some invalid -> warning

  expect_warning(
    result <- vigitel_parse_years(c(2021, 2022, 2023)),
    "not available"
  )
  expect_equal(result, c(2021L, 2023L))
})

test_that("vigitel_parse_years errors when all years unavailable", {
  # when ALL years are invalid -> error
  expect_error(vigitel_parse_years(2022), "No valid years")
  expect_error(vigitel_parse_years(c(2022, 2024)), "No valid years")
})

# tests for path functions
test_that("vigitel_excel_path returns correct extension", {
  path_xlsx <- vigitel_excel_path(2023)
  path_xls <- vigitel_excel_path(2021)

  expect_match(path_xlsx, "\\.xlsx$")
  expect_match(path_xls, "\\.xls$")
})

test_that("vigitel_parquet_path returns .parquet extension", {
  path <- vigitel_parquet_path(2023)
  expect_match(path, "\\.parquet$")
  expect_match(path, "2023")
})

# integration tests - skip on CRAN due to downloads
test_that("vigitel_dictionary downloads and parses correctly", {
  skip_on_cran()
  skip_if_offline()

  dict <- vigitel_dictionary()

  expect_s3_class(dict, "tbl_df")
  expect_true("variable_name" %in% names(dict))
  expect_true(nrow(dict) > 0)
})

test_that("vigitel_variables returns character vector", {
  skip_on_cran()
  skip_if_offline()

  vars <- vigitel_variables(2023)

  expect_type(vars, "character")
  expect_true(length(vars) > 0)
  expect_true("pesorake" %in% vars)
})

test_that("vigitel_data downloads and returns tibble", {
  skip_on_cran()
  skip_if_offline()

  df <- vigitel_data(2023)

  expect_s3_class(df, "tbl_df")
  expect_true("pesorake" %in% names(df))
  expect_true("ano" %in% names(df) || "year" %in% names(df))
  expect_true(nrow(df) > 0)
})

test_that("vigitel_data with lazy returns Arrow Dataset", {
  skip_on_cran()
  skip_if_offline()

  # ensure parquet exists first
  vigitel_data(2023)
  vigitel_convert_to_parquet(2023)

  df_lazy <- vigitel_data(2023, lazy = TRUE)

  expect_true(
    inherits(df_lazy, "ArrowObject") ||
    inherits(df_lazy, "arrow_dplyr_query") ||
    inherits(df_lazy, "Dataset")
  )
})

test_that("vigitel_data handles multiple years", {
  skip_on_cran()
  skip_if_offline()

  df <- vigitel_data(c(2021, 2023))

  expect_s3_class(df, "tbl_df")
  expect_true(all(c(2021, 2023) %in% unique(df$ano)))
})

test_that("vigitel_convert_to_parquet creates parquet files", {
  skip_on_cran()
  skip_if_offline()

  # download first

  vigitel_data(2023)

  # convert
  vigitel_convert_to_parquet(2023)

  # check file exists
  parquet_path <- vigitel_parquet_path(2023)
  expect_true(file.exists(parquet_path))
})

test_that("vigitel_cache_status returns tibble", {
  skip_on_cran()
  skip_if_offline()

  status <- vigitel_cache_status()

  expect_s3_class(status, "tbl_df")
  expect_true(all(c("year", "excel_cached", "parquet_cached") %in% names(status)))
})
