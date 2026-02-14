# tests for SIM module functions

# ============================================================================
# sim_years
# ============================================================================

test_that("sim_years returns integer vector", {
  years <- sim_years()
  expect_type(years, "integer")
  expect_gt(length(years), 0)
  expect_true(2022L %in% years)
  expect_true(1996L %in% years)
})

test_that("sim_years filters by status", {
  final <- sim_years("final")
  prelim <- sim_years("preliminary")
  all_years <- sim_years("all")

  expect_true(length(all_years) > length(final))
  expect_true(length(all_years) == length(final) + length(prelim))
  expect_true(all(final %in% all_years))
  expect_true(all(prelim %in% all_years))
})

test_that("sim_years errors on invalid status", {
  expect_error(sim_years("invalid"))
})

# ============================================================================
# sim_info
# ============================================================================

test_that("sim_info returns expected structure", {
  info <- sim_info()

  expect_type(info, "list")
  expect_true("name" %in% names(info))
  expect_true("source" %in% names(info))
  expect_true("final_years" %in% names(info))
  expect_true("preliminary_years" %in% names(info))
  expect_true("n_variables" %in% names(info))
})

# ============================================================================
# sim_variables
# ============================================================================

test_that("sim_variables returns tibble with expected columns", {
  vars <- sim_variables()
  expect_s3_class(vars, "tbl_df")
  expect_true(all(c("variable", "description", "type", "section") %in% names(vars)))
  expect_gt(nrow(vars), 0)
  expect_true("CAUSABAS" %in% vars$variable)
  expect_true("DTOBITO" %in% vars$variable)
  expect_true("SEXO" %in% vars$variable)
})

test_that("sim_variables search works", {
  causa_vars <- sim_variables(search = "causa")
  expect_gt(nrow(causa_vars), 0)
  # all results should match "causa" in variable or description
  matches <- grepl("causa", tolower(causa_vars$variable)) |
    grepl("causa", tolower(causa_vars$description))
  expect_true(all(matches))
})

