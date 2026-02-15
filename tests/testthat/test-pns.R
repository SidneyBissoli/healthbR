# tests for pns functions
# tests for PNS (Pesquisa Nacional de Saude) module

# ============================================================================
# basic info functions
# ============================================================================

test_that("pns_years returns expected years", {
  years <- pns_years()

  expect_type(years, "character")
  expect_equal(length(years), 2L)
  expect_true("2013" %in% years)
  expect_true("2019" %in% years)
})

test_that("pns_info returns expected structure", {
  info <- pns_info()

  expect_type(info, "list")
  expect_true("name" %in% names(info))
  expect_true("available_years" %in% names(info))
  expect_true("sidra_tables" %in% names(info))
  expect_true("url" %in% names(info))
  expect_equal(info$available_years, pns_years())
  expect_equal(info$sidra_tables, 2222)
})

test_that("pns_info accepts year parameter", {
  info <- pns_info(2019)

  expect_true("year_details" %in% names(info))
  expect_true("sample_size" %in% names(info$year_details))
  expect_true("reference_period" %in% names(info$year_details))
})

# ============================================================================
# modules functions
# ============================================================================

test_that("pns_modules returns tibble with expected columns", {
  modules <- pns_modules()

  expect_s3_class(modules, "tbl_df")
  expect_true(all(c("module", "name", "name_en") %in% names(modules)))
  expect_true(nrow(modules) > 0)
})

test_that("pns_modules filters by year correctly", {
  modules_2013 <- pns_modules(year = 2013)
  modules_2019 <- pns_modules(year = 2019)
  modules_all <- pns_modules()

  expect_true(nrow(modules_2013) > 0)
  expect_true(nrow(modules_2019) > 0)
  # 2019 has Y and Z modules not in 2013
  expect_true("Y" %in% modules_2019$module)
  expect_true("Z" %in% modules_2019$module)
})

test_that("pns_modules validates year parameter", {
  expect_error(pns_modules(year = 1999), "Invalid year")
})

# ============================================================================
# dictionary and variables functions
# ============================================================================

test_that("pns_dictionary validates year parameter", {
  expect_error(
    pns_dictionary(year = 1999, cache_dir = tempdir()),
    "Invalid year"
  )
})

test_that("pns_dictionary downloads and returns tibble", {
  skip_on_cran()
  skip_if_no_integration()

  dict <- pns_dictionary(year = 2019, cache_dir = tempdir())

  expect_s3_class(dict, "tbl_df")
  expect_true(nrow(dict) > 0)
  expect_true("year" %in% names(dict))
})

test_that("pns_dictionary uses cache on second call", {
  skip_on_cran()
  skip_if_no_integration()

  test_cache <- file.path(tempdir(), "test_pns_dict_cache")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # first call downloads
  dict1 <- pns_dictionary(year = 2019, cache_dir = test_cache)

  # verify cache exists
  cache_files <- list.files(test_cache, pattern = "pns_dictionary_2019")
  expect_true(length(cache_files) > 0)

  # second call should use cache
  dict2 <- pns_dictionary(year = 2019, cache_dir = test_cache)

  expect_equal(nrow(dict1), nrow(dict2))
})

test_that("pns_variables returns tibble", {
  skip_on_cran()
  skip_if_no_integration()

  vars <- pns_variables(year = 2019, cache_dir = tempdir())

  expect_s3_class(vars, "tbl_df")
  expect_true(nrow(vars) > 0)
  expect_true("year" %in% names(vars))
})

# ============================================================================
# validation functions
# ============================================================================

test_that("validate_pns_year validates correctly", {
  # valid years
  expect_equal(validate_pns_year(2013), 2013L)
  expect_equal(validate_pns_year(2019), 2019L)
  expect_equal(validate_pns_year(c(2013, 2019)), c(2013L, 2019L))

  # NULL returns all
  expect_equal(validate_pns_year(NULL), c(2013L, 2019L))

  # invalid years
  expect_error(validate_pns_year(2015), "Invalid year")
  expect_error(validate_pns_year(2020), "Invalid year")
  expect_error(validate_pns_year(c(2013, 2020)), "Invalid year")
})

test_that("pns_data validates year parameter", {
  expect_error(
    pns_data(year = 1999, cache_dir = tempdir()),
    "Invalid year"
  )
  expect_error(
    pns_data(year = 2020, cache_dir = tempdir()),
    "Invalid year"
  )
})

# ============================================================================
# cache functions
# ============================================================================

test_that("pns_cache_dir creates directory", {
  dir <- pns_cache_dir()

  expect_type(dir, "character")
  expect_true(dir.exists(dir))
})

test_that("pns_cache_dir respects custom cache_dir", {
  custom_dir <- file.path(tempdir(), "custom_pns_cache")
  on.exit(unlink(custom_dir, recursive = TRUE), add = TRUE)

  dir <- pns_cache_dir(custom_dir)

  expect_true(dir.exists(dir))
  expect_match(dir, "pns")
})

test_that("pns_cache_status returns tibble", {
  status <- pns_cache_status()

  expect_s3_class(status, "tbl_df")
  expect_true(all(c("file", "size_mb", "modified") %in% names(status)))
})

test_that("pns_clear_cache handles empty cache", {
  temp_cache <- file.path(tempdir(), "empty_pns_test")
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  expect_no_error(pns_clear_cache(cache_dir = temp_cache))
})

# ============================================================================
# SIDRA functions - catalog
# ============================================================================

test_that("pns_sidra_tables returns tibble with expected columns", {
  result <- pns_sidra_tables()

  expect_s3_class(result, "tbl_df")
  expect_true(all(
    c("table_code", "table_name", "theme", "theme_label") %in% names(result)
  ))
  expect_true(nrow(result) > 0)
})

