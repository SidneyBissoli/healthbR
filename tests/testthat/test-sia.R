# tests for SIA module functions

# ============================================================================
# sia_years
# ============================================================================

test_that("sia_years returns integer vector", {
  years <- sia_years()
  expect_type(years, "integer")
  expect_gt(length(years), 0)
  expect_true(2022L %in% years)
  expect_true(2008L %in% years)
})

test_that("sia_years filters by status", {
  final <- sia_years("final")
  prelim <- sia_years("preliminary")
  all_years <- sia_years("all")

  expect_true(length(all_years) > length(final))
  expect_true(length(all_years) == length(final) + length(prelim))
  expect_true(all(final %in% all_years))
  expect_true(all(prelim %in% all_years))
})

test_that("sia_years errors on invalid status", {
  expect_error(sia_years("invalid"))
})

# ============================================================================
# sia_info
# ============================================================================

test_that("sia_info returns expected structure", {
  info <- sia_info()

  expect_type(info, "list")
  expect_true("name" %in% names(info))
  expect_true("source" %in% names(info))
  expect_true("final_years" %in% names(info))
  expect_true("preliminary_years" %in% names(info))
  expect_true("n_variables" %in% names(info))
  expect_true("n_types" %in% names(info))
})

# ============================================================================
# sia_variables
# ============================================================================

test_that("sia_variables returns tibble with expected columns", {
  vars <- sia_variables()
  expect_s3_class(vars, "tbl_df")
  expect_true(all(c("variable", "description", "type", "section") %in% names(vars)))
  expect_gt(nrow(vars), 0)
  expect_true("PA_PROC_ID" %in% vars$variable)
  expect_true("PA_SEXO" %in% vars$variable)
  expect_true("PA_CIDPRI" %in% vars$variable)
  expect_true("PA_VALAPR" %in% vars$variable)
})

test_that("sia_variables has key variables present", {
  vars <- sia_variables()
  key_vars <- c("PA_CODUNI", "PA_PROC_ID", "PA_CIDPRI", "PA_SEXO",
                "PA_IDADE", "PA_RACACOR", "PA_VALPRO", "PA_VALAPR",
                "PA_UFMUN", "PA_MVM")
  for (v in key_vars) {
    expect_true(v %in% vars$variable, info = paste(v, "missing"))
  }
})

test_that("sia_variables search works", {
  proc_vars <- sia_variables(search = "procedimento")
  expect_gt(nrow(proc_vars), 0)
})

test_that("sia_variables search is accent-insensitive", {
  result_accent <- sia_variables(search = "diagn\u00f3stico")
  result_plain <- sia_variables(search = "diagnostico")
  expect_equal(nrow(result_accent), nrow(result_plain))
})

