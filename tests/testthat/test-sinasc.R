# tests for SINASC module functions

# ============================================================================
# sinasc_years
# ============================================================================

test_that("sinasc_years returns integer vector", {
  years <- sinasc_years()
  expect_type(years, "integer")
  expect_gt(length(years), 0)
  expect_true(2022L %in% years)
  expect_true(1996L %in% years)
})

test_that("sinasc_years filters by status", {
  final <- sinasc_years("final")
  prelim <- sinasc_years("preliminary")
  all_years <- sinasc_years("all")

  expect_true(length(all_years) > length(final))
  expect_true(length(all_years) == length(final) + length(prelim))
  expect_true(all(final %in% all_years))
  expect_true(all(prelim %in% all_years))
})

test_that("sinasc_years errors on invalid status", {
  expect_error(sinasc_years("invalid"))
})

# ============================================================================
# sinasc_info
# ============================================================================

test_that("sinasc_info returns expected structure", {
  info <- sinasc_info()

  expect_type(info, "list")
  expect_true("name" %in% names(info))
  expect_true("source" %in% names(info))
  expect_true("final_years" %in% names(info))
  expect_true("preliminary_years" %in% names(info))
  expect_true("n_variables" %in% names(info))
})

# ============================================================================
# sinasc_variables
# ============================================================================

test_that("sinasc_variables returns tibble with expected columns", {
  vars <- sinasc_variables()
  expect_s3_class(vars, "tbl_df")
  expect_true(all(c("variable", "description", "type", "section") %in% names(vars)))
  expect_gt(nrow(vars), 0)
  expect_true("DTNASC" %in% vars$variable)
  expect_true("SEXO" %in% vars$variable)
  expect_true("PESO" %in% vars$variable)
  expect_true("CODANOMAL" %in% vars$variable)
})

test_that("sinasc_variables search works", {
  mae_vars <- sinasc_variables(search = "mae")
  expect_gt(nrow(mae_vars), 0)
})

test_that("sinasc_variables search is accent-insensitive", {
  # search with accent
  result_accent <- sinasc_variables(search = "m\u00e3e")
  # search without accent
  result_plain <- sinasc_variables(search = "mae")
  expect_equal(nrow(result_accent), nrow(result_plain))
})

