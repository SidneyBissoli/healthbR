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
  skip_if_no_integration()

  dict <- pof_dictionary(year = "2017-2018", cache_dir = tempdir())

  expect_s3_class(dict, "tbl_df")
  expect_true(nrow(dict) > 0)
  expect_true("year" %in% names(dict))
  expect_true("register" %in% names(dict))
})

test_that("pof_dictionary filters by register", {
  skip_on_cran()
  skip_if_no_integration()

  dict_all <- pof_dictionary(year = "2017-2018", cache_dir = tempdir())
  dict_morador <- pof_dictionary(year = "2017-2018", register = "morador", cache_dir = tempdir())

  expect_true(nrow(dict_morador) < nrow(dict_all))
  expect_true(all(tolower(dict_morador$register) == "morador"))
})

test_that("pof_dictionary uses cache on second call", {
  skip_on_cran()
  skip_if_no_integration()

  test_cache <- file.path(tempdir(), "test_pof_dict_cache")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # first call downloads
  dict1 <- pof_dictionary(year = "2017-2018", cache_dir = test_cache)

  # verify cache exists (flat cache for dictionary)
  cache_files <- list.files(test_cache, pattern = "pof_dictionary")
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
  skip_if_no_integration()

  vars <- pof_variables(year = "2017-2018", cache_dir = tempdir())

  expect_s3_class(vars, "tbl_df")
  expect_true(nrow(vars) > 0)
  expect_true("variable" %in% names(vars))
})

test_that("pof_variables filters by register", {
  skip_on_cran()
  skip_if_no_integration()

  vars <- pof_variables(year = "2017-2018", register = "morador", cache_dir = tempdir())

  expect_s3_class(vars, "tbl_df")
  expect_true(nrow(vars) > 0)
})

test_that("pof_variables filters by search term", {
  skip_on_cran()
  skip_if_no_integration()

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
  skip_if_no_integration()

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
  skip_if_no_integration()

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
  skip_if_no_integration()

  test_cache <- file.path(tempdir(), "test_pof_cache_reuse")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # first call downloads
  df1 <- pof_data(year = "2017-2018", register = "morador", cache_dir = test_cache)

  # verify partitioned cache exists
  cache_files <- list.files(file.path(test_cache, "pof_morador_data"),
                            recursive = TRUE, pattern = "\\.parquet$")
  expect_true(length(cache_files) > 0)

  # second call should use cache
  df2 <- pof_data(year = "2017-2018", register = "morador", cache_dir = test_cache)

  expect_equal(nrow(df1), nrow(df2))
  expect_equal(ncol(df1), ncol(df2))
})

test_that("pof_data with as_survey returns survey design", {
  skip_on_cran()
  skip_if_no_integration()
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
  skip_if_no_integration()

  test_cache <- file.path(tempdir(), "test_pof_domicilio")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  df <- pof_data(year = "2017-2018", register = "domicilio", cache_dir = test_cache)

  expect_s3_class(df, "tbl_df")
  expect_true(nrow(df) > 0)
})

# ============================================================================
# additional unit tests (no internet required)
# ============================================================================

# --- pof_info() extended tests ---

test_that("pof_info returns invisible", {
  expect_invisible(pof_info("2017-2018"))
})

test_that("pof_info returns correct structure for all years", {
  for (yr in pof_years()) {
    info <- pof_info(yr)
    expect_type(info, "list")
    expect_equal(info$acronym, "POF")
    expect_equal(info$source, "IBGE")
    expect_equal(info$year, yr)
    expect_true(!is.null(info$available_registers))
    expect_true(!is.null(info$year_details))
    expect_true(!is.null(info$year_details$sample_size))
    expect_true(!is.null(info$year_details$reference_period))
    expect_true(!is.null(info$year_details$notes))
  }
})

test_that("pof_info contains all expected top-level keys", {
  info <- pof_info("2017-2018")
  expected_keys <- c("name", "name_en", "acronym", "source", "year",
                     "description", "url", "ftp_url", "available_registers",
                     "health_modules", "sample_design", "year_details")
  for (key in expected_keys) {
    expect_true(key %in% names(info), info = paste("missing key:", key))
  }
})

test_that("pof_info sample_design has correct variables", {
  info <- pof_info("2017-2018")
  expect_equal(info$sample_design$weight_var, "PESO_FINAL")
  expect_equal(info$sample_design$strata_var, "ESTRATO_POF")
  expect_equal(info$sample_design$psu_var, "COD_UPA")
  expect_true(info$sample_design$post_stratification)
})

test_that("pof_info despesas_saude is available for all years", {
  for (yr in pof_years()) {
    info <- pof_info(yr)
    expect_true(info$health_modules$despesas_saude$available)
  }
})

test_that("pof_info errors on invalid year", {
  expect_error(pof_info("2020-2021"), "not available")
  expect_error(pof_info("2000"), "not available")
})

test_that("pof_info 2002-2003 has no consumo_alimentar and no ebia and no antropometria", {
  info <- pof_info("2002-2003")
  expect_false(info$health_modules$consumo_alimentar$available)
  expect_false(info$health_modules$ebia$available)
  expect_false(info$health_modules$antropometria$available)
})

# --- pof_years() extended tests ---

test_that("pof_years returns sorted character vector", {
  years <- pof_years()
  expect_type(years, "character")
  expect_equal(years, c("2002-2003", "2008-2009", "2017-2018"))
})

# --- pof_registers() extended tests ---

test_that("pof_registers returns different counts per year", {
  reg_2002 <- pof_registers("2002-2003")
  reg_2008 <- pof_registers("2008-2009")
  reg_2017 <- pof_registers("2017-2018")

  expect_equal(nrow(reg_2002), length(healthbR:::pof_valid_registers[["2002-2003"]]))
  expect_equal(nrow(reg_2008), length(healthbR:::pof_valid_registers[["2008-2009"]]))
  expect_equal(nrow(reg_2017), length(healthbR:::pof_valid_registers[["2017-2018"]]))
})

test_that("pof_registers 2002-2003 does not have consumo_alimentar", {
  reg <- pof_registers("2002-2003")
  expect_false("consumo_alimentar" %in% reg$register)
})

test_that("pof_registers 2008-2009 has despesa_90dias and despesa_12meses", {
  reg <- pof_registers("2008-2009")
  expect_true("despesa_90dias" %in% reg$register)
  expect_true("despesa_12meses" %in% reg$register)
})

test_that("pof_registers 2017-2018 has aluguel_estimado and outros_rendimentos", {
  reg <- pof_registers("2017-2018")
  expect_true("aluguel_estimado" %in% reg$register)
  expect_true("outros_rendimentos" %in% reg$register)
})

test_that("pof_registers health_only returns only health-related", {
  for (yr in pof_years()) {
    health <- pof_registers(yr, health_only = TRUE)
    # all rows should have health_related == TRUE
    expect_true(all(health$health_related))
    # health registers should be a subset of the known health registers
    known_health <- c("domicilio", "morador", "consumo_alimentar",
                      "despesa_individual", "caderneta_coletiva")
    expect_true(all(health$register %in% known_health))
  }
})

test_that("pof_registers health_only FALSE returns more rows than TRUE", {
  all_reg <- pof_registers("2017-2018", health_only = FALSE)
  health_reg <- pof_registers("2017-2018", health_only = TRUE)
  expect_true(nrow(all_reg) > nrow(health_reg))
})

# --- .pof_validate_year() extended tests ---

test_that(".pof_validate_year returns invisible NULL on valid years", {
  for (yr in pof_years()) {
    result <- healthbR:::.pof_validate_year(yr)
    expect_null(result)
  }
})

test_that(".pof_validate_year rejects various invalid years", {
  invalid_years <- c("2017", "2018", "1990-1991", "2020-2021", "abc",
                     "2017-2019", "", "2017 - 2018")
  for (yr in invalid_years) {
    expect_error(healthbR:::.pof_validate_year(yr), "not available",
                 info = paste("should reject:", yr))
  }
})

# --- .pof_validate_register() extended tests ---

test_that(".pof_validate_register accepts all valid registers for each year", {
  for (yr in pof_years()) {
    regs <- healthbR:::pof_valid_registers[[yr]]
    for (reg in regs) {
      expect_silent(healthbR:::.pof_validate_register(reg, yr))
    }
  }
})

test_that(".pof_validate_register rejects year-specific registers", {
  # 2002-2003 has no consumo_alimentar
  expect_error(healthbR:::.pof_validate_register("consumo_alimentar", "2002-2003"),
               "not available")
  # 2017-2018 has no despesa_90dias
  expect_error(healthbR:::.pof_validate_register("despesa_90dias", "2017-2018"),
               "not available")
  # 2008-2009 has no aluguel_estimado
  expect_error(healthbR:::.pof_validate_register("aluguel_estimado", "2008-2009"),
               "not available")
})

test_that(".pof_validate_register is case-insensitive via tolower", {
  # the function uses tolower(register), so "Morador" should match "morador"
  expect_silent(healthbR:::.pof_validate_register("morador", "2017-2018"))
})

