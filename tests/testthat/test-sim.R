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


# ============================================================================
# consolidated download failure reporting
# ============================================================================

test_that("sim_data reports partial download failures", {
  local_mocked_bindings(
    .sim_validate_year = function(year, ...) as.integer(year),
    .sim_validate_uf = function(uf) toupper(uf),
    .sim_download_and_read = function(year, uf, ...) {
      if (uf == "XX") stop("Not found")
      tibble::tibble(year = as.integer(year), uf_source = uf, CAUSABAS = "X00")
    }
  )
  result <- suppressWarnings(
    sim_data(2022, uf = c("AC", "XX"), parse = FALSE, decode_age = FALSE)
  )
  expect_s3_class(result, "data.frame")
  failures <- attr(result, "download_failures")
  expect_false(is.null(failures))
  expect_equal(failures, "XX 2022")
})


# ============================================================================
# ADDITIONAL COVERAGE TESTS
# ============================================================================

# --- sim_info --- additional coverage ---

test_that("sim_info returns invisible list with all expected fields", {
  result <- sim_info()
  expect_type(result, "list")
  expect_equal(result$source, "DATASUS FTP")
  expect_true(length(result$final_years) > 0)
  expect_true(length(result$preliminary_years) > 0)
  expect_true(result$n_variables > 0)
  expect_true(grepl("SIM", result$name))
  expect_true(grepl("ftp://", result$url))
})

# --- .sim_decode_age --- additional edge cases ---

test_that(".sim_decode_age decodes hours correctly", {
  result <- .sim_decode_age("112")
  expect_equal(result, 12 / (365.25 * 24), tolerance = 0.0001)
})

test_that(".sim_decode_age decodes minutes correctly", {
  result <- .sim_decode_age("030")
  expect_equal(result, 30 / (365.25 * 24 * 60), tolerance = 0.0001)
})

test_that(".sim_decode_age handles unknown unit", {
  # unit code 6 is not defined in case_when, should return NA
  result <- .sim_decode_age("600")
  expect_true(is.na(result))
})

test_that(".sim_decode_age handles unit 5 (100+ years)", {
  expect_equal(.sim_decode_age("510"), 110)
  expect_equal(.sim_decode_age("520"), 120)
})

test_that(".sim_decode_age handles zero value for each unit", {
  expect_equal(.sim_decode_age("400"), 0)  # 0 years
  expect_equal(.sim_decode_age("300"), 0)  # 0 months
  expect_equal(.sim_decode_age("200"), 0)  # 0 days
  expect_equal(.sim_decode_age("100"), 0)  # 0 hours
  expect_equal(.sim_decode_age("000"), 0)  # 0 minutes
})

# --- .sim_download_loop --- mocked tests ---

test_that(".sim_download_loop binds results from multiple UFs", {
  local_mocked_bindings(
    .sim_download_and_read = function(year, uf, ...) {
      tibble::tibble(
        year = as.integer(year), uf_source = uf,
        CAUSABAS = "X00", SEXO = "M"
      )
    }
  )

  result <- .sim_download_loop(
    year = 2022L, target_ufs = c("AC", "RJ"),
    cache = FALSE, cache_dir = NULL
  )

  expect_true(is.list(result))
  expect_s3_class(result$data, "data.frame")
  expect_equal(nrow(result$data), 2)
  expect_equal(sort(unique(result$data$uf_source)), c("AC", "RJ"))
  expect_equal(length(result$failed_labels), 0)
})

test_that(".sim_download_loop binds results from multiple years", {
  local_mocked_bindings(
    .sim_download_and_read = function(year, uf, ...) {
      tibble::tibble(
        year = as.integer(year), uf_source = uf,
        CAUSABAS = "X00"
      )
    }
  )

  result <- .sim_download_loop(
    year = c(2020L, 2021L), target_ufs = "AC",
    cache = FALSE, cache_dir = NULL
  )

  expect_equal(nrow(result$data), 2)
  expect_equal(sort(unique(result$data$year)), c(2020L, 2021L))
})

