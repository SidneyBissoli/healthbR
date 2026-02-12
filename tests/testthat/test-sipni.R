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

test_that("sipni_years contains expected range", {
  years <- sipni_years()
  expect_equal(min(years), 1994L)
  expect_equal(max(years), 2019L)
  expect_equal(length(years), 26)
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
# .sipni_validate_type
# ============================================================================

test_that(".sipni_validate_type accepts valid types", {
  expect_equal(.sipni_validate_type("DPNI"), "DPNI")
  expect_equal(.sipni_validate_type("CPNI"), "CPNI")
})

test_that(".sipni_validate_type is case-insensitive", {
  expect_equal(.sipni_validate_type("dpni"), "DPNI")
  expect_equal(.sipni_validate_type("cpni"), "CPNI")
  expect_equal(.sipni_validate_type("Dpni"), "DPNI")
})

test_that(".sipni_validate_type errors on invalid type", {
  expect_error(.sipni_validate_type("XX"), "Invalid")
  expect_error(.sipni_validate_type("ST"), "Invalid")
})

# ============================================================================
# .sipni_validate_year
# ============================================================================

test_that(".sipni_validate_year accepts valid years", {
  expect_equal(.sipni_validate_year(2019), 2019L)
  expect_equal(.sipni_validate_year(c(2018, 2019)), c(2018L, 2019L))
  expect_equal(.sipni_validate_year(1994), 1994L)
})

test_that(".sipni_validate_year errors on invalid years", {
  expect_error(.sipni_validate_year(1993), "not available")
  expect_error(.sipni_validate_year(2020), "not available")
  expect_error(.sipni_validate_year(2050), "not available")
})

test_that(".sipni_validate_year errors on NULL", {
  expect_error(.sipni_validate_year(NULL), "required")
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

# ============================================================================
# sipni_valid_types
# ============================================================================

test_that("sipni_valid_types has correct structure", {
  expect_equal(nrow(sipni_valid_types), 2)
  expect_true(all(c("code", "name", "description") %in% names(sipni_valid_types)))
  expect_true("DPNI" %in% sipni_valid_types$code)
  expect_true("CPNI" %in% sipni_valid_types$code)
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

test_that("sipni_cache_status detects cached files", {
  temp_dir <- tempfile("sipni_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  # create fake cache files
  writeLines("test", file.path(temp_dir, "sipni_DPNI_AC_2019.rds"))
  writeLines("test", file.path(temp_dir, "sipni_DPNI_SP_2019.rds"))

  result <- sipni_cache_status(cache_dir = temp_dir)
  expect_equal(nrow(result), 2)
  expect_true(all(grepl("^sipni_", result$file)))
})

test_that("sipni_clear_cache removes cached files", {
  temp_dir <- tempfile("sipni_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  writeLines("test", file.path(temp_dir, "sipni_DPNI_AC_2019.rds"))
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
