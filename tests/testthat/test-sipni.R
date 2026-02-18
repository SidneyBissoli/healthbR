# tests for SI-PNI module functions

# ============================================================================
# sipni_years
# ============================================================================

test_that("sipni_years returns integer vector", {
  years <- sipni_years()
  expect_type(years, "integer")
  expect_gt(length(years), 0)
  expect_true(2019L %in% years)
  expect_true(1994L %in% years)
})

test_that("sipni_years contains expected range including API years", {
  years <- sipni_years()
  expect_equal(min(years), 1994L)
  expect_equal(max(years), 2025L)
  expect_equal(length(years), 32)
  expect_true(2020L %in% years)
  expect_true(2025L %in% years)
})

# ============================================================================
# sipni_info
# ============================================================================

test_that("sipni_info returns expected structure", {
  info <- sipni_info()

  expect_type(info, "list")
  expect_true("name" %in% names(info))
  expect_true("source" %in% names(info))
  expect_true("years" %in% names(info))
  expect_true("n_types" %in% names(info))
  expect_true("n_variables_dpni" %in% names(info))
  expect_true("n_variables_cpni" %in% names(info))
  expect_true("n_variables_api" %in% names(info))
})

test_that("sipni_info mentions both data sources", {
  info <- sipni_info()
  expect_true(grepl("FTP", info$source))
  expect_true(grepl("CSV", info$source))
  expect_true("url_ftp" %in% names(info))
  expect_true("url_csv" %in% names(info))
})

# ============================================================================
# sipni_variables
# ============================================================================

test_that("sipni_variables returns tibble with expected columns", {
  vars <- sipni_variables()
  expect_s3_class(vars, "tbl_df")
  expect_true(all(c("variable", "description", "type", "section") %in% names(vars)))
  expect_gt(nrow(vars), 0)
})

test_that("sipni_variables DPNI has expected variables", {
  vars <- sipni_variables(type = "DPNI")
  expect_true("IMUNO" %in% vars$variable)
  expect_true("QT_DOSE" %in% vars$variable)
  expect_true("DOSE" %in% vars$variable)
  expect_true("FX_ETARIA" %in% vars$variable)
  expect_true("ANO" %in% vars$variable)
  expect_true("MUNIC" %in% vars$variable)
  expect_equal(nrow(vars), 12)
})

test_that("sipni_variables CPNI has expected variables", {
  vars <- sipni_variables(type = "CPNI")
  expect_true("IMUNO" %in% vars$variable)
  expect_true("QT_DOSE" %in% vars$variable)
  expect_true("POP" %in% vars$variable)
  expect_true("COBERT" %in% vars$variable)
  expect_equal(nrow(vars), 7)
})

test_that("sipni_variables API has expected variables", {
  vars <- sipni_variables(type = "API")
  expect_s3_class(vars, "tbl_df")
  expect_true(all(c("variable", "description", "type", "section") %in% names(vars)))
  expect_equal(nrow(vars), 47)
})

test_that("sipni_variables API has key variables", {
  vars <- sipni_variables(type = "API")
  expect_true("data_vacina" %in% vars$variable)
  expect_true("descricao_vacina" %in% vars$variable)
  expect_true("tipo_sexo_paciente" %in% vars$variable)
  expect_true("numero_idade_paciente" %in% vars$variable)
  expect_true("sigla_uf_estabelecimento" %in% vars$variable)
  expect_true("codigo_paciente" %in% vars$variable)
})

test_that("sipni_variables API has correct sections", {
  vars <- sipni_variables(type = "API")
  sections <- unique(vars$section)
  expect_true("estabelecimento" %in% sections)
  expect_true("paciente" %in% sections)
  expect_true("vacina" %in% sections)
  expect_true("administracao" %in% sections)
  expect_true("estrategia" %in% sections)
  expect_true("maternal" %in% sections)
})

test_that("sipni_variables API search works", {
  result <- sipni_variables(type = "API", search = "vacina")
  expect_gt(nrow(result), 0)
})

test_that("sipni_variables search works", {
  result <- sipni_variables(search = "dose")
  expect_gt(nrow(result), 0)
})

test_that("sipni_variables search is accent-insensitive", {
  result_accent <- sipni_variables(search = "refer\u00eancia")
  result_plain <- sipni_variables(search = "referencia")
  expect_equal(nrow(result_accent), nrow(result_plain))
})