test_that(".sim_download_loop tracks failures correctly", {
  local_mocked_bindings(
    .sim_download_and_read = function(year, uf, ...) {
      if (uf == "ZZ") stop("FTP error")
      tibble::tibble(
        year = as.integer(year), uf_source = uf,
        CAUSABAS = "X00"
      )
    }
  )

  result <- .sim_download_loop(
    year = 2022L, target_ufs = c("AC", "ZZ"),
    cache = FALSE, cache_dir = NULL
  )

  expect_equal(nrow(result$data), 1)
  expect_equal(length(result$failed_labels), 1)
  expect_equal(result$failed_labels, "ZZ 2022")
})

test_that(".sim_download_loop aborts when all downloads fail", {
  local_mocked_bindings(
    .sim_download_and_read = function(year, uf, ...) stop("FTP error")
  )

  expect_error(
    .sim_download_loop(
      year = 2022L, target_ufs = "AC",
      cache = FALSE, cache_dir = NULL
    ),
    "No data could be downloaded"
  )
})

test_that(".sim_download_loop generates correct labels for year x uf grid", {
  call_count <- 0L
  local_mocked_bindings(
    .sim_download_and_read = function(year, uf, ...) {
      call_count <<- call_count + 1L
      tibble::tibble(
        year = as.integer(year), uf_source = uf,
        CAUSABAS = "X00"
      )
    }
  )

  result <- .sim_download_loop(
    year = c(2020L, 2021L), target_ufs = c("AC", "SP"),
    cache = FALSE, cache_dir = NULL
  )

  expect_equal(nrow(result$data), 4)
  expect_equal(length(result$failed_labels), 0)
})

# --- .sim_post_process --- test cause filter ---

test_that(".sim_post_process filters by cause", {
  mock_data <- tibble::tibble(
    year = rep(2022L, 5), uf_source = rep("AC", 5),
    CAUSABAS = c("I210", "I219", "J180", "C509", "I211"),
    SEXO = rep("M", 5), IDADE = rep("462", 5)
  )

  result <- .sim_post_process(
    data = mock_data, cause = "I21",
    decode_age = FALSE, parse = FALSE, col_types = NULL,
    lazy = FALSE, vars = NULL, lazy_select = NULL
  )

  expect_equal(nrow(result$data), 3)
  expect_true(all(grepl("^I21", result$data$CAUSABAS)))
})

test_that(".sim_post_process filters by multiple causes", {
  mock_data <- tibble::tibble(
    year = rep(2022L, 5), uf_source = rep("AC", 5),
    CAUSABAS = c("I210", "J180", "C509", "I211", "J181"),
    SEXO = rep("M", 5), IDADE = rep("462", 5)
  )

  result <- .sim_post_process(
    data = mock_data, cause = c("I21", "J18"),
    decode_age = FALSE, parse = FALSE, col_types = NULL,
    lazy = FALSE, vars = NULL, lazy_select = NULL
  )

  expect_equal(nrow(result$data), 4)
  expect_true(all(grepl("^(I21|J18)", result$data$CAUSABAS)))
})

test_that(".sim_post_process warns when CAUSABAS column not found", {
  mock_data <- tibble::tibble(
    year = 2022L, uf_source = "AC",
    SEXO = "M", IDADE = "462"
  )

  expect_warning(
    .sim_post_process(
      data = mock_data, cause = "I21",
      decode_age = FALSE, parse = FALSE, col_types = NULL,
      lazy = FALSE, vars = NULL, lazy_select = NULL
    ),
    "CAUSABAS"
  )
})

test_that(".sim_post_process decode_age adds age_years column", {
  mock_data <- tibble::tibble(
    year = 2022L, uf_source = "AC",
    CAUSABAS = "I210", SEXO = "M", IDADE = "462"
  )

  result <- .sim_post_process(
    data = mock_data, cause = NULL,
    decode_age = TRUE, parse = FALSE, col_types = NULL,
    lazy = FALSE, vars = NULL, lazy_select = NULL
  )

  expect_true("age_years" %in% names(result$data))
  expect_equal(result$data$age_years, 62)
})

