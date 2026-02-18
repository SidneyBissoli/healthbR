# tests for SISAB module functions

# ============================================================================
# sisab_years
# ============================================================================

test_that("sisab_years returns integer vector", {
  years <- sisab_years()
  expect_type(years, "integer")
  expect_gt(length(years), 0)
  expect_true(2024L %in% years)
  expect_true(2007L %in% years)
})

test_that("sisab_years contains expected range", {
  years <- sisab_years()
  expect_equal(min(years), 2007L)
})

# ============================================================================
# sisab_info
# ============================================================================

test_that("sisab_info returns expected structure", {
  info <- sisab_info()

  expect_type(info, "list")
  expect_true("name" %in% names(info))
  expect_true("source" %in% names(info))
  expect_true("n_types" %in% names(info))
  expect_true("n_variables_aps" %in% names(info))
  expect_true("url" %in% names(info))
})

# ============================================================================
# sisab_variables
# ============================================================================

test_that("sisab_variables returns tibble with expected columns", {
  vars <- sisab_variables()
  expect_s3_class(vars, "tbl_df")
  expect_true(all(c("variable", "description", "type", "section") %in% names(vars)))
  expect_gt(nrow(vars), 0)
})

test_that("sisab_variables APS has expected variables", {
  vars <- sisab_variables(type = "aps")
  expect_true("qtPopulacao" %in% vars$variable)
  expect_true("qtCobertura" %in% vars$variable)
  expect_true("qtEsf" %in% vars$variable)
  expect_true("nuComp" %in% vars$variable)
})

test_that("sisab_variables SB has expected variables", {
  vars <- sisab_variables(type = "sb")
  expect_true("pcCoberturaSbAps" %in% vars$variable)
  expect_true("qtEquipeSb40h" %in% vars$variable)
})

test_that("sisab_variables search works", {
  result <- sisab_variables(search = "cobertura")
  expect_gt(nrow(result), 0)
})

test_that("sisab_variables search is accent-insensitive", {
  result_accent <- sisab_variables(search = "regi\u00e3o")
  result_plain <- sisab_variables(search = "regiao")
  expect_equal(nrow(result_accent), nrow(result_plain))
})

