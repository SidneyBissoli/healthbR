# tests for SIH module functions

# ============================================================================
# sih_years
# ============================================================================

test_that("sih_years returns integer vector", {
  years <- sih_years()
  expect_type(years, "integer")
  expect_gt(length(years), 0)
  expect_true(2022L %in% years)
  expect_true(2008L %in% years)
})

test_that("sih_years filters by status", {
  final <- sih_years("final")
  prelim <- sih_years("preliminary")
  all_years <- sih_years("all")

  expect_true(length(all_years) > length(final))
  expect_true(length(all_years) == length(final) + length(prelim))
  expect_true(all(final %in% all_years))
  expect_true(all(prelim %in% all_years))
})

test_that("sih_years errors on invalid status", {
  expect_error(sih_years("invalid"))
})

# ============================================================================
# sih_info
# ============================================================================

test_that("sih_info returns expected structure", {
  info <- sih_info()

  expect_type(info, "list")
  expect_true("name" %in% names(info))
  expect_true("source" %in% names(info))
  expect_true("final_years" %in% names(info))
  expect_true("preliminary_years" %in% names(info))
  expect_true("n_variables" %in% names(info))
})

# ============================================================================
# sih_variables
# ============================================================================

test_that("sih_variables returns tibble with expected columns", {
  vars <- sih_variables()
  expect_s3_class(vars, "tbl_df")
  expect_true(all(c("variable", "description", "type", "section") %in% names(vars)))
  expect_gt(nrow(vars), 0)
  expect_true("DIAG_PRINC" %in% vars$variable)
  expect_true("SEXO" %in% vars$variable)
  expect_true("MORTE" %in% vars$variable)
  expect_true("VAL_TOT" %in% vars$variable)
})

test_that("sih_variables has key variables present", {
  vars <- sih_variables()
  key_vars <- c("N_AIH", "DIAG_PRINC", "DT_INTER", "DT_SAIDA",
                "MUNIC_RES", "SEXO", "IDADE", "MORTE", "VAL_TOT")
  for (v in key_vars) {
    expect_true(v %in% vars$variable, info = paste(v, "missing"))
  }
})

test_that("sih_variables search works", {
  diag_vars <- sih_variables(search = "diag")
  expect_gt(nrow(diag_vars), 0)
})

test_that("sih_variables search is accent-insensitive", {
  result_accent <- sih_variables(search = "interna\u00e7\u00e3o")
  result_plain <- sih_variables(search = "internacao")
  expect_equal(nrow(result_accent), nrow(result_plain))
})

