# tests for pof functions
# tests for POF (Pesquisa de Orcamentos Familiares) module

# ============================================================================
# basic info functions (no internet required)
# ============================================================================

test_that("pof_years returns expected years", {
  years <- pof_years()

  expect_type(years, "character")
  expect_equal(length(years), 3L)
  expect_true("2002-2003" %in% years)
  expect_true("2008-2009" %in% years)
  expect_true("2017-2018" %in% years)
})

test_that("pof_info returns expected structure", {
  info <- pof_info()

  expect_type(info, "list")
  expect_true("name" %in% names(info))
  expect_true("acronym" %in% names(info))
  expect_true("health_modules" %in% names(info))
  expect_true("sample_design" %in% names(info))
  expect_true("url" %in% names(info))
  expect_equal(info$acronym, "POF")
})

test_that("pof_info handles EBIA availability correctly", {
  info_2017 <- pof_info("2017-2018")
  info_2008 <- pof_info("2008-2009")

  expect_true(info_2017$health_modules$ebia$available)
  expect_false(info_2008$health_modules$ebia$available)
})

test_that("pof_info handles antropometria availability correctly", {
  info_2017 <- pof_info("2017-2018")
  info_2008 <- pof_info("2008-2009")

  expect_false(info_2017$health_modules$antropometria$available)
  expect_true(info_2008$health_modules$antropometria$available)
})

test_that("pof_info handles consumo_alimentar availability correctly", {
  info_2017 <- pof_info("2017-2018")
  info_2008 <- pof_info("2008-2009")
  info_2002 <- pof_info("2002-2003")

  expect_true(info_2017$health_modules$consumo_alimentar$available)
  expect_true(info_2008$health_modules$consumo_alimentar$available)
  expect_false(info_2002$health_modules$consumo_alimentar$available)
})

test_that("pof_info returns year details", {
  info <- pof_info("2017-2018")

  expect_true("year_details" %in% names(info))
  expect_true("sample_size" %in% names(info$year_details))
  expect_true("reference_period" %in% names(info$year_details))
})

# ============================================================================
# validation functions (no internet required)
# ============================================================================

test_that(".pof_validate_year aborts on invalid year", {
  expect_error(.pof_validate_year("1990-1991"), "not available")
  expect_error(.pof_validate_year("2020-2021"), "not available")
  expect_error(.pof_validate_year("2017"), "not available")
})

test_that(".pof_validate_year accepts valid years", {
  expect_silent(.pof_validate_year("2017-2018"))
  expect_silent(.pof_validate_year("2008-2009"))
  expect_silent(.pof_validate_year("2002-2003"))
})

test_that(".pof_validate_register aborts on invalid register", {
  expect_error(.pof_validate_register("invalid"), "not available")
  expect_error(.pof_validate_register("xyz"), "not available")
})

test_that(".pof_validate_register accepts valid registers", {
  expect_silent(.pof_validate_register("morador", "2017-2018"))
  expect_silent(.pof_validate_register("domicilio", "2017-2018"))
  expect_silent(.pof_validate_register("consumo_alimentar", "2017-2018"))
})

test_that(".pof_validate_register handles year-specific registers", {
  # consumo_alimentar is not available in 2002-2003
  expect_error(
    .pof_validate_register("consumo_alimentar", "2002-2003"),
    "not available"
  )
})

# ============================================================================
# registers function (no internet required)
# ============================================================================

test_that("pof_registers returns tibble with expected columns", {
  registers <- pof_registers()

  expect_s3_class(registers, "tbl_df")
  expect_true(all(c("register", "description", "health_related") %in% names(registers)))
  expect_true(nrow(registers) > 0)
})

test_that("pof_registers filters by year correctly", {
  registers_2017 <- pof_registers("2017-2018")
  registers_2002 <- pof_registers("2002-2003")

  expect_true(nrow(registers_2017) >= nrow(registers_2002))
  expect_true("consumo_alimentar" %in% registers_2017$register)
})

test_that("pof_registers health_only filter works", {
  all_registers <- pof_registers()
  health_registers <- pof_registers(health_only = TRUE)

  expect_true(nrow(health_registers) <= nrow(all_registers))
  expect_true(all(health_registers$health_related))
})

test_that("pof_registers validates year parameter", {
  expect_error(pof_registers("1999-2000"), "not available")
})