test_that("sipni_variables search returns empty tibble for no match", {
  result <- sipni_variables(search = "zzzznonexistent")
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

# ============================================================================
# sipni_dictionary
# ============================================================================

test_that("sipni_dictionary returns tibble with expected columns", {
  dict <- sipni_dictionary()
  expect_s3_class(dict, "tbl_df")
  expect_true(all(c("variable", "description", "code", "label") %in% names(dict)))
  expect_gt(nrow(dict), 0)
})

test_that("sipni_dictionary filters by variable", {
  imuno <- sipni_dictionary("IMUNO")
  expect_true(all(imuno$variable == "IMUNO"))
  expect_gt(nrow(imuno), 10)
})

test_that("sipni_dictionary case insensitive", {
  lower <- sipni_dictionary("imuno")
  upper <- sipni_dictionary("IMUNO")
  expect_equal(nrow(lower), nrow(upper))
})

test_that("sipni_dictionary warns on unknown variable", {
  expect_warning(sipni_dictionary("NONEXISTENT"), "not found")
})

test_that("sipni_dictionary has key variables", {
  dict <- sipni_dictionary()
  dict_vars <- unique(dict$variable)
  expect_true("IMUNO" %in% dict_vars)
  expect_true("DOSE" %in% dict_vars)
  expect_true("FX_ETARIA" %in% dict_vars)
})

# ============================================================================
# .sipni_build_ftp_url
# ============================================================================

test_that(".sipni_build_ftp_url constructs correct URL for DPNI", {
  url <- .sipni_build_ftp_url(2019, "AC", "DPNI")
  expect_match(url, "PNI/DADOS/DPNIAC19\\.DBF$")
  expect_match(url, "^ftp://ftp\\.datasus\\.gov\\.br/")
})

test_that(".sipni_build_ftp_url constructs correct URL for CPNI", {
  url <- .sipni_build_ftp_url(2019, "SP", "CPNI")
  expect_match(url, "PNI/DADOS/CPNISP19\\.DBF$")
})

test_that(".sipni_build_ftp_url handles different UFs and years", {
  url1 <- .sipni_build_ftp_url(1994, "RJ")
  expect_match(url1, "DPNIRJ94\\.DBF$")

  url2 <- .sipni_build_ftp_url(2000, "MG")
  expect_match(url2, "DPNIMG00\\.DBF$")

  url3 <- .sipni_build_ftp_url(2010, "BA", "CPNI")
  expect_match(url3, "CPNIBA10\\.DBF$")
})

test_that(".sipni_build_ftp_url errors on pre-1994", {
  expect_error(.sipni_build_ftp_url(1993, "SP"), "not supported")
})

# ============================================================================
# .sipni_csv_build_url
# ============================================================================

test_that(".sipni_csv_build_url constructs correct URL", {
  url <- .sipni_csv_build_url(2024, 1)
  expect_equal(url,
    "https://arquivosdadosabertos.saude.gov.br/dados/dbbni/vacinacao_jan_2024_csv.zip")
})

test_that(".sipni_csv_build_url works for different months", {
  url_jun <- .sipni_csv_build_url(2024, 6)
  expect_match(url_jun, "vacinacao_jun_2024_csv\\.zip$")

  url_dez <- .sipni_csv_build_url(2025, 12)
  expect_match(url_dez, "vacinacao_dez_2025_csv\\.zip$")
})

test_that(".sipni_csv_build_url uses correct Portuguese month names", {
  months <- c("jan", "fev", "mar", "abr", "mai", "jun",
              "jul", "ago", "set", "out", "nov", "dez")
  for (i in seq_along(months)) {
    url <- .sipni_csv_build_url(2024, i)
    expect_match(url, months[i], info = paste("Month", i))
  }
})

# ============================================================================
# .sipni_validate_type
# ============================================================================

test_that(".sipni_validate_type accepts valid types", {
  expect_equal(.sipni_validate_type("DPNI"), "DPNI")
  expect_equal(.sipni_validate_type("CPNI"), "CPNI")
  expect_equal(.sipni_validate_type("API"), "API")
})

test_that(".sipni_validate_type is case-insensitive", {
  expect_equal(.sipni_validate_type("dpni"), "DPNI")
  expect_equal(.sipni_validate_type("cpni"), "CPNI")
  expect_equal(.sipni_validate_type("Dpni"), "DPNI")
  expect_equal(.sipni_validate_type("api"), "API")
})

test_that(".sipni_validate_type errors on invalid type", {
  expect_error(.sipni_validate_type("XX"), "Invalid")
  expect_error(.sipni_validate_type("ST"), "Invalid")
})

# ============================================================================
# .sipni_validate_year
# ============================================================================

test_that(".sipni_validate_year accepts valid FTP years", {
  expect_equal(.sipni_validate_year(2019), 2019L)
  expect_equal(.sipni_validate_year(c(2018, 2019)), c(2018L, 2019L))
  expect_equal(.sipni_validate_year(1994), 1994L)
})

test_that(".sipni_validate_year accepts valid API years", {
  expect_equal(.sipni_validate_year(2020), 2020L)
  expect_equal(.sipni_validate_year(2024), 2024L)
  expect_equal(.sipni_validate_year(2025), 2025L)
  expect_equal(.sipni_validate_year(c(2020, 2025)), c(2020L, 2025L))
})

test_that(".sipni_validate_year accepts mixed FTP and API years", {
  expect_equal(.sipni_validate_year(c(2019, 2020)),
               c(2019L, 2020L))
})

test_that(".sipni_validate_year errors on invalid years", {
  expect_error(.sipni_validate_year(1993), "not available")
  expect_error(.sipni_validate_year(2026), "not available")
  expect_error(.sipni_validate_year(2050), "not available")
})

test_that(".sipni_validate_year errors on NULL", {
  expect_error(.sipni_validate_year(NULL), "required")
})

# ============================================================================
# .validate_month
# ============================================================================

test_that(".validate_month returns 1:12 for NULL", {
  result <- .validate_month(NULL)
  expect_equal(result, 1L:12L)
})

test_that(".validate_month accepts valid months", {
  expect_equal(.validate_month(1), 1L)
  expect_equal(.validate_month(12), 12L)
  expect_equal(.validate_month(1:6), 1L:6L)
  expect_equal(.validate_month(c(1, 6, 12)), c(1L, 6L, 12L))
})

test_that(".validate_month errors on invalid months", {
  expect_error(.validate_month(0), "Invalid")
  expect_error(.validate_month(13), "Invalid")
  expect_error(.validate_month(-1), "Invalid")
  expect_error(.validate_month(c(1, 13)), "Invalid")
})

# ============================================================================
# .sipni_validate_uf
# ============================================================================

test_that(".sipni_validate_uf accepts valid UFs", {
  expect_equal(.sipni_validate_uf("SP"), "SP")
  expect_equal(.sipni_validate_uf("sp"), "SP")
  expect_equal(.sipni_validate_uf(c("SP", "RJ")), c("SP", "RJ"))
})

test_that(".sipni_validate_uf errors on invalid UFs", {
  expect_error(.sipni_validate_uf("XX"), "Invalid")
  expect_error(.sipni_validate_uf(c("SP", "ZZ")), "Invalid")
})

# ============================================================================
# .sipni_validate_vars
# ============================================================================

test_that(".sipni_validate_vars warns on unknown variables", {
  expect_warning(.sipni_validate_vars("NONEXISTENT"), "not in known")
  expect_warning(
    .sipni_validate_vars(c("IMUNO", "FAKECOL")),
    "not in known"
  )
})

test_that(".sipni_validate_vars silent on known variables", {
  expect_no_warning(.sipni_validate_vars("IMUNO"))
  expect_no_warning(.sipni_validate_vars(c("IMUNO", "QT_DOSE", "DOSE")))
})

test_that(".sipni_validate_vars works for API type", {
  expect_no_warning(
    .sipni_validate_vars("data_vacina", type = "API")
  )
  expect_no_warning(
    .sipni_validate_vars(c("descricao_vacina", "tipo_sexo_paciente"),
                         type = "API")
  )
  expect_warning(
    .sipni_validate_vars("IMUNO", type = "API"),
    "not in known"
  )
})

# ============================================================================
# sipni_valid_types
# ============================================================================

test_that("sipni_valid_types has correct structure", {
  expect_equal(nrow(sipni_valid_types), 3)
  expect_true(all(c("code", "name", "description") %in% names(sipni_valid_types)))
  expect_true("DPNI" %in% sipni_valid_types$code)
  expect_true("CPNI" %in% sipni_valid_types$code)
  expect_true("API" %in% sipni_valid_types$code)
})

# ============================================================================
# year ranges
# ============================================================================

test_that("sipni_ftp_years covers 1994-2019", {
  expect_equal(sipni_ftp_years, 1994L:2019L)
})

test_that("sipni_api_years covers 2020-2025", {
  expect_equal(sipni_api_years, 2020L:2025L)
})

test_that("sipni_available_years is the union of FTP and API years", {
  expect_equal(sipni_available_years, c(sipni_ftp_years, sipni_api_years))
})

# ============================================================================
# sipni_label_maps
# ============================================================================

test_that("sipni_label_maps are consistent with dictionary", {
  for (var_name in names(sipni_label_maps)) {
    dict_rows <- sipni_dictionary(var_name)
    map_codes <- names(sipni_label_maps[[var_name]])
    expect_true(all(map_codes %in% dict_rows$code),
                info = paste(var_name, "label_maps codes not in dictionary"))
  }
})

# ============================================================================
# sipni_cache functions
# ============================================================================

test_that("sipni_cache_status works with empty cache", {
  temp_dir <- tempfile("sipni_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  result <- sipni_cache_status(cache_dir = temp_dir)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("sipni_clear_cache works with empty cache", {
  temp_dir <- tempfile("sipni_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  expect_no_error(sipni_clear_cache(cache_dir = temp_dir))
})

test_that("sipni_cache_status detects cached files including API format", {
  temp_dir <- tempfile("sipni_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  # create fake cache files (FTP + API formats)
  writeLines("test", file.path(temp_dir, "sipni_DPNI_AC_2019.rds"))
  writeLines("test", file.path(temp_dir, "sipni_DPNI_SP_2019.rds"))
  writeLines("test", file.path(temp_dir, "sipni_API_AC_202401.rds"))

  result <- sipni_cache_status(cache_dir = temp_dir)
  expect_equal(nrow(result), 3)
  expect_true(all(grepl("^sipni_", result$file)))
})

test_that("sipni_clear_cache removes cached files", {
  temp_dir <- tempfile("sipni_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  writeLines("test", file.path(temp_dir, "sipni_DPNI_AC_2019.rds"))
  writeLines("test", file.path(temp_dir, "sipni_API_AC_202401.rds"))
  sipni_clear_cache(cache_dir = temp_dir)

  files <- list.files(temp_dir, pattern = "^sipni_")
  expect_equal(length(files), 0)
})

test_that(".sipni_cache_dir creates directory", {
  temp_dir <- file.path(tempdir(), "sipni_cache_test_create")
  on.exit(unlink(temp_dir, recursive = TRUE))

  result <- .sipni_cache_dir(temp_dir)
  expect_true(dir.exists(result))
  expect_equal(result, temp_dir)
})

# ============================================================================
# API cache naming
# ============================================================================

test_that("API cache naming follows expected pattern", {
  # verify that the cache base naming for API data uses the right format
  cache_base <- stringr::str_c("sipni_API_", "AC", "_", 2024, sprintf("%02d", 1))
  expect_equal(cache_base, "sipni_API_AC_202401")

  cache_base2 <- stringr::str_c("sipni_API_", "SP", "_", 2025, sprintf("%02d", 12))
  expect_equal(cache_base2, "sipni_API_SP_202512")
})

# ============================================================================
# CSV base URL and month names
# ============================================================================

test_that("sipni_csv_base_url is correct", {
  expect_equal(sipni_csv_base_url,
               "https://arquivosdadosabertos.saude.gov.br/dados/dbbni")
})

test_that("sipni_month_names has 12 Portuguese month abbreviations", {
  expect_equal(length(sipni_month_names), 12)
  expect_equal(sipni_month_names[1], "jan")
  expect_equal(sipni_month_names[6], "jun")
  expect_equal(sipni_month_names[12], "dez")
})

# ============================================================================
# integration tests (require internet + HEALTHBR_INTEGRATION=true)
# ============================================================================

test_that("sipni_data downloads DPNI single year single UF", {
  skip_if_no_integration()

  data <- sipni_data(year = 2019, uf = "AC", cache_dir = tempdir())
  expect_s3_class(data, "tbl_df")
  expect_gt(nrow(data), 0)
  expect_true("year" %in% names(data))
  expect_true("uf_source" %in% names(data))
  expect_equal(unique(data$year), 2019L)
  expect_equal(unique(data$uf_source), "AC")
})

test_that("sipni_data downloads CPNI single year single UF", {
  skip_if_no_integration()

  data <- sipni_data(year = 2019, type = "CPNI", uf = "AC",
                     cache_dir = tempdir())
  expect_s3_class(data, "tbl_df")
  expect_gt(nrow(data), 0)
  expect_true("year" %in% names(data))
  expect_true("uf_source" %in% names(data))
})

test_that("sipni_data selects variables", {
  skip_if_no_integration()

  data <- sipni_data(year = 2019, uf = "AC",
                     vars = c("IMUNO", "QT_DOSE"),
                     cache_dir = tempdir())
  expect_true("IMUNO" %in% names(data))
  expect_true("QT_DOSE" %in% names(data))
  expect_true("year" %in% names(data))
  expect_true("uf_source" %in% names(data))
})

test_that("sipni_data cache works (second call faster)", {
  skip_if_no_integration()

  cache_dir <- tempfile("sipni_cache_test")
  dir.create(cache_dir, recursive = TRUE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  t1 <- system.time(sipni_data(year = 2019, uf = "AC",
                                cache_dir = cache_dir))
  t2 <- system.time(sipni_data(year = 2019, uf = "AC",
                                cache_dir = cache_dir))
  expect_lt(t2["elapsed"], t1["elapsed"])
})

# ============================================================================
# API integration tests
# ============================================================================

test_that("sipni_data downloads API data for single month", {
  skip_if_no_integration()

  cache_dir <- tempfile("sipni_api_test")
  dir.create(cache_dir, recursive = TRUE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  data <- sipni_data(year = 2024, uf = "AC", month = 1,
                     cache_dir = cache_dir)
  expect_s3_class(data, "tbl_df")
  expect_gt(nrow(data), 0)
  expect_true("year" %in% names(data))
  expect_true("uf_source" %in% names(data))
  expect_equal(unique(data$year), 2024L)
  expect_equal(unique(data$uf_source), "AC")
  # verify API columns present
  expect_true("data_vacina" %in% names(data))
  expect_true("descricao_vacina" %in% names(data))
})

test_that("sipni_data API column names match expected", {
  skip_if_no_integration()

  cache_dir <- tempfile("sipni_api_test2")
  dir.create(cache_dir, recursive = TRUE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  data <- sipni_data(year = 2024, uf = "AC", month = 1,
                     cache_dir = cache_dir)
  expected_vars <- sipni_variables_api$variable
  # all expected vars should be in data (excluding year/uf_source)
  data_vars <- setdiff(names(data), c("year", "uf_source"))
  # at least key vars should be present
  expect_true("data_vacina" %in% data_vars)
  expect_true("tipo_sexo_paciente" %in% data_vars)
})

test_that("sipni_data API cache works", {
  skip_if_no_integration()

  cache_dir <- tempfile("sipni_api_cache_test")
  dir.create(cache_dir, recursive = TRUE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  t1 <- system.time(sipni_data(year = 2024, uf = "AC", month = 1,
                                cache_dir = cache_dir))
  t2 <- system.time(sipni_data(year = 2024, uf = "AC", month = 1,
                                cache_dir = cache_dir))
  expect_lt(t2["elapsed"], t1["elapsed"])
})

# ============================================================================
# smart type parsing
# ============================================================================

test_that("sipni_variables type column has non-character types (DPNI)", {
  vars <- sipni_variables(type = "DPNI")
  expect_equal(vars$type[vars$variable == "QT_DOSE"], "integer")
  expect_equal(vars$type[vars$variable == "IMUNO"], "character")
})

test_that("sipni_variables type column has non-character types (CPNI)", {
  vars <- sipni_variables(type = "CPNI")
  expect_equal(vars$type[vars$variable == "QT_DOSE"], "integer")
  expect_equal(vars$type[vars$variable == "POP"], "integer")
  expect_equal(vars$type[vars$variable == "COBERT"], "double")
})

test_that("sipni_variables type column has non-character types (API)", {
  vars <- sipni_variables(type = "API")
  expect_equal(vars$type[vars$variable == "data_vacina"], "date")
  expect_equal(vars$type[vars$variable == "numero_idade_paciente"], "integer")
  expect_equal(vars$type[vars$variable == "tipo_sexo_paciente"], "character")
})

test_that("sipni parse converts mock FTP data correctly", {
  mock_data <- tibble::tibble(
    year = 2019L, uf_source = "AC",
    QT_DOSE = "100", IMUNO = "09", MUNIC = "120040"
  )
  spec <- .build_type_spec(sipni_variables_dpni)
  parsed <- .parse_columns(mock_data, spec)

  expect_type(parsed$QT_DOSE, "integer")
  expect_type(parsed$IMUNO, "character")
})

test_that("sipni parse converts mock API data correctly", {
  mock_data <- tibble::tibble(
    year = 2024L, month = 1L, uf_source = "AC",
    data_vacina = "2024-01-15",
    numero_idade_paciente = "30",
    tipo_sexo_paciente = "F"
  )
  spec <- .build_type_spec(sipni_variables_api)
  parsed <- .parse_columns(mock_data, spec)

  expect_s3_class(parsed$data_vacina, "Date")
  expect_type(parsed$numero_idade_paciente, "integer")
  expect_type(parsed$tipo_sexo_paciente, "character")
})


# ============================================================================
# consolidated download failure reporting
# ============================================================================

test_that("sipni_data reports partial download failures (FTP)", {
  local_mocked_bindings(
    .sipni_validate_year = function(year) as.integer(year),
    .sipni_validate_uf = function(uf) toupper(uf),
    .sipni_download_and_read = function(year, uf, ...) {
      if (uf == "XX") stop("Not found")
      tibble::tibble(year = as.integer(year), uf_source = uf, IMUNO = "001")
    }
  )
  # use year 2019 to stay in FTP path (sipni_ftp_years)
  result <- suppressWarnings(
    sipni_data(2019, uf = c("AC", "XX"), parse = FALSE)
  )
  expect_s3_class(result, "data.frame")
  failures <- attr(result, "download_failures")
  expect_false(is.null(failures))
  expect_equal(failures, "XX 2019")
})


# ============================================================================
# additional unit tests (no HTTP downloads)
# ============================================================================

# --- sipni_info ---

test_that("sipni_info returns invisible", {
  result <- withVisible(sipni_info())
  expect_false(result$visible)
})

test_that("sipni_info list has all expected fields", {
  info <- sipni_info()
  expected_fields <- c(
    "name", "source", "years", "n_types",
    "n_variables_dpni", "n_variables_cpni", "n_variables_api",
    "url_ftp", "url_csv"
  )
  for (f in expected_fields) {
    expect_true(f %in% names(info), info = paste("Missing field:", f))
  }
})

test_that("sipni_info years matches sipni_years()", {
  info <- sipni_info()
  expect_equal(info$years, sipni_years())
})

test_that("sipni_info n_types matches valid types", {
  info <- sipni_info()
  expect_equal(info$n_types, nrow(sipni_valid_types))
})

# --- .sipni_resolve_params ---

test_that(".sipni_resolve_params splits years into FTP and API groups", {
  params <- healthbR:::.sipni_resolve_params(
    year = c(2019, 2020), type = "DPNI", uf = "AC",
    month = NULL, vars = NULL, missing_type = TRUE
  )

  expect_equal(params$ftp_years, 2019L)
  expect_equal(params$api_years, 2020L)
  expect_equal(params$target_ufs, "AC")
})

test_that(".sipni_resolve_params FTP only years", {
  params <- healthbR:::.sipni_resolve_params(
    year = c(2018, 2019), type = "DPNI", uf = NULL,
    month = NULL, vars = NULL, missing_type = TRUE
  )

  expect_equal(params$ftp_years, c(2018L, 2019L))
  expect_equal(params$api_years, integer(0))
  expect_equal(params$target_ufs, sipni_uf_list)
})

test_that(".sipni_resolve_params API only years", {
  params <- healthbR:::.sipni_resolve_params(
    year = c(2024, 2025), type = "DPNI", uf = "SP",
    month = 1:3, vars = NULL, missing_type = TRUE
  )

  expect_equal(params$ftp_years, integer(0))
  expect_equal(params$api_years, c(2024L, 2025L))
  expect_equal(params$month_vals, 1L:3L)
})

test_that(".sipni_resolve_params validates type for FTP years", {
  expect_error(
    healthbR:::.sipni_resolve_params(
      year = 2019, type = "INVALID", uf = NULL,
      month = NULL, vars = NULL, missing_type = FALSE
    ),
    "Invalid"
  )
})

test_that(".sipni_resolve_params validates UF", {
  expect_error(
    healthbR:::.sipni_resolve_params(
      year = 2019, type = "DPNI", uf = "XX",
      month = NULL, vars = NULL, missing_type = TRUE
    ),
    "Invalid"
  )
})

test_that(".sipni_resolve_params warns when type set for API years", {
  expect_warning(
    healthbR:::.sipni_resolve_params(
      year = 2024, type = "DPNI", uf = "AC",
      month = NULL, vars = NULL, missing_type = FALSE
    ),
    "ignored"
  )
})

test_that(".sipni_resolve_params does not warn when type is missing for API", {
  expect_no_warning(
    healthbR:::.sipni_resolve_params(
      year = 2024, type = "DPNI", uf = "AC",
      month = NULL, vars = NULL, missing_type = TRUE
    )
  )
})

test_that(".sipni_resolve_params validates vars with warning", {
  expect_warning(
    healthbR:::.sipni_resolve_params(
      year = 2019, type = "DPNI", uf = "AC",
      month = NULL, vars = c("FAKECOL"), missing_type = TRUE
    ),
    "not in known"
  )
})

test_that(".sipni_resolve_params validates API vars correctly", {
  expect_no_warning(
    healthbR:::.sipni_resolve_params(
      year = 2024, type = "DPNI", uf = "AC",
      month = 1, vars = c("data_vacina"), missing_type = TRUE
    )
  )
})

test_that(".sipni_resolve_params month validation passes through", {
  params <- healthbR:::.sipni_resolve_params(
    year = 2024, type = "DPNI", uf = "AC",
    month = c(1, 6), vars = NULL, missing_type = TRUE
  )
  expect_equal(params$month_vals, c(1L, 6L))
})

test_that(".sipni_resolve_params NULL month returns 1:12", {
  params <- healthbR:::.sipni_resolve_params(
    year = 2024, type = "DPNI", uf = "AC",
    month = NULL, vars = NULL, missing_type = TRUE
  )
  expect_equal(params$month_vals, 1L:12L)
})

# --- .sipni_try_lazy_pre ---

test_that(".sipni_try_lazy_pre returns NULL when lazy=FALSE", {
  params <- list(
    ftp_years = 2019L, api_years = integer(0),
    type = "DPNI", target_ufs = "AC", month_vals = 1L:12L
  )
  result <- healthbR:::.sipni_try_lazy_pre(
    params, lazy = FALSE, backend = "arrow",
    cache_dir = tempdir(), parse = FALSE
  )
  expect_null(result)
})

test_that(".sipni_try_lazy_pre returns NULL when no cache exists", {
  temp_dir <- withr::local_tempdir()
  params <- list(
    ftp_years = 2019L, api_years = integer(0),
    type = "DPNI", target_ufs = "AC", month_vals = 1L:12L
  )
  result <- healthbR:::.sipni_try_lazy_pre(
    params, lazy = TRUE, backend = "arrow",
    cache_dir = temp_dir, parse = FALSE
  )
  expect_null(result)
})

test_that(".sipni_try_lazy_pre informs when parse=TRUE and lazy=TRUE", {
  temp_dir <- withr::local_tempdir()
  params <- list(
    ftp_years = 2019L, api_years = integer(0),
    type = "DPNI", target_ufs = "AC", month_vals = 1L:12L
  )
  expect_message(
    healthbR:::.sipni_try_lazy_pre(
      params, lazy = TRUE, backend = "arrow",
      cache_dir = temp_dir, parse = TRUE
    ),
    "parse.*ignored"
  )
})

test_that(".sipni_try_lazy_pre returns NULL for API years with no cache", {
  temp_dir <- withr::local_tempdir()
  params <- list(
    ftp_years = integer(0), api_years = 2024L,
    type = "DPNI", target_ufs = "AC", month_vals = 1L:3L
  )
  result <- healthbR:::.sipni_try_lazy_pre(
    params, lazy = TRUE, backend = "arrow",
    cache_dir = temp_dir, parse = FALSE
  )
  expect_null(result)
})

# --- .sipni_try_lazy_post ---

test_that(".sipni_try_lazy_post returns NULL when lazy=FALSE", {
  result <- healthbR:::.sipni_try_lazy_post(
    lazy = FALSE, backend = "arrow", year = 2019L,
    type = "DPNI", uf = "AC", month = NULL, vars = NULL,
    cache_dir = tempdir()
  )
  expect_null(result)
})

test_that(".sipni_try_lazy_post returns NULL when no cache (FTP)", {
  temp_dir <- withr::local_tempdir()
  result <- healthbR:::.sipni_try_lazy_post(
    lazy = TRUE, backend = "arrow", year = 2019L,
    type = "DPNI", uf = "AC", month = NULL, vars = NULL,
    cache_dir = temp_dir
  )
  expect_null(result)
})

test_that(".sipni_try_lazy_post returns NULL when no cache (API)", {
  temp_dir <- withr::local_tempdir()
  result <- healthbR:::.sipni_try_lazy_post(
    lazy = TRUE, backend = "arrow", year = 2024L,
    type = "DPNI", uf = "AC", month = 1L, vars = NULL,
    cache_dir = temp_dir
  )
  expect_null(result)
})

test_that(".sipni_try_lazy_post returns NULL for mixed years (no cache)", {
  temp_dir <- withr::local_tempdir()
  result <- healthbR:::.sipni_try_lazy_post(
    lazy = TRUE, backend = "arrow", year = c(2019L, 2024L),
    type = "DPNI", uf = "AC", month = NULL, vars = NULL,
    cache_dir = temp_dir
  )
  expect_null(result)
})

# --- .sipni_bind_results ---

test_that(".sipni_bind_results binds FTP results only", {
  ftp1 <- tibble::tibble(year = 2018L, uf_source = "AC", IMUNO = "01")
  ftp2 <- tibble::tibble(year = 2019L, uf_source = "AC", IMUNO = "02")

  result <- healthbR:::.sipni_bind_results(
    ftp_results = list(ftp1, ftp2),
    api_results = list()
  )
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_true(all(c("year", "uf_source", "IMUNO") %in% names(result)))
})

test_that(".sipni_bind_results binds API results only", {
  api1 <- tibble::tibble(year = 2024L, month = 1L, uf_source = "AC",
                          data_vacina = "2024-01-15")
  api2 <- tibble::tibble(year = 2024L, month = 2L, uf_source = "AC",
                          data_vacina = "2024-02-15")

  result <- healthbR:::.sipni_bind_results(
    ftp_results = list(),
    api_results = list(api1, api2)
  )
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_true("data_vacina" %in% names(result))
})

test_that(".sipni_bind_results combines FTP and API with different columns", {
  ftp1 <- tibble::tibble(year = 2019L, uf_source = "AC", IMUNO = "01",
                          QT_DOSE = "100")
  api1 <- tibble::tibble(year = 2024L, month = 1L, uf_source = "AC",
                          data_vacina = "2024-01-15")

  result <- healthbR:::.sipni_bind_results(
    ftp_results = list(ftp1),
    api_results = list(api1)
  )
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  # both column sets should be present with NAs for missing
  expect_true("IMUNO" %in% names(result))
  expect_true("data_vacina" %in% names(result))
})

test_that(".sipni_bind_results errors when both empty", {
  expect_error(
    healthbR:::.sipni_bind_results(
      ftp_results = list(),
      api_results = list()
    ),
    "No data"
  )
})

# --- .sipni_apply_parsing ---

test_that(".sipni_apply_parsing with parse=FALSE returns unchanged", {
  mock_data <- tibble::tibble(
    year = 2019L, uf_source = "AC",
    QT_DOSE = "100", IMUNO = "09"
  )

  result <- healthbR:::.sipni_apply_parsing(
    mock_data, has_ftp = TRUE, has_api = FALSE,
    type = "DPNI", parse = FALSE, col_types = NULL, lazy = FALSE
  )

  expect_type(result$QT_DOSE, "character")
})

test_that(".sipni_apply_parsing with parse=TRUE converts FTP DPNI data", {
  mock_data <- tibble::tibble(
    year = 2019L, uf_source = "AC",
    QT_DOSE = "100", IMUNO = "09"
  )

  result <- healthbR:::.sipni_apply_parsing(
    mock_data, has_ftp = TRUE, has_api = FALSE,
    type = "DPNI", parse = TRUE, col_types = NULL, lazy = FALSE
  )

  expect_type(result$QT_DOSE, "integer")
  expect_type(result$IMUNO, "character")
})

test_that(".sipni_apply_parsing with parse=TRUE converts CPNI data", {
  mock_data <- tibble::tibble(
    year = 2019L, uf_source = "AC",
    QT_DOSE = "50", POP = "10000", COBERT = "85.5"
  )

  result <- healthbR:::.sipni_apply_parsing(
    mock_data, has_ftp = TRUE, has_api = FALSE,
    type = "CPNI", parse = TRUE, col_types = NULL, lazy = FALSE
  )

  expect_type(result$QT_DOSE, "integer")
  expect_type(result$POP, "integer")
  expect_type(result$COBERT, "double")
})

test_that(".sipni_apply_parsing with parse=TRUE converts API data", {
  mock_data <- tibble::tibble(
    year = 2024L, month = 1L, uf_source = "AC",
    data_vacina = "2024-01-15",
    numero_idade_paciente = "30",
    tipo_sexo_paciente = "F"
  )

  result <- healthbR:::.sipni_apply_parsing(
    mock_data, has_ftp = FALSE, has_api = TRUE,
    type = "DPNI", parse = TRUE, col_types = NULL, lazy = FALSE
  )

  expect_s3_class(result$data_vacina, "Date")
  expect_type(result$numero_idade_paciente, "integer")
  expect_type(result$tipo_sexo_paciente, "character")
})

test_that(".sipni_apply_parsing returns unchanged when lazy=TRUE", {
  mock_data <- tibble::tibble(
    year = 2019L, uf_source = "AC",
    QT_DOSE = "100"
  )

  result <- healthbR:::.sipni_apply_parsing(
    mock_data, has_ftp = TRUE, has_api = FALSE,
    type = "DPNI", parse = TRUE, col_types = NULL, lazy = TRUE
  )

  # should not parse since lazy=TRUE
  expect_type(result$QT_DOSE, "character")
})

test_that(".sipni_apply_parsing with col_types override", {
  mock_data <- tibble::tibble(
    year = 2019L, uf_source = "AC",
    QT_DOSE = "100", IMUNO = "09"
  )

  result <- healthbR:::.sipni_apply_parsing(
    mock_data, has_ftp = TRUE, has_api = FALSE,
    type = "DPNI", parse = TRUE,
    col_types = list(QT_DOSE = "character"), lazy = FALSE
  )

  # QT_DOSE should remain character due to override
  expect_type(result$QT_DOSE, "character")
})

test_that(".sipni_apply_parsing with mixed FTP+API specs", {
  mock_data <- tibble::tibble(
    year = c(2019L, 2024L), uf_source = c("AC", "AC"),
    QT_DOSE = c("100", NA_character_),
    data_vacina = c(NA_character_, "2024-01-15")
  )

  result <- healthbR:::.sipni_apply_parsing(
    mock_data, has_ftp = TRUE, has_api = TRUE,
    type = "DPNI", parse = TRUE, col_types = NULL, lazy = FALSE
  )

  expect_type(result$QT_DOSE, "integer")
  expect_s3_class(result$data_vacina, "Date")
})

# --- .sipni_download_ftp (mocked) ---

test_that(".sipni_download_ftp returns empty for no FTP years", {
  result <- healthbR:::.sipni_download_ftp(
    ftp_years = integer(0), target_ufs = "AC",
    type = "DPNI", cache = FALSE, cache_dir = tempdir()
  )

  expect_equal(result$results, list())
  expect_equal(result$failed_labels, character(0))
})

test_that(".sipni_download_ftp returns results for single UF/year", {
  local_mocked_bindings(
    .sipni_download_and_read = function(year, uf, type, cache, cache_dir) {
      tibble::tibble(year = as.integer(year), uf_source = uf, IMUNO = "01")
    },
    .map_parallel = function(.x, .f, ..., .delay = NULL) {
      lapply(.x, .f)
    }
  )

  result <- healthbR:::.sipni_download_ftp(
    ftp_years = 2019L, target_ufs = "AC",
    type = "DPNI", cache = FALSE, cache_dir = tempdir()
  )

  expect_equal(length(result$results), 1)
  expect_equal(result$results[[1]]$year, 2019L)
  expect_equal(result$results[[1]]$uf_source, "AC")
  expect_equal(length(result$failed_labels), 0)
})

test_that(".sipni_download_ftp records failures", {
  local_mocked_bindings(
    .sipni_download_and_read = function(year, uf, type, cache, cache_dir) {
      if (uf == "XX") stop("File not found")
      tibble::tibble(year = as.integer(year), uf_source = uf, IMUNO = "01")
    },
    .map_parallel = function(.x, .f, ..., .delay = NULL) {
      lapply(.x, .f)
    }
  )

  result <- healthbR:::.sipni_download_ftp(
    ftp_years = 2019L, target_ufs = c("AC", "XX"),
    type = "DPNI", cache = FALSE, cache_dir = tempdir()
  )

  expect_equal(length(result$results), 1)
  expect_equal(result$failed_labels, "XX 2019")
})

test_that(".sipni_download_ftp multiple UFs x years", {
  local_mocked_bindings(
    .sipni_download_and_read = function(year, uf, type, cache, cache_dir) {
      tibble::tibble(year = as.integer(year), uf_source = uf, IMUNO = "01")
    },
    .map_parallel = function(.x, .f, ..., .delay = NULL) {
      lapply(.x, .f)
    }
  )

  result <- healthbR:::.sipni_download_ftp(
    ftp_years = c(2018L, 2019L), target_ufs = c("AC", "SP"),
    type = "DPNI", cache = FALSE, cache_dir = tempdir()
  )

  expect_equal(length(result$results), 4)  # 2 years x 2 UFs
  expect_equal(length(result$failed_labels), 0)
})

# --- .sipni_download_api (mocked) ---

test_that(".sipni_download_api returns empty for no API years", {
  result <- healthbR:::.sipni_download_api(
    api_years = integer(0), target_ufs = "AC",
    month_vals = 1L:12L, cache = FALSE, cache_dir = tempdir()
  )

  expect_equal(result$results, list())
  expect_equal(result$failed_labels, character(0))
})

test_that(".sipni_download_api returns results for single UF/year", {
  local_mocked_bindings(
    .sipni_api_download_and_read = function(year, uf, month, cache, cache_dir) {
      tibble::tibble(year = as.integer(year), month = 1L, uf_source = uf,
                      data_vacina = "2024-01-15")
    },
    .map_parallel = function(.x, .f, ..., .delay = NULL) {
      lapply(.x, .f)
    }
  )

  result <- healthbR:::.sipni_download_api(
    api_years = 2024L, target_ufs = "AC",
    month_vals = 1L, cache = FALSE, cache_dir = tempdir()
  )

  expect_equal(length(result$results), 1)
  expect_equal(result$results[[1]]$year, 2024L)
  expect_equal(length(result$failed_labels), 0)
})

test_that(".sipni_download_api records failures", {
  local_mocked_bindings(
    .sipni_api_download_and_read = function(year, uf, month, cache, cache_dir) {
      if (uf == "XX") stop("Download failed")
      tibble::tibble(year = as.integer(year), month = 1L, uf_source = uf,
                      data_vacina = "2024-01-15")
    },
    .map_parallel = function(.x, .f, ..., .delay = NULL) {
      lapply(.x, .f)
    }
  )

  result <- healthbR:::.sipni_download_api(
    api_years = 2024L, target_ufs = c("AC", "XX"),
    month_vals = 1L, cache = FALSE, cache_dir = tempdir()
  )

  expect_equal(length(result$results), 1)
  expect_equal(result$failed_labels, "XX 2024")
})

test_that(".sipni_download_api treats empty tibble return as failure", {
  local_mocked_bindings(
    .sipni_api_download_and_read = function(year, uf, month, cache, cache_dir) {
      tibble::tibble()
    },
    .map_parallel = function(.x, .f, ..., .delay = NULL) {
      lapply(.x, .f)
    }
  )

  result <- healthbR:::.sipni_download_api(
    api_years = 2024L, target_ufs = "AC",
    month_vals = 1L, cache = FALSE, cache_dir = tempdir()
  )

  # empty tibble should be treated as NULL (nrow == 0 => return(NULL))
  expect_equal(length(result$results), 0)
  expect_equal(result$failed_labels, "AC 2024")
})

# --- .sipni_build_ftp_url (additional edge cases) ---

test_that(".sipni_build_ftp_url year 2019 produces '19' suffix", {
  url <- healthbR:::.sipni_build_ftp_url(2019, "AC", "DPNI")
  expect_match(url, "DPNIAC19\\.DBF$")
})

test_that(".sipni_build_ftp_url year 1994 produces '94' suffix", {
  url <- healthbR:::.sipni_build_ftp_url(1994, "SP", "DPNI")
  expect_match(url, "DPNISP94\\.DBF$")
})

test_that(".sipni_build_ftp_url year 2005 produces '05' suffix", {
  url <- healthbR:::.sipni_build_ftp_url(2005, "RJ", "CPNI")
  expect_match(url, "CPNIRJ05\\.DBF$")
})

# --- sipni_data parameter validation ---

test_that("sipni_data errors on NULL year", {
  expect_error(sipni_data(year = NULL), "required")
})

test_that("sipni_data errors on invalid year", {
  expect_error(sipni_data(year = 1990), "not available")
  expect_error(sipni_data(year = 2050), "not available")
})

test_that("sipni_data errors on invalid type", {
  expect_error(sipni_data(year = 2019, type = "ZZZZ"), "Invalid")
})

test_that("sipni_data errors on invalid month", {
  expect_error(sipni_data(year = 2024, month = 13), "Invalid")
  expect_error(sipni_data(year = 2024, month = 0), "Invalid")
})

# --- sipni_data mocked full pipeline (FTP) ---

test_that("sipni_data returns parsed FTP data via mock", {
  local_mocked_bindings(
    .sipni_download_and_read = function(year, uf, type, cache, cache_dir) {
      tibble::tibble(
        year = as.integer(year), uf_source = uf,
        IMUNO = "09", QT_DOSE = "100", MUNIC = "120040"
      )
    },
    .map_parallel = function(.x, .f, ..., .delay = NULL) {
      lapply(.x, .f)
    }
  )

  result <- sipni_data(year = 2019, uf = "AC", parse = TRUE,
                        cache = FALSE)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_type(result$QT_DOSE, "integer")
  expect_type(result$IMUNO, "character")
})

test_that("sipni_data returns unparsed FTP data via mock", {
  local_mocked_bindings(
    .sipni_download_and_read = function(year, uf, type, cache, cache_dir) {
      tibble::tibble(
        year = as.integer(year), uf_source = uf,
        IMUNO = "09", QT_DOSE = "100"
      )
    },
    .map_parallel = function(.x, .f, ..., .delay = NULL) {
      lapply(.x, .f)
    }
  )

  result <- sipni_data(year = 2019, uf = "AC", parse = FALSE,
                        cache = FALSE)

  expect_type(result$QT_DOSE, "character")
})

test_that("sipni_data selects vars via mock", {
  local_mocked_bindings(
    .sipni_download_and_read = function(year, uf, type, cache, cache_dir) {
      tibble::tibble(
        year = as.integer(year), uf_source = uf,
        IMUNO = "09", QT_DOSE = "100", MUNIC = "120040"
      )
    },
    .map_parallel = function(.x, .f, ..., .delay = NULL) {
      lapply(.x, .f)
    }
  )

  result <- sipni_data(year = 2019, uf = "AC", vars = "IMUNO",
                        parse = FALSE, cache = FALSE)

  expect_true("IMUNO" %in% names(result))
  expect_true("year" %in% names(result))
  expect_true("uf_source" %in% names(result))
  expect_false("MUNIC" %in% names(result))
})

# --- sipni_data mocked full pipeline (API) ---

test_that("sipni_data returns parsed API data via mock", {
  local_mocked_bindings(
    .sipni_api_download_and_read = function(year, uf, month, cache, cache_dir) {
      tibble::tibble(
        year = as.integer(year), month = 1L, uf_source = uf,
        data_vacina = "2024-01-15",
        numero_idade_paciente = "30",
        tipo_sexo_paciente = "F"
      )
    },
    .map_parallel = function(.x, .f, ..., .delay = NULL) {
      lapply(.x, .f)
    }
  )

  result <- sipni_data(year = 2024, uf = "AC", month = 1,
                        parse = TRUE, cache = FALSE)

  expect_s3_class(result, "tbl_df")
  expect_s3_class(result$data_vacina, "Date")
  expect_type(result$numero_idade_paciente, "integer")
})

# --- sipni_data mocked mixed FTP+API ---

test_that("sipni_data handles mixed FTP and API years via mock", {
  local_mocked_bindings(
    .sipni_download_and_read = function(year, uf, type, cache, cache_dir) {
      tibble::tibble(
        year = as.integer(year), uf_source = uf,
        IMUNO = "09", QT_DOSE = "100"
      )
    },
    .sipni_api_download_and_read = function(year, uf, month, cache, cache_dir) {
      tibble::tibble(
        year = as.integer(year), month = 1L, uf_source = uf,
        data_vacina = "2024-01-15"
      )
    },
    .map_parallel = function(.x, .f, ..., .delay = NULL) {
      lapply(.x, .f)
    }
  )

  result <- sipni_data(year = c(2019, 2024), uf = "AC", month = 1,
                        parse = FALSE, cache = FALSE)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_true(all(c(2019L, 2024L) %in% result$year))
})

# --- .sipni_read_dbf ---

test_that(".sipni_read_dbf returns tibble with character columns", {
  # create a minimal DBF using foreign
  temp_dir <- withr::local_tempdir()
  dbf_path <- file.path(temp_dir, "test.dbf")
  df <- data.frame(COL1 = c(1L, 2L), COL2 = c("A", "B"),
                    stringsAsFactors = FALSE)
  foreign::write.dbf(df, dbf_path)

  result <- healthbR:::.sipni_read_dbf(dbf_path)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  # all columns should be character
  for (col in names(result)) {
    expect_type(result[[col]], "character")
  }
})

# --- sipni_dictionary ---

test_that("sipni_dictionary returns full dictionary when variable=NULL", {
  dict <- sipni_dictionary()
  expect_s3_class(dict, "tbl_df")
  expect_gt(nrow(dict), 0)
  expect_true(all(c("variable", "description", "code", "label") %in%
                    names(dict)))
})

test_that("sipni_dictionary filters by variable name (uppercase)", {
  dict <- sipni_dictionary("DOSE")
  expect_true(all(dict$variable == "DOSE"))
  expect_gt(nrow(dict), 0)
})

test_that("sipni_dictionary filters by variable name (lowercase)", {
  dict <- sipni_dictionary("dose")
  expect_true(all(dict$variable == "DOSE"))
})

test_that("sipni_dictionary warns on nonexistent variable", {
  expect_warning(sipni_dictionary("ZZZZZ"), "not found")
})

# --- sipni_variables with type parameter ---

test_that("sipni_variables returns different results for each type", {
  dpni <- sipni_variables(type = "DPNI")
  cpni <- sipni_variables(type = "CPNI")
  api  <- sipni_variables(type = "API")

  expect_false(identical(dpni, cpni))
  expect_false(identical(dpni, api))
  expect_false(identical(cpni, api))
})

test_that("sipni_variables search filters across all columns", {
  result <- sipni_variables(search = "munic")
  expect_gt(nrow(result), 0)
})

# ============================================================================
# ADDITIONAL COVERAGE: .sipni_csv_process_national (mocked)
# ============================================================================

test_that(".sipni_csv_process_national reads CSV from zip and splits by UF", {
  temp_dir <- withr::local_tempdir()
  cache_dir <- withr::local_tempdir()

  # create a fake CSV with semicolon delimiter and latin1 encoding
  csv_content <- paste(
    "sigla_uf_estabelecimento;data_vacina;descricao_vacina",
    "AC;2024-01-15;BCG",
    "AC;2024-01-16;Hepatite B",
    "SP;2024-01-15;COVID-19",
    sep = "\n"
  )
  csv_path <- file.path(temp_dir, "vacinacao.csv")
  writeLines(csv_content, csv_path, useBytes = TRUE)

  # create a ZIP containing the CSV
  zip_path <- file.path(temp_dir, "vacinacao_jan_2024_csv.zip")
  withr::with_dir(temp_dir, {
    utils::zip(zip_path, "vacinacao.csv", flags = "-q")
  })

  # call with pre-downloaded zip_path
  result <- healthbR:::.sipni_csv_process_national(
    year = 2024, month = 1, uf = "AC",
    cache = FALSE, cache_dir = cache_dir,
    zip_path = zip_path
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_equal(unique(result$uf_source), "AC")
  expect_equal(unique(result$year), 2024L)
  expect_equal(unique(result$month), 1L)
  expect_true("data_vacina" %in% names(result))
})

test_that(".sipni_csv_process_national returns empty tibble for missing UF", {
  temp_dir <- withr::local_tempdir()
  cache_dir <- withr::local_tempdir()

  csv_content <- paste(
    "sigla_uf_estabelecimento;data_vacina;descricao_vacina",
    "SP;2024-01-15;BCG",
    sep = "\n"
  )
  csv_path <- file.path(temp_dir, "vacinacao.csv")
  writeLines(csv_content, csv_path, useBytes = TRUE)

  zip_path <- file.path(temp_dir, "vacinacao_jan_2024_csv.zip")
  withr::with_dir(temp_dir, {
    utils::zip(zip_path, "vacinacao.csv", flags = "-q")
  })

  result <- suppressWarnings(
    healthbR:::.sipni_csv_process_national(
      year = 2024, month = 1, uf = "AC",
      cache = FALSE, cache_dir = cache_dir,
      zip_path = zip_path
    )
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that(".sipni_csv_process_national handles uf_estabelecimento alt column", {
  temp_dir <- withr::local_tempdir()
  cache_dir <- withr::local_tempdir()

  # use alternative UF column name
  csv_content <- paste(
    "uf_estabelecimento;data_vacina;descricao_vacina",
    "AC;2024-01-15;BCG",
    sep = "\n"
  )
  csv_path <- file.path(temp_dir, "vacinacao.csv")
  writeLines(csv_content, csv_path, useBytes = TRUE)

  zip_path <- file.path(temp_dir, "vacinacao_jan_2024_csv.zip")
  withr::with_dir(temp_dir, {
    utils::zip(zip_path, "vacinacao.csv", flags = "-q")
  })

  result <- healthbR:::.sipni_csv_process_national(
    year = 2024, month = 1, uf = "AC",
    cache = FALSE, cache_dir = cache_dir,
    zip_path = zip_path
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_equal(unique(result$uf_source), "AC")
})

test_that(".sipni_csv_process_national handles CSV with no UF column", {
  temp_dir <- withr::local_tempdir()
  cache_dir <- withr::local_tempdir()

  # CSV without any UF column
  csv_content <- paste(
    "data_vacina;descricao_vacina",
    "2024-01-15;BCG",
    sep = "\n"
  )
  csv_path <- file.path(temp_dir, "vacinacao.csv")
  writeLines(csv_content, csv_path, useBytes = TRUE)

  zip_path <- file.path(temp_dir, "vacinacao_jan_2024_csv.zip")
  withr::with_dir(temp_dir, {
    utils::zip(zip_path, "vacinacao.csv", flags = "-q")
  })

  # no UF column means everything goes to "ALL" bucket, not "AC"
  result <- suppressWarnings(
    healthbR:::.sipni_csv_process_national(
      year = 2024, month = 1, uf = "AC",
      cache = FALSE, cache_dir = cache_dir,
      zip_path = zip_path
    )
  )

  # AC won't be found since data goes to "ALL" bucket
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that(".sipni_csv_process_national caches when cache=TRUE", {
  cache_dir <- withr::local_tempdir()
  temp_dir <- withr::local_tempdir()

  csv_content <- paste(
    "sigla_uf_estabelecimento;data_vacina;descricao_vacina",
    "AC;2024-01-15;BCG",
    sep = "\n"
  )
  csv_path <- file.path(temp_dir, "vacinacao.csv")
  writeLines(csv_content, csv_path, useBytes = TRUE)

  zip_path <- file.path(temp_dir, "vacinacao_jan_2024_csv.zip")
  withr::with_dir(temp_dir, {
    utils::zip(zip_path, "vacinacao.csv", flags = "-q")
  })

  result <- healthbR:::.sipni_csv_process_national(
    year = 2024, month = 1, uf = "AC",
    cache = TRUE, cache_dir = cache_dir,
    zip_path = zip_path
  )

  # verify cache was written
  dataset_path <- file.path(cache_dir, "sipni_csv_data")
  expect_true(dir.exists(dataset_path))
})

# ============================================================================
# ADDITIONAL COVERAGE: .sipni_csv_download_months (mocked)
# ============================================================================

test_that(".sipni_csv_download_months processes single month via mock", {
  local_mocked_bindings(
    .sipni_csv_process_national = function(year, month, uf,
                                            cache, cache_dir, zip_path = NULL) {
      tibble::tibble(
        year = as.integer(year), month = as.integer(month),
        uf_source = uf, data_vacina = "2024-01-15"
      )
    }
  )

  result <- healthbR:::.sipni_csv_download_months(
    year = 2024, months = 1L, uf = "AC",
    cache = FALSE, cache_dir = tempdir()
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_equal(result$month, 1L)
})

test_that(".sipni_csv_download_months processes multiple months via mock", {
  local_mocked_bindings(
    .sipni_csv_process_national = function(year, month, uf,
                                            cache, cache_dir, zip_path = NULL) {
      tibble::tibble(
        year = as.integer(year), month = as.integer(month),
        uf_source = uf, data_vacina = paste0("2024-0", month, "-15")
      )
    },
    .multi_download = function(urls, destfiles, ...) {
      # create empty files to simulate successful downloads
      for (d in destfiles) writeLines("fake", d)
      data.frame(
        success = rep(TRUE, length(urls)),
        url = urls, destfile = destfiles,
        status_code = rep(200L, length(urls)),
        error = rep(NA_character_, length(urls)),
        stringsAsFactors = FALSE
      )
    }
  )

  result <- healthbR:::.sipni_csv_download_months(
    year = 2024, months = 1L:3L, uf = "AC",
    cache = FALSE, cache_dir = tempdir()
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3)
  expect_equal(sort(result$month), 1L:3L)
})

test_that(".sipni_csv_download_months returns empty for all failures", {
  local_mocked_bindings(
    .sipni_csv_process_national = function(year, month, uf,
                                            cache, cache_dir, zip_path = NULL) {
      stop("Download failed")
    }
  )

  result <- healthbR:::.sipni_csv_download_months(
    year = 2024, months = 1L, uf = "AC",
    cache = FALSE, cache_dir = tempdir()
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

# ============================================================================
# ADDITIONAL COVERAGE: .sipni_download_and_read (mocked success path)
# ============================================================================

test_that(".sipni_download_and_read reads DBF and adds partition cols", {
  temp_dir <- withr::local_tempdir()
  cache_dir <- withr::local_tempdir()

  # create a minimal DBF and capture as raw bytes
  dbf_path <- file.path(temp_dir, "DPNIAC19.DBF")
  df <- data.frame(
    IMUNO = c("09", "10"), QT_DOSE = c("100", "200"),
    stringsAsFactors = FALSE
  )
  foreign::write.dbf(df, dbf_path)
  dbf_bytes <- readBin(dbf_path, "raw", n = file.size(dbf_path))

  local_mocked_bindings(
    .datasus_download = function(url, destfile, ...) {
      writeBin(dbf_bytes, destfile)
      invisible(destfile)
    }
  )

  result <- healthbR:::.sipni_download_and_read(
    year = 2019, uf = "AC", type = "DPNI",
    cache = FALSE, cache_dir = cache_dir
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_true("year" %in% names(result))
  expect_true("uf_source" %in% names(result))
  expect_equal(unique(result$year), 2019L)
  expect_equal(unique(result$uf_source), "AC")
  expect_type(result$IMUNO, "character")
  expect_type(result$QT_DOSE, "character")
})

test_that(".sipni_download_and_read falls back to lowercase .dbf extension", {
  temp_dir <- withr::local_tempdir()
  cache_dir <- withr::local_tempdir()

  # create a DBF with multiple rows so file size exceeds 100 bytes
  dbf_path <- file.path(temp_dir, "DPNIAC19.DBF")
  df <- data.frame(
    IMUNO = rep("09", 10), QT_DOSE = rep("100", 10),
    MUNIC = rep("120040", 10),
    stringsAsFactors = FALSE
  )
  foreign::write.dbf(df, dbf_path)
  dbf_bytes <- readBin(dbf_path, "raw", n = file.size(dbf_path))

  call_count <- 0L
  local_mocked_bindings(
    .datasus_download = function(url, destfile, ...) {
      call_count <<- call_count + 1L
      if (call_count == 1L) stop("Not found (.DBF)")
      # second call (lowercase .dbf) succeeds
      writeBin(dbf_bytes, destfile)
      invisible(destfile)
    }
  )

  result <- healthbR:::.sipni_download_and_read(
    year = 2019, uf = "AC", type = "DPNI",
    cache = FALSE, cache_dir = cache_dir
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 10)
  expect_equal(call_count, 2L)
})

test_that(".sipni_download_and_read fixes CPNI comma in COBERT", {
  temp_dir <- withr::local_tempdir()
  cache_dir <- withr::local_tempdir()

  dbf_path <- file.path(temp_dir, "CPNIAC19.DBF")
  df <- data.frame(
    IMUNO = "09", QT_DOSE = "100", COBERT = "85,5",
    stringsAsFactors = FALSE
  )
  foreign::write.dbf(df, dbf_path)
  dbf_bytes <- readBin(dbf_path, "raw", n = file.size(dbf_path))

  local_mocked_bindings(
    .datasus_download = function(url, destfile, ...) {
      writeBin(dbf_bytes, destfile)
      invisible(destfile)
    }
  )

  result <- healthbR:::.sipni_download_and_read(
    year = 2019, uf = "AC", type = "CPNI",
    cache = FALSE, cache_dir = cache_dir
  )

  expect_equal(result$COBERT, "85.5")
})

test_that(".sipni_download_and_read aborts on tiny file", {
  temp_dir <- withr::local_tempdir()
  cache_dir <- withr::local_tempdir()

  local_mocked_bindings(
    .datasus_download = function(url, destfile, ...) {
      writeBin(raw(10), destfile)
      invisible(destfile)
    }
  )

  expect_error(
    healthbR:::.sipni_download_and_read(
      year = 2019, uf = "AC", type = "DPNI",
      cache = FALSE, cache_dir = cache_dir
    ),
    "corrupted"
  )
})

# ============================================================================
# ADDITIONAL COVERAGE: sipni_data full orchestration (API path + vars)
# ============================================================================

test_that("sipni_data API path selects vars via mock", {
  local_mocked_bindings(
    .sipni_api_download_and_read = function(year, uf, month, cache, cache_dir) {
      tibble::tibble(
        year = as.integer(year), month = 1L, uf_source = uf,
        data_vacina = "2024-01-15",
        descricao_vacina = "BCG",
        tipo_sexo_paciente = "F"
      )
    },
    .map_parallel = function(.x, .f, ..., .delay = NULL) {
      lapply(.x, .f)
    }
  )

  result <- sipni_data(
    year = 2024, uf = "AC", month = 1,
    vars = c("data_vacina", "descricao_vacina"),
    parse = FALSE, cache = FALSE
  )

  expect_true("data_vacina" %in% names(result))
  expect_true("descricao_vacina" %in% names(result))
  expect_false("tipo_sexo_paciente" %in% names(result))
  expect_true("year" %in% names(result))
  expect_true("uf_source" %in% names(result))
})

test_that("sipni_data reports all failures as error", {
  local_mocked_bindings(
    .sipni_download_and_read = function(year, uf, ...) {
      stop("All fail")
    },
    .map_parallel = function(.x, .f, ..., .delay = NULL) {
      lapply(.x, .f)
    }
  )

  expect_error(
    sipni_data(year = 2019, uf = "AC", parse = FALSE, cache = FALSE),
    "No data"
  )
})

test_that("sipni_data with col_types override in API path", {
  local_mocked_bindings(
    .sipni_api_download_and_read = function(year, uf, month, cache, cache_dir) {
      tibble::tibble(
        year = as.integer(year), month = 1L, uf_source = uf,
        data_vacina = "2024-01-15",
        numero_idade_paciente = "30"
      )
    },
    .map_parallel = function(.x, .f, ..., .delay = NULL) {
      lapply(.x, .f)
    }
  )

  result <- sipni_data(
    year = 2024, uf = "AC", month = 1,
    parse = TRUE, col_types = list(numero_idade_paciente = "character"),
    cache = FALSE
  )

  # override should keep it as character
  expect_type(result$numero_idade_paciente, "character")
})

# ============================================================================
# ADDITIONAL COVERAGE: .sipni_api_download_and_read delegates properly
# ============================================================================

test_that(".sipni_api_download_and_read delegates to csv_download_months", {
  local_mocked_bindings(
    .sipni_csv_download_months = function(year, months, uf, cache, cache_dir) {
      tibble::tibble(
        year = as.integer(year), month = months[1],
        uf_source = uf, data_vacina = "2024-01-15"
      )
    }
  )

  result <- healthbR:::.sipni_api_download_and_read(
    year = 2024, uf = "AC", month = 1L,
    cache = FALSE, cache_dir = tempdir()
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
})

# ============================================================================
# ADDITIONAL COVERAGE: sipni_data partial failure warning (API path)
# ============================================================================

test_that("sipni_data reports partial download failures (API)", {
  local_mocked_bindings(
    .sipni_api_download_and_read = function(year, uf, month, cache, cache_dir) {
      if (uf == "RJ") stop("Server error")
      tibble::tibble(
        year = as.integer(year), month = 1L, uf_source = uf,
        data_vacina = "2024-01-15"
      )
    },
    .map_parallel = function(.x, .f, ..., .delay = NULL) {
      lapply(.x, .f)
    }
  )

  result <- suppressWarnings(
    sipni_data(2024, uf = c("AC", "RJ"), month = 1, parse = FALSE, cache = FALSE)
  )
  expect_s3_class(result, "data.frame")
  failures <- attr(result, "download_failures")
  expect_false(is.null(failures))
  expect_equal(failures, "RJ 2024")
})

# ============================================================================
# ADDITIONAL COVERAGE: sipni_variables with invalid type
# ============================================================================

test_that("sipni_variables errors on invalid type", {
  expect_error(sipni_variables(type = "INVALID"), "Invalid")
})

# ============================================================================
# ADDITIONAL COVERAGE: .sipni_csv_build_url edge cases
# ============================================================================

test_that(".sipni_csv_build_url year 2020 month 1 produces correct URL", {
  url <- healthbR:::.sipni_csv_build_url(2020, 1)
  expect_equal(
    url,
    "https://arquivosdadosabertos.saude.gov.br/dados/dbbni/vacinacao_jan_2020_csv.zip"
  )
})

test_that(".sipni_csv_build_url year 2025 month 12 produces correct URL", {
  url <- healthbR:::.sipni_csv_build_url(2025, 12)
  expect_equal(
    url,
    "https://arquivosdadosabertos.saude.gov.br/dados/dbbni/vacinacao_dez_2025_csv.zip"
  )
})