test_that("sim_variables search returns empty tibble for no match", {
  result <- sim_variables(search = "zzzznonexistent")
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

# ============================================================================
# sim_dictionary
# ============================================================================

test_that("sim_dictionary returns tibble with expected columns", {
  dict <- sim_dictionary()
  expect_s3_class(dict, "tbl_df")
  expect_true(all(c("variable", "description", "code", "label") %in% names(dict)))
  expect_gt(nrow(dict), 0)
})

test_that("sim_dictionary filters by variable", {
  sexo <- sim_dictionary("SEXO")
  expect_true(all(sexo$variable == "SEXO"))
  expect_true("Masculino" %in% sexo$label)
  expect_true("Feminino" %in% sexo$label)
})

test_that("sim_dictionary case insensitive", {
  sexo_lower <- sim_dictionary("sexo")
  sexo_upper <- sim_dictionary("SEXO")
  expect_equal(nrow(sexo_lower), nrow(sexo_upper))
})

test_that("sim_dictionary warns on unknown variable", {
  expect_warning(sim_dictionary("NONEXISTENT"), "not found")
})

# ============================================================================
# .sim_decode_age
# ============================================================================

test_that(".sim_decode_age decodes years correctly", {
  expect_equal(.sim_decode_age("462"), 62)
  expect_equal(.sim_decode_age("400"), 0)
  expect_equal(.sim_decode_age("499"), 99)
  expect_equal(.sim_decode_age("505"), 105)
  expect_equal(.sim_decode_age("500"), 100)
})

test_that(".sim_decode_age decodes months correctly", {
  expect_equal(.sim_decode_age("306"), 0.5)
  expect_equal(.sim_decode_age("301"), 1 / 12)
})

test_that(".sim_decode_age decodes days correctly", {
  expect_equal(.sim_decode_age("215"), 15 / 365.25, tolerance = 0.001)
})

test_that(".sim_decode_age handles NA and empty", {
  expect_true(is.na(.sim_decode_age(NA_character_)))
  expect_true(is.na(.sim_decode_age("")))
})

test_that(".sim_decode_age is vectorized", {
  result <- .sim_decode_age(c("462", "400", "505", NA_character_, ""))
  expect_length(result, 5)
  expect_equal(result[1], 62)
  expect_equal(result[2], 0)
  expect_equal(result[3], 105)
  expect_true(is.na(result[4]))
  expect_true(is.na(result[5]))
})

# ============================================================================
# .sim_build_ftp_url
# ============================================================================

test_that(".sim_build_ftp_url constructs correct CID-10 URLs", {
  url <- .sim_build_ftp_url(2022, "RJ")
  expect_match(url, "CID10/DORES/DORJ2022\\.dbc$")
  expect_match(url, "^ftp://ftp\\.datasus\\.gov\\.br/")

  url2 <- .sim_build_ftp_url(1996, "AC")
  expect_match(url2, "CID10/DORES/DOAC1996\\.dbc$")
})

test_that(".sim_build_ftp_url errors on pre-1996 years", {
  expect_error(.sim_build_ftp_url(1995, "SP"), "not supported")
})

# ============================================================================
# .sim_uf_to_code
# ============================================================================

test_that(".sim_uf_to_code converts correctly", {
  expect_equal(.sim_uf_to_code("SP"), "35")
  expect_equal(.sim_uf_to_code("RJ"), "33")
  expect_equal(.sim_uf_to_code("AC"), "12")
  expect_equal(.sim_uf_to_code(c("SP", "RJ")), c("35", "33"))
})

test_that(".sim_uf_to_code is case insensitive", {
  expect_equal(.sim_uf_to_code("sp"), "35")
  expect_equal(.sim_uf_to_code("rj"), "33")
})

test_that(".sim_uf_to_code errors on invalid UF", {
  expect_error(.sim_uf_to_code("XX"), "Invalid")
  expect_error(.sim_uf_to_code(c("SP", "XX")), "Invalid")
})

# ============================================================================
# .sim_validate_year
# ============================================================================

test_that(".sim_validate_year accepts valid years", {
  expect_equal(.sim_validate_year(2022), 2022L)
  expect_equal(.sim_validate_year(c(2020, 2021)), c(2020L, 2021L))
})

test_that(".sim_validate_year errors on invalid years", {
  expect_error(.sim_validate_year(1990), "not available")
  expect_error(.sim_validate_year(2050), "not available")
})

test_that(".sim_validate_year errors on NULL", {
  expect_error(.sim_validate_year(NULL), "required")
})

# ============================================================================
# .sim_validate_uf
# ============================================================================

test_that(".sim_validate_uf accepts valid UFs", {
  expect_equal(.sim_validate_uf("SP"), "SP")
  expect_equal(.sim_validate_uf("sp"), "SP")
  expect_equal(.sim_validate_uf(c("SP", "RJ")), c("SP", "RJ"))
})

test_that(".sim_validate_uf errors on invalid UFs", {
  expect_error(.sim_validate_uf("XX"), "Invalid")
  expect_error(.sim_validate_uf(c("SP", "ZZ")), "Invalid")
})

# ============================================================================
# sim_cache functions
# ============================================================================

test_that("sim_cache_status works with empty cache", {
  temp_dir <- tempfile("sim_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  result <- sim_cache_status(cache_dir = temp_dir)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("sim_clear_cache works with empty cache", {
  temp_dir <- tempfile("sim_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  expect_no_error(sim_clear_cache(cache_dir = temp_dir))
})

# ============================================================================
# integration tests (require internet + HEALTHBR_INTEGRATION=true)
# ============================================================================

test_that("sim_data downloads and reads data from FTP", {
  skip_if_no_integration()

  data <- sim_data(year = 2022, uf = "AC",
                   cache_dir = tempdir())
  expect_s3_class(data, "tbl_df")
  expect_gt(nrow(data), 0)
  expect_true("CAUSABAS" %in% names(data))
  expect_true("DTOBITO" %in% names(data))
  expect_true("CODMUNRES" %in% names(data))
  expect_true("age_years" %in% names(data))
  expect_true("year" %in% names(data))
  expect_true("uf_source" %in% names(data))
  expect_equal(unique(data$year), 2022L)
  expect_equal(unique(data$uf_source), "AC")
})

test_that("sim_data filters by cause", {
  skip_if_no_integration()

  infarct <- sim_data(year = 2022, uf = "AC", cause = "I21",
                      cache_dir = tempdir())
  if (nrow(infarct) > 0) {
    expect_true(all(grepl("^I21", infarct$CAUSABAS)))
  }
})

test_that("sim_data selects variables", {
  skip_if_no_integration()

  data <- sim_data(year = 2022, uf = "AC",
                   vars = c("CAUSABAS", "SEXO", "IDADE"),
                   cache_dir = tempdir())
  # should have year, uf_source, requested vars, and age_years (from IDADE)
  expect_true("CAUSABAS" %in% names(data))
  expect_true("SEXO" %in% names(data))
  expect_true("IDADE" %in% names(data))
  expect_true("age_years" %in% names(data))
  expect_true("year" %in% names(data))
  expect_true("uf_source" %in% names(data))
})

test_that("sim_data cache works (second call faster)", {
  skip_if_no_integration()

  cache_dir <- tempfile("sim_cache_test")
  dir.create(cache_dir, recursive = TRUE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  t1 <- system.time(sim_data(year = 2022, uf = "AC", cache_dir = cache_dir))
  t2 <- system.time(sim_data(year = 2022, uf = "AC", cache_dir = cache_dir))
  expect_lt(t2["elapsed"], t1["elapsed"])
})

# ============================================================================
# smart type parsing
# ============================================================================

test_that("sim_variables type column has non-character types", {
  vars <- sim_variables()
  types <- unique(vars$type)
  expect_true("date_dmy" %in% types)
  expect_true("integer" %in% types)
  expect_true("character" %in% types)
  # specific checks
  expect_equal(vars$type[vars$variable == "DTOBITO"], "date_dmy")
  expect_equal(vars$type[vars$variable == "PESO"], "integer")
  expect_equal(vars$type[vars$variable == "SEXO"], "character")
})

test_that("sim_data parse = FALSE returns all character", {
  # create mock data as if downloaded
  mock_data <- tibble::tibble(
    year = 2022L, uf_source = "AC",
    DTOBITO = "25122022", PESO = "3500", SEXO = "M",
    IDADE = "4025", IDADEMAE = "30"
  )

  # simulate what parse = FALSE should preserve
  spec <- .build_type_spec(sim_variables_metadata)
  parsed <- .parse_columns(mock_data, spec)

  expect_s3_class(parsed$DTOBITO, "Date")
  expect_type(parsed$PESO, "integer")
  expect_type(parsed$SEXO, "character")
  expect_type(parsed$IDADEMAE, "integer")
})