test_that("sia_variables search returns empty tibble for no match", {
  result <- sia_variables(search = "zzzznonexistent")
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("sia_variables search matches variable names too", {
  result <- sia_variables(search = "PA_SEXO")
  expect_gt(nrow(result), 0)
  expect_true("PA_SEXO" %in% result$variable)
})

test_that("sia_variables has expected sections", {
  vars <- sia_variables()
  sections <- unique(vars$section)
  expect_true("gestao" %in% sections)
  expect_true("procedimento" %in% sections)
  expect_true("paciente" %in% sections)
  expect_true("diagnostico" %in% sections)
  expect_true("financeiro" %in% sections)
  expect_true("localizacao" %in% sections)
  expect_true("temporal" %in% sections)
})

# ============================================================================
# sia_dictionary
# ============================================================================

test_that("sia_dictionary returns tibble with expected columns", {
  dict <- sia_dictionary()
  expect_s3_class(dict, "tbl_df")
  expect_true(all(c("variable", "description", "code", "label") %in% names(dict)))
  expect_gt(nrow(dict), 0)
})

test_that("sia_dictionary filters by variable", {
  sexo <- sia_dictionary("PA_SEXO")
  expect_true(all(sexo$variable == "PA_SEXO"))
  expect_true("Masculino" %in% sexo$label)
  expect_true("Feminino" %in% sexo$label)
})

test_that("sia_dictionary case insensitive", {
  lower <- sia_dictionary("pa_sexo")
  upper <- sia_dictionary("PA_SEXO")
  expect_equal(nrow(lower), nrow(upper))
})

test_that("sia_dictionary warns on unknown variable", {
  expect_warning(sia_dictionary("NONEXISTENT"), "not found")
})

test_that("sia_dictionary has key variables", {
  dict <- sia_dictionary()
  dict_vars <- unique(dict$variable)
  expect_true("PA_SEXO" %in% dict_vars)
  expect_true("PA_RACACOR" %in% dict_vars)
  expect_true("PA_CONDIC" %in% dict_vars)
  expect_true("PA_TIPATE" %in% dict_vars)
  expect_true("PA_TPFIN" %in% dict_vars)
  expect_true("PA_CATEND" %in% dict_vars)
})

test_that("sia_dictionary PA_SEXO has correct codes", {
  sexo <- sia_dictionary("PA_SEXO")
  expect_true("1" %in% sexo$code)
  expect_true("2" %in% sexo$code)
  expect_equal(nrow(sexo), 2)
})

test_that("sia_dictionary PA_RACACOR has correct categories", {
  raca <- sia_dictionary("PA_RACACOR")
  expect_equal(nrow(raca), 5)
  expect_true("Branca" %in% raca$label)
  expect_true("Preta" %in% raca$label)
  expect_true("Parda" %in% raca$label)
})

test_that("sia_dictionary PA_CONDIC has correct categories", {
  condic <- sia_dictionary("PA_CONDIC")
  expect_equal(nrow(condic), 4)
  expect_true("EP" %in% condic$code)
  expect_true("MC" %in% condic$code)
})

test_that("sia_dictionary PA_TIPATE has correct categories", {
  tipate <- sia_dictionary("PA_TIPATE")
  expect_equal(nrow(tipate), 4)
  expect_true("Eletivo" %in% tipate$label)
})

test_that("sia_dictionary PA_TPFIN has correct categories", {
  tpfin <- sia_dictionary("PA_TPFIN")
  expect_equal(nrow(tpfin), 5)
})

# ============================================================================
# .sia_build_ftp_url
# ============================================================================

test_that(".sia_build_ftp_url constructs correct URL for PA", {
  url <- .sia_build_ftp_url(2022, 1, "SP")
  expect_match(url, "SIASUS/200801_/Dados/PASP2201\\.dbc$")
  expect_match(url, "^ftp://ftp\\.datasus\\.gov\\.br/")
})

test_that(".sia_build_ftp_url handles 3-letter types", {
  url <- .sia_build_ftp_url(2022, 1, "SP", type = "ACF")
  expect_match(url, "ACFSP2201\\.dbc$")

  url2 <- .sia_build_ftp_url(2022, 6, "RJ", type = "ATD")
  expect_match(url2, "ATDRJ2206\\.dbc$")

  url3 <- .sia_build_ftp_url(2022, 12, "AC", type = "AMP")
  expect_match(url3, "AMPAC2212\\.dbc$")
})

test_that(".sia_build_ftp_url handles various year/month combos", {
  url1 <- .sia_build_ftp_url(2008, 12, "AC")
  expect_match(url1, "PAAC0812\\.dbc$")

  url2 <- .sia_build_ftp_url(2015, 6, "SP")
  expect_match(url2, "PASP1506\\.dbc$")

  url3 <- .sia_build_ftp_url(2023, 1, "TO")
  expect_match(url3, "PATO2301\\.dbc$")
})

test_that(".sia_build_ftp_url errors on pre-2008", {
  expect_error(.sia_build_ftp_url(2007, 1, "SP"), "not supported")
})

# ============================================================================
# .sia_validate_type
# ============================================================================

test_that(".sia_validate_type accepts valid types", {
  expect_equal(.sia_validate_type("PA"), "PA")
  expect_equal(.sia_validate_type("BI"), "BI")
  expect_equal(.sia_validate_type("ACF"), "ACF")
  expect_equal(.sia_validate_type("PS"), "PS")
})

test_that(".sia_validate_type is case-insensitive", {
  expect_equal(.sia_validate_type("pa"), "PA")
  expect_equal(.sia_validate_type("acf"), "ACF")
  expect_equal(.sia_validate_type("Bi"), "BI")
})

test_that(".sia_validate_type errors on invalid type", {
  expect_error(.sia_validate_type("XX"), "Invalid")
  expect_error(.sia_validate_type("ZZZ"), "Invalid")
})

test_that(".sia_validate_type accepts all 13 types", {
  all_types <- c("PA", "BI", "AD", "AM", "AN", "AQ", "AR", "AB",
                 "ACF", "ATD", "AMP", "SAD", "PS")
  for (t in all_types) {
    expect_equal(.sia_validate_type(t), t)
  }
})

# ============================================================================
# .sia_validate_month
# ============================================================================

test_that(".sia_validate_month accepts valid months", {
  expect_equal(.sia_validate_month(1), 1L)
  expect_equal(.sia_validate_month(12), 12L)
  expect_equal(.sia_validate_month(c(1, 6, 12)), c(1L, 6L, 12L))
})

test_that(".sia_validate_month NULL returns 1:12", {
  expect_equal(.sia_validate_month(NULL), 1L:12L)
})

test_that(".sia_validate_month errors on invalid months", {
  expect_error(.sia_validate_month(0), "Invalid")
  expect_error(.sia_validate_month(13), "Invalid")
  expect_error(.sia_validate_month(-1), "Invalid")
})

test_that(".sia_validate_month boundary checks", {
  expect_equal(.sia_validate_month(1), 1L)
  expect_equal(.sia_validate_month(12), 12L)
  expect_error(.sia_validate_month(c(1, 13)), "Invalid")
})

# ============================================================================
# .sia_validate_year
# ============================================================================

test_that(".sia_validate_year accepts valid years", {
  expect_equal(.sia_validate_year(2022), 2022L)
  expect_equal(.sia_validate_year(c(2020, 2021)), c(2020L, 2021L))
})

test_that(".sia_validate_year errors on invalid years", {
  expect_error(.sia_validate_year(2007), "not available")
  expect_error(.sia_validate_year(2050), "not available")
})

test_that(".sia_validate_year errors on NULL", {
  expect_error(.sia_validate_year(NULL), "required")
})

# ============================================================================
# .sia_validate_uf
# ============================================================================

test_that(".sia_validate_uf accepts valid UFs", {
  expect_equal(.sia_validate_uf("SP"), "SP")
  expect_equal(.sia_validate_uf("sp"), "SP")
  expect_equal(.sia_validate_uf(c("SP", "RJ")), c("SP", "RJ"))
})

test_that(".sia_validate_uf errors on invalid UFs", {
  expect_error(.sia_validate_uf("XX"), "Invalid")
  expect_error(.sia_validate_uf(c("SP", "ZZ")), "Invalid")
})

# ============================================================================
# .sia_validate_vars
# ============================================================================

test_that(".sia_validate_vars warns on unknown variables", {
  expect_warning(.sia_validate_vars("NONEXISTENT"), "not in known")
  expect_warning(
    .sia_validate_vars(c("PA_SEXO", "FAKECOL")),
    "not in known"
  )
})

test_that(".sia_validate_vars silent on known variables", {
  expect_no_warning(.sia_validate_vars("PA_SEXO"))
  expect_no_warning(.sia_validate_vars(c("PA_SEXO", "PA_CIDPRI", "PA_VALAPR")))
})

# ============================================================================
# sia_valid_types
# ============================================================================

test_that("sia_valid_types has 13 types with correct structure", {
  expect_equal(nrow(sia_valid_types), 13)
  expect_true(all(c("code", "name", "description") %in% names(sia_valid_types)))
  expect_true("PA" %in% sia_valid_types$code)
  expect_true("PS" %in% sia_valid_types$code)
})

# ============================================================================
# sia_label_maps
# ============================================================================

test_that("sia_label_maps are consistent with dictionary", {
  for (var_name in names(sia_label_maps)) {
    dict_rows <- sia_dictionary(var_name)
    map_codes <- names(sia_label_maps[[var_name]])
    expect_true(all(map_codes %in% dict_rows$code),
                info = paste(var_name, "label_maps codes not in dictionary"))
  }
})

# ============================================================================
# sia_cache functions
# ============================================================================

test_that("sia_cache_status works with empty cache", {
  temp_dir <- tempfile("sia_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  result <- sia_cache_status(cache_dir = temp_dir)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("sia_clear_cache works with empty cache", {
  temp_dir <- tempfile("sia_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  expect_no_error(sia_clear_cache(cache_dir = temp_dir))
})

test_that("sia_cache_status detects cached files", {
  temp_dir <- tempfile("sia_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  # create fake cache files
  writeLines("test", file.path(temp_dir, "sia_PA_AC_202201.rds"))
  writeLines("test", file.path(temp_dir, "sia_PA_AC_202202.rds"))

  result <- sia_cache_status(cache_dir = temp_dir)
  expect_equal(nrow(result), 2)
  expect_true(all(grepl("^sia_", result$file)))
})

test_that("sia_clear_cache removes cached files", {
  temp_dir <- tempfile("sia_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  writeLines("test", file.path(temp_dir, "sia_PA_AC_202201.rds"))
  sia_clear_cache(cache_dir = temp_dir)

  files <- list.files(temp_dir, pattern = "^sia_")
  expect_equal(length(files), 0)
})

test_that(".sia_cache_dir creates directory", {
  temp_dir <- file.path(tempdir(), "sia_cache_test_create")
  on.exit(unlink(temp_dir, recursive = TRUE))

  result <- .sia_cache_dir(temp_dir)
  expect_true(dir.exists(result))
  expect_equal(result, temp_dir)
})

# ============================================================================
# integration tests (require internet + HEALTHBR_INTEGRATION=true)
# ============================================================================

test_that("sia_data downloads PA single month single UF", {
  skip_if_no_integration()

  data <- sia_data(year = 2022, month = 1, uf = "AC",
                   cache_dir = tempdir())
  expect_s3_class(data, "tbl_df")
  expect_gt(nrow(data), 0)
  expect_true("PA_PROC_ID" %in% names(data))
  expect_true("PA_SEXO" %in% names(data))
  expect_true("PA_VALAPR" %in% names(data))
  expect_true("PA_CIDPRI" %in% names(data))
  expect_true("year" %in% names(data))
  expect_true("month" %in% names(data))
  expect_true("uf_source" %in% names(data))
  expect_equal(unique(data$year), 2022L)
  expect_equal(unique(data$month), 1L)
  expect_equal(unique(data$uf_source), "AC")
})

test_that("sia_data filters by procedure", {
  skip_if_no_integration()

  proc_data <- sia_data(year = 2022, month = 1, uf = "AC",
                        procedure = "0301",
                        cache_dir = tempdir())
  if (nrow(proc_data) > 0) {
    expect_true(all(grepl("^0301", proc_data$PA_PROC_ID)))
  }
})

test_that("sia_data filters by diagnosis", {
  skip_if_no_integration()

  diag_data <- sia_data(year = 2022, month = 1, uf = "AC",
                        diagnosis = "J",
                        cache_dir = tempdir())
  if (nrow(diag_data) > 0) {
    expect_true(all(grepl("^J", diag_data$PA_CIDPRI)))
  }
})

test_that("sia_data selects variables", {
  skip_if_no_integration()

  data <- sia_data(year = 2022, month = 1, uf = "AC",
                   vars = c("PA_PROC_ID", "PA_SEXO", "PA_VALAPR"),
                   cache_dir = tempdir())
  expect_true("PA_PROC_ID" %in% names(data))
  expect_true("PA_SEXO" %in% names(data))
  expect_true("PA_VALAPR" %in% names(data))
  expect_true("year" %in% names(data))
  expect_true("month" %in% names(data))
  expect_true("uf_source" %in% names(data))
})

test_that("sia_data cache works (second call faster)", {
  skip_if_no_integration()

  cache_dir <- tempfile("sia_cache_test")
  dir.create(cache_dir, recursive = TRUE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  t1 <- system.time(sia_data(year = 2022, month = 1, uf = "AC",
                              cache_dir = cache_dir))
  t2 <- system.time(sia_data(year = 2022, month = 1, uf = "AC",
                              cache_dir = cache_dir))
  expect_lt(t2["elapsed"], t1["elapsed"])
})

test_that("sia_data handles multiple months", {
  skip_if_no_integration()

  data <- sia_data(year = 2022, month = 1:2, uf = "AC",
                   cache_dir = tempdir())
  expect_s3_class(data, "tbl_df")
  expect_gt(nrow(data), 0)
  expect_true(all(c(1L, 2L) %in% data$month))
})

test_that("sia_data downloads different file type (BI)", {
  skip_if_no_integration()

  data <- sia_data(year = 2022, month = 1, uf = "AC", type = "BI",
                   cache_dir = tempdir())
  expect_s3_class(data, "tbl_df")
  expect_gt(nrow(data), 0)
  expect_true("year" %in% names(data))
  expect_true("month" %in% names(data))
  expect_true("uf_source" %in% names(data))
})

# ============================================================================
# smart type parsing
# ============================================================================

test_that("sia_variables type column has non-character types", {
  vars <- sia_variables()
  types <- unique(vars$type)
  expect_true("date_ym" %in% types)
  expect_true("integer" %in% types)
  expect_true("double" %in% types)
  expect_equal(vars$type[vars$variable == "PA_MVM"], "date_ym")
  expect_equal(vars$type[vars$variable == "PA_QTDPRO"], "integer")
  expect_equal(vars$type[vars$variable == "PA_VALAPR"], "double")
  expect_equal(vars$type[vars$variable == "PA_SEXO"], "character")
})

test_that("sia parse converts mock data correctly", {
  mock_data <- tibble::tibble(
    year = 2022L, month = 1L, uf_source = "AC",
    PA_MVM = "202201", PA_QTDPRO = "10",
    PA_VALAPR = "150.75", PA_SEXO = "1"
  )
  spec <- .build_type_spec(sia_variables_metadata)
  parsed <- .parse_columns(mock_data, spec)

  expect_s3_class(parsed$PA_MVM, "Date")
  expect_type(parsed$PA_QTDPRO, "integer")
  expect_type(parsed$PA_VALAPR, "double")
  expect_type(parsed$PA_SEXO, "character")
})


# ============================================================================
# consolidated download failure reporting
# ============================================================================

test_that("sia_data reports partial download failures", {
  local_mocked_bindings(
    .sia_validate_year = function(year, ...) as.integer(year),
    .sia_validate_uf = function(uf) toupper(uf),
    .sia_download_and_read = function(year, month, uf, ...) {
      if (uf == "XX") stop("Not found")
      tibble::tibble(year = as.integer(year), month = as.integer(month),
                     uf_source = uf, PA_PROC_ID = "0301")
    }
  )
  result <- suppressWarnings(
    sia_data(2022, month = 1, uf = c("AC", "XX"), parse = FALSE)
  )
  expect_s3_class(result, "data.frame")
  failures <- attr(result, "download_failures")
  expect_false(is.null(failures))
  expect_equal(failures, "PA XX 2022/01")
})
