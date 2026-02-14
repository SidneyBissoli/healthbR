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
# .sipni_validate_month
# ============================================================================

test_that(".sipni_validate_month returns 1:12 for NULL", {
  result <- .sipni_validate_month(NULL)
  expect_equal(result, 1L:12L)
})

test_that(".sipni_validate_month accepts valid months", {
  expect_equal(.sipni_validate_month(1), 1L)
  expect_equal(.sipni_validate_month(12), 12L)
  expect_equal(.sipni_validate_month(1:6), 1L:6L)
  expect_equal(.sipni_validate_month(c(1, 6, 12)), c(1L, 6L, 12L))
})

test_that(".sipni_validate_month errors on invalid months", {
  expect_error(.sipni_validate_month(0), "Invalid")
  expect_error(.sipni_validate_month(13), "Invalid")
  expect_error(.sipni_validate_month(-1), "Invalid")
  expect_error(.sipni_validate_month(c(1, 13)), "Invalid")
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