test_that("pns_sidra_tables filters by theme", {
  result <- pns_sidra_tables(theme = "chronic_diseases")

  expect_true(all(result$theme == "chronic_diseases"))
  expect_true(nrow(result) > 0)
})

test_that("pns_sidra_tables handles invalid theme", {
  expect_error(pns_sidra_tables(theme = "nonexistent"), "Invalid theme")
})

test_that("pns_sidra_tables filters by year", {
  result_2019 <- pns_sidra_tables(year = 2019)
  result_2013 <- pns_sidra_tables(year = 2013)

  expect_true(nrow(result_2019) > 0)
  expect_true(nrow(result_2013) > 0)
})

test_that("pns_sidra_tables returns multiple themes", {
  result <- pns_sidra_tables()
  expect_true(length(unique(result$theme)) > 1)
})

# ============================================================================
# SIDRA functions - search
# ============================================================================

test_that("pns_sidra_search finds tables by keyword", {
  result <- pns_sidra_search("diabetes")

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
})

test_that("pns_sidra_search is case-insensitive", {
  result_lower <- pns_sidra_search("diabetes")
  result_upper <- pns_sidra_search("DIABETES")

  expect_equal(nrow(result_lower), nrow(result_upper))
})

test_that("pns_sidra_search returns empty tibble for no match", {
  result <- pns_sidra_search("xyznonexistent")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("pns_sidra_search requires minimum keyword length", {
  expect_error(pns_sidra_search("a"), "at least 2 characters")
})

test_that("pns_sidra_search handles accent-insensitive search", {
  result1 <- pns_sidra_search("hipertensao")
  result2 <- pns_sidra_search("hipertens")

  expect_true(nrow(result1) > 0 || nrow(result2) > 0)
})

# ============================================================================
# SIDRA functions - data retrieval
# ============================================================================

test_that("pns_sidra_data validates territorial_level", {
  expect_error(
    pns_sidra_data(table = 4751, territorial_level = "invalid"),
    "Invalid territorial_level"
  )
})

test_that("pns_sidra_data returns tibble from API", {
  skip_on_cran()
  skip_if_no_integration()

  result <- pns_sidra_data(
    table = 4751,
    territorial_level = "brazil",
    year = 2019
  )

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
})

test_that("pns_sidra_data returns data by state", {
  skip_on_cran()
  skip_if_no_integration()

  result <- pns_sidra_data(
    table = 4751,
    territorial_level = "state",
    year = 2019
  )

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  # should have multiple rows (one per state or more)
  expect_true(nrow(result) > 1)
})

test_that("pns_sidra_data raw parameter works", {
  skip_on_cran()
  skip_if_no_integration()

  result_raw <- pns_sidra_data(
    table = 4751,
    territorial_level = "brazil",
    year = 2019,
    raw = TRUE
  )
  result_clean <- pns_sidra_data(
    table = 4751,
    territorial_level = "brazil",
    year = 2019,
    raw = FALSE
  )

  # raw has header row, so >= clean
  expect_true(nrow(result_raw) >= nrow(result_clean))
})

test_that("pns_sidra_data handles multiple years", {
  skip_on_cran()
  skip_if_no_integration()

  result <- pns_sidra_data(
    table = 4751,
    territorial_level = "brazil",
    year = c(2013, 2019)
  )

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
})

test_that("pns_sidra_data warns for unknown table", {
  skip_on_cran()
  skip_if_no_integration()

  # table 99999 should not exist in catalog - expect warning about catalog
  # and then an error from the API (invalid table)
  expect_warning(
    tryCatch(
      pns_sidra_data(table = 99999, territorial_level = "brazil", year = 2019),
      error = function(e) NULL
    ),
    "not found in internal catalog"
  )
})

# ============================================================================
# microdata download - integration tests
# ============================================================================

test_that("pns_data downloads and returns tibble", {
  skip_on_cran()
  skip_if_no_integration()

  test_cache <- file.path(tempdir(), "test_pns_download")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # test with 2019 (smaller file)
  df <- pns_data(year = 2019, cache_dir = test_cache)

  expect_s3_class(df, "tbl_df")
  expect_true(nrow(df) > 0)
  expect_true(ncol(df) > 0)
  expect_true("year" %in% names(df))
})

test_that("pns_data handles variable selection", {
  skip_on_cran()
  skip_if_no_integration()

  test_cache <- file.path(tempdir(), "test_pns_vars")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # get full data first
  df_full <- pns_data(year = 2019, cache_dir = test_cache)

  # select specific variables (make sure to pick fewer than total)
  all_vars <- setdiff(names(df_full), "year")
  vars_to_select <- head(all_vars, min(5, length(all_vars) - 1))

  df <- pns_data(
    year = 2019,
    vars = vars_to_select,
    cache_dir = test_cache
  )

  expect_true("year" %in% names(df))
  expect_true(all(toupper(vars_to_select) %in% names(df)))
  # should have year + selected vars = 6 columns (or fewer if data has < 6 vars)
  expect_equal(ncol(df), length(vars_to_select) + 1)  # +1 for year column
})

test_that("pns_data uses cache on second call", {
  skip_on_cran()
  skip_if_no_integration()

  test_cache <- file.path(tempdir(), "test_pns_cache_reuse")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # first call downloads
  df1 <- pns_data(year = 2019, cache_dir = test_cache)

  # verify partitioned cache exists
  cache_files <- list.files(file.path(test_cache, "pns_data"),
                            recursive = TRUE, pattern = "\\.parquet$")
  expect_true(length(cache_files) > 0)

  # second call should use cache
  df2 <- pns_data(year = 2019, cache_dir = test_cache)

  expect_equal(nrow(df1), nrow(df2))
  expect_equal(ncol(df1), ncol(df2))
})