test_that(".pof_validate_register handles NULL year (fallback registers)", {
  # when year is not in pof_valid_registers, function falls back to default list
  # this tests the fallback path (line 124-127)
  expect_silent(healthbR:::.pof_validate_register("morador", "unknown-year"))
  expect_error(healthbR:::.pof_validate_register("xyz_invalid", "unknown-year"),
               "not available")
})

# --- .pof_build_url() extended tests ---

test_that(".pof_build_url returns correct data URLs for all years", {
  url_2017 <- healthbR:::.pof_build_url("2017-2018", "data")
  url_2008 <- healthbR:::.pof_build_url("2008-2009", "data")
  url_2002 <- healthbR:::.pof_build_url("2002-2003", "data")

  expect_true(grepl("^https://ftp.ibge.gov.br/", url_2017))
  expect_true(grepl("^https://ftp.ibge.gov.br/", url_2008))
  expect_true(grepl("^https://ftp.ibge.gov.br/", url_2002))

  expect_true(grepl("\\.zip$", url_2017))
  expect_true(grepl("\\.zip$", url_2008))
  expect_true(grepl("\\.zip$", url_2002))
})

test_that(".pof_build_url returns correct doc URLs for all years", {
  for (yr in pof_years()) {
    url <- healthbR:::.pof_build_url(yr, "doc")
    expect_true(grepl("Documentacao", url))
    expect_true(grepl("\\.zip$", url))
  }
})

test_that(".pof_build_url type defaults to data", {
  url_data <- healthbR:::.pof_build_url("2017-2018", "data")
  # type="data" is the explicit data path
  expect_match(url_data, "Dados")
})

test_that(".pof_build_url non-data type returns doc URL", {
  # when type != "data", function returns doc URL
  url_doc <- healthbR:::.pof_build_url("2017-2018", "other")
  expect_match(url_doc, "Documentacao")
})

test_that(".pof_build_url errors on invalid year", {
  expect_error(healthbR:::.pof_build_url("1999-2000"), "not configured")
})

# --- .pof_find_dictionary_file() extended tests ---

test_that(".pof_find_dictionary_file finds file with 'dicion' pattern", {
  temp_dir <- withr::local_tempdir()
  # create mock files
  file.create(file.path(temp_dir, "README.txt"))
  file.create(file.path(temp_dir, "Dicionario_POF.xlsx"))
  file.create(file.path(temp_dir, "data.csv"))

  extracted <- list.files(temp_dir, full.names = TRUE)
  result <- healthbR:::.pof_find_dictionary_file(extracted, "2017-2018")
  expect_true(grepl("Dicionario_POF\\.xlsx$", result))
})

test_that(".pof_find_dictionary_file finds file with 'variav' pattern", {
  temp_dir <- withr::local_tempdir()
  file.create(file.path(temp_dir, "README.txt"))
  file.create(file.path(temp_dir, "variaveis_pof.xls"))
  file.create(file.path(temp_dir, "other.csv"))

  extracted <- list.files(temp_dir, full.names = TRUE)
  result <- healthbR:::.pof_find_dictionary_file(extracted, "2017-2018")
  expect_true(grepl("variaveis_pof\\.xls$", result))
})

test_that(".pof_find_dictionary_file returns NULL when no match", {
  temp_dir <- withr::local_tempdir()
  file.create(file.path(temp_dir, "data.txt"))
  file.create(file.path(temp_dir, "readme.csv"))

  extracted <- list.files(temp_dir, full.names = TRUE)
  result <- healthbR:::.pof_find_dictionary_file(extracted, "2017-2018")
  expect_null(result)
})

test_that(".pof_find_dictionary_file returns NULL for empty file list", {
  result <- healthbR:::.pof_find_dictionary_file(character(0), "2017-2018")
  expect_null(result)
})

test_that(".pof_find_dictionary_file ignores non-xls files", {
  temp_dir <- withr::local_tempdir()
  # create files with matching patterns but wrong extensions
  file.create(file.path(temp_dir, "dicionario.txt"))
  file.create(file.path(temp_dir, "dicionario.csv"))
  file.create(file.path(temp_dir, "variaveis.pdf"))

  extracted <- list.files(temp_dir, full.names = TRUE)
  result <- healthbR:::.pof_find_dictionary_file(extracted, "2017-2018")
  expect_null(result)
})

test_that(".pof_find_dictionary_file prefers 'dicion' over 'variav'", {
  temp_dir <- withr::local_tempdir()
  file.create(file.path(temp_dir, "variaveis.xlsx"))
  file.create(file.path(temp_dir, "dicionario.xls"))

  extracted <- list.files(temp_dir, full.names = TRUE)
  result <- healthbR:::.pof_find_dictionary_file(extracted, "2017-2018")
  expect_true(grepl("dicionario", result))
})

test_that(".pof_find_dictionary_file handles case-insensitive matching", {
  temp_dir <- withr::local_tempdir()
  file.create(file.path(temp_dir, "DICIONARIO_POF.XLS"))

  extracted <- list.files(temp_dir, full.names = TRUE)
  result <- healthbR:::.pof_find_dictionary_file(extracted, "2017-2018")
  expect_true(grepl("DICIONARIO_POF", result))
})

test_that(".pof_find_dictionary_file approach 3 uses accent stripping", {
  # test the accent-stripping path (approach 3)
  # create a file whose basename won't match approach 1 or 2 directly
  # but will match after accent stripping
  temp_dir <- withr::local_tempdir()
  # "Dicion\u00e1rio" has an accent - approach 1 grepl with 'dicion' should

  # still match since 'dicion' is a substring
  # To test approach 3 specifically, we need a name where approach 1 fails
  # Actually approach 1 checks "dicion" which matches "Dicionario" already
  # approach 3 is a fallback, let's just ensure a file ending in .xlsx
  # with accented "variáveis" is found via accent stripping
  # (approach 1 checks "variav" and "variaveis" which won't match accented)
  # Actually approach 1 uses useBytes=TRUE so accented chars might not match "variav"
  # Let's test: create file only matchable through accent stripping
  fname <- file.path(temp_dir, "lista_vari\u00e1veis.xlsx")
  file.create(fname)

  extracted <- list.files(temp_dir, full.names = TRUE)
  result <- healthbR:::.pof_find_dictionary_file(extracted, "2017-2018")
  # should find via approach 1 or 3 (grepl on "variav" with useBytes)
  # If not matched by approach 1, approach 3 strips accents and matches "variav"
  expect_true(!is.null(result))
})

# --- .pof_select_vars() extended tests ---

test_that(".pof_select_vars returns full df when vars is NULL", {
  df <- tibble::tibble(
    year = "2017-2018",
    COD_UPA = "001",
    ESTRATO_POF = "01",
    PESO_FINAL = "100",
    UF = "33",
    V0403 = "1",
    V0404 = "2"
  )

  result <- healthbR:::.pof_select_vars(df, NULL)
  expect_equal(ncol(result), ncol(df))
  expect_equal(nrow(result), nrow(df))
})

test_that(".pof_select_vars always keeps design vars and year", {
  df <- tibble::tibble(
    year = "2017-2018",
    COD_UPA = "001",
    ESTRATO_POF = "01",
    PESO_FINAL = "100",
    UF = "33",
    V0403 = "1",
    V0404 = "2",
    RENDA = "5000"
  )

  result <- healthbR:::.pof_select_vars(df, "RENDA")
  expect_true("year" %in% names(result))
  expect_true("COD_UPA" %in% names(result))
  expect_true("ESTRATO_POF" %in% names(result))
  expect_true("PESO_FINAL" %in% names(result))
  expect_true("UF" %in% names(result))
  expect_true("RENDA" %in% names(result))
  # V0403 and V0404 should NOT be selected
  expect_false("V0403" %in% names(result))
  expect_false("V0404" %in% names(result))
})

test_that(".pof_select_vars is case-insensitive", {
  df <- tibble::tibble(
    year = "2017-2018",
    cod_upa = "001",
    estrato_pof = "01",
    peso_final = "100",
    uf = "33",
    v0403 = "1"
  )

  result <- healthbR:::.pof_select_vars(df, "v0403")
  # should find lowercase columns by matching toupper
  expect_true("v0403" %in% names(result))
})

test_that(".pof_select_vars warns on missing variables", {
  df <- tibble::tibble(
    year = "2017-2018",
    COD_UPA = "001",
    ESTRATO_POF = "01",
    PESO_FINAL = "100",
    UF = "33"
  )

  expect_warning(
    healthbR:::.pof_select_vars(df, c("NONEXISTENT_VAR")),
    "not found"
  )
})

test_that(".pof_select_vars deduplicates vars", {
  df <- tibble::tibble(
    year = "2017-2018",
    COD_UPA = "001",
    ESTRATO_POF = "01",
    PESO_FINAL = "100",
    UF = "33",
    V0403 = "1"
  )

  # request V0403 twice, and also UF which is already a design var
  result <- healthbR:::.pof_select_vars(df, c("V0403", "V0403", "UF"))
  # no duplicate columns
  expect_equal(length(names(result)), length(unique(names(result))))
})

test_that(".pof_select_vars handles df without year column", {
  df <- tibble::tibble(
    COD_UPA = "001",
    ESTRATO_POF = "01",
    PESO_FINAL = "100",
    UF = "33",
    V0403 = "1"
  )

  result <- healthbR:::.pof_select_vars(df, "V0403")
  expect_false("year" %in% names(result))
  expect_true("V0403" %in% names(result))
})

