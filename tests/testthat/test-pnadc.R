# tests for pnadc functions
# tests for PNADC (PNAD Continua) module

# ============================================================================
# basic info functions
# ============================================================================

test_that("pnadc_modules returns expected structure", {
  modules <- pnadc_modules()

  expect_s3_class(modules, "tbl_df")
  expect_true(all(c("module", "name", "name_en", "years", "description") %in% names(modules)))
  expect_true(nrow(modules) >= 4)

  # check expected modules exist
  expect_true("deficiencia" %in% modules$module)
  expect_true("habitacao" %in% modules$module)
  expect_true("moradores" %in% modules$module)
  expect_true("aps" %in% modules$module)
})

test_that("pnadc_years returns expected years for each module", {
  # deficiencia has 2019, 2022, 2024
  years_def <- pnadc_years("deficiencia")
  expect_type(years_def, "integer")
  expect_true(2022L %in% years_def)
  expect_true(length(years_def) >= 3)

  # habitacao has multiple years
  years_hab <- pnadc_years("habitacao")
  expect_type(years_hab, "integer")
  expect_true(2012L %in% years_hab)
  expect_true(2024L %in% years_hab)
  expect_true(length(years_hab) >= 10)

  # moradores has same years as habitacao
  years_mor <- pnadc_years("moradores")
  expect_type(years_mor, "integer")
  expect_equal(years_hab, years_mor)

  # aps only has 2022
  years_aps <- pnadc_years("aps")
  expect_type(years_aps, "integer")
  expect_equal(years_aps, 2022L)
})

test_that("pnadc_years validates module parameter", {
  expect_error(pnadc_years("invalid"), "Invalid module")
  expect_error(pnadc_years(NULL), "must be specified")
})

test_that("pnadc_info returns expected structure", {
  info <- pnadc_info()

  expect_type(info, "list")
  expect_true("name" %in% names(info))
  expect_true("modules" %in% names(info))
  expect_true("survey_design" %in% names(info))
  expect_true("url" %in% names(info))
  expect_true("ftp_url" %in% names(info))

  # check survey design info
  expect_equal(info$survey_design$psu, "UPA")
  expect_equal(info$survey_design$strata, "Estrato")
  expect_equal(info$survey_design$weight, "V1028")
})

# ============================================================================
# validation functions
# ============================================================================

test_that("validate_pnadc_module validates correctly", {
  # valid modules
  expect_equal(validate_pnadc_module("deficiencia"), "deficiencia")
  expect_equal(validate_pnadc_module("habitacao"), "habitacao")
  expect_equal(validate_pnadc_module("DEFICIENCIA"), "deficiencia")

  # invalid modules
  expect_error(validate_pnadc_module("invalid"), "Invalid module")
  expect_error(validate_pnadc_module(NULL), "must be specified")
  expect_error(validate_pnadc_module(c("deficiencia", "habitacao")), "must be specified")
})

test_that("validate_pnadc_year validates correctly for deficiencia module", {
  # valid year
  expect_equal(validate_pnadc_year(2022, "deficiencia"), 2022L)

  # NULL returns all available
  all_years <- validate_pnadc_year(NULL, "deficiencia")
  expect_true(2022L %in% all_years)

  # invalid year
  expect_error(validate_pnadc_year(2021, "deficiencia"), "Invalid year")
  expect_error(validate_pnadc_year(2023, "deficiencia"), "Invalid year")
})

test_that("validate_pnadc_year validates correctly for habitacao module", {
  # valid years
  expect_equal(validate_pnadc_year(2016, "habitacao"), 2016L)
  expect_equal(validate_pnadc_year(2024, "habitacao"), 2024L)
  expect_equal(validate_pnadc_year(2015, "habitacao"), 2015L)
  expect_equal(validate_pnadc_year(c(2018, 2019), "habitacao"), c(2018L, 2019L))

  # NULL returns all available
  all_years <- validate_pnadc_year(NULL, "habitacao")
  expect_true(2016L %in% all_years)
  expect_true(2024L %in% all_years)
  expect_true(2015L %in% all_years)

  # invalid year (2020, 2021 not available in FTP)
  expect_error(validate_pnadc_year(2020, "habitacao"), "Invalid year")
  expect_error(validate_pnadc_year(2021, "habitacao"), "Invalid year")
})

# ============================================================================
# URL building functions
# ============================================================================

test_that("pnadc_find_data_url builds correct URLs for trimestre modules", {
  skip_on_cran()
  skip_if_offline()

  # deficiencia is trimestre 3
  url_info <- pnadc_find_data_url("deficiencia", 2022)

  expect_type(url_info, "list")
  expect_true("data_url" %in% names(url_info))
  expect_true("data_filename" %in% names(url_info))

  expect_match(url_info$data_url, "Trimestre_3")
  expect_match(url_info$data_url, "2022")
  expect_match(url_info$data_filename, "trimestre3")

  # aps is trimestre 2
  url_info_aps <- pnadc_find_data_url("aps", 2022)
  expect_match(url_info_aps$data_url, "Trimestre_2")
})

