# tests for SINAN module functions

# ============================================================================
# sinan_years
# ============================================================================

test_that("sinan_years returns integer vector", {
  years <- sinan_years()
  expect_type(years, "integer")
  expect_gt(length(years), 0)
  expect_true(2022L %in% years)
  expect_true(2007L %in% years)
})

test_that("sinan_years filters by status", {
  final <- sinan_years("final")
  prelim <- sinan_years("preliminary")
  all_years <- sinan_years("all")

  expect_true(length(all_years) > length(final))
  expect_true(length(all_years) == length(final) + length(prelim))
  expect_true(all(final %in% all_years))
  expect_true(all(prelim %in% all_years))
})

test_that("sinan_years errors on invalid status", {
  expect_error(sinan_years("invalid"))
})

test_that("sinan_years default is final", {
  expect_equal(sinan_years(), sinan_years("final"))
})

# ============================================================================
# sinan_info
# ============================================================================

test_that("sinan_info returns expected structure", {
  info <- sinan_info()

  expect_type(info, "list")
  expect_true("name" %in% names(info))
  expect_true("source" %in% names(info))
  expect_true("final_years" %in% names(info))
  expect_true("preliminary_years" %in% names(info))
  expect_true("n_diseases" %in% names(info))
  expect_true("n_variables" %in% names(info))
})

# ============================================================================
# sinan_diseases
# ============================================================================

test_that("sinan_diseases returns tibble with expected columns", {
  diseases <- sinan_diseases()
  expect_s3_class(diseases, "tbl_df")
  expect_true(all(c("code", "name", "description") %in% names(diseases)))
  expect_gt(nrow(diseases), 0)
  expect_true("DENG" %in% diseases$code)
  expect_true("TUBE" %in% diseases$code)
})

test_that("sinan_diseases search works", {
  dengue <- sinan_diseases(search = "dengue")
  expect_gt(nrow(dengue), 0)
  expect_true("DENG" %in% dengue$code)
})