test_that("sisab_variables search returns empty tibble for no match", {
  result <- sisab_variables(search = "zzzznonexistent")
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

# ============================================================================
# sisab_valid_types
# ============================================================================

test_that("sisab_valid_types has expected structure", {
  expect_s3_class(sisab_valid_types, "tbl_df")
  expect_true(all(c("code", "name", "endpoint", "description") %in% names(sisab_valid_types)))
  expect_equal(nrow(sisab_valid_types), 4)
  expect_true("aps" %in% sisab_valid_types$code)
  expect_true("sb" %in% sisab_valid_types$code)
  expect_true("acs" %in% sisab_valid_types$code)
  expect_true("pns" %in% sisab_valid_types$code)
})

# ============================================================================
# sisab_valid_levels
# ============================================================================

test_that("sisab_valid_levels has expected values", {
  expect_type(sisab_valid_levels, "character")
  expect_equal(length(sisab_valid_levels), 4)
  expect_true("brazil" %in% names(sisab_valid_levels))
  expect_true("region" %in% names(sisab_valid_levels))
  expect_true("uf" %in% names(sisab_valid_levels))
  expect_true("municipality" %in% names(sisab_valid_levels))
  expect_equal(sisab_valid_levels[["brazil"]], "BRASIL")
  expect_equal(sisab_valid_levels[["municipality"]], "MUNICIPIO")
})

# ============================================================================
# .sisab_validate_year
# ============================================================================

test_that(".sisab_validate_year accepts valid years", {
  expect_equal(.sisab_validate_year(2024), 2024L)
  expect_equal(.sisab_validate_year(c(2023, 2024)), c(2023L, 2024L))
})

test_that(".sisab_validate_year errors on invalid years", {
  expect_error(.sisab_validate_year(1900), "not available")
})

test_that(".sisab_validate_year errors on NULL", {
  expect_error(.sisab_validate_year(NULL), "required")
})

# ============================================================================
# .sisab_validate_type
# ============================================================================

test_that(".sisab_validate_type accepts valid types", {
  expect_equal(.sisab_validate_type("aps"), "aps")
  expect_equal(.sisab_validate_type("sb"), "sb")
  expect_equal(.sisab_validate_type("acs"), "acs")
  expect_equal(.sisab_validate_type("pns"), "pns")
})

test_that(".sisab_validate_type is case insensitive", {
  expect_equal(.sisab_validate_type("APS"), "aps")
  expect_equal(.sisab_validate_type("Sb"), "sb")
})

test_that(".sisab_validate_type errors on invalid type", {
  expect_error(.sisab_validate_type("invalid"), "Invalid")
})

# ============================================================================
# .sisab_validate_level
# ============================================================================

test_that(".sisab_validate_level accepts valid levels", {
  expect_equal(.sisab_validate_level("brazil"), "brazil")
  expect_equal(.sisab_validate_level("uf"), "uf")
  expect_equal(.sisab_validate_level("municipality"), "municipality")
})

test_that(".sisab_validate_level is case insensitive", {
  expect_equal(.sisab_validate_level("BRAZIL"), "brazil")
  expect_equal(.sisab_validate_level("UF"), "uf")
})

test_that(".sisab_validate_level errors on invalid level", {
  expect_error(.sisab_validate_level("invalid"), "Invalid")
})

# ============================================================================
# .validate_month
# ============================================================================

test_that(".validate_month accepts valid months", {
  expect_equal(.validate_month(1), 1L)
  expect_equal(.validate_month(c(1, 6, 12)), c(1L, 6L, 12L))
})

test_that(".validate_month returns 1:12 for NULL", {
  expect_equal(.validate_month(NULL), 1L:12L)
})

test_that(".validate_month errors on invalid months", {
  expect_error(.validate_month(0), "Invalid")
  expect_error(.validate_month(13), "Invalid")
})

# ============================================================================
# .sisab_validate_uf
# ============================================================================

test_that(".sisab_validate_uf accepts valid UFs", {
  expect_equal(.sisab_validate_uf("SP"), "SP")
  expect_equal(.sisab_validate_uf("sp"), "SP")
  expect_equal(.sisab_validate_uf(c("SP", "RJ")), c("SP", "RJ"))
})

test_that(".sisab_validate_uf errors on invalid UFs", {
  expect_error(.sisab_validate_uf("XX"), "Invalid")
})

# ============================================================================
# .sisab_validate_vars
# ============================================================================

test_that(".sisab_validate_vars silent on valid vars", {
  expect_no_warning(.sisab_validate_vars("qtPopulacao", type = "aps"))
  expect_no_warning(.sisab_validate_vars("qtCobertura", type = "aps"))
})

test_that(".sisab_validate_vars warns on unknown vars", {
  expect_warning(
    .sisab_validate_vars("NONEXISTENT_VAR", type = "aps"),
    "not in known"
  )
})

# ============================================================================
# sisab_uf_map
# ============================================================================

test_that("sisab_uf_map has all 27 UFs", {
  expect_equal(length(sisab_uf_map), 27)
  expect_true("SP" %in% names(sisab_uf_map))
  expect_equal(sisab_uf_map[["SP"]], "35")
  expect_equal(sisab_uf_map[["AC"]], "12")
})

# ============================================================================
# .sisab_build_url
# ============================================================================

test_that(".sisab_build_url returns expected URLs", {
  url_aps <- .sisab_build_url("aps")
  expect_true(grepl("relatorioaps-prd.saude.gov.br/cobertura/aps", url_aps))

  url_sb <- .sisab_build_url("sb")
  expect_true(grepl("relatorioaps-prd.saude.gov.br/cobertura/sb/v2", url_sb))
})

# ============================================================================
# cache functions
# ============================================================================

test_that("sisab_cache_status works with empty cache", {
  temp_dir <- tempfile("sisab_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  result <- sisab_cache_status(cache_dir = temp_dir)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("sisab_cache_status detects cached files", {
  temp_dir <- tempfile("sisab_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  saveRDS(data.frame(x = 1), file.path(temp_dir, "sisab_aps_uf_ALL_2024_full.rds"))

  result <- sisab_cache_status(cache_dir = temp_dir)
  expect_equal(nrow(result), 1)
  expect_true("file" %in% names(result))
  expect_true("size_mb" %in% names(result))
})

test_that("sisab_clear_cache removes cached files", {
  temp_dir <- tempfile("sisab_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  saveRDS(data.frame(x = 1), file.path(temp_dir, "sisab_aps_uf_ALL_2024_full.rds"))
  sisab_clear_cache(cache_dir = temp_dir)

  files <- list.files(temp_dir, pattern = "^sisab_")
  expect_equal(length(files), 0)
})

test_that("sisab_clear_cache handles empty cache gracefully", {
  temp_dir <- tempfile("sisab_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  expect_no_error(sisab_clear_cache(cache_dir = temp_dir))
})

test_that(".sisab_cache_dir creates directory", {
  temp_dir <- tempfile("sisab_cache_test")
  on.exit(unlink(temp_dir, recursive = TRUE))

  result <- .sisab_cache_dir(temp_dir)
  expect_true(dir.exists(result))
  expect_equal(result, temp_dir)
})

# ============================================================================
# .sisab_get_variables_meta
# ============================================================================

test_that(".sisab_get_variables_meta returns correct metadata for each type", {
  aps <- .sisab_get_variables_meta("aps")
  expect_s3_class(aps, "tbl_df")
  expect_true("qtCobertura" %in% aps$variable)

  sb <- .sisab_get_variables_meta("sb")
  expect_true("pcCoberturaSbAps" %in% sb$variable)

  acs <- .sisab_get_variables_meta("acs")
  expect_true("pcCoberturaAcsAb" %in% acs$variable)

  pns <- .sisab_get_variables_meta("pns")
  expect_true("vlCobertura" %in% pns$variable)
})

# ============================================================================
# integration tests
# ============================================================================

test_that("sisab_data downloads APS coverage data for UF level", {
  skip_if_no_integration()

  data <- sisab_data(year = 2024, type = "aps", level = "uf",
                     month = 1, cache_dir = tempdir())
  expect_s3_class(data, "tbl_df")
  expect_gt(nrow(data), 0)
  expect_true("year" %in% names(data))
  expect_true("type" %in% names(data))
  expect_true("qtCobertura" %in% names(data))
  expect_equal(unique(data$year), 2024L)
  expect_equal(unique(data$type), "aps")
  # 27 UFs expected
  expect_equal(nrow(data), 27)
})

test_that("sisab_data downloads APS coverage data for BRASIL level", {
  skip_if_no_integration()

  data <- sisab_data(year = 2024, type = "aps", level = "brazil",
                     month = 1, cache_dir = tempdir())
  expect_s3_class(data, "tbl_df")
  expect_equal(nrow(data), 1)
  expect_true("qtCobertura" %in% names(data))
})

test_that("sisab_data variable selection works", {
  skip_if_no_integration()

  data <- sisab_data(year = 2024, type = "aps", level = "brazil",
                     month = 1, vars = c("qtPopulacao", "qtCobertura"),
                     cache_dir = tempdir())
  expect_true("qtPopulacao" %in% names(data))
  expect_true("qtCobertura" %in% names(data))
  expect_true("year" %in% names(data))
  expect_true("type" %in% names(data))
})

test_that("sisab_data cache works (second call faster)", {
  skip_if_no_integration()

  cache_dir <- tempfile("sisab_cache_test")
  dir.create(cache_dir, recursive = TRUE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  t1 <- system.time(sisab_data(year = 2024, type = "aps", level = "brazil",
                                month = 1, cache_dir = cache_dir))
  t2 <- system.time(sisab_data(year = 2024, type = "aps", level = "brazil",
                                month = 1, cache_dir = cache_dir))
  expect_lt(t2["elapsed"], t1["elapsed"])
})


# ============================================================================
# consolidated download failure reporting
# ============================================================================

test_that("sisab_data reports partial download failures", {
  local_mocked_bindings(
    .sisab_validate_year = function(year) as.integer(year),
    .sisab_download_and_read = function(year, ...) {
      if (year == 9999L) return(NULL)
      tibble::tibble(cobertura = 0.5)
    }
  )
  result <- suppressWarnings(
    sisab_data(c(2024, 9999))
  )
  expect_s3_class(result, "data.frame")
  failures <- attr(result, "download_failures")
  expect_false(is.null(failures))
  expect_true(any(grepl("9999", failures)))
})


# ============================================================================
# ADDITIONAL COVERAGE TESTS
# ============================================================================

# --- sisab_info --- additional coverage ---

test_that("sisab_info returns invisible result", {
  result <- sisab_info()
  expect_type(result, "list")
  expect_equal(result$source, "API REST relatorioaps")
  expect_equal(result$n_types, 4)
  expect_true(result$n_variables_aps > 0)
})

# --- .sisab_resolve_params --- test param resolution ---

test_that(".sisab_resolve_params resolves defaults correctly", {
  params <- .sisab_resolve_params(2024, "aps", "uf", NULL, NULL, NULL)

  expect_equal(params$year, 2024L)
  expect_equal(params$type, "aps")
  expect_equal(params$level, "uf")
  expect_equal(params$month, 1L:12L)
  expect_null(params$uf)
  expect_equal(params$target_ufs, list(NULL))
})

test_that(".sisab_resolve_params with specific month", {
  params <- .sisab_resolve_params(2024, "aps", "uf", 3, NULL, NULL)
  expect_equal(params$month, 3L)
})

test_that(".sisab_resolve_params with uf at uf level", {
  params <- .sisab_resolve_params(2024, "aps", "uf", 1, "SP", NULL)
  expect_equal(params$uf, "SP")
  expect_equal(params$target_ufs, list("SP"))
})

test_that(".sisab_resolve_params with multiple UFs", {
  params <- .sisab_resolve_params(2024, "aps", "uf", 1, c("SP", "RJ"), NULL)
  expect_equal(params$uf, c("SP", "RJ"))
  expect_equal(params$target_ufs, list("SP", "RJ"))
})

test_that(".sisab_resolve_params with uf at municipality level", {
  params <- .sisab_resolve_params(2024, "aps", "municipality", 1, "SP", NULL)
  expect_equal(params$target_ufs, list("SP"))
})

test_that(".sisab_resolve_params with uf at brazil level ignores uf filter", {
  params <- .sisab_resolve_params(2024, "aps", "brazil", 1, "SP", NULL)
  # at brazil level, target_ufs should be list(NULL)
  expect_equal(params$target_ufs, list(NULL))
})

test_that(".sisab_resolve_params warns for municipality without uf filter", {
  expect_warning(
    .sisab_resolve_params(2024, "aps", "municipality", NULL, NULL, NULL),
    "may be slow"
  )
})

test_that(".sisab_resolve_params municipality with uf no warning for few months", {
  # With uf specified, no warning even with all 12 months
  expect_no_warning(
    .sisab_resolve_params(2024, "aps", "municipality", NULL, "SP", NULL)
  )
})

test_that(".sisab_resolve_params municipality no uf but few months no warning", {
  # <= 3 months should not trigger warning
  expect_no_warning(
    .sisab_resolve_params(2024, "aps", "municipality", c(1, 2, 3), NULL, NULL)
  )
})

test_that(".sisab_resolve_params validates vars with warning", {
  expect_warning(
    .sisab_resolve_params(2024, "aps", "uf", 1, NULL, "NONEXISTENT"),
    "not in known"
  )
})

test_that(".sisab_resolve_params accepts valid vars silently", {
  expect_no_warning(
    .sisab_resolve_params(2024, "aps", "uf", 1, NULL, "qtPopulacao")
  )
})

test_that(".sisab_resolve_params validates multiple years", {
  params <- .sisab_resolve_params(c(2023, 2024), "aps", "uf", 1, NULL, NULL)
  expect_equal(params$year, c(2023L, 2024L))
})

# --- .sisab_download_loop --- mocked tests ---

test_that(".sisab_download_loop binds results from multiple years", {
  local_mocked_bindings(
    .sisab_download_and_read = function(year, months, type, level, uf, ...) {
      tibble::tibble(
        qtCobertura = runif(1),
        nuComp = sprintf("%04d%02d", year, min(months))
      )
    }
  )

  result <- .sisab_download_loop(
    year = c(2023L, 2024L), type = "aps", level = "uf",
    month = 1L, target_ufs = list(NULL), cache = FALSE, cache_dir = NULL
  )

  expect_true(is.list(result))
  expect_s3_class(result$data, "data.frame")
  expect_equal(nrow(result$data), 2)
  expect_true("year" %in% names(result$data))
  expect_true("type" %in% names(result$data))
  expect_equal(sort(unique(result$data$year)), c(2023L, 2024L))
  expect_equal(length(result$failed_labels), 0)
})

test_that(".sisab_download_loop tracks failures", {
  local_mocked_bindings(
    .sisab_download_and_read = function(year, months, type, level, uf, ...) {
      if (year == 9999L) stop("API error")
      tibble::tibble(qtCobertura = 0.5)
    }
  )

  result <- .sisab_download_loop(
    year = c(2024L, 9999L), type = "aps", level = "uf",
    month = 1L, target_ufs = list(NULL), cache = FALSE, cache_dir = NULL
  )

  expect_equal(nrow(result$data), 1)
  expect_equal(length(result$failed_labels), 1)
  expect_true(grepl("9999", result$failed_labels))
})

test_that(".sisab_download_loop aborts when all downloads fail", {
  local_mocked_bindings(
    .sisab_download_and_read = function(year, ...) stop("API error")
  )

  expect_error(
    .sisab_download_loop(
      year = 2024L, type = "aps", level = "uf",
      month = 1L, target_ufs = list(NULL), cache = FALSE, cache_dir = NULL
    ),
    "No data could be downloaded"
  )
})

test_that(".sisab_download_loop with multiple UFs", {
  local_mocked_bindings(
    .sisab_download_and_read = function(year, months, type, level, uf, ...) {
      tibble::tibble(qtCobertura = runif(1), sgUf = ifelse(is.null(uf), "ALL", uf))
    }
  )

  result <- .sisab_download_loop(
    year = 2024L, type = "aps", level = "uf",
    month = 1L, target_ufs = list("SP", "RJ"),
    cache = FALSE, cache_dir = NULL
  )

  expect_equal(nrow(result$data), 2)
  expect_equal(length(result$failed_labels), 0)
})

test_that(".sisab_download_loop skips NULL results", {
  local_mocked_bindings(
    .sisab_download_and_read = function(year, months, type, level, uf, ...) {
      if (!is.null(uf) && uf == "RJ") return(NULL)
      tibble::tibble(qtCobertura = 0.5)
    }
  )

  result <- .sisab_download_loop(
    year = 2024L, type = "aps", level = "uf",
    month = 1L, target_ufs = list("SP", "RJ"),
    cache = FALSE, cache_dir = NULL
  )

  expect_equal(nrow(result$data), 1)
  expect_equal(length(result$failed_labels), 1)
})

# --- .sisab_build_url --- additional coverage ---

test_that(".sisab_build_url returns correct URL for acs", {
  url_acs <- .sisab_build_url("acs")
  expect_true(grepl("relatorioaps-prd.saude.gov.br/cobertura/acs", url_acs))
})

test_that(".sisab_build_url returns correct URL for pns", {
  url_pns <- .sisab_build_url("pns")
  expect_true(grepl("relatorioaps-prd.saude.gov.br/cobertura/pns", url_pns))
})

# --- .sisab_validate_type --- additional coverage ---

test_that(".sisab_validate_type error message mentions valid types", {
  expect_error(.sisab_validate_type("xyz"), "aps")
})

# --- .sisab_validate_level --- additional coverage ---

test_that(".sisab_validate_level accepts region level", {
  expect_equal(.sisab_validate_level("region"), "region")
  expect_equal(.sisab_validate_level("Region"), "region")
})

# --- .sisab_validate_year --- additional coverage ---

test_that(".sisab_validate_year rejects future years", {
  far_future <- as.integer(format(Sys.Date(), "%Y")) + 5L
  expect_error(.sisab_validate_year(far_future), "not available")
})

test_that(".sisab_validate_year rejects NA", {
  expect_error(.sisab_validate_year(NA), "not available")
})

test_that(".sisab_validate_year rejects zero-length input", {
  expect_error(.sisab_validate_year(integer(0)), "required")
})

# --- .sisab_get_variables_meta --- additional coverage ---

test_that(".sisab_get_variables_meta defaults to aps for unknown type", {
  # The switch fallback returns sisab_variables_aps for unknown types
  result <- .sisab_get_variables_meta("unknown_type")
  expect_s3_class(result, "tbl_df")
  expect_true("qtCobertura" %in% result$variable)
})

# --- sisab_data --- mocked end-to-end ---

test_that("sisab_data with vars selects columns", {
  local_mocked_bindings(
    .sisab_download_and_read = function(year, months, type, level, uf, ...) {
      tibble::tibble(
        qtPopulacao = "100000",
        qtCobertura = "0.85",
        qtEsf = "10",
        nuComp = "202401"
      )
    }
  )

  result <- sisab_data(2024, month = 1, vars = c("qtPopulacao", "qtCobertura"))
  expect_true("qtPopulacao" %in% names(result))
  expect_true("qtCobertura" %in% names(result))
  expect_true("year" %in% names(result))
  expect_true("type" %in% names(result))
})

test_that("sisab_data type parameter works with different types", {
  local_mocked_bindings(
    .sisab_download_and_read = function(year, months, type, level, uf, ...) {
      tibble::tibble(
        pcCoberturaSbAps = "0.5",
        nuComp = "202401"
      )
    }
  )

  result <- sisab_data(2024, type = "sb", month = 1)
  expect_s3_class(result, "tbl_df")
  expect_equal(unique(result$type), "sb")
})
