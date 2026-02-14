# tests for CNES module functions

# ============================================================================
# cnes_years
# ============================================================================

test_that("cnes_years returns integer vector", {
  years <- cnes_years()
  expect_type(years, "integer")
  expect_gt(length(years), 0)
  expect_true(2022L %in% years)
  expect_true(2005L %in% years)
})

test_that("cnes_years filters by status", {
  final <- cnes_years("final")
  prelim <- cnes_years("preliminary")
  all_years <- cnes_years("all")

  expect_true(length(all_years) > length(final))
  expect_true(length(all_years) == length(final) + length(prelim))
  expect_true(all(final %in% all_years))
  expect_true(all(prelim %in% all_years))
})

test_that("cnes_years errors on invalid status", {
  expect_error(cnes_years("invalid"))
})

test_that("cnes_years final starts at 2005", {
  final <- cnes_years("final")
  expect_equal(min(final), 2005L)
})

# ============================================================================
# cnes_info
# ============================================================================

test_that("cnes_info returns expected structure", {
  info <- cnes_info()

  expect_type(info, "list")
  expect_true("name" %in% names(info))
  expect_true("source" %in% names(info))
  expect_true("final_years" %in% names(info))
  expect_true("preliminary_years" %in% names(info))
  expect_true("n_variables" %in% names(info))
  expect_true("n_types" %in% names(info))
})

# ============================================================================
# cnes_variables
# ============================================================================

test_that("cnes_variables returns tibble with expected columns", {
  vars <- cnes_variables()
  expect_s3_class(vars, "tbl_df")
  expect_true(all(c("variable", "description", "type", "section") %in% names(vars)))
  expect_gt(nrow(vars), 0)
  expect_true("CNES" %in% vars$variable)
  expect_true("TP_UNID" %in% vars$variable)
  expect_true("VINC_SUS" %in% vars$variable)
  expect_true("TP_GESTAO" %in% vars$variable)
})

test_that("cnes_variables has key variables present", {
  vars <- cnes_variables()
  key_vars <- c("CNES", "CODUFMUN", "TP_UNID", "VINC_SUS", "TP_GESTAO",
                "ESFERA_A", "PF_PJ", "COMPETEN")
  for (v in key_vars) {
    expect_true(v %in% vars$variable, info = paste(v, "missing"))
  }
})

test_that("cnes_variables search works", {
  type_vars <- cnes_variables(search = "tipo")
  expect_gt(nrow(type_vars), 0)
})

test_that("cnes_variables search is accent-insensitive", {
  result_accent <- cnes_variables(search = "gest\u00e3o")
  result_plain <- cnes_variables(search = "gestao")
  expect_equal(nrow(result_accent), nrow(result_plain))
})