test_that("sinan_diseases search returns empty tibble for no match", {
  result <- sinan_diseases(search = "zzzznonexistent")
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

# ============================================================================
# sinan_variables
# ============================================================================

test_that("sinan_variables returns tibble with expected columns", {
  vars <- sinan_variables()
  expect_s3_class(vars, "tbl_df")
  expect_true(all(c("variable", "description", "type", "section") %in% names(vars)))
  expect_gt(nrow(vars), 0)
  expect_true("CS_SEXO" %in% vars$variable)
  expect_true("DT_NOTIFIC" %in% vars$variable)
  expect_true("CLASSI_FIN" %in% vars$variable)
})

test_that("sinan_variables has expected key variables", {
  vars <- sinan_variables()
  key_vars <- c("DT_NOTIFIC", "ID_AGRAVO", "CS_SEXO", "CS_RACA",
                "NU_IDADE_N", "ID_MUNICIP", "CLASSI_FIN", "EVOLUCAO")
  expect_true(all(key_vars %in% vars$variable))
})

test_that("sinan_variables search works", {
  sexo_vars <- sinan_variables(search = "sexo")
  expect_gt(nrow(sexo_vars), 0)
})

test_that("sinan_variables search is accent-insensitive", {
  # "notificacao" should match "notificação"
  result <- sinan_variables(search = "notificacao")
  expect_gt(nrow(result), 0)
})

test_that("sinan_variables search returns empty tibble for no match", {
  result <- sinan_variables(search = "zzzznonexistent")
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("sinan_variables has expected sections", {
  vars <- sinan_variables()
  expected_sections <- c("notificacao", "paciente", "residencia",
                         "investigacao", "temporal")
  expect_true(all(expected_sections %in% vars$section))
})

# ============================================================================
# sinan_dictionary
# ============================================================================

test_that("sinan_dictionary returns tibble with expected columns", {
  dict <- sinan_dictionary()
  expect_s3_class(dict, "tbl_df")
  expect_true(all(c("variable", "description", "code", "label") %in% names(dict)))
  expect_gt(nrow(dict), 0)
})

test_that("sinan_dictionary filters by variable", {
  sexo <- sinan_dictionary("CS_SEXO")
  expect_true(all(sexo$variable == "CS_SEXO"))
  expect_true("Masculino" %in% sexo$label)
  expect_true("Feminino" %in% sexo$label)
})

test_that("sinan_dictionary case insensitive", {
  sexo_lower <- sinan_dictionary("cs_sexo")
  sexo_upper <- sinan_dictionary("CS_SEXO")
  expect_equal(nrow(sexo_lower), nrow(sexo_upper))
})

test_that("sinan_dictionary warns on unknown variable", {
  expect_warning(sinan_dictionary("NONEXISTENT"), "not found")
})

test_that("sinan_dictionary has key variables", {
  dict <- sinan_dictionary()
  expect_true("CS_SEXO" %in% dict$variable)
  expect_true("CS_RACA" %in% dict$variable)
  expect_true("EVOLUCAO" %in% dict$variable)
  expect_true("CLASSI_FIN" %in% dict$variable)
})

test_that("sinan_dictionary SEXO has correct codes", {
  sexo <- sinan_dictionary("CS_SEXO")
  expect_true("M" %in% sexo$code)
  expect_true("F" %in% sexo$code)
  expect_true("I" %in% sexo$code)
})

test_that("sinan_dictionary EVOLUCAO has correct codes", {
  evol <- sinan_dictionary("EVOLUCAO")
  expect_true("1" %in% evol$code)
  expect_true("2" %in% evol$code)
  expect_true("Cura" %in% evol$label)
})

# ============================================================================
# .sinan_build_ftp_url
# ============================================================================

test_that(".sinan_build_ftp_url constructs correct final URLs", {
  url <- .sinan_build_ftp_url(2022, "DENG")
  expect_match(url, "FINAIS/DENGBR22\\.dbc$")
  expect_match(url, "^ftp://ftp\\.datasus\\.gov\\.br/")
})

test_that(".sinan_build_ftp_url constructs correct preliminary URLs", {
  url <- .sinan_build_ftp_url(2023, "DENG")
  expect_match(url, "PRELIM/DENGBR23\\.dbc$")
})

test_that(".sinan_build_ftp_url works with different diseases", {
  url_tube <- .sinan_build_ftp_url(2020, "TUBE")
  expect_match(url_tube, "FINAIS/TUBEBR20\\.dbc$")

  url_hans <- .sinan_build_ftp_url(2015, "HANS")
  expect_match(url_hans, "FINAIS/HANSBR15\\.dbc$")

  url_chik <- .sinan_build_ftp_url(2022, "CHIK")
  expect_match(url_chik, "FINAIS/CHIKBR22\\.dbc$")
})

test_that(".sinan_build_ftp_url errors on pre-2007 years", {
  expect_error(.sinan_build_ftp_url(2006, "DENG"), "not supported")
  expect_error(.sinan_build_ftp_url(2000, "TUBE"), "not supported")
})

# ============================================================================
# .sinan_validate_disease
# ============================================================================

test_that(".sinan_validate_disease accepts valid codes", {
  expect_equal(.sinan_validate_disease("DENG"), "DENG")
  expect_equal(.sinan_validate_disease("TUBE"), "TUBE")
  expect_equal(.sinan_validate_disease("HANS"), "HANS")
})

test_that(".sinan_validate_disease is case insensitive", {
  expect_equal(.sinan_validate_disease("deng"), "DENG")
  expect_equal(.sinan_validate_disease("tube"), "TUBE")
  expect_equal(.sinan_validate_disease("Chik"), "CHIK")
})

test_that(".sinan_validate_disease errors on invalid code", {
  expect_error(.sinan_validate_disease("INVALID"), "Invalid")
  expect_error(.sinan_validate_disease("XYZ"), "Invalid")
})

test_that(".sinan_validate_disease accepts all valid codes", {
  for (code in sinan_valid_diseases$code) {
    expect_equal(.sinan_validate_disease(code), code)
  }
})

# ============================================================================
# .sinan_validate_year
# ============================================================================

test_that(".sinan_validate_year accepts valid years", {
  expect_equal(.sinan_validate_year(2022), 2022L)
  expect_equal(.sinan_validate_year(c(2020, 2021)), c(2020L, 2021L))
})

test_that(".sinan_validate_year errors on invalid years", {
  expect_error(.sinan_validate_year(2000), "not available")
  expect_error(.sinan_validate_year(2050), "not available")
})

test_that(".sinan_validate_year errors on NULL", {
  expect_error(.sinan_validate_year(NULL), "required")
})

# ============================================================================
# .sinan_validate_vars
# ============================================================================

test_that(".sinan_validate_vars passes silently for valid vars", {
  expect_no_warning(.sinan_validate_vars(c("CS_SEXO", "DT_NOTIFIC")))
})

test_that(".sinan_validate_vars warns on unknown vars", {
  expect_warning(
    .sinan_validate_vars(c("CS_SEXO", "UNKNOWN_VAR")),
    "not in known"
  )
})

# ============================================================================
# sinan_valid_diseases metadata
# ============================================================================

test_that("sinan_valid_diseases has expected structure", {
  expect_s3_class(sinan_valid_diseases, "tbl_df")
  expect_true(all(c("code", "name", "description") %in% names(sinan_valid_diseases)))
  expect_gt(nrow(sinan_valid_diseases), 20)
  expect_true("DENG" %in% sinan_valid_diseases$code)
  expect_true("TUBE" %in% sinan_valid_diseases$code)
  expect_true("ZIKA" %in% sinan_valid_diseases$code)
})

# ============================================================================
# sinan_label_maps
# ============================================================================

test_that("sinan_label_maps has expected variables", {
  expect_type(sinan_label_maps, "list")
  expect_true("CS_SEXO" %in% names(sinan_label_maps))
  expect_true("CS_RACA" %in% names(sinan_label_maps))
  expect_true("EVOLUCAO" %in% names(sinan_label_maps))
  expect_true("CLASSI_FIN" %in% names(sinan_label_maps))

  # check CS_SEXO values
  expect_equal(
    sinan_label_maps$CS_SEXO[["M"]],
    "Masculino"
  )
})

# ============================================================================
# sinan_cache functions
# ============================================================================

test_that("sinan_cache_status works with empty cache", {
  temp_dir <- tempfile("sinan_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  result <- sinan_cache_status(cache_dir = temp_dir)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("sinan_clear_cache works with empty cache", {
  temp_dir <- tempfile("sinan_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  expect_no_error(sinan_clear_cache(cache_dir = temp_dir))
})

test_that("sinan_cache_status detects cached files", {
  temp_dir <- tempfile("sinan_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  # create fake cache file
  saveRDS(data.frame(x = 1), file.path(temp_dir, "sinan_DENG_2022.rds"))

  result <- sinan_cache_status(cache_dir = temp_dir)
  expect_equal(nrow(result), 1)
  expect_true(grepl("sinan_DENG_2022", result$file))
})

test_that("sinan_clear_cache removes cached files", {
  temp_dir <- tempfile("sinan_cache_test")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))

  # create fake cache files
  saveRDS(data.frame(x = 1), file.path(temp_dir, "sinan_DENG_2022.rds"))
  saveRDS(data.frame(x = 2), file.path(temp_dir, "sinan_TUBE_2020.rds"))

  sinan_clear_cache(cache_dir = temp_dir)

  files <- list.files(temp_dir, pattern = "^sinan_.*\\.rds$")
  expect_equal(length(files), 0)
})

test_that(".sinan_cache_dir creates directory if needed", {
  temp_dir <- file.path(tempdir(), "sinan_cache_test_create")
  on.exit(unlink(temp_dir, recursive = TRUE))

  result <- .sinan_cache_dir(temp_dir)
  expect_true(dir.exists(result))
  expect_equal(result, temp_dir)
})

# ============================================================================
# integration tests (require internet + HEALTHBR_INTEGRATION=true)
# ============================================================================

test_that("sinan_data downloads and reads data from FTP", {
  skip_if_no_integration()

  data <- sinan_data(year = 2022, disease = "DENG",
                     cache_dir = tempdir())
  expect_s3_class(data, "tbl_df")
  expect_gt(nrow(data), 0)
  expect_true("DT_NOTIFIC" %in% names(data))
  expect_true("CS_SEXO" %in% names(data))
  expect_true("year" %in% names(data))
  expect_true("disease" %in% names(data))
  expect_equal(unique(data$year), 2022L)
  expect_equal(unique(data$disease), "DENG")
})

test_that("sinan_data selects variables", {
  skip_if_no_integration()

  data <- sinan_data(year = 2022, disease = "DENG",
                     vars = c("DT_NOTIFIC", "CS_SEXO", "ID_MUNICIP"),
                     cache_dir = tempdir())
  # should have year, disease, requested vars
  expect_true("DT_NOTIFIC" %in% names(data))
  expect_true("CS_SEXO" %in% names(data))
  expect_true("ID_MUNICIP" %in% names(data))
  expect_true("year" %in% names(data))
  expect_true("disease" %in% names(data))
})

test_that("sinan_data works with different disease", {
  skip_if_no_integration()

  data <- sinan_data(year = 2022, disease = "TUBE",
                     cache_dir = tempdir())
  expect_s3_class(data, "tbl_df")
  expect_gt(nrow(data), 0)
  expect_equal(unique(data$disease), "TUBE")
})

test_that("sinan_data cache works (second call faster)", {
  skip_if_no_integration()

  cache_dir <- tempfile("sinan_cache_test")
  dir.create(cache_dir, recursive = TRUE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  t1 <- system.time(sinan_data(year = 2022, disease = "DENG",
                                cache_dir = cache_dir))
  t2 <- system.time(sinan_data(year = 2022, disease = "DENG",
                                cache_dir = cache_dir))
  expect_lt(t2["elapsed"], t1["elapsed"])
})

# ============================================================================
# smart type parsing
# ============================================================================

test_that("sinan_variables type column has non-character types", {
  vars <- sinan_variables()
  types <- unique(vars$type)
  expect_true("date_dmy" %in% types)
  expect_true("integer" %in% types)
  expect_equal(vars$type[vars$variable == "DT_NOTIFIC"], "date_dmy")
  expect_equal(vars$type[vars$variable == "NU_ANO"], "integer")
  expect_equal(vars$type[vars$variable == "CS_SEXO"], "character")
})

test_that("sinan parse converts mock data correctly", {
  mock_data <- tibble::tibble(
    year = 2022L, disease = "DENG",
    DT_NOTIFIC = "15012022", NU_ANO = "2022",
    CS_SEXO = "M", NU_IDADE_N = "4025"
  )
  spec <- .build_type_spec(sinan_variables_metadata)
  parsed <- .parse_columns(mock_data, spec)

  expect_s3_class(parsed$DT_NOTIFIC, "Date")
  expect_type(parsed$NU_ANO, "integer")
  expect_type(parsed$CS_SEXO, "character")
  expect_type(parsed$NU_IDADE_N, "character")
})


# ============================================================================
# consolidated download failure reporting
# ============================================================================

test_that("sinan_data reports partial download failures", {
  local_mocked_bindings(
    .sinan_validate_year = function(year, ...) as.integer(year),
    .sinan_download_and_read = function(year, disease, ...) {
      if (year == 9999L) stop("Not found")
      tibble::tibble(year = as.integer(year), disease = disease,
                     DT_NOTIFIC = "01012022")
    }
  )
  result <- suppressWarnings(
    sinan_data(c(2022, 9999), parse = FALSE)
  )
  expect_s3_class(result, "data.frame")
  failures <- attr(result, "download_failures")
  expect_false(is.null(failures))
  expect_equal(failures, "DENG 9999")
})