# ============================================================================
# URL building (no internet required)
# ============================================================================

test_that(".pof_build_url builds correct URLs for 2017-2018", {
  url_data <- .pof_build_url("2017-2018", "data")
  url_doc <- .pof_build_url("2017-2018", "doc")

  expect_match(url_data, "Dados_20230713\\.zip")
  expect_match(url_data, "Pesquisa_de_Orcamentos_Familiares_2017_2018")
  expect_match(url_doc, "Documentacao_20230713\\.zip")
})

test_that(".pof_build_url builds correct URLs for 2008-2009", {
  url_data <- .pof_build_url("2008-2009", "data")
  url_doc <- .pof_build_url("2008-2009", "doc")

  expect_match(url_data, "Dados_20231009\\.zip")
  expect_match(url_data, "Pesquisa_de_Orcamentos_Familiares_2008_2009")
  expect_match(url_doc, "Documentacao_20231009\\.zip")
})

test_that(".pof_build_url builds correct URLs for 2002-2003", {
  url_data <- .pof_build_url("2002-2003", "data")
  url_doc <- .pof_build_url("2002-2003", "doc")

  expect_match(url_data, "Dados\\.zip")
  expect_match(url_data, "Pesquisa_de_Orcamentos_Familiares_2002_2003")
  expect_match(url_doc, "Documentacao\\.zip")
})

test_that(".pof_build_url aborts for invalid year", {
  expect_error(.pof_build_url("1990-1991"), "not configured")
})

# ============================================================================
# cache functions (no internet required)
# ============================================================================

test_that("pof_cache_dir creates directory", {
  dir <- pof_cache_dir()

  expect_type(dir, "character")
  expect_true(dir.exists(dir))
})

test_that("pof_cache_dir respects custom cache_dir", {
  custom_dir <- file.path(tempdir(), "custom_pof_cache")
  on.exit(unlink(custom_dir, recursive = TRUE), add = TRUE)

  dir <- pof_cache_dir(custom_dir)

  expect_true(dir.exists(dir))
  expect_match(dir, "pof")
})

test_that("pof_cache_status returns tibble", {
  status <- pof_cache_status()

  expect_s3_class(status, "tbl_df")
  expect_true(all(c("file", "size_mb", "modified") %in% names(status)))
})

test_that("pof_clear_cache handles empty cache", {
  temp_cache <- file.path(tempdir(), "empty_pof_test")
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  expect_no_error(pof_clear_cache(cache_dir = temp_cache))
})

# ============================================================================
# dictionary functions (require internet)
# ============================================================================

test_that("pof_dictionary validates year parameter", {
  expect_error(
    pof_dictionary(year = "1999-2000", cache_dir = tempdir()),
    "not available"
  )
})

test_that("pof_dictionary validates register parameter", {
  expect_error(
    pof_dictionary(year = "2017-2018", register = "invalid", cache_dir = tempdir()),
    "not available"
  )
})

test_that("pof_dictionary downloads and returns tibble", {
  skip_on_cran()
  skip_if_offline()

  dict <- pof_dictionary(year = "2017-2018", cache_dir = tempdir())

  expect_s3_class(dict, "tbl_df")
  expect_true(nrow(dict) > 0)
  expect_true("year" %in% names(dict))
  expect_true("register" %in% names(dict))
})

test_that("pof_dictionary filters by register", {
  skip_on_cran()
  skip_if_offline()

  dict_all <- pof_dictionary(year = "2017-2018", cache_dir = tempdir())
  dict_morador <- pof_dictionary(year = "2017-2018", register = "morador", cache_dir = tempdir())

  expect_true(nrow(dict_morador) < nrow(dict_all))
  expect_true(all(tolower(dict_morador$register) == "morador"))
})

test_that("pof_dictionary uses cache on second call", {
  skip_on_cran()
  skip_if_offline()

  test_cache <- file.path(tempdir(), "test_pof_dict_cache")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # first call downloads
  dict1 <- pof_dictionary(year = "2017-2018", cache_dir = test_cache)

  # verify cache exists
  cache_files <- list.files(file.path(test_cache, "pof"), pattern = "pof_dictionary")
  expect_true(length(cache_files) > 0)

  # second call should use cache
  dict2 <- pof_dictionary(year = "2017-2018", cache_dir = test_cache)

  expect_equal(nrow(dict1), nrow(dict2))
})