test_that("cnes_variables search returns empty tibble for no match", {
  result <- cnes_variables(search = "zzzznonexistent")
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("cnes_variables search matches variable names too", {
  result <- cnes_variables(search = "CNES")
  expect_gt(nrow(result), 0)
  expect_true("CNES" %in% result$variable)
})

test_that("cnes_variables has expected sections", {
  vars <- cnes_variables()
  sections <- unique(vars$section)
  expect_true("identificacao" %in% sections)
  expect_true("classificacao" %in% sections)
  expect_true("sus" %in% sections)
  expect_true("atendimento" %in% sections)
  expect_true("temporal" %in% sections)
})

# ============================================================================
# cnes_dictionary
# ============================================================================

test_that("cnes_dictionary returns tibble with expected columns", {
  dict <- cnes_dictionary()
  expect_s3_class(dict, "tbl_df")
  expect_true(all(c("variable", "description", "code", "label") %in% names(dict)))
  expect_gt(nrow(dict), 0)
})

test_that("cnes_dictionary filters by variable", {
  tp_unid <- cnes_dictionary("TP_UNID")
  expect_true(all(tp_unid$variable == "TP_UNID"))
  expect_gt(nrow(tp_unid), 10)
})

test_that("cnes_dictionary case insensitive", {
  lower <- cnes_dictionary("tp_unid")
  upper <- cnes_dictionary("TP_UNID")
  expect_equal(nrow(lower), nrow(upper))
})

test_that("cnes_dictionary warns on unknown variable", {
  expect_warning(cnes_dictionary("NONEXISTENT"), "not found")
})

test_that("cnes_dictionary has key variables", {
  dict <- cnes_dictionary()
  dict_vars <- unique(dict$variable)
  expect_true("TP_UNID" %in% dict_vars)
  expect_true("ESFERA_A" %in% dict_vars)
  expect_true("VINC_SUS" %in% dict_vars)
  expect_true("TP_GESTAO" %in% dict_vars)
  expect_true("PF_PJ" %in% dict_vars)
})

test_that("cnes_dictionary TP_UNID has correct codes", {
  tp_unid <- cnes_dictionary("TP_UNID")
  expect_equal(nrow(tp_unid), 22)
  expect_true("05" %in% tp_unid$code)
  expect_true("Hospital geral" %in% tp_unid$label)
})

test_that("cnes_dictionary ESFERA_A has correct categories", {
  esfera <- cnes_dictionary("ESFERA_A")
  expect_equal(nrow(esfera), 4)
  expect_true("Federal" %in% esfera$label)
  expect_true("Estadual" %in% esfera$label)
  expect_true("Municipal" %in% esfera$label)
  expect_true("Privada" %in% esfera$label)
})

test_that("cnes_dictionary VINC_SUS has correct categories", {
  vinc <- cnes_dictionary("VINC_SUS")
  expect_equal(nrow(vinc), 2)
  expect_true("0" %in% vinc$code)
  expect_true("1" %in% vinc$code)
})

# ============================================================================
# .cnes_build_ftp_url
# ============================================================================

test_that(".cnes_build_ftp_url constructs correct URL for ST with subdirectory", {
  url <- .cnes_build_ftp_url(2023, 1, "SP")
  expect_match(url, "CNES/200508_/Dados/ST/STSP2301\\.dbc$")
  expect_match(url, "^ftp://ftp\\.datasus\\.gov\\.br/")
})

test_that(".cnes_build_ftp_url handles different types with subdirectory", {
  url_lt <- .cnes_build_ftp_url(2023, 1, "SP", type = "LT")
  expect_match(url_lt, "/LT/LTSP2301\\.dbc$")

  url_pf <- .cnes_build_ftp_url(2023, 6, "RJ", type = "PF")
  expect_match(url_pf, "/PF/PFRJ2306\\.dbc$")

  url_eq <- .cnes_build_ftp_url(2023, 12, "AC", type = "EQ")
  expect_match(url_eq, "/EQ/EQAC2312\\.dbc$")
})

test_that(".cnes_build_ftp_url handles various year/month combos", {
  url1 <- .cnes_build_ftp_url(2005, 8, "AC")
  expect_match(url1, "STAC0508\\.dbc$")

  url2 <- .cnes_build_ftp_url(2015, 6, "SP")
  expect_match(url2, "STSP1506\\.dbc$")

  url3 <- .cnes_build_ftp_url(2023, 1, "TO")
  expect_match(url3, "STTO2301\\.dbc$")
})

test_that(".cnes_build_ftp_url errors on pre-2005", {
  expect_error(.cnes_build_ftp_url(2004, 1, "SP"), "not supported")
})

# ============================================================================
# .cnes_validate_type
# ============================================================================

test_that(".cnes_validate_type accepts valid types", {
  expect_equal(.cnes_validate_type("ST"), "ST")
  expect_equal(.cnes_validate_type("LT"), "LT")
  expect_equal(.cnes_validate_type("PF"), "PF")
  expect_equal(.cnes_validate_type("GM"), "GM")
})

test_that(".cnes_validate_type is case-insensitive", {
  expect_equal(.cnes_validate_type("st"), "ST")
  expect_equal(.cnes_validate_type("lt"), "LT")
  expect_equal(.cnes_validate_type("Pf"), "PF")
})

test_that(".cnes_validate_type errors on invalid type", {
  expect_error(.cnes_validate_type("XX"), "Invalid")
  expect_error(.cnes_validate_type("ZZZ"), "Invalid")
})

test_that(".cnes_validate_type accepts all 13 types", {
  all_types <- c("ST", "LT", "PF", "DC", "EQ", "SR", "HB", "EP",
                 "RC", "IN", "EE", "EF", "GM")
  for (t in all_types) {
    expect_equal(.cnes_validate_type(t), t)
  }
})

# ============================================================================
# .validate_month
# ============================================================================

test_that(".validate_month accepts valid months", {
  expect_equal(.validate_month(1), 1L)
  expect_equal(.validate_month(12), 12L)
  expect_equal(.validate_month(c(1, 6, 12)), c(1L, 6L, 12L))
})

test_that(".validate_month NULL returns 1:12", {
  expect_equal(.validate_month(NULL), 1L:12L)
})

test_that(".validate_month errors on invalid months", {
  expect_error(.validate_month(0), "Invalid")
  expect_error(.validate_month(13), "Invalid")
  expect_error(.validate_month(-1), "Invalid")
})

test_that(".validate_month boundary checks", {
  expect_equal(.validate_month(1), 1L)
  expect_equal(.validate_month(12), 12L)
  expect_error(.validate_month(c(1, 13)), "Invalid")
})

# ============================================================================
# .cnes_validate_year
# ============================================================================

test_that(".cnes_validate_year accepts valid years", {
  expect_equal(.cnes_validate_year(2023), 2023L)
  expect_equal(.cnes_validate_year(c(2020, 2021)), c(2020L, 2021L))
})

test_that(".cnes_validate_year errors on invalid years", {
  expect_error(.cnes_validate_year(2004), "not available")
  expect_error(.cnes_validate_year(2050), "not available")
})

test_that(".cnes_validate_year errors on NULL", {
  expect_error(.cnes_validate_year(NULL), "required")
})

# ============================================================================
# .cnes_validate_uf
# ============================================================================

test_that(".cnes_validate_uf accepts valid UFs", {
  expect_equal(.cnes_validate_uf("SP"), "SP")
  expect_equal(.cnes_validate_uf("sp"), "SP")
  expect_equal(.cnes_validate_uf(c("SP", "RJ")), c("SP", "RJ"))
})

test_that(".cnes_validate_uf errors on invalid UFs", {
  expect_error(.cnes_validate_uf("XX"), "Invalid")
  expect_error(.cnes_validate_uf(c("SP", "ZZ")), "Invalid")
})

# ============================================================================
# .cnes_validate_vars
# ============================================================================

test_that(".cnes_validate_vars warns on unknown variables", {
  expect_warning(.cnes_validate_vars("NONEXISTENT"), "not in known")
  expect_warning(
    .cnes_validate_vars(c("CNES", "FAKECOL")),
    "not in known"
  )
})

test_that(".cnes_validate_vars silent on known variables", {
  expect_no_warning(.cnes_validate_vars("CNES"))
  expect_no_warning(.cnes_validate_vars(c("CNES", "TP_UNID", "VINC_SUS")))
})

# ============================================================================
# cnes_valid_types
# ============================================================================

test_that("cnes_valid_types has 13 types with correct structure", {
  expect_equal(nrow(cnes_valid_types), 13)
  expect_true(all(c("code", "name", "description") %in% names(cnes_valid_types)))
  expect_true("ST" %in% cnes_valid_types$code)
  expect_true("GM" %in% cnes_valid_types$code)
})

# ============================================================================
# cnes_label_maps
# ============================================================================

test_that("cnes_label_maps are consistent with dictionary", {
  for (var_name in names(cnes_label_maps)) {
    dict_rows <- cnes_dictionary(var_name)
    map_codes <- names(cnes_label_maps[[var_name]])
    expect_true(all(map_codes %in% dict_rows$code),
                info = paste(var_name, "label_maps codes not in dictionary"))
  }
})

# ============================================================================
# cnes_cache functions
# ============================================================================

test_that("cnes_cache_status works with empty cache", {
  temp_dir <- tempfile("cnes_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  result <- cnes_cache_status(cache_dir = temp_dir)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("cnes_clear_cache works with empty cache", {
  temp_dir <- tempfile("cnes_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  expect_no_error(cnes_clear_cache(cache_dir = temp_dir))
})

test_that("cnes_cache_status detects cached files", {
  temp_dir <- tempfile("cnes_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  # create fake cache files
  writeLines("test", file.path(temp_dir, "cnes_ST_AC_202301.rds"))
  writeLines("test", file.path(temp_dir, "cnes_ST_AC_202302.rds"))

  result <- cnes_cache_status(cache_dir = temp_dir)
  expect_equal(nrow(result), 2)
  expect_true(all(grepl("^cnes_", result$file)))
})

test_that("cnes_clear_cache removes cached files", {
  temp_dir <- tempfile("cnes_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  writeLines("test", file.path(temp_dir, "cnes_ST_AC_202301.rds"))
  cnes_clear_cache(cache_dir = temp_dir)

  files <- list.files(temp_dir, pattern = "^cnes_")
  expect_equal(length(files), 0)
})

test_that(".cnes_cache_dir creates directory", {
  temp_dir <- file.path(tempdir(), "cnes_cache_test_create")
  on.exit(unlink(temp_dir, recursive = TRUE))

  result <- .cnes_cache_dir(temp_dir)
  expect_true(dir.exists(result))
  expect_equal(result, temp_dir)
})

# ============================================================================
# integration tests (require internet + HEALTHBR_INTEGRATION=true)
# ============================================================================

test_that("cnes_data downloads ST single month single UF", {
  skip_if_no_integration()

  data <- cnes_data(year = 2023, month = 1, uf = "AC",
                    cache_dir = tempdir())
  expect_s3_class(data, "tbl_df")
  expect_gt(nrow(data), 0)
  expect_true("CNES" %in% names(data))
  expect_true("TP_UNID" %in% names(data))
  expect_true("VINC_SUS" %in% names(data))
  expect_true("year" %in% names(data))
  expect_true("month" %in% names(data))
  expect_true("uf_source" %in% names(data))
  expect_equal(unique(data$year), 2023L)
  expect_equal(unique(data$month), 1L)
  expect_equal(unique(data$uf_source), "AC")
})

test_that("cnes_data selects variables", {
  skip_if_no_integration()

  data <- cnes_data(year = 2023, month = 1, uf = "AC",
                    vars = c("CNES", "TP_UNID", "VINC_SUS"),
                    cache_dir = tempdir())
  expect_true("CNES" %in% names(data))
  expect_true("TP_UNID" %in% names(data))
  expect_true("VINC_SUS" %in% names(data))
  expect_true("year" %in% names(data))
  expect_true("month" %in% names(data))
  expect_true("uf_source" %in% names(data))
})

test_that("cnes_data handles multiple months", {
  skip_if_no_integration()

  data <- cnes_data(year = 2023, month = 1:2, uf = "AC",
                    cache_dir = tempdir())
  expect_s3_class(data, "tbl_df")
  expect_gt(nrow(data), 0)
  expect_true(all(c(1L, 2L) %in% data$month))
})

test_that("cnes_data downloads different file type (LT)", {
  skip_if_no_integration()

  data <- cnes_data(year = 2023, month = 1, uf = "AC", type = "LT",
                    cache_dir = tempdir())
  expect_s3_class(data, "tbl_df")
  expect_gt(nrow(data), 0)
  expect_true("year" %in% names(data))
  expect_true("month" %in% names(data))
  expect_true("uf_source" %in% names(data))
})

test_that("cnes_data cache works (second call faster)", {
  skip_if_no_integration()

  cache_dir <- tempfile("cnes_cache_test")
  dir.create(cache_dir, recursive = TRUE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  t1 <- system.time(cnes_data(year = 2023, month = 1, uf = "AC",
                               cache_dir = cache_dir))
  t2 <- system.time(cnes_data(year = 2023, month = 1, uf = "AC",
                               cache_dir = cache_dir))
  expect_lt(t2["elapsed"], t1["elapsed"])
})

# ============================================================================
# smart type parsing
# ============================================================================

test_that("cnes_variables type column has date_ym for COMPETEN", {
  vars <- cnes_variables()
  expect_equal(vars$type[vars$variable == "COMPETEN"], "date_ym")
  # most should still be character
  expect_true(sum(vars$type == "character") > 20)
})

test_that("cnes parse converts mock data correctly", {
  mock_data <- tibble::tibble(
    year = 2023L, month = 1L, uf_source = "AC",
    COMPETEN = "202301", CNES = "1234567", TP_UNID = "05"
  )
  spec <- .build_type_spec(cnes_variables_metadata)
  parsed <- .parse_columns(mock_data, spec)

  expect_s3_class(parsed$COMPETEN, "Date")
  expect_type(parsed$CNES, "character")
  expect_type(parsed$TP_UNID, "character")
})


# ============================================================================
# consolidated download failure reporting
# ============================================================================

test_that("cnes_data reports partial download failures", {
  local_mocked_bindings(
    .cnes_validate_year = function(year, ...) as.integer(year),
    .cnes_validate_uf = function(uf) toupper(uf),
    .cnes_download_and_read = function(year, month, uf, ...) {
      if (uf == "XX") stop("Not found")
      tibble::tibble(year = as.integer(year), month = as.integer(month),
                     uf_source = uf, CNES = "1234567")
    }
  )
  result <- suppressWarnings(
    cnes_data(2023, month = 1, uf = c("AC", "XX"), parse = FALSE)
  )
  expect_s3_class(result, "data.frame")
  failures <- attr(result, "download_failures")
  expect_false(is.null(failures))
  expect_equal(failures, "ST XX 2023/01")
})