test_that("pnadc_find_data_url builds correct URLs for visita modules", {
  skip_on_cran()
  skip_if_offline()

  # habitacao and moradores are visita 1
  url_info <- pnadc_find_data_url("habitacao", 2022)

  expect_match(url_info$data_url, "Visita_1")
  expect_match(url_info$data_url, "2022")
  expect_match(url_info$data_filename, "visita1")
})

# ============================================================================
# cache functions
# ============================================================================

test_that("pnadc_cache_dir creates directory", {
  dir <- pnadc_cache_dir()

  expect_type(dir, "character")
  expect_true(dir.exists(dir))
  expect_match(dir, "pnadc")
})

test_that("pnadc_cache_dir respects custom cache_dir", {
  custom_dir <- file.path(tempdir(), "custom_pnadc_cache")
  on.exit(unlink(custom_dir, recursive = TRUE), add = TRUE)

  dir <- pnadc_cache_dir(custom_dir)

  expect_true(dir.exists(dir))
  expect_match(dir, "pnadc")
})

test_that("pnadc_cache_status returns tibble", {
  status <- pnadc_cache_status()

  expect_s3_class(status, "tbl_df")
  expect_true(all(c("file", "module", "year", "size_mb", "modified") %in% names(status)))
})

test_that("pnadc_clear_cache handles empty cache", {
  temp_cache <- file.path(tempdir(), "empty_pnadc_test")
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  expect_no_error(pnadc_clear_cache(cache_dir = temp_cache))
})

test_that("pnadc_clear_cache validates module parameter", {
  expect_error(
    pnadc_clear_cache(module = "invalid", cache_dir = tempdir()),
    "Invalid module"
  )
})

# ============================================================================
# helper function tests
# ============================================================================

test_that("pnadc_has_arrow returns logical", {
  result <- pnadc_has_arrow()
  expect_type(result, "logical")
})

test_that("pnadc_has_srvyr returns logical", {
  result <- pnadc_has_srvyr()
  expect_type(result, "logical")
})

test_that("pnadc_required_vars returns expected variables", {
  vars <- pnadc_required_vars()

  expect_type(vars, "character")
  expect_true("UPA" %in% vars)
  expect_true("Estrato" %in% vars)
  expect_true("V1028" %in% vars)
  expect_true("UF" %in% vars)
  expect_true("Ano" %in% vars)
})

# ============================================================================
# dictionary and variables - validation tests
# ============================================================================

test_that("pnadc_dictionaries validates module parameter", {
  expect_error(
    pnadc_dictionaries(module = "invalid", cache_dir = tempdir()),
    "Invalid module"
  )
})

test_that("pnadc_dictionaries validates year parameter", {
  expect_error(
    pnadc_dictionaries(module = "deficiencia", year = 2021, cache_dir = tempdir()),
    "Invalid year"
  )
})

test_that("pnadc_variables validates module parameter", {
  expect_error(
    pnadc_variables(module = "invalid", cache_dir = tempdir()),
    "Invalid module"
  )
})

# ============================================================================
# data download - validation tests
# ============================================================================

test_that("pnadc_data validates module parameter", {
  expect_error(
    pnadc_data(module = "invalid", cache_dir = tempdir()),
    "Invalid module"
  )
})

test_that("pnadc_data validates year parameter", {
  expect_error(
    pnadc_data(module = "deficiencia", year = 2021, cache_dir = tempdir()),
    "Invalid year"
  )
  # 2020 and 2021 are not available for habitacao
  expect_error(
    pnadc_data(module = "habitacao", year = 2020, cache_dir = tempdir()),
    "Invalid year"
  )
})

# ============================================================================
# integration tests - require internet
# ============================================================================

test_that("pnadc_dictionaries downloads and returns tibble", {
  skip_on_cran()
  skip_if_offline()

  test_cache <- file.path(tempdir(), "test_pnadc_dict")
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  dict <- pnadc_dictionaries(
    module = "deficiencia",
    year = 2022,
    cache_dir = test_cache
  )

  expect_s3_class(dict, "tbl_df")
  expect_true(nrow(dict) > 0)
  expect_true("variable" %in% names(dict))
  expect_true("position" %in% names(dict))
  expect_true("width" %in% names(dict))
  expect_true("year" %in% names(dict))
  expect_true("module" %in% names(dict))
})

test_that("pnadc_dictionaries uses cache on second call", {
  skip_on_cran()
  skip_if_offline()

  test_cache <- file.path(tempdir(), "test_pnadc_dict_cache")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # first call downloads
  dict1 <- pnadc_dictionaries(
    module = "deficiencia",
    year = 2022,
    cache_dir = test_cache
  )

  # verify cache exists
  cache_files <- list.files(
    file.path(test_cache, "pnadc"),
    pattern = "pnadc_dict_deficiencia_2022"
  )
  expect_true(length(cache_files) > 0)

  # second call should use cache
  dict2 <- pnadc_dictionaries(
    module = "deficiencia",
    year = 2022,
    cache_dir = test_cache
  )

  expect_equal(nrow(dict1), nrow(dict2))
})