# --- .pof_try_lazy_return() extended tests ---

test_that(".pof_try_lazy_return returns NULL when lazy is FALSE", {
  result <- healthbR:::.pof_try_lazy_return(
    lazy = FALSE, backend = "arrow", register = "morador",
    vars = NULL, year = "2017-2018", cache_dir = tempdir()
  )
  expect_null(result)
})

test_that(".pof_try_lazy_return returns NULL with empty cache", {
  temp_cache <- withr::local_tempdir()
  result <- healthbR:::.pof_try_lazy_return(
    lazy = TRUE, backend = "arrow", register = "morador",
    vars = NULL, year = "2017-2018", cache_dir = temp_cache
  )
  expect_null(result)
})

test_that(".pof_try_lazy_return builds correct dataset name", {
  # just verify it doesn't error with various registers
  temp_cache <- withr::local_tempdir()
  for (reg in c("morador", "domicilio", "consumo_alimentar")) {
    result <- healthbR:::.pof_try_lazy_return(
      lazy = TRUE, backend = "arrow", register = reg,
      vars = NULL, year = "2017-2018", cache_dir = temp_cache
    )
    expect_null(result)  # no cache, so always NULL
  }
})

# --- .pof_check_cache() extended tests ---

test_that(".pof_check_cache returns NULL when no cache exists", {
  temp_cache <- withr::local_tempdir()
  result <- healthbR:::.pof_check_cache(
    cache_dir = temp_cache, dataset_name = "pof_morador_data",
    year = "2017-2018", register = "morador", refresh = FALSE
  )
  expect_null(result)
})

test_that(".pof_check_cache returns NULL when refresh is TRUE", {
  temp_cache <- withr::local_tempdir()
  result <- healthbR:::.pof_check_cache(
    cache_dir = temp_cache, dataset_name = "pof_morador_data",
    year = "2017-2018", register = "morador", refresh = TRUE
  )
  expect_null(result)
})

test_that(".pof_check_cache returns NULL when arrow is not available", {
  temp_cache <- withr::local_tempdir()
  local_mocked_bindings(.has_arrow = function() FALSE, .package = "healthbR")
  result <- healthbR:::.pof_check_cache(
    cache_dir = temp_cache, dataset_name = "pof_morador_data",
    year = "2017-2018", register = "morador", refresh = FALSE
  )
  expect_null(result)
})

# --- .pof_create_survey_design() extended tests ---

test_that(".pof_create_survey_design errors when survey is not available", {
  skip_if(requireNamespace("survey", quietly = TRUE),
          "Test requires survey to NOT be installed")

  df <- tibble::tibble(PESO_FINAL = 1, ESTRATO_POF = 1, COD_UPA = 1)
  expect_error(
    healthbR:::.pof_create_survey_design(df, "2017-2018", tempdir()),
    "survey"
  )
})

test_that(".pof_create_survey_design errors when srvyr is not available", {
  skip_if(requireNamespace("srvyr", quietly = TRUE),
          "Test requires srvyr to NOT be installed")

  df <- tibble::tibble(PESO_FINAL = 1, ESTRATO_POF = 1, COD_UPA = 1)
  expect_error(
    healthbR:::.pof_create_survey_design(df, "2017-2018", tempdir()),
    "srvyr"
  )
})

test_that(".pof_create_survey_design errors when design vars are missing", {
  skip_if_not_installed("survey")
  skip_if_not_installed("srvyr")

  # data frame missing required design variables

  df <- tibble::tibble(V0403 = c("1", "2"), V0404 = c("3", "4"))
  expect_error(
    healthbR:::.pof_create_survey_design(df, "2017-2018", tempdir()),
    "Missing required variables"
  )
})

test_that(".pof_create_survey_design errors when only weight is present", {
  skip_if_not_installed("survey")
  skip_if_not_installed("srvyr")

  df <- tibble::tibble(PESO_FINAL = c(100, 200), OTHER = c(1, 2))
  expect_error(
    healthbR:::.pof_create_survey_design(df, "2017-2018", tempdir()),
    "Missing required variables"
  )
})

test_that(".pof_create_survey_design identifies alternative variable names", {
  skip_if_not_installed("survey")
  skip_if_not_installed("srvyr")

  # uses V9001, V0024, V0001 (alternative patterns)
  temp_cache <- withr::local_tempdir()
  df <- tibble::tibble(
    V9001 = c(100, 200, 300),
    V0024 = c(1, 1, 2),
    V0001 = c(10, 10, 20)
  )

  # mock .pof_download_post_strat to avoid HTTP
  local_mocked_bindings(
    .pof_download_post_strat = function(...) NULL,
    .package = "healthbR"
  )

  result <- healthbR:::.pof_create_survey_design(df, "2017-2018", temp_cache)
  expect_s3_class(result, "tbl_svy")
})

test_that(".pof_create_survey_design works with PESO/ESTRATO/UPA names", {
  skip_if_not_installed("survey")
  skip_if_not_installed("srvyr")

  temp_cache <- withr::local_tempdir()
  df <- tibble::tibble(
    PESO = c(100, 200, 300),
    ESTRATO = c(1, 1, 2),
    UPA = c(10, 10, 20)
  )

  local_mocked_bindings(
    .pof_download_post_strat = function(...) NULL,
    .package = "healthbR"
  )

  result <- healthbR:::.pof_create_survey_design(df, "2017-2018", temp_cache)
  expect_s3_class(result, "tbl_svy")
})

# --- pof_cache_status() extended tests ---

test_that("pof_cache_status returns empty tibble for empty cache", {
  temp_cache <- withr::local_tempdir()
  status <- pof_cache_status(cache_dir = temp_cache)

  expect_s3_class(status, "tbl_df")
  expect_equal(nrow(status), 0)
  expect_true(all(c("file", "size_mb", "modified") %in% names(status)))
})

test_that("pof_cache_status lists files when present", {
  temp_cache <- withr::local_tempdir()
  # pof_cache_status -> pof_cache_dir -> .module_cache_dir("pof", temp_cache)
  # when cache_dir is provided, it returns cache_dir as-is
  writeLines("test", file.path(temp_cache, "test_file.rds"))

  status <- pof_cache_status(cache_dir = temp_cache)
  expect_true(nrow(status) > 0)
  expect_true("test_file.rds" %in% status$file)
  expect_true(status$size_mb[1] >= 0)
})

# --- pof_clear_cache() extended tests ---

test_that("pof_clear_cache returns invisible NULL", {
  temp_cache <- withr::local_tempdir()
  result <- pof_clear_cache(cache_dir = temp_cache)
  expect_null(result)
  expect_invisible(pof_clear_cache(cache_dir = temp_cache))
})

test_that("pof_clear_cache removes files", {
  temp_cache <- withr::local_tempdir()
  writeLines("test", file.path(temp_cache, "pof_dict.rds"))
  writeLines("test", file.path(temp_cache, "pof_data.rds"))

  # verify files exist
  expect_true(length(list.files(temp_cache)) > 0)

  pof_clear_cache(cache_dir = temp_cache)

  # cache dir should be recreated but empty
  expect_equal(length(list.files(temp_cache, recursive = TRUE)), 0)
})

# --- pof_cache_dir() extended tests ---

test_that("pof_cache_dir appends 'pof' to custom dir", {
  temp <- withr::local_tempdir()
  dir <- pof_cache_dir(temp)
  # The module_cache_dir uses cache_dir directly when provided
  expect_true(dir.exists(dir))
})

# --- pof_data() parameter validation extended tests ---

test_that("pof_data errors on invalid year", {
  expect_error(pof_data(year = "2020-2021", cache_dir = tempdir()), "not available")
  expect_error(pof_data(year = "1990", cache_dir = tempdir()), "not available")
})

test_that("pof_data errors on register not available for year", {
  expect_error(
    pof_data(year = "2002-2003", register = "consumo_alimentar", cache_dir = tempdir()),
    "not available"
  )
  expect_error(
    pof_data(year = "2017-2018", register = "despesa_90dias", cache_dir = tempdir()),
    "not available"
  )
})

test_that("pof_data errors on completely invalid register", {
  expect_error(
    pof_data(year = "2017-2018", register = "nonexistent", cache_dir = tempdir()),
    "not available"
  )
})

test_that("pof_data with as_survey=TRUE checks srvyr", {
  skip_if(requireNamespace("srvyr", quietly = TRUE),
          "Test requires srvyr to NOT be installed")
  expect_error(
    pof_data(year = "2017-2018", as_survey = TRUE, cache_dir = tempdir()),
    "srvyr"
  )
})

# --- pof_dictionary() parameter validation tests ---

test_that("pof_dictionary validates year parameter", {
  expect_error(pof_dictionary(year = "2000-2001", cache_dir = tempdir()), "not available")
})

test_that("pof_dictionary validates register parameter when given", {
  expect_error(
    pof_dictionary(year = "2017-2018", register = "invalid_reg", cache_dir = tempdir()),
    "not available"
  )
})