test_that("sih_variables search returns empty tibble for no match", {
  result <- sih_variables(search = "zzzznonexistent")
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("sih_variables has expected sections", {
  vars <- sih_variables()
  sections <- unique(vars$section)
  expect_true("identificacao" %in% sections)
  expect_true("paciente" %in% sections)
  expect_true("clinica" %in% sections)
  expect_true("procedimento" %in% sections)
  expect_true("internacao" %in% sections)
  expect_true("hospital" %in% sections)
  expect_true("desfecho" %in% sections)
  expect_true("financeiro" %in% sections)
})

# ============================================================================
# sih_dictionary
# ============================================================================

test_that("sih_dictionary returns tibble with expected columns", {
  dict <- sih_dictionary()
  expect_s3_class(dict, "tbl_df")
  expect_true(all(c("variable", "description", "code", "label") %in% names(dict)))
  expect_gt(nrow(dict), 0)
})

test_that("sih_dictionary filters by variable", {
  sexo <- sih_dictionary("SEXO")
  expect_true(all(sexo$variable == "SEXO"))
  expect_true("Masculino" %in% sexo$label)
  expect_true("Feminino" %in% sexo$label)
})

test_that("sih_dictionary case insensitive", {
  car_lower <- sih_dictionary("car_int")
  car_upper <- sih_dictionary("CAR_INT")
  expect_equal(nrow(car_lower), nrow(car_upper))
})

test_that("sih_dictionary warns on unknown variable", {
  expect_warning(sih_dictionary("NONEXISTENT"), "not found")
})

test_that("sih_dictionary has key variables", {
  dict <- sih_dictionary()
  dict_vars <- unique(dict$variable)
  expect_true("SEXO" %in% dict_vars)
  expect_true("RACA_COR" %in% dict_vars)
  expect_true("CAR_INT" %in% dict_vars)
  expect_true("COMPLEX" %in% dict_vars)
  expect_true("MORTE" %in% dict_vars)
  expect_true("IDENT" %in% dict_vars)
  expect_true("COD_IDADE" %in% dict_vars)
  expect_true("ESPEC" %in% dict_vars)
})

test_that("sih_dictionary SEXO has SIH-specific codes", {
  sexo <- sih_dictionary("SEXO")
  expect_true("0" %in% sexo$code)
  expect_true("1" %in% sexo$code)
  expect_true("3" %in% sexo$code)
  expect_true("Ignorado" %in% sexo$label)
})

test_that("sih_dictionary CAR_INT has correct categories", {
  car <- sih_dictionary("CAR_INT")
  expect_equal(nrow(car), 6)
  expect_true("Eletiva" %in% car$label)
  expect_true("Urg\u00eancia" %in% car$label)
})

test_that("sih_dictionary COMPLEX has correct categories", {
  complex <- sih_dictionary("COMPLEX")
  expect_equal(nrow(complex), 3)
  expect_true("Alta complexidade" %in% complex$label)
  expect_true("M\u00e9dia complexidade" %in% complex$label)
})

# ============================================================================
# .sih_build_ftp_url
# ============================================================================

test_that(".sih_build_ftp_url constructs correct URL with YYMM", {
  url <- .sih_build_ftp_url(2022, 1, "RJ")
  expect_match(url, "SIHSUS/200801_/Dados/RDRJ2201\\.dbc$")
  expect_match(url, "^ftp://ftp\\.datasus\\.gov\\.br/")
})

test_that(".sih_build_ftp_url handles various year/month combos", {
  url1 <- .sih_build_ftp_url(2008, 12, "AC")
  expect_match(url1, "RDAC0812\\.dbc$")

  url2 <- .sih_build_ftp_url(2015, 6, "SP")
  expect_match(url2, "RDSP1506\\.dbc$")

  url3 <- .sih_build_ftp_url(2023, 1, "TO")
  expect_match(url3, "RDTO2301\\.dbc$")
})

test_that(".sih_build_ftp_url errors on pre-2008", {
  expect_error(.sih_build_ftp_url(2007, 1, "SP"), "not supported")
})

# ============================================================================
# .sih_validate_month
# ============================================================================

test_that(".sih_validate_month accepts valid months", {
  expect_equal(.sih_validate_month(1), 1L)
  expect_equal(.sih_validate_month(12), 12L)
  expect_equal(.sih_validate_month(c(1, 6, 12)), c(1L, 6L, 12L))
})

test_that(".sih_validate_month NULL returns 1:12", {
  expect_equal(.sih_validate_month(NULL), 1L:12L)
})

test_that(".sih_validate_month errors on invalid months", {
  expect_error(.sih_validate_month(0), "Invalid")
  expect_error(.sih_validate_month(13), "Invalid")
  expect_error(.sih_validate_month(-1), "Invalid")
})

test_that(".sih_validate_month boundary checks", {
  expect_equal(.sih_validate_month(1), 1L)
  expect_equal(.sih_validate_month(12), 12L)
  expect_error(.sih_validate_month(c(1, 13)), "Invalid")
})

# ============================================================================
# .sih_validate_year
# ============================================================================

test_that(".sih_validate_year accepts valid years", {
  expect_equal(.sih_validate_year(2022), 2022L)
  expect_equal(.sih_validate_year(c(2020, 2021)), c(2020L, 2021L))
})

test_that(".sih_validate_year errors on invalid years", {
  expect_error(.sih_validate_year(2007), "not available")
  expect_error(.sih_validate_year(2050), "not available")
})

test_that(".sih_validate_year errors on NULL", {
  expect_error(.sih_validate_year(NULL), "required")
})

# ============================================================================
# .sih_validate_uf
# ============================================================================

test_that(".sih_validate_uf accepts valid UFs", {
  expect_equal(.sih_validate_uf("SP"), "SP")
  expect_equal(.sih_validate_uf("sp"), "SP")
  expect_equal(.sih_validate_uf(c("SP", "RJ")), c("SP", "RJ"))
})

test_that(".sih_validate_uf errors on invalid UFs", {
  expect_error(.sih_validate_uf("XX"), "Invalid")
  expect_error(.sih_validate_uf(c("SP", "ZZ")), "Invalid")
})

# ============================================================================
# .sih_validate_vars
# ============================================================================

test_that(".sih_validate_vars warns on unknown variables", {
  expect_warning(.sih_validate_vars("NONEXISTENT"), "not in known")
  expect_warning(
    .sih_validate_vars(c("SEXO", "FAKECOL")),
    "not in known"
  )
})

test_that(".sih_validate_vars silent on known variables", {
  expect_no_warning(.sih_validate_vars("SEXO"))
  expect_no_warning(.sih_validate_vars(c("SEXO", "DIAG_PRINC", "MORTE")))
})

# ============================================================================
# sih_cache functions
# ============================================================================

test_that("sih_cache_status works with empty cache", {
  temp_dir <- tempfile("sih_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  result <- sih_cache_status(cache_dir = temp_dir)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("sih_clear_cache works with empty cache", {
  temp_dir <- tempfile("sih_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  expect_no_error(sih_clear_cache(cache_dir = temp_dir))
})

test_that(".sih_cache_dir creates directory", {
  temp_dir <- file.path(tempdir(), "sih_cache_test_create")
  on.exit(unlink(temp_dir, recursive = TRUE))

  result <- .sih_cache_dir(temp_dir)
  expect_true(dir.exists(result))
  expect_equal(result, temp_dir)
})

# ============================================================================
# integration tests (require internet + HEALTHBR_INTEGRATION=true)
# ============================================================================

test_that("sih_data downloads single month single UF", {
  skip_if_no_integration()

  data <- sih_data(year = 2022, month = 1, uf = "AC",
                   cache_dir = tempdir())
  expect_s3_class(data, "tbl_df")
  expect_gt(nrow(data), 0)
  expect_true("DIAG_PRINC" %in% names(data))
  expect_true("SEXO" %in% names(data))
  expect_true("VAL_TOT" %in% names(data))
  expect_true("MUNIC_RES" %in% names(data))
  expect_true("year" %in% names(data))
  expect_true("month" %in% names(data))
  expect_true("uf_source" %in% names(data))
  expect_equal(unique(data$year), 2022L)
  expect_equal(unique(data$month), 1L)
  expect_equal(unique(data$uf_source), "AC")
})

test_that("sih_data filters by diagnosis", {
  skip_if_no_integration()

  diag_data <- sih_data(year = 2022, month = 1, uf = "AC",
                        diagnosis = "I21",
                        cache_dir = tempdir())
  if (nrow(diag_data) > 0) {
    expect_true(all(grepl("^I21", diag_data$DIAG_PRINC)))
  }
})

test_that("sih_data selects variables (month always kept)", {
  skip_if_no_integration()

  data <- sih_data(year = 2022, month = 1, uf = "AC",
                   vars = c("DIAG_PRINC", "SEXO", "VAL_TOT"),
                   cache_dir = tempdir())
  expect_true("DIAG_PRINC" %in% names(data))
  expect_true("SEXO" %in% names(data))
  expect_true("VAL_TOT" %in% names(data))
  expect_true("year" %in% names(data))
  expect_true("month" %in% names(data))
  expect_true("uf_source" %in% names(data))
})

test_that("sih_data cache works (second call faster)", {
  skip_if_no_integration()

  cache_dir <- tempfile("sih_cache_test")
  dir.create(cache_dir, recursive = TRUE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  t1 <- system.time(sih_data(year = 2022, month = 1, uf = "AC",
                              cache_dir = cache_dir))
  t2 <- system.time(sih_data(year = 2022, month = 1, uf = "AC",
                              cache_dir = cache_dir))
  expect_lt(t2["elapsed"], t1["elapsed"])
})

test_that("sih_data handles multiple months", {
  skip_if_no_integration()

  data <- sih_data(year = 2022, month = 1:2, uf = "AC",
                   cache_dir = tempdir())
  expect_s3_class(data, "tbl_df")
  expect_gt(nrow(data), 0)
  expect_true(all(c(1L, 2L) %in% data$month))
})