test_that("pnadc_variables returns character vector", {
  skip_on_cran()
  skip_if_offline()

  test_cache <- file.path(tempdir(), "test_pnadc_vars")
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  vars <- pnadc_variables(
    module = "deficiencia",
    year = 2022,
    cache_dir = test_cache
  )

  expect_type(vars, "character")
  expect_true(length(vars) > 0)
})

test_that("pnadc_data downloads and returns tibble", {
  skip_on_cran()
  skip_if_offline()

  test_cache <- file.path(tempdir(), "test_pnadc_download")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # test with deficiencia module (2022)
  df <- pnadc_data(
    module = "deficiencia",
    year = 2022,
    cache_dir = test_cache
  )

  expect_s3_class(df, "tbl_df")
  expect_true(nrow(df) > 0)
  expect_true(ncol(df) > 0)

  # check for survey design variables
  expect_true("UPA" %in% names(df))
  expect_true("Estrato" %in% names(df))
  expect_true("V1028" %in% names(df))

  # check for module identifier
  expect_true("pnadc_module" %in% names(df))
  expect_equal(unique(df$pnadc_module), "deficiencia")
})

test_that("pnadc_data handles variable selection", {
  skip_on_cran()
  skip_if_offline()

  test_cache <- file.path(tempdir(), "test_pnadc_vars_select")
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # select specific variables
  df <- pnadc_data(
    module = "deficiencia",
    year = 2022,
    vars = c("S11001", "S11002"),
    cache_dir = test_cache
  )

  # should have requested vars plus required vars
  expect_true("pnadc_module" %in% names(df))

  # survey design vars should always be present
  expect_true("UPA" %in% names(df))
  expect_true("Estrato" %in% names(df))
  expect_true("V1028" %in% names(df))
})

test_that("pnadc_data uses cache on second call", {
  skip_on_cran()
  skip_if_offline()

  test_cache <- file.path(tempdir(), "test_pnadc_cache_reuse")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # first call downloads
  df1 <- pnadc_data(
    module = "deficiencia",
    year = 2022,
    cache_dir = test_cache
  )

  # verify cache exists
  cache_files <- list.files(
    file.path(test_cache, "pnadc"),
    pattern = "pnadc_deficiencia_2022"
  )
  expect_true(length(cache_files) > 0)

  # second call should use cache
  df2 <- pnadc_data(
    module = "deficiencia",
    year = 2022,
    cache_dir = test_cache
  )

  expect_equal(nrow(df1), nrow(df2))
  expect_equal(ncol(df1), ncol(df2))
})

test_that("pnadc_data returns survey design when as_survey = TRUE", {
  skip_on_cran()
  skip_if_offline()
  skip_if_not_installed("srvyr")

  test_cache <- file.path(tempdir(), "test_pnadc_survey")
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  svy <- pnadc_data(
    module = "deficiencia",
    year = 2022,
    as_survey = TRUE,
    cache_dir = test_cache
  )

  expect_s3_class(svy, "tbl_svy")
})

test_that("pnadc_data errors when as_survey = TRUE and srvyr not installed", {
  skip_on_cran()
  skip_if_offline()

  # temporarily unload srvyr if it exists
  if (requireNamespace("srvyr", quietly = TRUE)) {
    skip("srvyr is installed, cannot test missing package error")
  }

  test_cache <- file.path(tempdir(), "test_pnadc_no_srvyr")
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  expect_error(
    pnadc_data(
      module = "deficiencia",
      year = 2022,
      as_survey = TRUE,
      cache_dir = test_cache
    ),
    "srvyr"
  )
})

# ============================================================================
# cache status after downloads
# ============================================================================

test_that("pnadc_cache_status shows cached files", {
  skip_on_cran()
  skip_if_offline()

  test_cache <- file.path(tempdir(), "test_pnadc_status")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # download some data
  df <- pnadc_data(
    module = "deficiencia",
    year = 2022,
    cache_dir = test_cache
  )

  # check cache status
  status <- pnadc_cache_status(cache_dir = test_cache)

  expect_s3_class(status, "tbl_df")
  expect_true(nrow(status) > 0)
  expect_true(any(status$module == "deficiencia"))
  expect_true(any(status$year == 2022))
})

test_that("pnadc_clear_cache removes specific module", {
  skip_on_cran()
  skip_if_offline()

  test_cache <- file.path(tempdir(), "test_pnadc_clear_module")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # download data
  df <- pnadc_data(
    module = "deficiencia",
    year = 2022,
    cache_dir = test_cache
  )

  # verify cache exists
  status_before <- pnadc_cache_status(cache_dir = test_cache)
  expect_true(nrow(status_before) > 0)

  # clear specific module
  pnadc_clear_cache(module = "deficiencia", cache_dir = test_cache)

  # verify cleared
  status_after <- pnadc_cache_status(cache_dir = test_cache)
  expect_true(nrow(status_after) < nrow(status_before) ||
                !any(status_after$module == "deficiencia", na.rm = TRUE))
})