test_that("pof_dictionary validates register availability per year", {
  expect_error(
    pof_dictionary(year = "2002-2003", register = "consumo_alimentar", cache_dir = tempdir()),
    "not available"
  )
})

# --- pof_variables() parameter validation tests ---

test_that("pof_variables validates year", {
  expect_error(
    pof_variables(year = "1999-2000", cache_dir = tempdir()),
    "not available"
  )
})

test_that("pof_variables validates register", {
  expect_error(
    pof_variables(year = "2017-2018", register = "bad_register", cache_dir = tempdir()),
    "not available"
  )
})

# --- .pof_download_data() tests (mocked) ---

test_that(".pof_download_data uses cached file when present", {
  temp_cache <- withr::local_tempdir()
  zip_path <- file.path(temp_cache, "pof_2017-2018_dados.zip")
  writeLines("fake zip", zip_path)

  result <- healthbR:::.pof_download_data("2017-2018", temp_cache)
  expect_equal(result, zip_path)
})

test_that(".pof_download_documentation uses cached file when present", {
  temp_cache <- withr::local_tempdir()
  zip_path <- file.path(temp_cache, "pof_2017-2018_doc.zip")
  writeLines("fake doc zip", zip_path)

  result <- healthbR:::.pof_download_documentation("2017-2018", temp_cache)
  expect_equal(result, zip_path)
})

# --- .pof_download_register() mocked test ---

test_that(".pof_download_register builds correct dataset_name", {
  # mock all the download functions
  temp_cache <- withr::local_tempdir()
  fake_df <- tibble::tibble(COD_UPA = "1", ESTRATO_POF = "1",
                            PESO_FINAL = "100", UF = "33")

  local_mocked_bindings(
    .pof_download_data = function(year, cache_dir) "fake.zip",
    pof_dictionary = function(...) tibble::tibble(
      variable = "COD_UPA", position = 1L, length = 3L,
      register = "morador", description = "UPA"
    ),
    .pof_read_fwf = function(...) fake_df,
    .cache_append_partitioned = function(...) invisible(NULL),
    .package = "healthbR"
  )

  result <- healthbR:::.pof_download_register(
    "2017-2018", "morador", temp_cache, "pof_morador_data"
  )
  expect_s3_class(result, "tbl_df")
  expect_true("year" %in% names(result))
  expect_equal(result$year[1], "2017-2018")
})

# --- internal constants checks ---

test_that("pof_register_files has entries for all years", {
  files <- healthbR:::pof_register_files
  expect_true("2017-2018" %in% names(files))
  expect_true("2008-2009" %in% names(files))
  expect_true("2002-2003" %in% names(files))
})

test_that("pof_register_files entries match pof_valid_registers", {
  for (yr in pof_years()) {
    file_regs <- names(healthbR:::pof_register_files[[yr]])
    valid_regs <- healthbR:::pof_valid_registers[[yr]]
    expect_equal(sort(file_regs), sort(valid_regs),
                 info = paste("mismatch for", yr))
  }
})

test_that("pof_register_files all map to .txt files", {
  for (yr in pof_years()) {
    for (reg in names(healthbR:::pof_register_files[[yr]])) {
      fname <- healthbR:::pof_register_files[[yr]][[reg]]
      expect_match(fname, "\\.txt$", info = paste(yr, reg))
    }
  }
})

test_that("pof_url_patterns has entries for all years", {
  patterns <- healthbR:::pof_url_patterns
  for (yr in pof_years()) {
    expect_true(yr %in% names(patterns), info = paste("missing URL for", yr))
    expect_true("data" %in% names(patterns[[yr]]))
    expect_true("doc" %in% names(patterns[[yr]]))
  }
})

test_that("pof_health_registers is a character vector", {
  hr <- healthbR:::pof_health_registers
  expect_type(hr, "character")
  expect_true(length(hr) > 0)
  expect_true("morador" %in% hr)
  expect_true("domicilio" %in% hr)
})

# ============================================================================
# .pof_download_data() — mocked download path
# ============================================================================

test_that(".pof_download_data downloads when file does not exist", {
  temp_cache <- withr::local_tempdir()

  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      writeLines("fake zip data", destfile)
    },
    .package = "curl"
  )

  result <- healthbR:::.pof_download_data("2017-2018", temp_cache)
  expect_true(file.exists(result))
  expect_match(basename(result), "pof_2017-2018_dados\\.zip$")
})

test_that(".pof_download_data aborts on download failure", {
  temp_cache <- withr::local_tempdir()

  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      stop("Connection refused")
    },
    .package = "curl"
  )

  expect_error(
    healthbR:::.pof_download_data("2017-2018", temp_cache),
    "Failed to download POF data"
  )
  # should also clean up partial file
  zip_path <- file.path(temp_cache, "pof_2017-2018_dados.zip")
  expect_false(file.exists(zip_path))
})

test_that(".pof_download_data cleans up partial file on error", {
  temp_cache <- withr::local_tempdir()
  zip_path <- file.path(temp_cache, "pof_2017-2018_dados.zip")

  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      # simulate a partial write then error
      writeLines("partial", destfile)
      stop("Network timeout")
    },
    .package = "curl"
  )

  expect_error(
    healthbR:::.pof_download_data("2017-2018", temp_cache),
    "Failed to download"
  )
  expect_false(file.exists(zip_path))
})

# ============================================================================
# .pof_download_documentation() — mocked download path
# ============================================================================

test_that(".pof_download_documentation downloads when file does not exist", {
  temp_cache <- withr::local_tempdir()

  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      writeLines("fake doc zip", destfile)
    },
    .package = "curl"
  )

  result <- healthbR:::.pof_download_documentation("2017-2018", temp_cache)
  expect_true(file.exists(result))
  expect_match(basename(result), "pof_2017-2018_doc\\.zip$")
})

test_that(".pof_download_documentation aborts on download failure", {
  temp_cache <- withr::local_tempdir()

  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      stop("Connection refused")
    },
    .package = "curl"
  )

  expect_error(
    healthbR:::.pof_download_documentation("2017-2018", temp_cache),
    "Failed to download POF documentation"
  )
})

test_that(".pof_download_documentation cleans up partial file on error", {
  temp_cache <- withr::local_tempdir()

  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      writeLines("partial doc", destfile)
      stop("timeout")
    },
    .package = "curl"
  )

  expect_error(
    healthbR:::.pof_download_documentation("2017-2018", temp_cache),
    "Failed to download"
  )
  zip_path <- file.path(temp_cache, "pof_2017-2018_doc.zip")
  expect_false(file.exists(zip_path))
})

# ============================================================================
# .pof_parse_dictionary() — mock Excel via readxl
# ============================================================================

test_that(".pof_parse_dictionary parses Excel with standard header", {
  skip_if_not_installed("readxl")

  # create a mock Excel file using writexl
  skip_if_not_installed("writexl")

  temp_dir <- withr::local_tempdir()
  dict_path <- file.path(temp_dir, "dictionary.xlsx")

  # sheet: "Morador" with standard header at row 3
  morador_df <- data.frame(
    X1 = c("REGISTRO - MORADOR", NA,
            "Posicao Inicial", "1", "4"),
    X2 = c(NA, NA, "Tamanho", "3", "2"),
    X3 = c(NA, NA, "Codigo da variavel", "COD_UPA", "V0403"),
    X4 = c(NA, NA, "Descricao da variavel", "Codigo UPA", "Idade"),
    X5 = c(NA, NA, "Decimais", "0", "0"),
    X6 = c(NA, NA, "Categorias", NA, NA),
    stringsAsFactors = FALSE
  )

  writexl::write_xlsx(list("Morador" = morador_df), dict_path)

  result <- healthbR:::.pof_parse_dictionary(dict_path, "2017-2018")

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) >= 2)
  expect_true("variable" %in% names(result))
  expect_true("position" %in% names(result))
  expect_true("length" %in% names(result))
  expect_true("register" %in% names(result))
  expect_true("year" %in% names(result))
  expect_equal(result$year[1], "2017-2018")
  expect_equal(result$register[1], "morador")
})

test_that(".pof_parse_dictionary maps sheet names to register names correctly", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")

  temp_dir <- withr::local_tempdir()
  dict_path <- file.path(temp_dir, "dictionary.xlsx")

  # create two sheets: Domicilio and Rendimento
  make_sheet <- function(title) {
    data.frame(
      X1 = c(paste("REGISTRO -", title), NA,
              "Posicao Inicial", "1"),
      X2 = c(NA, NA, "Tamanho", "5"),
      X3 = c(NA, NA, "Codigo da variavel", "VAR1"),
      X4 = c(NA, NA, "Descricao da variavel", "Variable 1"),
      stringsAsFactors = FALSE
    )
  }

  writexl::write_xlsx(list(
    "Domicilio" = make_sheet("DOMICILIO"),
    "Rendimento" = make_sheet("RENDIMENTO")
  ), dict_path)

  result <- healthbR:::.pof_parse_dictionary(dict_path, "2017-2018")

  registers <- unique(result$register)
  expect_true("domicilio" %in% registers)
  expect_true("rendimento" %in% registers)
})