test_that("sinasc_variables search returns empty tibble for no match", {
  result <- sinasc_variables(search = "zzzznonexistent")
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("sinasc_variables has expected sections", {
  vars <- sinasc_variables()
  sections <- unique(vars$section)
  expect_true("recem_nascido" %in% sections)
  expect_true("materna" %in% sections)
  expect_true("gestacao" %in% sections)
  expect_true("parto" %in% sections)
  expect_true("localizacao" %in% sections)
  expect_true("administrativa" %in% sections)
})

# ============================================================================
# sinasc_dictionary
# ============================================================================

test_that("sinasc_dictionary returns tibble with expected columns", {
  dict <- sinasc_dictionary()
  expect_s3_class(dict, "tbl_df")
  expect_true(all(c("variable", "description", "code", "label") %in% names(dict)))
  expect_gt(nrow(dict), 0)
})

test_that("sinasc_dictionary filters by variable", {
  sexo <- sinasc_dictionary("SEXO")
  expect_true(all(sexo$variable == "SEXO"))
  expect_true("Masculino" %in% sexo$label)
  expect_true("Feminino" %in% sexo$label)
})

test_that("sinasc_dictionary case insensitive", {
  parto_lower <- sinasc_dictionary("parto")
  parto_upper <- sinasc_dictionary("PARTO")
  expect_equal(nrow(parto_lower), nrow(parto_upper))
})

test_that("sinasc_dictionary warns on unknown variable", {
  expect_warning(sinasc_dictionary("NONEXISTENT"), "not found")
})

test_that("sinasc_dictionary has key variables", {
  dict <- sinasc_dictionary()
  dict_vars <- unique(dict$variable)
  expect_true("SEXO" %in% dict_vars)
  expect_true("RACACOR" %in% dict_vars)
  expect_true("LOCNASC" %in% dict_vars)
  expect_true("PARTO" %in% dict_vars)
  expect_true("GESTACAO" %in% dict_vars)
  expect_true("CONSULTAS" %in% dict_vars)
  expect_true("IDANOMAL" %in% dict_vars)
})

test_that("sinasc_dictionary GESTACAO has correct categories", {
  gest <- sinasc_dictionary("GESTACAO")
  expect_equal(nrow(gest), 7)
  expect_true("Menos de 22 semanas" %in% gest$label)
  expect_true("37 a 41 semanas" %in% gest$label)
  expect_true("Ignorado" %in% gest$label)
})

test_that("sinasc_dictionary CONSULTAS has correct categories", {
  cons <- sinasc_dictionary("CONSULTAS")
  expect_equal(nrow(cons), 5)
  expect_true("Nenhuma" %in% cons$label)
  expect_true("7 e mais" %in% cons$label)
})

# ============================================================================
# .sinasc_build_ftp_url
# ============================================================================

test_that(".sinasc_build_ftp_url constructs correct URLs", {
  url <- .sinasc_build_ftp_url(2022, "RJ")
  expect_match(url, "SINASC/1996_/Dados/DNRES/DNRJ2022\\.dbc$")
  expect_match(url, "^ftp://ftp\\.datasus\\.gov\\.br/")

  url2 <- .sinasc_build_ftp_url(1996, "AC")
  expect_match(url2, "DNRES/DNAC1996\\.dbc$")
})

test_that(".sinasc_build_ftp_url errors on pre-1996 years", {
  expect_error(.sinasc_build_ftp_url(1995, "SP"), "not supported")
})

# ============================================================================
# .sinasc_validate_year
# ============================================================================

test_that(".sinasc_validate_year accepts valid years", {
  expect_equal(.sinasc_validate_year(2022), 2022L)
  expect_equal(.sinasc_validate_year(c(2020, 2021)), c(2020L, 2021L))
})

test_that(".sinasc_validate_year errors on invalid years", {
  expect_error(.sinasc_validate_year(1990), "not available")
  expect_error(.sinasc_validate_year(2050), "not available")
})

test_that(".sinasc_validate_year errors on NULL", {
  expect_error(.sinasc_validate_year(NULL), "required")
})

# ============================================================================
# .sinasc_validate_uf
# ============================================================================

test_that(".sinasc_validate_uf accepts valid UFs", {
  expect_equal(.sinasc_validate_uf("SP"), "SP")
  expect_equal(.sinasc_validate_uf("sp"), "SP")
  expect_equal(.sinasc_validate_uf(c("SP", "RJ")), c("SP", "RJ"))
})

test_that(".sinasc_validate_uf errors on invalid UFs", {
  expect_error(.sinasc_validate_uf("XX"), "Invalid")
  expect_error(.sinasc_validate_uf(c("SP", "ZZ")), "Invalid")
})

# ============================================================================
# .sinasc_validate_vars
# ============================================================================

test_that(".sinasc_validate_vars warns on unknown variables", {
  expect_warning(.sinasc_validate_vars("NONEXISTENT"), "not in known")
  expect_warning(
    .sinasc_validate_vars(c("SEXO", "FAKECOL")),
    "not in known"
  )
})

test_that(".sinasc_validate_vars silent on known variables", {
  expect_no_warning(.sinasc_validate_vars("SEXO"))
  expect_no_warning(.sinasc_validate_vars(c("SEXO", "PESO", "PARTO")))
})

# ============================================================================
# sinasc_cache functions
# ============================================================================

test_that("sinasc_cache_status works with empty cache", {
  temp_dir <- tempfile("sinasc_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  result <- sinasc_cache_status(cache_dir = temp_dir)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("sinasc_clear_cache works with empty cache", {
  temp_dir <- tempfile("sinasc_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  expect_no_error(sinasc_clear_cache(cache_dir = temp_dir))
})

test_that(".sinasc_cache_dir creates directory", {
  temp_dir <- file.path(tempdir(), "sinasc_cache_test_create")
  on.exit(unlink(temp_dir, recursive = TRUE))

  result <- .sinasc_cache_dir(temp_dir)
  expect_true(dir.exists(result))
  expect_equal(result, temp_dir)
})

# ============================================================================
# integration tests (require internet + HEALTHBR_INTEGRATION=true)
# ============================================================================

test_that("sinasc_data downloads and reads data from FTP", {
  skip_if_no_integration()

  data <- sinasc_data(year = 2022, uf = "AC",
                      cache_dir = tempdir())
  expect_s3_class(data, "tbl_df")
  expect_gt(nrow(data), 0)
  expect_true("DTNASC" %in% names(data))
  expect_true("SEXO" %in% names(data))
  expect_true("PESO" %in% names(data))
  expect_true("CODMUNRES" %in% names(data))
  expect_true("year" %in% names(data))
  expect_true("uf_source" %in% names(data))
  expect_equal(unique(data$year), 2022L)
  expect_equal(unique(data$uf_source), "AC")
})

test_that("sinasc_data filters by anomaly", {
  skip_if_no_integration()

  anomalies <- sinasc_data(year = 2022, uf = "AC", anomaly = "Q",
                           cache_dir = tempdir())
  if (nrow(anomalies) > 0) {
    expect_true(all(grepl("^Q", anomalies$CODANOMAL)))
  }
})

test_that("sinasc_data selects variables", {
  skip_if_no_integration()

  data <- sinasc_data(year = 2022, uf = "AC",
                      vars = c("DTNASC", "SEXO", "PESO"),
                      cache_dir = tempdir())
  expect_true("DTNASC" %in% names(data))
  expect_true("SEXO" %in% names(data))
  expect_true("PESO" %in% names(data))
  expect_true("year" %in% names(data))
  expect_true("uf_source" %in% names(data))
})

test_that("sinasc_data cache works (second call faster)", {
  skip_if_no_integration()

  cache_dir <- tempfile("sinasc_cache_test")
  dir.create(cache_dir, recursive = TRUE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  t1 <- system.time(sinasc_data(year = 2022, uf = "AC", cache_dir = cache_dir))
  t2 <- system.time(sinasc_data(year = 2022, uf = "AC", cache_dir = cache_dir))
  expect_lt(t2["elapsed"], t1["elapsed"])
})

test_that("sinasc_data handles multiple UFs", {
  skip_if_no_integration()

  data <- sinasc_data(year = 2022, uf = c("AC", "RR"),
                      cache_dir = tempdir())
  expect_s3_class(data, "tbl_df")
  expect_gt(nrow(data), 0)
  expect_true(all(c("AC", "RR") %in% data$uf_source))
})

# ============================================================================
# smart type parsing
# ============================================================================

test_that("sinasc_variables type column has non-character types", {
  vars <- sinasc_variables()
  types <- unique(vars$type)
  expect_true("date_dmy" %in% types)
  expect_true("integer" %in% types)
  expect_equal(vars$type[vars$variable == "DTNASC"], "date_dmy")
  expect_equal(vars$type[vars$variable == "PESO"], "integer")
  expect_equal(vars$type[vars$variable == "APGAR1"], "integer")
  expect_equal(vars$type[vars$variable == "SEXO"], "character")
})

test_that("sinasc parse converts mock data correctly", {
  mock_data <- tibble::tibble(
    year = 2022L, uf_source = "AC",
    DTNASC = "25122022", PESO = "3500", APGAR1 = "8",
    SEXO = "1", IDADEMAE = "30"
  )
  spec <- .build_type_spec(sinasc_variables_metadata)
  parsed <- .parse_columns(mock_data, spec)

  expect_s3_class(parsed$DTNASC, "Date")
  expect_type(parsed$PESO, "integer")
  expect_type(parsed$APGAR1, "integer")
  expect_type(parsed$SEXO, "character")
})


# ============================================================================
# consolidated download failure reporting
# ============================================================================

test_that("sinasc_data reports partial download failures", {
  local_mocked_bindings(
    .sinasc_validate_year = function(year, ...) as.integer(year),
    .sinasc_validate_uf = function(uf) toupper(uf),
    .sinasc_download_and_read = function(year, uf, ...) {
      if (uf == "XX") stop("Not found")
      tibble::tibble(year = as.integer(year), uf_source = uf, CODANOMAL = "Q00")
    }
  )
  result <- suppressWarnings(
    sinasc_data(2022, uf = c("AC", "XX"), parse = FALSE)
  )
  expect_s3_class(result, "data.frame")
  failures <- attr(result, "download_failures")
  expect_false(is.null(failures))
  expect_equal(failures, "XX 2022")
})
