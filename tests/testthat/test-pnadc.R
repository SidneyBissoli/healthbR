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
  skip_if_no_integration()

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
  skip_if_no_integration()

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

test_that(".has_arrow returns logical", {
  result <- healthbR:::.has_arrow()
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
  skip_if_no_integration()

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
  skip_if_no_integration()

  test_cache <- file.path(tempdir(), "test_pnadc_dict_cache")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # first call downloads
  dict1 <- pnadc_dictionaries(
    module = "deficiencia",
    year = 2022,
    cache_dir = test_cache
  )

  # verify cache exists (flat RDS for dictionaries)
  cache_files <- list.files(test_cache, pattern = "pnadc_dict_deficiencia_2022")
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
  skip_if_no_integration()

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
  skip_if_no_integration()

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
  skip_if_no_integration()

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
  skip_if_no_integration()

  test_cache <- file.path(tempdir(), "test_pnadc_cache_reuse")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # first call downloads
  df1 <- pnadc_data(
    module = "deficiencia",
    year = 2022,
    cache_dir = test_cache
  )

  # verify partitioned cache exists
  cache_files <- list.files(
    file.path(test_cache, "pnadc_deficiencia_data"),
    recursive = TRUE, pattern = "\\.parquet$"
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
  skip_if_no_integration()
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
  skip_if_no_integration()

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
  skip_if_no_integration()

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
  skip_if_no_integration()

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

# ============================================================================
# additional unit tests — no HTTP calls
# ============================================================================

# --- pnadc_info() -----------------------------------------------------------

test_that("pnadc_info returns invisible list with all expected fields", {

  info <- pnadc_info()
  expect_type(info, "list")
  expect_true("name" %in% names(info))
  expect_true("name_en" %in% names(info))
  expect_true("institution" %in% names(info))
  expect_true("description" %in% names(info))
  expect_true("url" %in% names(info))
  expect_true("ftp_url" %in% names(info))
  expect_true("modules" %in% names(info))
  expect_true("survey_design" %in% names(info))
  expect_true("citation" %in% names(info))

  # modules should be a tibble

  expect_s3_class(info$modules, "tbl_df")
  expect_true(nrow(info$modules) >= 4)

  # citation contains IBGE
  expect_match(info$citation, "IBGE")

  # invisibly returns (capture.output forces printing side-effects)
  out <- withVisible(pnadc_info())
  expect_false(out$visible)
})

# --- pnadc_base_url() -------------------------------------------------------

test_that("pnadc_base_url returns correct URL string", {
  url <- healthbR:::pnadc_base_url()
  expect_type(url, "character")
  expect_match(url, "ftp\\.ibge\\.gov\\.br")
  expect_match(url, "Pesquisa_Nacional_por_Amostra_de_Domicilios_continua")
})

# --- pnadc_years() additional cases -----------------------------------------

test_that("pnadc_years returns integer for aps module", {
  years <- pnadc_years("aps")
  expect_type(years, "integer")
  expect_equal(years, 2022L)
})

test_that("pnadc_years case-insensitive", {
  expect_equal(pnadc_years("HABITACAO"), pnadc_years("habitacao"))
  expect_equal(pnadc_years("Deficiencia"), pnadc_years("deficiencia"))
})

# --- pnadc_modules() --------------------------------------------------------

test_that("pnadc_modules contains expected columns and module data", {
  modules <- pnadc_modules()
  expect_s3_class(modules, "tbl_df")
  expect_true("quarter" %in% names(modules))

  # deficiencia has quarter 3
  def <- modules[modules$module == "deficiencia", ]
  expect_equal(def$quarter, 3L)

  # habitacao has NA quarter (visita)
  hab <- modules[modules$module == "habitacao", ]
  expect_true(is.na(hab$quarter))

  # moradores also has NA quarter
  mor <- modules[modules$module == "moradores", ]
  expect_true(is.na(mor$quarter))

  # aps has quarter 2
  aps <- modules[modules$module == "aps", ]
  expect_equal(aps$quarter, 2L)

  # years column is a list column
  expect_true(is.list(modules$years))
  expect_true(length(def$years[[1]]) >= 3)
})

# --- validate_pnadc_module() additional cases --------------------------------

test_that("validate_pnadc_module normalises mixed case", {
  expect_equal(validate_pnadc_module("APS"), "aps")
  expect_equal(validate_pnadc_module("Moradores"), "moradores")
})

test_that("validate_pnadc_module errors on empty string", {
  expect_error(validate_pnadc_module(""), "Invalid module")
})

test_that("validate_pnadc_module errors on numeric input", {
  expect_error(validate_pnadc_module(123), "Invalid module")
})

# --- validate_pnadc_year() additional cases ----------------------------------

test_that("validate_pnadc_year works for moradores module", {
  expect_equal(validate_pnadc_year(2012, "moradores"), 2012L)
  expect_equal(validate_pnadc_year(c(2012, 2015), "moradores"), c(2012L, 2015L))
  all_years <- validate_pnadc_year(NULL, "moradores")
  expect_true(2012L %in% all_years)
  expect_true(2024L %in% all_years)
  # 2020-2021 not available
  expect_error(validate_pnadc_year(2020, "moradores"), "Invalid year")
})

test_that("validate_pnadc_year works for aps module", {
  expect_equal(validate_pnadc_year(2022, "aps"), 2022L)
  expect_error(validate_pnadc_year(2023, "aps"), "Invalid year")
  expect_error(validate_pnadc_year(2021, "aps"), "Invalid year")
})

test_that("validate_pnadc_year accepts character coerced to integer", {
  expect_equal(validate_pnadc_year("2022", "deficiencia"), 2022L)
})

test_that("validate_pnadc_year error message contains year info", {
  expect_error(
    validate_pnadc_year(1999, "deficiencia"),
    "1999"
  )
})

# --- pnadc_required_vars() --------------------------------------------------

test_that("pnadc_required_vars returns expected complete set", {
  vars <- healthbR:::pnadc_required_vars()
  expect_type(vars, "character")
  expect_true(length(vars) >= 10)
  expect_true("Ano" %in% vars)
  expect_true("Trimestre" %in% vars)
  expect_true("UF" %in% vars)
  expect_true("Capital" %in% vars)
  expect_true("RM_RIDE" %in% vars)
  expect_true("V1008" %in% vars)
  expect_true("V1014" %in% vars)
  expect_true("V2007" %in% vars)
  expect_true("V2009" %in% vars)
  expect_true("V2010" %in% vars)
  expect_true("V1027" %in% vars)
})

# --- .pnadc_try_lazy() ------------------------------------------------------

test_that(".pnadc_try_lazy returns NULL when lazy is FALSE", {
  result <- healthbR:::.pnadc_try_lazy("deficiencia", 2022, NULL,
                                       lazy = FALSE, backend = "arrow",
                                       cache_dir = tempdir())
  expect_null(result)
})

test_that(".pnadc_try_lazy returns NULL when no cache exists", {
  tmp <- withr::local_tempdir()
  result <- healthbR:::.pnadc_try_lazy("deficiencia", 2022, NULL,
                                       lazy = TRUE, backend = "arrow",
                                       cache_dir = tmp)
  expect_null(result)
})

test_that(".pnadc_try_lazy returns NULL with vars when no cache exists", {
  tmp <- withr::local_tempdir()
  result <- healthbR:::.pnadc_try_lazy("deficiencia", 2022,
                                       vars = c("S11001", "S11002"),
                                       lazy = TRUE, backend = "arrow",
                                       cache_dir = tmp)
  expect_null(result)
})

test_that(".pnadc_try_lazy returns NULL with NULL year", {
  tmp <- withr::local_tempdir()
  result <- healthbR:::.pnadc_try_lazy("deficiencia", NULL, NULL,
                                       lazy = TRUE, backend = "arrow",
                                       cache_dir = tmp)
  expect_null(result)
})

# --- .pnadc_select_vars() ---------------------------------------------------

test_that(".pnadc_select_vars returns all columns when vars is NULL", {
  mock_data <- tibble::tibble(
    pnadc_module = "deficiencia",
    Ano = 2022L, Trimestre = 3L, UF = "33",
    Capital = "1", RM_RIDE = "1", V1008 = "1", V1014 = "1",
    V2007 = "1", V2009 = 30L, V2010 = "1",
    UPA = "123", Estrato = "456", V1028 = 1.5, V1027 = 1.2,
    S11001 = "1", S11002 = "2", EXTRA = "x"
  )
  result <- healthbR:::.pnadc_select_vars(mock_data, NULL)
  expect_equal(ncol(result), ncol(mock_data))
  expect_equal(names(result), names(mock_data))
})

test_that(".pnadc_select_vars selects requested + required vars", {
  mock_data <- tibble::tibble(
    pnadc_module = "deficiencia",
    Ano = 2022L, Trimestre = 3L, UF = "33",
    Capital = "1", RM_RIDE = "1", V1008 = "1", V1014 = "1",
    V2007 = "1", V2009 = 30L, V2010 = "1",
    UPA = "123", Estrato = "456", V1028 = 1.5, V1027 = 1.2,
    S11001 = "1", S11002 = "2", EXTRA = "x"
  )
  result <- healthbR:::.pnadc_select_vars(mock_data, c("S11001"))
  # should include pnadc_module, all required vars, and S11001
  expect_true("pnadc_module" %in% names(result))
  expect_true("S11001" %in% names(result))
  expect_true("UPA" %in% names(result))
  expect_true("Estrato" %in% names(result))
  expect_true("V1028" %in% names(result))
  expect_true("Ano" %in% names(result))
  # EXTRA should NOT be included

  expect_false("EXTRA" %in% names(result))
  # S11002 should NOT be included
  expect_false("S11002" %in% names(result))
})

test_that(".pnadc_select_vars uppercases var names for matching", {
  mock_data <- tibble::tibble(
    pnadc_module = "deficiencia",
    Ano = 2022L, Trimestre = 3L, UF = "33",
    Capital = "1", RM_RIDE = "1", V1008 = "1", V1014 = "1",
    V2007 = "1", V2009 = 30L, V2010 = "1",
    UPA = "123", Estrato = "456", V1028 = 1.5, V1027 = 1.2,
    S11001 = "1"
  )
  result <- healthbR:::.pnadc_select_vars(mock_data, c("s11001"))
  expect_true("S11001" %in% names(result))
})

test_that(".pnadc_select_vars warns about missing user-requested vars", {
  mock_data <- tibble::tibble(
    pnadc_module = "deficiencia",
    Ano = 2022L, Trimestre = 3L, UF = "33",
    Capital = "1", RM_RIDE = "1", V1008 = "1", V1014 = "1",
    V2007 = "1", V2009 = 30L, V2010 = "1",
    UPA = "123", Estrato = "456", V1028 = 1.5, V1027 = 1.2,
    S11001 = "1"
  )
  expect_warning(
    healthbR:::.pnadc_select_vars(mock_data, c("NONEXISTENT", "ALSO_MISSING")),
    "Variables not found"
  )
})

test_that(".pnadc_select_vars does NOT warn if only required vars are missing", {
  # If a required var is missing from data but no user var is missing,
  # there should be no warning (the missing required vars are just silently skipped)
  mock_data <- tibble::tibble(
    pnadc_module = "deficiencia",
    Ano = 2022L, Trimestre = 3L, UF = "33",
    UPA = "123", Estrato = "456", V1028 = 1.5,
    S11001 = "1"
    # Missing: Capital, RM_RIDE, V1008, V1014, V2007, V2009, V2010, V1027
  )
  # Request only S11001 which IS present — no user-missing vars
  expect_no_warning(
    healthbR:::.pnadc_select_vars(mock_data, c("S11001"))
  )
})

# --- pnadc_parse_input_file() -----------------------------------------------

test_that("pnadc_parse_input_file parses IBGE format correctly", {
  tmp <- withr::local_tempfile(fileext = ".txt")
  writeLines(c(
    "INPUT",
    "  @1  UF     $2.",
    "  @3  V2007  $1.",
    "  @4  V2009   3.",
    "  @7  V1028  15."
  ), tmp)

  specs <- healthbR:::pnadc_parse_input_file(tmp)
  expect_type(specs, "list")
  expect_length(specs, 4)

  # first column: UF at position 1, character, width 2
  expect_equal(specs[[1]]$start, 1L)
  expect_equal(specs[[1]]$name, "UF")
  expect_true(specs[[1]]$is_char)
  expect_equal(specs[[1]]$width, 2L)

  # third column: V2009 at position 4, numeric, width 3
  expect_equal(specs[[3]]$start, 4L)
  expect_equal(specs[[3]]$name, "V2009")
  expect_false(specs[[3]]$is_char)
  expect_equal(specs[[3]]$width, 3L)
})

test_that("pnadc_parse_input_file errors on empty/no-spec file", {
  tmp <- withr::local_tempfile(fileext = ".txt")
  writeLines(c("just some text", "no specs here"), tmp)

  expect_error(
    healthbR:::pnadc_parse_input_file(tmp),
    "Could not parse"
  )
})

test_that("pnadc_parse_input_file skips unparseable lines", {
  tmp <- withr::local_tempfile(fileext = ".txt")
  writeLines(c(
    "INPUT",
    "  @1  UF     $2.",
    "  some garbage line",
    "  @3  V2009   3."
  ), tmp)

  specs <- healthbR:::pnadc_parse_input_file(tmp)
  # should parse only the 2 valid lines
  expect_length(specs, 2)
  expect_equal(specs[[1]]$name, "UF")
  expect_equal(specs[[2]]$name, "V2009")
})

# --- pnadc_read_fwf() -------------------------------------------------------

test_that("pnadc_read_fwf reads fixed-width data correctly", {
  # create input spec file
  input_tmp <- withr::local_tempfile(fileext = ".txt")
  writeLines(c(
    "  @1  UF     $2.",
    "  @3  AGE     3.",
    "  @6  SEX    $1."
  ), input_tmp)

  # create fixed-width data file
  data_tmp <- withr::local_tempfile(fileext = ".txt")
  writeLines(c(
    "33030M",
    "11025F",
    "53045M"
  ), data_tmp)

  result <- healthbR:::pnadc_read_fwf(data_tmp, input_tmp)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3)
  expect_equal(ncol(result), 3)
  expect_equal(result$UF, c("33", "11", "53"))
  expect_equal(result$AGE, c(30, 25, 45))
  expect_equal(result$SEX, c("M", "F", "M"))
})

# --- pnadc_download_file() --------------------------------------------------

test_that("pnadc_download_file returns cached file when exists and no refresh", {
  tmp <- withr::local_tempfile(fileext = ".zip")
  writeLines("fake data", tmp)

  result <- healthbR:::pnadc_download_file("https://example.com/file.zip", tmp,
                                           refresh = FALSE)
  expect_equal(result, tmp)
})

# --- pnadc_list_ftp_files() -------------------------------------------------

test_that("pnadc_list_ftp_files returns empty on connection error", {
  # Use a URL that will definitely fail
  result <- healthbR:::pnadc_list_ftp_files(
    "https://localhost:1/nonexistent_dir/", "zip"
  )
  expect_type(result, "character")
  expect_length(result, 0)
})

# --- pnadc_apply_survey_design() --------------------------------------------

test_that("pnadc_apply_survey_design errors on missing design vars", {
  mock_data <- tibble::tibble(
    Ano = 2022L,
    UF = "33"
    # missing UPA, Estrato, V1028
  )
  expect_error(
    healthbR:::pnadc_apply_survey_design(mock_data),
    "Missing survey design variables"
  )
})

test_that("pnadc_apply_survey_design errors with partial missing vars", {
  mock_data <- tibble::tibble(
    UPA = "123",
    UF = "33"
    # missing Estrato, V1028
  )
  expect_error(
    healthbR:::pnadc_apply_survey_design(mock_data),
    "Missing survey design variables"
  )
})

# --- pnadc_cache_status() with files ----------------------------------------

test_that("pnadc_cache_status returns empty tibble for empty cache dir", {
  tmp <- withr::local_tempdir()
  status <- pnadc_cache_status(cache_dir = tmp)
  expect_s3_class(status, "tbl_df")
  expect_equal(nrow(status), 0)
  expect_true(all(c("file", "module", "year", "size_mb", "modified") %in% names(status)))
})

test_that("pnadc_cache_status detects files in cache dir", {
  tmp <- withr::local_tempdir()
  cache_dir <- healthbR:::pnadc_cache_dir(tmp)

  # create fake cache files
  writeLines("data", file.path(cache_dir, "pnadc_deficiencia_2022.rds"))
  writeLines("data", file.path(cache_dir, "pnadc_habitacao_2019.rds"))

  status <- pnadc_cache_status(cache_dir = tmp)
  expect_s3_class(status, "tbl_df")
  expect_equal(nrow(status), 2)
  expect_true("deficiencia" %in% status$module)
  expect_true("habitacao" %in% status$module)
  expect_true(2022L %in% status$year)
  expect_true(2019L %in% status$year)
})

test_that("pnadc_cache_status reports file sizes", {
  tmp <- withr::local_tempdir()
  cache_dir <- healthbR:::pnadc_cache_dir(tmp)

  writeLines(paste(rep("x", 1000), collapse = ""),
             file.path(cache_dir, "pnadc_aps_2022.rds"))

  status <- pnadc_cache_status(cache_dir = tmp)
  expect_true("size_mb" %in% names(status))
  expect_true(is.numeric(status$size_mb))
})

# --- pnadc_clear_cache() with files -----------------------------------------

test_that("pnadc_clear_cache removes all files when module is NULL", {
  tmp <- withr::local_tempdir()
  cache_dir <- healthbR:::pnadc_cache_dir(tmp)

  writeLines("data", file.path(cache_dir, "pnadc_deficiencia_2022.rds"))
  writeLines("data", file.path(cache_dir, "pnadc_habitacao_2019.rds"))

  expect_true(length(list.files(cache_dir)) > 0)

  pnadc_clear_cache(cache_dir = tmp)

  # directory should exist but be empty (or recreated empty)
  expect_true(dir.exists(cache_dir))
  expect_equal(length(list.files(cache_dir, recursive = TRUE)), 0)
})

test_that("pnadc_clear_cache removes only matching module files", {
  tmp <- withr::local_tempdir()
  cache_dir <- healthbR:::pnadc_cache_dir(tmp)

  writeLines("data", file.path(cache_dir, "pnadc_deficiencia_2022.rds"))
  writeLines("data", file.path(cache_dir, "pnadc_habitacao_2019.rds"))

  pnadc_clear_cache(module = "deficiencia", cache_dir = tmp)

  remaining <- list.files(cache_dir)
  expect_false(any(grepl("deficiencia", remaining)))
  expect_true(any(grepl("habitacao", remaining)))
})

test_that("pnadc_clear_cache with empty cache reports info", {
  tmp <- withr::local_tempdir()
  # Should not error
  expect_no_error(pnadc_clear_cache(cache_dir = tmp))
})

# --- pnadc_data() parameter validation --------------------------------------

test_that("pnadc_data errors with invalid module", {
  expect_error(pnadc_data(module = "nonexistent"), "Invalid module")
})

test_that("pnadc_data errors with NULL module", {
  expect_error(pnadc_data(module = NULL), "must be specified")
})

test_that("pnadc_data errors with multiple modules", {
  expect_error(
    pnadc_data(module = c("deficiencia", "habitacao")),
    "must be specified"
  )
})

test_that("pnadc_data errors with invalid year for aps", {
  expect_error(
    pnadc_data(module = "aps", year = 2023, cache_dir = tempdir()),
    "Invalid year"
  )
})

test_that("pnadc_data validates backend argument", {
  expect_error(
    pnadc_data(module = "deficiencia", year = 2022,
               backend = "invalid", cache_dir = tempdir()),
    "should be one of"
  )
})

# --- .pnadc_download_loop() with mocks --------------------------------------

test_that(".pnadc_download_loop binds rows from multiple years", {
  tmp <- withr::local_tempdir()
  cache_dir <- healthbR:::pnadc_cache_dir(tmp)
  ds_name <- "pnadc_deficiencia_data"

  mock_download_count <- 0L

  local_mocked_bindings(
    pnadc_find_data_url = function(module, year) {
      list(
        data_url = paste0("https://example.com/", year, ".zip"),
        data_dir_url = "https://example.com/",
        data_filename = paste0("PNADC_", year, ".zip"),
        input_url = paste0("https://example.com/input_", year, ".txt"),
        input_filename = paste0("input_", year, ".txt"),
        doc_dir_url = "https://example.com/doc/"
      )
    },
    pnadc_download_file = function(url, destfile, refresh = FALSE) {
      invisible(destfile)
    },
    pnadc_read_zip = function(zip_path, input_path, module, year) {
      tibble::tibble(
        UPA = c("100", "200"),
        Estrato = c("10", "20"),
        V1028 = c(1.5, 2.5),
        S11001 = c("1", "2")
      )
    },
    .cache_append_partitioned = function(data, cache_dir, dataset_name, partitioning) {
      invisible(NULL)
    },
    .has_partitioned_cache = function(cache_dir, dataset_name) FALSE,
    .package = "healthbR"
  )

  result <- healthbR:::.pnadc_download_loop(
    "deficiencia", c(2019L, 2022L), cache_dir, FALSE, ds_name
  )

  expect_type(result, "list")
  expect_length(result, 2)

  # each element should be a tibble with year and pnadc_module columns added
  expect_true("year" %in% names(result[[1]]))
  expect_true("pnadc_module" %in% names(result[[1]]))
  expect_equal(result[[1]]$year[1], 2019L)
  expect_equal(result[[2]]$year[1], 2022L)
  expect_equal(result[[1]]$pnadc_module[1], "deficiencia")
})

test_that(".pnadc_download_loop errors when input_url is NULL", {
  tmp <- withr::local_tempdir()
  cache_dir <- healthbR:::pnadc_cache_dir(tmp)
  ds_name <- "pnadc_deficiencia_data"

  local_mocked_bindings(
    pnadc_find_data_url = function(module, year) {
      list(
        data_url = "https://example.com/file.zip",
        data_dir_url = "https://example.com/",
        data_filename = "PNADC_2022.zip",
        input_url = NULL,
        input_filename = NULL,
        doc_dir_url = "https://example.com/doc/"
      )
    },
    pnadc_download_file = function(url, destfile, refresh = FALSE) {
      invisible(destfile)
    },
    .has_partitioned_cache = function(cache_dir, dataset_name) FALSE,
    .package = "healthbR"
  )

  expect_error(
    healthbR:::.pnadc_download_loop("deficiencia", 2022L, cache_dir, FALSE, ds_name),
    "Could not find input specification file"
  )
})

# --- pnadc_data() full pipeline with mocks -----------------------------------

test_that("pnadc_data returns tibble with mocked download", {
  tmp <- withr::local_tempdir()

  local_mocked_bindings(
    pnadc_find_data_url = function(module, year) {
      list(
        data_url = paste0("https://example.com/", year, ".zip"),
        data_dir_url = "https://example.com/",
        data_filename = paste0("PNADC_", year, ".zip"),
        input_url = paste0("https://example.com/input.txt"),
        input_filename = "input.txt",
        doc_dir_url = "https://example.com/doc/"
      )
    },
    pnadc_download_file = function(url, destfile, refresh = FALSE) {
      invisible(destfile)
    },
    pnadc_read_zip = function(zip_path, input_path, module, year) {
      tibble::tibble(
        Ano = 2022L, Trimestre = 3L, UF = "33",
        Capital = "1", RM_RIDE = "1", V1008 = "1", V1014 = "1",
        V2007 = "1", V2009 = 30L, V2010 = "1",
        UPA = c("100", "200"), Estrato = c("10", "20"),
        V1028 = c(1.5, 2.5), V1027 = c(1.0, 2.0),
        S11001 = c("1", "2"), S11002 = c("3", "4")
      )
    },
    .cache_append_partitioned = function(data, cache_dir, dataset_name, partitioning) {
      invisible(NULL)
    },
    .has_partitioned_cache = function(cache_dir, dataset_name) FALSE,
    .package = "healthbR"
  )

  result <- pnadc_data(module = "deficiencia", year = 2022, cache_dir = tmp)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_true("pnadc_module" %in% names(result))
  expect_true("year" %in% names(result))
  expect_true("UPA" %in% names(result))
  expect_true("S11001" %in% names(result))
})

test_that("pnadc_data selects vars when specified", {
  tmp <- withr::local_tempdir()

  local_mocked_bindings(
    pnadc_find_data_url = function(module, year) {
      list(
        data_url = "https://example.com/file.zip",
        data_dir_url = "https://example.com/",
        data_filename = "PNADC_2022.zip",
        input_url = "https://example.com/input.txt",
        input_filename = "input.txt",
        doc_dir_url = "https://example.com/doc/"
      )
    },
    pnadc_download_file = function(url, destfile, refresh = FALSE) {
      invisible(destfile)
    },
    pnadc_read_zip = function(zip_path, input_path, module, year) {
      tibble::tibble(
        Ano = 2022L, Trimestre = 3L, UF = "33",
        Capital = "1", RM_RIDE = "1", V1008 = "1", V1014 = "1",
        V2007 = "1", V2009 = 30L, V2010 = "1",
        UPA = c("100", "200"), Estrato = c("10", "20"),
        V1028 = c(1.5, 2.5), V1027 = c(1.0, 2.0),
        S11001 = c("1", "2"), S11002 = c("3", "4"),
        EXTRA_VAR = c("a", "b")
      )
    },
    .cache_append_partitioned = function(data, cache_dir, dataset_name, partitioning) {
      invisible(NULL)
    },
    .has_partitioned_cache = function(cache_dir, dataset_name) FALSE,
    .package = "healthbR"
  )

  result <- pnadc_data(module = "deficiencia", year = 2022,
                       vars = c("S11001"), cache_dir = tmp)
  expect_true("S11001" %in% names(result))
  expect_true("UPA" %in% names(result))
  expect_false("EXTRA_VAR" %in% names(result))
  expect_false("S11002" %in% names(result))
})

test_that("pnadc_data multiple years with mocked download", {
  tmp <- withr::local_tempdir()

  local_mocked_bindings(
    pnadc_find_data_url = function(module, year) {
      list(
        data_url = paste0("https://example.com/", year, ".zip"),
        data_dir_url = "https://example.com/",
        data_filename = paste0("PNADC_", year, ".zip"),
        input_url = "https://example.com/input.txt",
        input_filename = "input.txt",
        doc_dir_url = "https://example.com/doc/"
      )
    },
    pnadc_download_file = function(url, destfile, refresh = FALSE) {
      invisible(destfile)
    },
    pnadc_read_zip = function(zip_path, input_path, module, year) {
      tibble::tibble(
        Ano = as.integer(year), Trimestre = 3L, UF = "33",
        Capital = "1", RM_RIDE = "1", V1008 = "1", V1014 = "1",
        V2007 = "1", V2009 = 30L, V2010 = "1",
        UPA = c("100"), Estrato = c("10"),
        V1028 = c(1.5), V1027 = c(1.0),
        S11001 = c("1")
      )
    },
    .cache_append_partitioned = function(data, cache_dir, dataset_name, partitioning) {
      invisible(NULL)
    },
    .has_partitioned_cache = function(cache_dir, dataset_name) FALSE,
    .package = "healthbR"
  )

  result <- pnadc_data(module = "deficiencia", year = c(2019, 2022),
                       cache_dir = tmp)
  expect_s3_class(result, "tbl_df")
  # should bind 2 years: 1 row each = 2 total
  expect_equal(nrow(result), 2)
  expect_true(all(c(2019L, 2022L) %in% result$year))
})

test_that("pnadc_data with as_survey=TRUE applies survey design", {
  skip_if_not_installed("srvyr")
  tmp <- withr::local_tempdir()

  local_mocked_bindings(
    pnadc_find_data_url = function(module, year) {
      list(
        data_url = "https://example.com/file.zip",
        data_dir_url = "https://example.com/",
        data_filename = "PNADC_2022.zip",
        input_url = "https://example.com/input.txt",
        input_filename = "input.txt",
        doc_dir_url = "https://example.com/doc/"
      )
    },
    pnadc_download_file = function(url, destfile, refresh = FALSE) {
      invisible(destfile)
    },
    pnadc_read_zip = function(zip_path, input_path, module, year) {
      tibble::tibble(
        Ano = 2022L, Trimestre = 3L, UF = rep("33", 10),
        Capital = rep("1", 10), RM_RIDE = rep("1", 10),
        V1008 = rep("1", 10), V1014 = rep("1", 10),
        V2007 = rep("1", 10), V2009 = rep(30L, 10), V2010 = rep("1", 10),
        UPA = as.character(rep(1:5, 2)),
        Estrato = rep(c("10", "20"), each = 5),
        V1028 = rep(1.5, 10), V1027 = rep(1.0, 10),
        S11001 = as.character(1:10)
      )
    },
    .cache_append_partitioned = function(data, cache_dir, dataset_name, partitioning) {
      invisible(NULL)
    },
    .has_partitioned_cache = function(cache_dir, dataset_name) FALSE,
    .package = "healthbR"
  )

  result <- pnadc_data(module = "deficiencia", year = 2022,
                       as_survey = TRUE, cache_dir = tmp)
  expect_s3_class(result, "tbl_svy")
})

# --- pnadc_dictionaries() parameter logic ------------------------------------

test_that("pnadc_dictionaries validates year parameter for module", {
  expect_error(
    pnadc_dictionaries(module = "aps", year = 2023, cache_dir = tempdir()),
    "Invalid year"
  )
})

test_that("pnadc_dictionaries validates module parameter", {
  expect_error(
    pnadc_dictionaries(module = "nonexistent", cache_dir = tempdir()),
    "Invalid module"
  )
})

# --- pnadc_dictionaries() with mocked download -------------------------------

test_that("pnadc_dictionaries returns cached dict when file exists", {
  tmp <- withr::local_tempdir()
  cache_dir <- healthbR:::pnadc_cache_dir(tmp)

  # pre-create a cached dictionary file
  dict_df <- tibble::tibble(
    year = 2022L,
    module = "deficiencia",
    position = c(1L, 3L, 6L),
    variable = c("UF", "V2007", "V2009"),
    width = c(2L, 3L, 3L)
  )
  saveRDS(dict_df, file.path(cache_dir, "pnadc_dict_deficiencia_2022.rds"))

  result <- pnadc_dictionaries(module = "deficiencia", year = 2022,
                               cache_dir = tmp)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3)
  expect_equal(result$variable, c("UF", "V2007", "V2009"))
})

test_that("pnadc_dictionaries picks max year when multiple years given", {
  tmp <- withr::local_tempdir()
  cache_dir <- healthbR:::pnadc_cache_dir(tmp)

  # pre-create cached dictionary for year 2024 (the max)
  dict_df <- tibble::tibble(
    year = 2024L,
    module = "deficiencia",
    position = c(1L, 3L),
    variable = c("UF", "V2007"),
    width = c(2L, 3L)
  )
  saveRDS(dict_df, file.path(cache_dir, "pnadc_dict_deficiencia_2024.rds"))

  # requesting NULL year with deficiencia (years: 2019, 2022, 2024) => max = 2024
  result <- pnadc_dictionaries(module = "deficiencia", year = NULL,
                               cache_dir = tmp)
  expect_s3_class(result, "tbl_df")
  expect_equal(result$year[1], 2024L)
})

# --- pnadc_read_zip() error paths -------------------------------------------

test_that("pnadc_read_zip errors when no data txt found in ZIP", {
  tmp_dir <- withr::local_tempdir()

  # create a ZIP with only an "input" txt file (no data)
  input_file <- file.path(tmp_dir, "input_PNADC_2022.txt")
  writeLines("@1 UF $2.", input_file)

  zip_path <- file.path(tmp_dir, "test.zip")
  # create zip with just the input file
  withr::with_dir(tmp_dir, {
    utils::zip(zip_path, "input_PNADC_2022.txt")
  })

  input_spec <- withr::local_tempfile(fileext = ".txt")
  writeLines("@1 UF $2.", input_spec)

  expect_error(
    healthbR:::pnadc_read_zip(zip_path, input_spec, "deficiencia", 2022),
    "Could not find data file"
  )
})

# --- pnadc_find_data_url() URL building (mocked FTP listing) -----------------

test_that("pnadc_find_data_url builds visita URLs for habitacao", {
  local_mocked_bindings(
    pnadc_list_ftp_files = function(url, extension = "zip") {
      if (grepl("Dados", url)) {
        return(c("PNADC_2022_visita1.zip"))
      }
      if (grepl("Documentacao", url)) {
        return(c("input_PNADC_2022_visita1_20230101.txt"))
      }
      character(0)
    },
    .package = "healthbR"
  )

  result <- healthbR:::pnadc_find_data_url("habitacao", 2022)
  expect_type(result, "list")
  expect_match(result$data_url, "Visita_1")
  expect_match(result$data_url, "PNADC_2022_visita1")
  expect_match(result$data_filename, "visita1")
  expect_match(result$input_url, "input_PNADC_2022_visita1")
})

test_that("pnadc_find_data_url builds trimestre URLs for deficiencia", {
  local_mocked_bindings(
    pnadc_list_ftp_files = function(url, extension = "zip") {
      if (grepl("Dados", url)) {
        return(c("PNADC_2022_trimestre3.zip"))
      }
      if (grepl("Documentacao", url)) {
        return(c("input_PNADC_trimestre3_20230101.txt"))
      }
      character(0)
    },
    .package = "healthbR"
  )

  result <- healthbR:::pnadc_find_data_url("deficiencia", 2022)
  expect_type(result, "list")
  expect_match(result$data_url, "Trimestre_3")
  expect_match(result$data_url, "PNADC_2022_trimestre3")
  expect_match(result$input_url, "input_PNADC_trimestre3")
})

test_that("pnadc_find_data_url builds trimestre URLs for aps (quarter 2)", {
  local_mocked_bindings(
    pnadc_list_ftp_files = function(url, extension = "zip") {
      if (grepl("Dados", url)) {
        return(c("PNADC_2022_trimestre2.zip"))
      }
      if (grepl("Documentacao", url)) {
        return(c("input_PNADC_trimestre2_20230101.txt"))
      }
      character(0)
    },
    .package = "healthbR"
  )

  result <- healthbR:::pnadc_find_data_url("aps", 2022)
  expect_match(result$data_url, "Trimestre_2")
  expect_match(result$data_filename, "trimestre2")
})

test_that("pnadc_find_data_url uses 2012_a_2014 pattern for early visita years", {
  local_mocked_bindings(
    pnadc_list_ftp_files = function(url, extension = "zip") {
      if (grepl("Dados", url)) {
        return(c("PNADC_2013_visita1.zip"))
      }
      if (grepl("Documentacao", url)) {
        return(c("input_PNADC_2012_a_2014_visita1_20230101.txt"))
      }
      character(0)
    },
    .package = "healthbR"
  )

  result <- healthbR:::pnadc_find_data_url("habitacao", 2013)
  # for year 2013 (in 2012:2014 range), input_pattern should use 2012_a_2014
  expect_match(result$input_url, "2012_a_2014")
})

test_that("pnadc_find_data_url errors when no data files found", {
  local_mocked_bindings(
    pnadc_list_ftp_files = function(url, extension = "zip") {
      character(0)
    },
    .package = "healthbR"
  )

  expect_error(
    healthbR:::pnadc_find_data_url("deficiencia", 2022),
    "Could not list files"
  )
})

test_that("pnadc_find_data_url errors when no matching file for year", {
  local_mocked_bindings(
    pnadc_list_ftp_files = function(url, extension = "zip") {
      if (grepl("Dados", url)) {
        return(c("PNADC_2019_trimestre3.zip"))  # wrong year
      }
      character(0)
    },
    .package = "healthbR"
  )

  expect_error(
    healthbR:::pnadc_find_data_url("deficiencia", 2022),
    "No data file found"
  )
})

test_that("pnadc_find_data_url handles NULL input_url (no matching doc)", {
  local_mocked_bindings(
    pnadc_list_ftp_files = function(url, extension = "zip") {
      if (grepl("Dados", url) && extension == "zip") {
        return(c("PNADC_2022_trimestre3.zip"))
      }
      # return empty for documentation directory
      character(0)
    },
    .package = "healthbR"
  )

  result <- healthbR:::pnadc_find_data_url("deficiencia", 2022)
  expect_null(result$input_url)
  expect_null(result$input_filename)
})

# --- pnadc_module_registry structure ----------------------------------------

test_that("pnadc_module_registry has expected structure for all modules", {
  registry <- healthbR:::pnadc_module_registry
  expect_type(registry, "list")
  expect_true(length(registry) >= 4)

  for (mod_name in names(registry)) {
    mod <- registry[[mod_name]]
    expect_true("name" %in% names(mod), info = paste("module:", mod_name))
    expect_true("name_en" %in% names(mod), info = paste("module:", mod_name))
    expect_true("years" %in% names(mod), info = paste("module:", mod_name))
    expect_true("path_type" %in% names(mod), info = paste("module:", mod_name))
    expect_true("prefix" %in% names(mod), info = paste("module:", mod_name))
    expect_true("description" %in% names(mod), info = paste("module:", mod_name))
    expect_true(mod$path_type %in% c("visita", "trimestre"),
                info = paste("module:", mod_name))
  }
})

test_that("trimestre modules have quarter, visita modules have NULL quarter", {
  registry <- healthbR:::pnadc_module_registry

  for (mod_name in names(registry)) {
    mod <- registry[[mod_name]]
    if (mod$path_type == "trimestre") {
      expect_true(is.integer(mod$quarter) || is.numeric(mod$quarter),
                  info = paste(mod_name, "should have integer quarter"))
    } else {
      expect_null(mod$quarter,
                  info = paste(mod_name, "should have NULL quarter"))
    }
  }
})

# --- pnadc_variables() validation -------------------------------------------

test_that("pnadc_variables errors with invalid year", {
  expect_error(
    pnadc_variables(module = "deficiencia", year = 1999, cache_dir = tempdir()),
    "Invalid year"
  )
})

# --- .has_arrow() -----------------------------------------------------------

test_that(".has_arrow returns logical scalar", {
  result <- healthbR:::.has_arrow()
  expect_type(result, "logical")
  expect_length(result, 1)
})

# --- pnadc_cache_dir() ------------------------------------------------------

test_that("pnadc_cache_dir creates nested directory", {
  tmp <- withr::local_tempdir()
  nested <- file.path(tmp, "deep", "nested")
  result <- healthbR:::pnadc_cache_dir(nested)
  expect_true(dir.exists(result))
})