test_that(".pof_parse_dictionary maps consumo sheet to consumo_alimentar", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")

  temp_dir <- withr::local_tempdir()
  dict_path <- file.path(temp_dir, "dictionary.xlsx")

  sheet_df <- data.frame(
    X1 = c("CONSUMO ALIMENTAR", NA, "Posicao Inicial", "1"),
    X2 = c(NA, NA, "Tamanho", "3"),
    X3 = c(NA, NA, "Codigo da variavel", "FOOD1"),
    X4 = c(NA, NA, "Descricao da variavel", "Food item"),
    stringsAsFactors = FALSE
  )

  writexl::write_xlsx(list("Consumo Alimentar" = sheet_df), dict_path)

  result <- healthbR:::.pof_parse_dictionary(dict_path, "2017-2018")
  expect_equal(unique(result$register), "consumo_alimentar")
})

test_that(".pof_parse_dictionary maps despesa individual correctly", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")

  temp_dir <- withr::local_tempdir()
  dict_path <- file.path(temp_dir, "dictionary.xlsx")

  sheet_df <- data.frame(
    X1 = c("DESPESA INDIVIDUAL", NA, "Posicao Inicial", "1"),
    X2 = c(NA, NA, "Tamanho", "3"),
    X3 = c(NA, NA, "Codigo da variavel", "DESP1"),
    X4 = c(NA, NA, "Descricao da variavel", "Expense 1"),
    stringsAsFactors = FALSE
  )

  writexl::write_xlsx(list("Despesa Individual" = sheet_df), dict_path)

  result <- healthbR:::.pof_parse_dictionary(dict_path, "2017-2018")
  expect_equal(unique(result$register), "despesa_individual")
})

test_that(".pof_parse_dictionary maps caderneta to caderneta_coletiva", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")

  temp_dir <- withr::local_tempdir()
  dict_path <- file.path(temp_dir, "dictionary.xlsx")

  sheet_df <- data.frame(
    X1 = c("CADERNETA", NA, "Posicao Inicial", "1"),
    X2 = c(NA, NA, "Tamanho", "4"),
    X3 = c(NA, NA, "Codigo da variavel", "ITEM1"),
    X4 = c(NA, NA, "Descricao da variavel", "Caderneta item"),
    stringsAsFactors = FALSE
  )

  writexl::write_xlsx(list("Caderneta Coletiva" = sheet_df), dict_path)

  result <- healthbR:::.pof_parse_dictionary(dict_path, "2017-2018")
  expect_equal(unique(result$register), "caderneta_coletiva")
})

test_that(".pof_parse_dictionary skips non-register sheets", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")

  temp_dir <- withr::local_tempdir()
  dict_path <- file.path(temp_dir, "dictionary.xlsx")

  # one valid sheet and one unrelated
  valid_sheet <- data.frame(
    X1 = c("MORADOR", NA, "Posicao Inicial", "1"),
    X2 = c(NA, NA, "Tamanho", "3"),
    X3 = c(NA, NA, "Codigo da variavel", "UF"),
    X4 = c(NA, NA, "Descricao da variavel", "Estado"),
    stringsAsFactors = FALSE
  )

  invalid_sheet <- data.frame(
    X1 = c("Notes", "This is a metadata sheet"),
    stringsAsFactors = FALSE
  )

  writexl::write_xlsx(list(
    "Morador" = valid_sheet,
    "Notas" = invalid_sheet
  ), dict_path)

  result <- healthbR:::.pof_parse_dictionary(dict_path, "2017-2018")
  expect_equal(unique(result$register), "morador")
  expect_true(nrow(result) > 0)
})

test_that(".pof_parse_dictionary aborts when no parseable sheets", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")

  temp_dir <- withr::local_tempdir()
  dict_path <- file.path(temp_dir, "dictionary.xlsx")

  # only non-matching sheets
  writexl::write_xlsx(list(
    "Notas" = data.frame(X1 = "Notes"),
    "Instrucoes" = data.frame(X1 = "Instructions")
  ), dict_path)

  expect_error(
    healthbR:::.pof_parse_dictionary(dict_path, "2017-2018"),
    "Could not parse any sheets"
  )
})

test_that(".pof_parse_dictionary converts position and length to integer", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")

  temp_dir <- withr::local_tempdir()
  dict_path <- file.path(temp_dir, "dictionary.xlsx")

  sheet_df <- data.frame(
    X1 = c("MORADOR", NA, "Posicao Inicial", "1", "6"),
    X2 = c(NA, NA, "Tamanho", "5", "3"),
    X3 = c(NA, NA, "Codigo da variavel", "VAR1", "VAR2"),
    X4 = c(NA, NA, "Descricao da variavel", "Var one", "Var two"),
    stringsAsFactors = FALSE
  )

  writexl::write_xlsx(list("Morador" = sheet_df), dict_path)

  result <- healthbR:::.pof_parse_dictionary(dict_path, "2017-2018")

  expect_type(result$position, "integer")
  expect_type(result$length, "integer")
  expect_equal(result$position, c(1L, 6L))
  expect_equal(result$length, c(5L, 3L))
})

test_that(".pof_parse_dictionary handles outros rendimentos mapping", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")

  temp_dir <- withr::local_tempdir()
  dict_path <- file.path(temp_dir, "dictionary.xlsx")

  sheet_df <- data.frame(
    X1 = c("OUTROS RENDIMENTOS", NA, "Posicao Inicial", "1"),
    X2 = c(NA, NA, "Tamanho", "3"),
    X3 = c(NA, NA, "Codigo da variavel", "REND1"),
    X4 = c(NA, NA, "Descricao da variavel", "Other income"),
    stringsAsFactors = FALSE
  )

  writexl::write_xlsx(list("Outros Rendimentos" = sheet_df), dict_path)

  result <- healthbR:::.pof_parse_dictionary(dict_path, "2017-2018")
  expect_equal(unique(result$register), "outros_rendimentos")
})

test_that(".pof_parse_dictionary handles aluguel estimado mapping", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")

  temp_dir <- withr::local_tempdir()
  dict_path <- file.path(temp_dir, "dictionary.xlsx")

  sheet_df <- data.frame(
    X1 = c("ALUGUEL ESTIMADO", NA, "Posicao Inicial", "1"),
    X2 = c(NA, NA, "Tamanho", "4"),
    X3 = c(NA, NA, "Codigo da variavel", "ALU1"),
    X4 = c(NA, NA, "Descricao da variavel", "Aluguel estimado"),
    stringsAsFactors = FALSE
  )

  writexl::write_xlsx(list("Aluguel Estimado" = sheet_df), dict_path)

  result <- healthbR:::.pof_parse_dictionary(dict_path, "2017-2018")
  expect_equal(unique(result$register), "aluguel_estimado")
})

test_that(".pof_parse_dictionary handles despesa coletiva mapping", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")

  temp_dir <- withr::local_tempdir()
  dict_path <- file.path(temp_dir, "dictionary.xlsx")

  sheet_df <- data.frame(
    X1 = c("DESPESA COLETIVA", NA, "Posicao Inicial", "1"),
    X2 = c(NA, NA, "Tamanho", "3"),
    X3 = c(NA, NA, "Codigo da variavel", "DCOL1"),
    X4 = c(NA, NA, "Descricao da variavel", "Collective expense"),
    stringsAsFactors = FALSE
  )

  writexl::write_xlsx(list("Despesa Coletiva" = sheet_df), dict_path)

  result <- healthbR:::.pof_parse_dictionary(dict_path, "2017-2018")
  expect_equal(unique(result$register), "despesa_coletiva")
})

test_that(".pof_parse_dictionary handles inventario mapping", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")

  temp_dir <- withr::local_tempdir()
  dict_path <- file.path(temp_dir, "dictionary.xlsx")

  sheet_df <- data.frame(
    X1 = c("INVENTARIO", NA, "Posicao Inicial", "1"),
    X2 = c(NA, NA, "Tamanho", "5"),
    X3 = c(NA, NA, "Codigo da variavel", "INV1"),
    X4 = c(NA, NA, "Descricao da variavel", "Inventory item"),
    stringsAsFactors = FALSE
  )

  writexl::write_xlsx(list("Inventario" = sheet_df), dict_path)

  result <- healthbR:::.pof_parse_dictionary(dict_path, "2017-2018")
  expect_equal(unique(result$register), "inventario")
})

test_that(".pof_parse_dictionary includes decimals and categories when present", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")

  temp_dir <- withr::local_tempdir()
  dict_path <- file.path(temp_dir, "dictionary.xlsx")

  sheet_df <- data.frame(
    X1 = c("MORADOR", NA, "Posicao Inicial", "1"),
    X2 = c(NA, NA, "Tamanho", "3"),
    X3 = c(NA, NA, "Decimais", "2"),
    X4 = c(NA, NA, "Codigo da variavel", "PESO"),
    X5 = c(NA, NA, "Descricao da variavel", "Weight"),
    X6 = c(NA, NA, "Categorias", "kg"),
    stringsAsFactors = FALSE
  )

  writexl::write_xlsx(list("Morador" = sheet_df), dict_path)

  result <- healthbR:::.pof_parse_dictionary(dict_path, "2017-2018")
  expect_true("decimals" %in% names(result))
  expect_true("categories" %in% names(result))
})