# ============================================================================
# variables function (require internet)
# ============================================================================

test_that("pof_variables returns tibble", {
  skip_on_cran()
  skip_if_offline()

  vars <- pof_variables(year = "2017-2018", cache_dir = tempdir())

  expect_s3_class(vars, "tbl_df")
  expect_true(nrow(vars) > 0)
  expect_true("variable" %in% names(vars))
})

test_that("pof_variables filters by register", {
  skip_on_cran()
  skip_if_offline()

  vars <- pof_variables(year = "2017-2018", register = "morador", cache_dir = tempdir())

  expect_s3_class(vars, "tbl_df")
  expect_true(nrow(vars) > 0)
})

test_that("pof_variables filters by search term", {
  skip_on_cran()
  skip_if_offline()

  vars <- pof_variables(year = "2017-2018", search = "uf", cache_dir = tempdir())

  expect_s3_class(vars, "tbl_df")
  # should find at least UF variable
})

# ============================================================================
# data validation (no download)
# ============================================================================

test_that("pof_data validates year parameter", {
  expect_error(
    pof_data(year = "1999-2000", cache_dir = tempdir()),
    "not available"
  )
})

test_that("pof_data validates register parameter", {
  expect_error(
    pof_data(year = "2017-2018", register = "invalid", cache_dir = tempdir()),
    "not available"
  )
})

test_that("pof_data requires srvyr for as_survey = TRUE", {
  # skip if srvyr is actually installed
  skip_if(requireNamespace("srvyr", quietly = TRUE))

  expect_error(
    pof_data(year = "2017-2018", as_survey = TRUE, cache_dir = tempdir()),
    "srvyr"
  )
})

# ============================================================================
# data download - integration tests (require internet)
# ============================================================================

test_that("pof_data downloads and returns tibble", {
  skip_on_cran()
  skip_if_offline()

  test_cache <- file.path(tempdir(), "test_pof_download")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # test with morador register (essential for survey design)
  df <- pof_data(year = "2017-2018", register = "morador", cache_dir = test_cache)

  expect_s3_class(df, "tbl_df")
  expect_true(nrow(df) > 0)
  expect_true(ncol(df) > 0)
  expect_true("year" %in% names(df))
})

test_that("pof_data handles variable selection", {
  skip_on_cran()
  skip_if_offline()

  test_cache <- file.path(tempdir(), "test_pof_vars")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # select specific variables
  df <- pof_data(
    year = "2017-2018",
    register = "morador",
    vars = c("UF", "V0403"),
    cache_dir = test_cache
  )

  expect_s3_class(df, "tbl_df")
  expect_true("year" %in% names(df))
  # design variables are always included
})

test_that("pof_data uses cache on second call", {
  skip_on_cran()
  skip_if_offline()

  test_cache <- file.path(tempdir(), "test_pof_cache_reuse")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # first call downloads
  df1 <- pof_data(year = "2017-2018", register = "morador", cache_dir = test_cache)

  # verify cache exists
  cache_files <- list.files(file.path(test_cache, "pof"), pattern = "pof_2017-2018_morador")
  expect_true(length(cache_files) > 0)

  # second call should use cache
  df2 <- pof_data(year = "2017-2018", register = "morador", cache_dir = test_cache)

  expect_equal(nrow(df1), nrow(df2))
  expect_equal(ncol(df1), ncol(df2))
})

test_that("pof_data with as_survey returns survey design", {
  skip_on_cran()
  skip_if_offline()
  skip_if_not_installed("srvyr")

  test_cache <- file.path(tempdir(), "test_pof_survey")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  svy <- pof_data(
    year = "2017-2018",
    register = "morador",
    as_survey = TRUE,
    cache_dir = test_cache
  )

  expect_s3_class(svy, "tbl_svy")
})

test_that("pof_data can download domicilio register", {
  skip_on_cran()
  skip_if_offline()

  test_cache <- file.path(tempdir(), "test_pof_domicilio")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  df <- pof_data(year = "2017-2018", register = "domicilio", cache_dir = test_cache)

  expect_s3_class(df, "tbl_df")
  expect_true(nrow(df) > 0)
})