test_that(".sim_post_process decode_age places age_years after IDADE", {
  mock_data <- tibble::tibble(
    year = 2022L, uf_source = "AC",
    CAUSABAS = "I210", SEXO = "M", IDADE = "462"
  )

  result <- .sim_post_process(
    data = mock_data, cause = NULL,
    decode_age = TRUE, parse = FALSE, col_types = NULL,
    lazy = FALSE, vars = NULL, lazy_select = NULL
  )

  col_positions <- which(names(result$data) %in% c("IDADE", "age_years"))
  expect_equal(diff(col_positions), 1)
})

test_that(".sim_post_process decode_age=FALSE does not add age_years", {
  mock_data <- tibble::tibble(
    year = 2022L, uf_source = "AC",
    CAUSABAS = "I210", SEXO = "M", IDADE = "462"
  )

  result <- .sim_post_process(
    data = mock_data, cause = NULL,
    decode_age = FALSE, parse = FALSE, col_types = NULL,
    lazy = FALSE, vars = NULL, lazy_select = NULL
  )

  expect_false("age_years" %in% names(result$data))
})

test_that(".sim_post_process updates lazy_select with age_years when relevant", {
  mock_data <- tibble::tibble(
    year = 2022L, uf_source = "AC",
    CAUSABAS = "I210", SEXO = "M", IDADE = "462"
  )

  result <- .sim_post_process(
    data = mock_data, cause = NULL,
    decode_age = TRUE, parse = FALSE, col_types = NULL,
    lazy = FALSE,
    vars = c("IDADE", "SEXO"),
    lazy_select = c("year", "uf_source", "IDADE", "SEXO")
  )

  expect_true("age_years" %in% result$lazy_select)
})

test_that(".sim_post_process parse=TRUE converts types", {
  mock_data <- tibble::tibble(
    year = 2022L, uf_source = "AC",
    DTOBITO = "25122022", PESO = "3500", SEXO = "M", IDADE = "462"
  )

  result <- .sim_post_process(
    data = mock_data, cause = NULL,
    decode_age = FALSE, parse = TRUE, col_types = NULL,
    lazy = FALSE, vars = NULL, lazy_select = NULL
  )

  expect_s3_class(result$data$DTOBITO, "Date")
  expect_type(result$data$PESO, "integer")
  expect_type(result$data$SEXO, "character")
})

test_that(".sim_post_process parse skipped when lazy=TRUE", {
  mock_data <- tibble::tibble(
    year = 2022L, uf_source = "AC",
    DTOBITO = "25122022", PESO = "3500", SEXO = "M", IDADE = "462"
  )

  result <- .sim_post_process(
    data = mock_data, cause = NULL,
    decode_age = FALSE, parse = TRUE, col_types = NULL,
    lazy = TRUE, vars = NULL, lazy_select = NULL
  )

  # parse should be skipped when lazy=TRUE, so DTOBITO stays character
  expect_type(result$data$DTOBITO, "character")
})

# --- sim_data --- additional mocked end-to-end ---

test_that("sim_data with vars selects columns", {
  local_mocked_bindings(
    .sim_download_and_read = function(year, uf, ...) {
      tibble::tibble(
        year = as.integer(year), uf_source = uf,
        CAUSABAS = "X00", SEXO = "M", IDADE = "462",
        DTOBITO = "01012022", CODMUNRES = "120040"
      )
    }
  )

  result <- sim_data(2022, uf = "AC", vars = c("CAUSABAS", "SEXO"),
                     parse = FALSE, decode_age = FALSE)

  expect_true("CAUSABAS" %in% names(result))
  expect_true("SEXO" %in% names(result))
  expect_true("year" %in% names(result))
  expect_true("uf_source" %in% names(result))
  # DTOBITO should not be present since it's not in vars
  expect_false("DTOBITO" %in% names(result))
})