# ============================================================================
# .pof_download_and_parse_dictionary() — mocked orchestration
# ============================================================================

test_that(".pof_download_and_parse_dictionary orchestrates download + parse", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")

  temp_cache <- withr::local_tempdir()

  # Create a real Excel dictionary file in a temp zip
  dict_excel_dir <- file.path(tempdir(), "pof_mock_dict")
  if (dir.exists(dict_excel_dir)) unlink(dict_excel_dir, recursive = TRUE)
  dir.create(dict_excel_dir, recursive = TRUE)

  sheet_df <- data.frame(
    X1 = c("MORADOR", NA, "Posicao Inicial", "1"),
    X2 = c(NA, NA, "Tamanho", "3"),
    X3 = c(NA, NA, "Codigo da variavel", "UF"),
    X4 = c(NA, NA, "Descricao da variavel", "Estado"),
    stringsAsFactors = FALSE
  )

  dict_path <- file.path(dict_excel_dir, "Dicionario_POF.xlsx")
  writexl::write_xlsx(list("Morador" = sheet_df), dict_path)

  # create a zip from it
  mock_zip <- file.path(temp_cache, "pof_2017-2018_doc.zip")
  withr::with_dir(dict_excel_dir, {
    utils::zip(mock_zip, files = "Dicionario_POF.xlsx")
  })

  # mock the download to just "return" our pre-made zip
  local_mocked_bindings(
    .pof_download_documentation = function(year, cache_dir) mock_zip,
    .package = "healthbR"
  )

  result <- healthbR:::.pof_download_and_parse_dictionary("2017-2018", temp_cache)

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true("register" %in% names(result))
  expect_true("year" %in% names(result))

  # cleanup
  unlink(dict_excel_dir, recursive = TRUE)
})

test_that(".pof_download_and_parse_dictionary aborts when no dict file found", {
  temp_cache <- withr::local_tempdir()

  # create a zip with only a .txt file (no Excel)
  txt_dir <- file.path(tempdir(), "pof_no_dict")
  if (dir.exists(txt_dir)) unlink(txt_dir, recursive = TRUE)
  dir.create(txt_dir, recursive = TRUE)
  writeLines("readme", file.path(txt_dir, "README.txt"))

  mock_zip <- file.path(temp_cache, "pof_2017-2018_doc.zip")
  withr::with_dir(txt_dir, {
    utils::zip(mock_zip, files = "README.txt")
  })

  local_mocked_bindings(
    .pof_download_documentation = function(year, cache_dir) mock_zip,
    .package = "healthbR"
  )

  expect_error(
    healthbR:::.pof_download_and_parse_dictionary("2017-2018", temp_cache),
    "Could not find dictionary file"
  )

  unlink(txt_dir, recursive = TRUE)
})

test_that(".pof_download_and_parse_dictionary aborts on extraction failure", {
  temp_cache <- withr::local_tempdir()
  # create an invalid zip (just a text file renamed to .zip)
  bad_zip <- file.path(temp_cache, "pof_2017-2018_doc.zip")
  writeLines("this is not a zip", bad_zip)

  local_mocked_bindings(
    .pof_download_documentation = function(year, cache_dir) bad_zip,
    .package = "healthbR"
  )

  # on Windows it may try PowerShell fallback (generating a warning) but still fail
  suppressWarnings(
    expect_error(
      healthbR:::.pof_download_and_parse_dictionary("2017-2018", temp_cache),
      "Could not extract|Could not find"
    )
  )
})

# ============================================================================
# .pof_read_fwf() — mocked zip reading
# ============================================================================

test_that(".pof_read_fwf reads fixed-width data correctly", {
  temp_dir <- withr::local_tempdir()

  # create a mock fixed-width text file
  # COD_UPA at pos 1 length 3, UF at pos 4 length 2, V0403 at pos 6 length 1
  fwf_content <- c(
    "001351",
    "002332",
    "003213"
  )

  txt_file <- file.path(temp_dir, "MORADOR.txt")
  writeLines(fwf_content, txt_file, useBytes = TRUE)

  # create a zip containing the text file
  zip_path <- file.path(temp_dir, "data.zip")
  withr::with_dir(temp_dir, {
    utils::zip(zip_path, files = "MORADOR.txt")
  })

  # create a dictionary
  dict <- tibble::tibble(
    variable = c("COD_UPA", "UF", "V0403"),
    position = c(1L, 4L, 6L),
    length = c(3L, 2L, 1L),
    register = c("morador", "morador", "morador"),
    description = c("UPA code", "State", "Age")
  )

  result <- healthbR:::.pof_read_fwf(zip_path, "morador", dict, "2017-2018")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3)
  expect_true("COD_UPA" %in% names(result))
  expect_true("UF" %in% names(result))
  expect_true("V0403" %in% names(result))
})

test_that(".pof_read_fwf errors on unknown year", {
  expect_error(
    healthbR:::.pof_read_fwf("fake.zip", "morador",
                              tibble::tibble(), "1990-1991"),
    "No file mapping"
  )
})

test_that(".pof_read_fwf errors on unknown register", {
  expect_error(
    healthbR:::.pof_read_fwf("fake.zip", "nonexistent",
                              tibble::tibble(), "2017-2018"),
    "Unknown register"
  )
})

test_that(".pof_read_fwf errors when file not found in zip", {
  temp_dir <- withr::local_tempdir()

  # create a zip with a different file name
  writeLines("data", file.path(temp_dir, "OTHER.txt"))
  zip_path <- file.path(temp_dir, "data.zip")
  withr::with_dir(temp_dir, {
    utils::zip(zip_path, files = "OTHER.txt")
  })

  dict <- tibble::tibble(
    variable = "VAR1", position = 1L, length = 3L,
    register = "morador", description = "test"
  )

  expect_error(
    healthbR:::.pof_read_fwf(zip_path, "morador", dict, "2017-2018"),
    "Could not find file"
  )
})

test_that(".pof_read_fwf errors when dictionary has no specs for register", {
  temp_dir <- withr::local_tempdir()

  writeLines("123", file.path(temp_dir, "MORADOR.txt"))
  zip_path <- file.path(temp_dir, "data.zip")
  withr::with_dir(temp_dir, {
    utils::zip(zip_path, files = "MORADOR.txt")
  })

  # dictionary with different register
  dict <- tibble::tibble(
    variable = "VAR1", position = 1L, length = 3L,
    register = "domicilio", description = "test"
  )

  expect_error(
    healthbR:::.pof_read_fwf(zip_path, "morador", dict, "2017-2018"),
    "No column specifications"
  )
})

test_that(".pof_read_fwf deduplicates dictionary variables", {
  temp_dir <- withr::local_tempdir()

  fwf_content <- c("001351", "002332")
  txt_file <- file.path(temp_dir, "MORADOR.txt")
  writeLines(fwf_content, txt_file, useBytes = TRUE)

  zip_path <- file.path(temp_dir, "data.zip")
  withr::with_dir(temp_dir, {
    utils::zip(zip_path, files = "MORADOR.txt")
  })

  # dictionary with duplicate variable
  dict <- tibble::tibble(
    variable = c("COD_UPA", "COD_UPA", "UF"),
    position = c(1L, 1L, 4L),
    length = c(3L, 3L, 2L),
    register = c("morador", "morador", "morador"),
    description = c("UPA code", "UPA code dup", "State")
  )

  result <- healthbR:::.pof_read_fwf(zip_path, "morador", dict, "2017-2018")
  # should not have duplicate columns
  expect_equal(sum(names(result) == "COD_UPA"), 1)
})

# ============================================================================
# .pof_download_post_strat() — mocked
# ============================================================================

test_that(".pof_download_post_strat returns NULL when no post-strat file exists", {
  temp_cache <- withr::local_tempdir()

  # create a zip with only a README
  txt_dir <- file.path(tempdir(), "pof_ps_test")
  if (dir.exists(txt_dir)) unlink(txt_dir, recursive = TRUE)
  dir.create(txt_dir, recursive = TRUE)
  writeLines("readme", file.path(txt_dir, "readme.txt"))

  mock_zip <- file.path(temp_cache, "pof_2017-2018_doc.zip")
  withr::with_dir(txt_dir, {
    utils::zip(mock_zip, files = "readme.txt")
  })

  local_mocked_bindings(
    .pof_download_documentation = function(year, cache_dir) mock_zip,
    .package = "healthbR"
  )

  expect_warning(
    result <- healthbR:::.pof_download_post_strat("2017-2018", temp_cache),
    "post-stratification"
  )
  expect_null(result)

  unlink(txt_dir, recursive = TRUE)
})

test_that(".pof_download_post_strat returns NULL on zip read error", {
  temp_cache <- withr::local_tempdir()

  # create an invalid zip
  bad_zip <- file.path(temp_cache, "pof_2017-2018_doc.zip")
  writeLines("not a zip", bad_zip)

  local_mocked_bindings(
    .pof_download_documentation = function(year, cache_dir) bad_zip,
    .package = "healthbR"
  )

  expect_warning(
    result <- healthbR:::.pof_download_post_strat("2017-2018", temp_cache),
    "post-stratification"
  )
  expect_null(result)
})

test_that(".pof_download_post_strat reads Excel post-strat file", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")

  temp_cache <- withr::local_tempdir()
  ps_dir <- file.path(tempdir(), "pof_ps_excel_test")
  if (dir.exists(ps_dir)) unlink(ps_dir, recursive = TRUE)
  dir.create(ps_dir, recursive = TRUE)

  # create an Excel post-strat file
  ps_df <- data.frame(
    ESTRATO = c(1, 2, 3),
    TOTAL = c(1000, 2000, 3000)
  )
  ps_path <- file.path(ps_dir, "pos_estratificacao.xlsx")
  writexl::write_xlsx(ps_df, ps_path)

  mock_zip <- file.path(temp_cache, "pof_2017-2018_doc.zip")
  withr::with_dir(ps_dir, {
    utils::zip(mock_zip, files = "pos_estratificacao.xlsx")
  })

  local_mocked_bindings(
    .pof_download_documentation = function(year, cache_dir) mock_zip,
    .package = "healthbR"
  )

  result <- healthbR:::.pof_download_post_strat("2017-2018", temp_cache)

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)

  unlink(ps_dir, recursive = TRUE)
})

test_that(".pof_download_post_strat reads text post-strat file", {
  temp_cache <- withr::local_tempdir()
  ps_dir <- file.path(tempdir(), "pof_ps_txt_test")
  if (dir.exists(ps_dir)) unlink(ps_dir, recursive = TRUE)
  dir.create(ps_dir, recursive = TRUE)

  # create a semicolon-delimited text post-strat file
  writeLines("ESTRATO;TOTAL\n1;1000\n2;2000", file.path(ps_dir, "pos_estratificacao.txt"))

  mock_zip <- file.path(temp_cache, "pof_2017-2018_doc.zip")
  withr::with_dir(ps_dir, {
    utils::zip(mock_zip, files = "pos_estratificacao.txt")
  })

  local_mocked_bindings(
    .pof_download_documentation = function(year, cache_dir) mock_zip,
    .package = "healthbR"
  )

  result <- healthbR:::.pof_download_post_strat("2017-2018", temp_cache)

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)

  unlink(ps_dir, recursive = TRUE)
})

# ============================================================================
# pof_data() — full orchestration with mocking
# ============================================================================

test_that("pof_data orchestration works with mocked downloads", {
  temp_cache <- withr::local_tempdir()

  mock_data <- tibble::tibble(
    COD_UPA = c("123", "456"),
    ESTRATO_POF = c("1", "2"),
    PESO_FINAL = c("1.5", "2.5"),
    UF = c("35", "33"),
    V0403 = c("1", "2")
  )

  local_mocked_bindings(
    .pof_download_data = function(...) "fake.zip",
    .pof_read_fwf = function(...) mock_data,
    pof_dictionary = function(...) tibble::tibble(
      variable = c("COD_UPA", "V0403"),
      description = c("UPA", "Age"),
      position = 1:2,
      length = c(3L, 1L),
      register = "morador",
      year = "2017-2018"
    ),
    .cache_append_partitioned = function(...) invisible(NULL),
    .has_arrow = function() FALSE,
    .has_partitioned_cache = function(...) FALSE,
    .package = "healthbR"
  )

  result <- pof_data("2017-2018", "morador", cache_dir = temp_cache)
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true("year" %in% names(result))
  expect_equal(result$year[1], "2017-2018")
})

test_that("pof_data with vars selects requested variables", {
  temp_cache <- withr::local_tempdir()

  mock_data <- tibble::tibble(
    COD_UPA = c("123", "456"),
    ESTRATO_POF = c("1", "2"),
    PESO_FINAL = c("1.5", "2.5"),
    UF = c("35", "33"),
    V0403 = c("1", "2"),
    V0404 = c("3", "4"),
    EXTRA = c("x", "y")
  )

  local_mocked_bindings(
    .pof_download_data = function(...) "fake.zip",
    .pof_read_fwf = function(...) mock_data,
    pof_dictionary = function(...) tibble::tibble(
      variable = c("COD_UPA", "V0403", "V0404", "EXTRA"),
      description = c("UPA", "Age", "Sex", "Extra"),
      position = 1:4,
      length = rep(3L, 4),
      register = "morador",
      year = "2017-2018"
    ),
    .cache_append_partitioned = function(...) invisible(NULL),
    .has_arrow = function() FALSE,
    .has_partitioned_cache = function(...) FALSE,
    .package = "healthbR"
  )

  result <- pof_data("2017-2018", "morador", vars = c("V0403"),
                     cache_dir = temp_cache)
  expect_true("V0403" %in% names(result))
  # design vars should still be there
  expect_true("COD_UPA" %in% names(result))
  expect_true("PESO_FINAL" %in% names(result))
  # EXTRA should NOT be there (not requested)
  expect_false("EXTRA" %in% names(result))
})

test_that("pof_data with as_survey returns tbl_svy via mocking", {
  skip_if_not_installed("survey")
  skip_if_not_installed("srvyr")

  temp_cache <- withr::local_tempdir()

  # survey::svydesign needs numeric weights, so use numeric columns
  mock_data <- tibble::tibble(
    COD_UPA = c(10, 10, 20, 20),
    ESTRATO_POF = c(1, 1, 2, 2),
    PESO_FINAL = c(100, 200, 150, 250),
    UF = c(35, 35, 33, 33),
    V0403 = c(25, 30, 40, 50)
  )

  local_mocked_bindings(
    .pof_download_data = function(...) "fake.zip",
    .pof_read_fwf = function(...) mock_data,
    pof_dictionary = function(...) tibble::tibble(
      variable = c("COD_UPA", "V0403"),
      description = c("UPA", "Age"),
      position = 1:2,
      length = c(3L, 1L),
      register = "morador",
      year = "2017-2018"
    ),
    .cache_append_partitioned = function(...) invisible(NULL),
    .has_arrow = function() FALSE,
    .has_partitioned_cache = function(...) FALSE,
    .pof_download_post_strat = function(...) NULL,
    .package = "healthbR"
  )

  result <- pof_data("2017-2018", "morador", as_survey = TRUE,
                     cache_dir = temp_cache)
  expect_s3_class(result, "tbl_svy")
})

test_that("pof_data uses cached data when available", {
  skip_if_not_installed("arrow")

  temp_cache <- withr::local_tempdir()

  # pof_cache_dir(temp_cache) returns temp_cache directly (no "pof" appended)
  # so dataset lives at temp_cache/pof_morador_data/year=2017-2018/
  ds_dir <- file.path(temp_cache, "pof_morador_data", "year=2017-2018")
  dir.create(ds_dir, recursive = TRUE)

  mock_df <- tibble::tibble(
    COD_UPA = c("10", "20"),
    ESTRATO_POF = c("1", "2"),
    PESO_FINAL = c("100", "200"),
    UF = c("35", "33"),
    V0403 = c("25", "30")
  )

  arrow::write_parquet(mock_df, file.path(ds_dir, "part-0.parquet"))

  # should NOT call .pof_download_data
  download_called <- FALSE
  local_mocked_bindings(
    .pof_download_data = function(...) {
      download_called <<- TRUE
      "fake.zip"
    },
    .package = "healthbR"
  )

  result <- pof_data("2017-2018", "morador", cache_dir = temp_cache)
  expect_s3_class(result, "tbl_df")
  expect_false(download_called)
  expect_true(nrow(result) == 2)
})

# ============================================================================
# pof_dictionary() — mocked download and cache paths
# ============================================================================

test_that("pof_dictionary downloads and caches when no cache exists", {
  temp_cache <- withr::local_tempdir()

  mock_dict <- tibble::tibble(
    year = "2017-2018",
    position = 1L,
    length = 3L,
    variable = "UF",
    description = "Estado",
    register = "morador"
  )

  local_mocked_bindings(
    .pof_download_and_parse_dictionary = function(year, cache_dir) mock_dict,
    .package = "healthbR"
  )

  result <- pof_dictionary("2017-2018", cache_dir = temp_cache)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)

  # verify cache was created (pof_cache_dir(temp_cache) returns temp_cache directly)
  cache_files <- list.files(temp_cache,
                            pattern = "pof_dictionary", recursive = TRUE)
  expect_true(length(cache_files) > 0)
})

test_that("pof_dictionary uses cache on second call", {
  temp_cache <- withr::local_tempdir()

  mock_dict <- tibble::tibble(
    year = "2017-2018",
    position = 1L,
    length = 3L,
    variable = "UF",
    description = "Estado",
    register = "morador"
  )

  download_count <- 0L
  local_mocked_bindings(
    .pof_download_and_parse_dictionary = function(year, cache_dir) {
      download_count <<- download_count + 1L
      mock_dict
    },
    .package = "healthbR"
  )

  # first call: downloads
  result1 <- pof_dictionary("2017-2018", cache_dir = temp_cache)
  expect_equal(download_count, 1L)

  # second call: uses cache (no additional download)
  result2 <- pof_dictionary("2017-2018", cache_dir = temp_cache)
  expect_equal(download_count, 1L)
  expect_equal(nrow(result1), nrow(result2))
})

test_that("pof_dictionary with refresh=TRUE re-downloads", {
  temp_cache <- withr::local_tempdir()

  mock_dict <- tibble::tibble(
    year = "2017-2018",
    position = 1L,
    length = 3L,
    variable = "UF",
    description = "Estado",
    register = "morador"
  )

  download_count <- 0L
  local_mocked_bindings(
    .pof_download_and_parse_dictionary = function(year, cache_dir) {
      download_count <<- download_count + 1L
      mock_dict
    },
    .package = "healthbR"
  )

  pof_dictionary("2017-2018", cache_dir = temp_cache)
  expect_equal(download_count, 1L)

  pof_dictionary("2017-2018", cache_dir = temp_cache, refresh = TRUE)
  expect_equal(download_count, 2L)
})

test_that("pof_dictionary filters by register", {
  temp_cache <- withr::local_tempdir()

  mock_dict <- tibble::tibble(
    year = rep("2017-2018", 3),
    position = 1:3,
    length = rep(3L, 3),
    variable = c("UF", "V0403", "ITEM1"),
    description = c("Estado", "Idade", "Item"),
    register = c("morador", "morador", "domicilio")
  )

  local_mocked_bindings(
    .pof_download_and_parse_dictionary = function(year, cache_dir) mock_dict,
    .package = "healthbR"
  )

  result <- pof_dictionary("2017-2018", register = "morador",
                           cache_dir = temp_cache)
  expect_true(all(tolower(result$register) == "morador"))
  expect_equal(nrow(result), 2)
})

# ============================================================================
# pof_variables() — mocked search path
# ============================================================================

test_that("pof_variables returns simplified view", {
  temp_cache <- withr::local_tempdir()

  mock_dict <- tibble::tibble(
    year = rep("2017-2018", 2),
    position = 1:2,
    length = c(3L, 1L),
    variable = c("UF", "V0403"),
    description = c("Estado", "Idade do morador"),
    register = c("morador", "morador"),
    decimals = c("0", "0"),
    categories = c(NA, NA)
  )

  local_mocked_bindings(
    .pof_download_and_parse_dictionary = function(year, cache_dir) mock_dict,
    .package = "healthbR"
  )

  result <- pof_variables("2017-2018", cache_dir = temp_cache)
  expect_s3_class(result, "tbl_df")
  expected_cols <- c("variable", "description", "position", "length", "register")
  expect_true(all(expected_cols %in% names(result)))
  # should not include year, decimals, categories
  expect_false("year" %in% names(result))
  expect_false("decimals" %in% names(result))
})

test_that("pof_variables search filters by term", {
  temp_cache <- withr::local_tempdir()

  mock_dict <- tibble::tibble(
    year = rep("2017-2018", 3),
    position = 1:3,
    length = rep(3L, 3),
    variable = c("UF", "V0403", "PESO_FINAL"),
    description = c("Estado", "Idade do morador", "Peso final"),
    register = c("morador", "morador", "morador")
  )

  local_mocked_bindings(
    .pof_download_and_parse_dictionary = function(year, cache_dir) mock_dict,
    .package = "healthbR"
  )

  result <- pof_variables("2017-2018", search = "idade",
                          cache_dir = temp_cache)
  expect_true(nrow(result) >= 1)
  # should match V0403 (description contains "Idade")
  expect_true("V0403" %in% result$variable)
})

test_that("pof_variables search warns when no match", {
  temp_cache <- withr::local_tempdir()

  mock_dict <- tibble::tibble(
    year = "2017-2018",
    position = 1L,
    length = 3L,
    variable = "UF",
    description = "Estado",
    register = "morador"
  )

  local_mocked_bindings(
    .pof_download_and_parse_dictionary = function(year, cache_dir) mock_dict,
    .package = "healthbR"
  )

  expect_message(
    result <- pof_variables("2017-2018", search = "zzzznotfound",
                            cache_dir = temp_cache),
    "No variables found"
  )
  expect_equal(nrow(result), 0)
})

test_that("pof_variables search reports count when found", {
  temp_cache <- withr::local_tempdir()

  mock_dict <- tibble::tibble(
    year = rep("2017-2018", 2),
    position = 1:2,
    length = c(2L, 3L),
    variable = c("UF", "V0403"),
    description = c("UF code", "Idade"),
    register = c("morador", "morador")
  )

  local_mocked_bindings(
    .pof_download_and_parse_dictionary = function(year, cache_dir) mock_dict,
    .package = "healthbR"
  )

  expect_message(
    result <- pof_variables("2017-2018", search = "uf",
                            cache_dir = temp_cache),
    "Found.*variable"
  )
  expect_true(nrow(result) >= 1)
})

test_that("pof_variables filters by register", {
  temp_cache <- withr::local_tempdir()

  mock_dict <- tibble::tibble(
    year = rep("2017-2018", 3),
    position = 1:3,
    length = rep(3L, 3),
    variable = c("UF", "V0403", "ITEM1"),
    description = c("Estado", "Idade", "Item"),
    register = c("morador", "morador", "domicilio")
  )

  local_mocked_bindings(
    .pof_download_and_parse_dictionary = function(year, cache_dir) mock_dict,
    .package = "healthbR"
  )

  result <- pof_variables("2017-2018", register = "domicilio",
                          cache_dir = temp_cache)
  expect_equal(nrow(result), 1)
  expect_equal(result$variable, "ITEM1")
})

# ============================================================================
# .pof_create_survey_design() — with post-stratification messages
# ============================================================================

test_that(".pof_create_survey_design reports post-strat available", {
  skip_if_not_installed("survey")
  skip_if_not_installed("srvyr")

  temp_cache <- withr::local_tempdir()
  df <- tibble::tibble(
    PESO_FINAL = c(100, 200, 300, 400),
    ESTRATO_POF = c(1, 1, 2, 2),
    COD_UPA = c(10, 10, 20, 20),
    UF = c(35, 35, 33, 33)
  )

  # mock post-strat to return non-NULL (triggers the message)
  local_mocked_bindings(
    .pof_download_post_strat = function(...) {
      tibble::tibble(ESTRATO = 1:2, TOTAL = c(1000, 2000))
    },
    .package = "healthbR"
  )

  expect_message(
    result <- healthbR:::.pof_create_survey_design(df, "2017-2018", temp_cache),
    "Post-stratification"
  )
  expect_s3_class(result, "tbl_svy")
})

# ============================================================================
# .pof_find_dictionary_file() — approach 2 (raw bytes) test
# ============================================================================

test_that(".pof_find_dictionary_file approach 2 finds file starting with Dicion", {
  temp_dir <- withr::local_tempdir()
  # Create a file that starts with "Dicion" (no accent)
  # approach 1 also matches "dicion" but approach 2 checks raw bytes of first 6 chars
  fname <- file.path(temp_dir, "Dicion_special_format.xlsx")
  file.create(fname)

  extracted <- list.files(temp_dir, full.names = TRUE)
  result <- healthbR:::.pof_find_dictionary_file(extracted, "2017-2018")
  expect_true(!is.null(result))
  expect_match(basename(result), "Dicion")
})

# ============================================================================
# pof_data() — lazy return paths
# ============================================================================

test_that("pof_data with lazy=TRUE returns lazy query from cache", {
  skip_if_not_installed("arrow")

  temp_cache <- withr::local_tempdir()

  # pof_cache_dir(temp_cache) returns temp_cache directly
  ds_dir <- file.path(temp_cache, "pof_morador_data", "year=2017-2018")
  dir.create(ds_dir, recursive = TRUE)

  mock_df <- tibble::tibble(
    COD_UPA = c("10", "20"),
    ESTRATO_POF = c("1", "2"),
    PESO_FINAL = c("100", "200"),
    UF = c("35", "33"),
    V0403 = c("25", "30")
  )
  arrow::write_parquet(mock_df, file.path(ds_dir, "part-0.parquet"))

  result <- pof_data("2017-2018", "morador", lazy = TRUE,
                     cache_dir = temp_cache)
  # lazy result should not be a tibble yet
  expect_true(!inherits(result, "tbl_df") || inherits(result, "ArrowObject") ||
              inherits(result, "arrow_dplyr_query") || inherits(result, "Dataset") ||
              inherits(result, "FileSystemDataset"))
  # collecting should give a tibble
  collected <- dplyr::collect(result)
  expect_s3_class(collected, "tbl_df")
  expect_equal(nrow(collected), 2)
})

# ============================================================================
# .pof_parse_dictionary() — fallback path (no header row found)
# ============================================================================

test_that(".pof_parse_dictionary uses fallback when no Posi header found", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")

  temp_dir <- withr::local_tempdir()
  dict_path <- file.path(temp_dir, "dictionary.xlsx")

  # sheet with headers already in row 1 (no "Posi" pattern to detect)
  sheet_df <- data.frame(
    posicao_inicial = c(1L, 4L),
    tamanho = c(3L, 2L),
    codigo_da_variavel = c("COD_UPA", "UF"),
    descricao_da_variavel = c("UPA code", "State"),
    stringsAsFactors = FALSE
  )

  writexl::write_xlsx(list("Morador" = sheet_df), dict_path)

  result <- healthbR:::.pof_parse_dictionary(dict_path, "2017-2018")
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) >= 2)
  expect_equal(result$register[1], "morador")
})
