# Tests for ANS module (Agencia Nacional de Saude Suplementar)

# ============================================================================
# helper: skip integration tests
# ============================================================================

skip_if_no_integration <- function() {
  if (identical(Sys.getenv("HEALTHBR_INTEGRATION"), "true")) return(invisible())
  skip("Integration tests skipped. Set HEALTHBR_INTEGRATION=true to run.")
}

# ============================================================================
# constants
# ============================================================================

test_that("ans_base_url is correct", {
  expect_equal(ans_base_url, "https://dadosabertos.ans.gov.br/FTP/PDA")
})

test_that("ans_available_years has all three types", {
  expect_true("beneficiaries" %in% names(ans_available_years))
  expect_true("complaints" %in% names(ans_available_years))
  expect_true("financial" %in% names(ans_available_years))
})

test_that("ans_available_years beneficiaries start at 2019", {
  expect_equal(min(ans_available_years$beneficiaries), 2019L)
})

test_that("ans_available_years complaints start at 2011", {
  expect_equal(min(ans_available_years$complaints), 2011L)
})

test_that("ans_available_years financial start at 2007", {
  expect_equal(min(ans_available_years$financial), 2007L)
})

test_that("ans_valid_types has 3 types", {
  expect_equal(nrow(ans_valid_types), 3)
  expect_equal(ans_valid_types$code,
               c("beneficiaries", "complaints", "financial"))
})

test_that("ans_uf_list has 27 states", {
  expect_equal(length(ans_uf_list), 27)
  expect_true("SP" %in% ans_uf_list)
  expect_true("AC" %in% ans_uf_list)
})

test_that("ans_uf_list_xx has 28 entries", {
  expect_equal(length(ans_uf_list_xx), 28)
  expect_true("XX" %in% ans_uf_list_xx)
})


# ============================================================================
# variable metadata
# ============================================================================

test_that("ans_beneficiaries_metadata has 22 variables", {
  expect_equal(nrow(ans_beneficiaries_metadata), 22)
  expect_true("ID_CMPT_MOVEL" %in% ans_beneficiaries_metadata$variable)
  expect_true("QT_BENEFICIARIO_ATIVO" %in% ans_beneficiaries_metadata$variable)
})

test_that("ans_complaints_metadata has 27 variables", {
  expect_equal(nrow(ans_complaints_metadata), 27)
  expect_true("NUMERO_DA_DEMANDA" %in% ans_complaints_metadata$variable)
  expect_true("RESPOSTA_BENEFICIARIO" %in% ans_complaints_metadata$variable)
})

test_that("ans_financial_metadata has 6 variables", {
  expect_equal(nrow(ans_financial_metadata), 6)
  expect_true("DATA" %in% ans_financial_metadata$variable)
  expect_true("VL_SALDO_FINAL" %in% ans_financial_metadata$variable)
})

test_that("ans_operators_metadata has 20 variables", {
  expect_equal(nrow(ans_operators_metadata), 20)
  expect_true("REGISTRO_OPERADORA" %in% ans_operators_metadata$variable)
  expect_true("Data_Registro_ANS" %in% ans_operators_metadata$variable)
})

test_that("all metadata tibbles have required columns", {
  for (meta in list(ans_beneficiaries_metadata, ans_complaints_metadata,
                    ans_financial_metadata, ans_operators_metadata)) {
    expect_true(all(c("variable", "description", "type", "section") %in%
                      names(meta)))
  }
})

test_that("all metadata types are valid", {
  valid_types <- c("character", "integer", "double", "date_dmy",
                   "date_ymd", "date_ym", "date")
  for (meta in list(ans_beneficiaries_metadata, ans_complaints_metadata,
                    ans_financial_metadata, ans_operators_metadata)) {
    expect_true(all(meta$type %in% valid_types))
  }
})


# ============================================================================
# .ans_validate_type
# ============================================================================

test_that(".ans_validate_type accepts valid types", {
  expect_equal(.ans_validate_type("beneficiaries"), "beneficiaries")
  expect_equal(.ans_validate_type("complaints"), "complaints")
  expect_equal(.ans_validate_type("financial"), "financial")
})

test_that(".ans_validate_type is case insensitive", {
  expect_equal(.ans_validate_type("BENEFICIARIES"), "beneficiaries")
  expect_equal(.ans_validate_type("Complaints"), "complaints")
})

test_that(".ans_validate_type errors on invalid type", {
  expect_error(.ans_validate_type("invalid"), "Invalid")
  expect_error(.ans_validate_type("operators"), "Invalid")
})


# ============================================================================
# .ans_validate_year
# ============================================================================

test_that(".ans_validate_year accepts valid years per type", {
  expect_equal(.ans_validate_year(2023, "beneficiaries"), 2023L)
  expect_equal(.ans_validate_year(2015, "complaints"), 2015L)
  expect_equal(.ans_validate_year(2010, "financial"), 2010L)
})

test_that(".ans_validate_year errors on invalid years per type", {
  expect_error(.ans_validate_year(2018, "beneficiaries"), "not available")
  expect_error(.ans_validate_year(2010, "complaints"), "not available")
  expect_error(.ans_validate_year(2006, "financial"), "not available")
})

test_that(".ans_validate_year accepts multiple years", {
  expect_equal(.ans_validate_year(c(2022, 2023), "beneficiaries"),
               c(2022L, 2023L))
})


# ============================================================================
# .ans_validate_uf
# ============================================================================

test_that(".ans_validate_uf accepts standard UFs", {
  expect_equal(.ans_validate_uf("AC"), "AC")
  expect_equal(.ans_validate_uf("SP"), "SP")
})

test_that(".ans_validate_uf accepts XX", {
  expect_equal(.ans_validate_uf("XX"), "XX")
})

test_that(".ans_validate_uf is case insensitive", {
  expect_equal(.ans_validate_uf("ac"), "AC")
  expect_equal(.ans_validate_uf("xx"), "XX")
})

test_that(".ans_validate_uf errors on invalid UF", {
  expect_error(.ans_validate_uf("ZZ"), "Invalid")
})


# ============================================================================
# .ans_validate_month_beneficiaries
# ============================================================================

test_that(".ans_validate_month_beneficiaries returns 1:12 for NULL", {
  expect_equal(.ans_validate_month_beneficiaries(NULL, 2023), 1L:12L)
})

test_that(".ans_validate_month_beneficiaries accepts valid months for non-2019", {
  expect_equal(.ans_validate_month_beneficiaries(1, 2023), 1L)
  expect_equal(.ans_validate_month_beneficiaries(c(1, 6), 2023), c(1L, 6L))
})

test_that(".ans_validate_month_beneficiaries errors on Jan-Mar 2019", {
  expect_error(.ans_validate_month_beneficiaries(1, 2019), "not available")
  expect_error(.ans_validate_month_beneficiaries(3, 2019), "not available")
})

test_that(".ans_validate_month_beneficiaries accepts Apr+ 2019", {
  expect_equal(.ans_validate_month_beneficiaries(4, 2019), 4L)
  expect_equal(.ans_validate_month_beneficiaries(12, 2019), 12L)
})


# ============================================================================
# .ans_validate_vars
# ============================================================================

test_that(".ans_validate_vars warns on unknown variables", {
  expect_warning(
    .ans_validate_vars(c("CD_OPERADORA", "FAKE_VAR"), "beneficiaries"),
    "FAKE_VAR"
  )
})

test_that(".ans_validate_vars silent on valid variables", {
  expect_silent(.ans_validate_vars("CD_OPERADORA", "beneficiaries"))
  expect_silent(.ans_validate_vars("NUMERO_DA_DEMANDA", "complaints"))
  expect_silent(.ans_validate_vars("REG_ANS", "financial"))
})


# ============================================================================
# .ans_get_variables_meta
# ============================================================================

test_that(".ans_get_variables_meta returns correct metadata", {
  expect_identical(.ans_get_variables_meta("beneficiaries"),
                   ans_beneficiaries_metadata)
  expect_identical(.ans_get_variables_meta("complaints"),
                   ans_complaints_metadata)
  expect_identical(.ans_get_variables_meta("financial"),
                   ans_financial_metadata)
})


# ============================================================================
# URL builders
# ============================================================================

test_that(".ans_beneficiaries_url builds correct URL", {
  url <- .ans_beneficiaries_url(2023, 12, "AC")
  expect_true(grepl("informacoes_consolidadas_de_beneficiarios", url))
  expect_true(grepl("202312", url))
  expect_true(grepl("pda-024-icb-AC-2023_12.zip", url))
})

test_that(".ans_beneficiaries_url pads month", {
  url <- .ans_beneficiaries_url(2023, 1, "SP")
  expect_true(grepl("202301", url))
  expect_true(grepl("2023_01.zip", url))
})

test_that(".ans_complaints_url builds correct URL", {
  url <- .ans_complaints_url(2022)
  expect_true(grepl("demandas_dos_consumidores_nip", url))
  expect_true(grepl("pda-013-demandas_dos_consumidores_nip-2022.csv", url))
})

test_that(".ans_financial_url builds correct URL", {
  url <- .ans_financial_url(2023, 1)
  expect_true(grepl("demonstracoes_contabeis/2023", url))
  expect_true(grepl("1T2023.zip", url))
})

test_that(".ans_financial_url handles all quarters", {
  for (q in 1:4) {
    url <- .ans_financial_url(2023, q)
    expect_true(grepl(paste0(q, "T2023.zip"), url))
  }
})

test_that(".ans_operators_url builds correct URLs", {
  active <- .ans_operators_url("active")
  cancelled <- .ans_operators_url("cancelled")
  expect_true(grepl("operadoras_de_plano_de_saude_ativas", active))
  expect_true(grepl("Relatorio_cadop.csv", active))
  expect_true(grepl("operadoras_de_plano_de_saude_canceladas", cancelled))
  expect_true(grepl("Relatorio_cadop_canceladas.csv", cancelled))
})


# ============================================================================
# .ans_cache_dir
# ============================================================================

test_that(".ans_cache_dir creates directory", {
  d <- tempfile()
  result <- .ans_cache_dir(d)
  expect_true(dir.exists(result))
  unlink(d, recursive = TRUE)
})

test_that(".ans_cache_dir uses default when NULL", {
  result <- .ans_cache_dir(NULL)
  expect_true(grepl("ans", result))
})


# ============================================================================
# ans_years (exported)
# ============================================================================

test_that("ans_years returns correct years for beneficiaries", {
  years <- ans_years()
  expect_true(2019L %in% years)
  expect_true(2025L %in% years)
  expect_false(2018L %in% years)
})

test_that("ans_years returns correct years for complaints", {
  years <- ans_years(type = "complaints")
  expect_true(2011L %in% years)
  expect_true(2026L %in% years)
})

test_that("ans_years returns correct years for financial", {
  years <- ans_years(type = "financial")
  expect_true(2007L %in% years)
  expect_true(2025L %in% years)
})

test_that("ans_years errors on invalid type", {
  expect_error(ans_years(type = "invalid"), "Invalid")
})


# ============================================================================
# ans_info (exported)
# ============================================================================

test_that("ans_info returns invisible list", {
  result <- ans_info()
  expect_type(result, "list")
  expect_true("name" %in% names(result))
  expect_true("source" %in% names(result))
  expect_true("url" %in% names(result))
})

test_that("ans_info prints without error", {
  expect_no_error(invisible(capture.output(ans_info())))
})


# ============================================================================
# ans_variables (exported)
# ============================================================================

test_that("ans_variables returns beneficiaries by default", {
  vars <- ans_variables()
  expect_equal(nrow(vars), nrow(ans_beneficiaries_metadata))
})

test_that("ans_variables returns correct type", {
  vars_c <- ans_variables(type = "complaints")
  expect_equal(nrow(vars_c), nrow(ans_complaints_metadata))

  vars_f <- ans_variables(type = "financial")
  expect_equal(nrow(vars_f), nrow(ans_financial_metadata))

  vars_o <- ans_variables(type = "operators")
  expect_equal(nrow(vars_o), nrow(ans_operators_metadata))
})

test_that("ans_variables search works", {
  vars <- ans_variables(search = "operadora")
  expect_true(nrow(vars) > 0)
  expect_true(nrow(vars) < nrow(ans_beneficiaries_metadata))
})

test_that("ans_variables search is case insensitive", {
  vars1 <- ans_variables(search = "operadora")
  vars2 <- ans_variables(search = "OPERADORA")
  expect_equal(nrow(vars1), nrow(vars2))
})

test_that("ans_variables errors on invalid type", {
  expect_error(ans_variables(type = "invalid"), "Invalid")
})


# ============================================================================
# ans_data parameter warnings
# ============================================================================

test_that("ans_data warns about unused quarter for beneficiaries", {
  expect_warning(
    tryCatch(
      ans_data(year = 2023, type = "beneficiaries", quarter = 1,
               uf = "AC", month = 12, cache = FALSE),
      error = function(e) NULL
    ),
    "quarter.*ignored"
  )
})

test_that("ans_data warns about unused uf for complaints", {
  expect_warning(
    tryCatch(
      ans_data(year = 2022, type = "complaints", uf = "AC",
               cache = FALSE),
      error = function(e) NULL
    ),
    "uf.*ignored"
  )
})

test_that("ans_data warns about unused month for complaints", {
  expect_warning(
    tryCatch(
      ans_data(year = 2022, type = "complaints", month = 1,
               cache = FALSE),
      error = function(e) NULL
    ),
    "month.*ignored"
  )
})

test_that("ans_data warns about unused quarter for complaints", {
  expect_warning(
    tryCatch(
      ans_data(year = 2022, type = "complaints", quarter = 1,
               cache = FALSE),
      error = function(e) NULL
    ),
    "quarter.*ignored"
  )
})

test_that("ans_data warns about unused uf for financial", {
  expect_warning(
    tryCatch(
      ans_data(year = 2023, type = "financial", uf = "AC",
               cache = FALSE),
      error = function(e) NULL
    ),
    "uf.*ignored"
  )
})

test_that("ans_data warns about unused month for financial", {
  expect_warning(
    tryCatch(
      ans_data(year = 2023, type = "financial", month = 1,
               cache = FALSE),
      error = function(e) NULL
    ),
    "month.*ignored"
  )
})


# ============================================================================
# ans_data validation
# ============================================================================

test_that("ans_data errors on invalid type", {
  expect_error(ans_data(year = 2023, type = "invalid"), "Invalid")
})

test_that("ans_data errors on invalid year for beneficiaries", {
  expect_error(ans_data(year = 2018, type = "beneficiaries"), "not available")
})

test_that("ans_data errors on invalid year for complaints", {
  expect_error(
    suppressWarnings(ans_data(year = 2010, type = "complaints")),
    "not available"
  )
})

test_that("ans_data errors on invalid year for financial", {
  expect_error(
    suppressWarnings(ans_data(year = 2006, type = "financial")),
    "not available"
  )
})


# ============================================================================
# ans_operators validation
# ============================================================================

test_that("ans_operators errors on invalid status", {
  expect_error(ans_operators(status = "invalid"))
})


# ============================================================================
# ans_cache_status / ans_clear_cache
# ============================================================================

test_that("ans_cache_status works with empty cache", {
  d <- tempfile()
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE))
  result <- ans_cache_status(cache_dir = d)
  expect_equal(nrow(result), 0)
})

test_that("ans_clear_cache works with empty cache", {
  d <- tempfile()
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE))
  expect_no_error(ans_clear_cache(cache_dir = d))
})

test_that("ans_cache_status detects cached files", {
  d <- tempfile()
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE))
  # create fake cache file
  writeLines("test", file.path(d, "ans_test.parquet"))
  result <- ans_cache_status(cache_dir = d)
  expect_equal(nrow(result), 1)
})

test_that("ans_clear_cache removes cached files", {
  d <- tempfile()
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE))
  writeLines("test", file.path(d, "ans_test.parquet"))
  ans_clear_cache(cache_dir = d)
  files <- list.files(d, pattern = "ans_")
  expect_equal(length(files), 0)
})


# ============================================================================
# download helpers (mocked via cache)
# ============================================================================

test_that(".ans_download_beneficiaries checks partitioned cache", {
  d <- tempfile()
  dir.create(d, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE))

  skip_if_not_installed("arrow")

  # create fake partitioned cache
  fake_data <- tibble::tibble(
    year = 2023L, month = 12L, uf_source = "AC",
    CD_OPERADORA = "123456", SG_UF = "AC"
  )
  .cache_append_partitioned(fake_data, d, "ans_beneficiaries_data",
                            c("uf_source", "year", "month"))

  result <- .ans_download_beneficiaries(2023, 12, "AC", cache = TRUE,
                                        cache_dir = d)
  expect_equal(nrow(result), 1)
  expect_equal(result$CD_OPERADORA, "123456")
})

test_that(".ans_download_complaints checks partitioned cache", {
  d <- tempfile()
  dir.create(d, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE))

  skip_if_not_installed("arrow")

  fake_data <- tibble::tibble(
    year = 2022L,
    NUMERO_DA_DEMANDA = "999999", REGISTRO_OPERADORA = "111111"
  )
  .cache_append_partitioned(fake_data, d, "ans_complaints_data", c("year"))

  result <- .ans_download_complaints(2022, cache = TRUE, cache_dir = d)
  expect_equal(nrow(result), 1)
  expect_equal(result$NUMERO_DA_DEMANDA, "999999")
})

test_that(".ans_download_financial checks partitioned cache", {
  d <- tempfile()
  dir.create(d, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE))

  skip_if_not_installed("arrow")

  fake_data <- tibble::tibble(
    year = 2023L, quarter = 1L,
    REG_ANS = "123456", VL_SALDO_FINAL = "0"
  )
  .cache_append_partitioned(fake_data, d, "ans_financial_data",
                            c("year", "quarter"))

  result <- .ans_download_financial(2023, 1, cache = TRUE, cache_dir = d)
  expect_equal(nrow(result), 1)
  expect_equal(result$REG_ANS, "123456")
})

test_that(".ans_download_operators checks flat cache", {
  d <- tempfile()
  dir.create(d, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE))

  fake_data <- tibble::tibble(
    REGISTRO_OPERADORA = "999999", CNPJ = "12345678901234"
  )
  .cache_write(fake_data, d, "ans_operators_active")

  result <- .ans_download_operators("active", cache = TRUE, cache_dir = d)
  expect_equal(nrow(result), 1)
  expect_equal(result$REGISTRO_OPERADORA, "999999")
})


# ============================================================================
# dispatch routing (mocked via cache)
# ============================================================================

test_that(".ans_data_beneficiaries returns cached data", {
  d <- tempfile()
  dir.create(d, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE))

  skip_if_not_installed("arrow")

  fake_data <- tibble::tibble(
    year = 2023L, month = 12L, uf_source = "AC",
    CD_OPERADORA = "123456", QT_BENEFICIARIO_ATIVO = "10"
  )
  .cache_append_partitioned(fake_data, d, "ans_beneficiaries_data",
                            c("uf_source", "year", "month"))

  result <- .ans_data_beneficiaries(
    2023, "AC", 12, NULL, TRUE, d, FALSE, "arrow"
  )
  expect_s3_class(result, "tbl_df")
  expect_true("CD_OPERADORA" %in% names(result))
})

test_that(".ans_data_complaints returns cached data", {
  d <- tempfile()
  dir.create(d, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE))

  skip_if_not_installed("arrow")

  fake_data <- tibble::tibble(
    year = 2022L,
    NUMERO_DA_DEMANDA = "999999", SEXO = "F"
  )
  .cache_append_partitioned(fake_data, d, "ans_complaints_data", c("year"))

  result <- .ans_data_complaints(2022, NULL, TRUE, d, FALSE, "arrow")
  expect_s3_class(result, "tbl_df")
  expect_true("NUMERO_DA_DEMANDA" %in% names(result))
})

test_that(".ans_data_financial returns cached data", {
  d <- tempfile()
  dir.create(d, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE))

  skip_if_not_installed("arrow")

  fake_data <- tibble::tibble(
    year = 2023L, quarter = 1L,
    REG_ANS = "123456", DESCRICAO = "Teste"
  )
  .cache_append_partitioned(fake_data, d, "ans_financial_data",
                            c("year", "quarter"))

  result <- .ans_data_financial(2023, 1, NULL, TRUE, d, FALSE, "arrow")
  expect_s3_class(result, "tbl_df")
  expect_true("REG_ANS" %in% names(result))
})


# ============================================================================
# ans_data routing via type (mocked)
# ============================================================================

test_that("ans_data routes to beneficiaries", {
  d <- tempfile()
  dir.create(d, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE))

  skip_if_not_installed("arrow")

  fake_data <- tibble::tibble(
    year = 2023L, month = 12L, uf_source = "AC",
    CD_OPERADORA = "123456"
  )
  .cache_append_partitioned(fake_data, d, "ans_beneficiaries_data",
                            c("uf_source", "year", "month"))

  result <- ans_data(year = 2023, type = "beneficiaries",
                     uf = "AC", month = 12, cache_dir = d)
  expect_s3_class(result, "tbl_df")
  expect_true("CD_OPERADORA" %in% names(result))
})

test_that("ans_data routes to complaints", {
  d <- tempfile()
  dir.create(d, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE))

  skip_if_not_installed("arrow")

  fake_data <- tibble::tibble(
    year = 2022L,
    NUMERO_DA_DEMANDA = "999999"
  )
  .cache_append_partitioned(fake_data, d, "ans_complaints_data", c("year"))

  result <- ans_data(year = 2022, type = "complaints", cache_dir = d)
  expect_s3_class(result, "tbl_df")
  expect_true("NUMERO_DA_DEMANDA" %in% names(result))
})

test_that("ans_data routes to financial", {
  d <- tempfile()
  dir.create(d, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE))

  skip_if_not_installed("arrow")

  fake_data <- tibble::tibble(
    year = 2023L, quarter = 1L,
    REG_ANS = "123456"
  )
  .cache_append_partitioned(fake_data, d, "ans_financial_data",
                            c("year", "quarter"))

  result <- ans_data(year = 2023, type = "financial",
                     quarter = 1, cache_dir = d)
  expect_s3_class(result, "tbl_df")
  expect_true("REG_ANS" %in% names(result))
})


# ============================================================================
# column selection (vars)
# ============================================================================

test_that("ans_data vars selects columns for beneficiaries", {
  d <- tempfile()
  dir.create(d, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE))

  skip_if_not_installed("arrow")

  fake_data <- tibble::tibble(
    year = 2023L, month = 12L, uf_source = "AC",
    CD_OPERADORA = "123456", SG_UF = "AC", TP_SEXO = "M"
  )
  .cache_append_partitioned(fake_data, d, "ans_beneficiaries_data",
                            c("uf_source", "year", "month"))

  result <- ans_data(year = 2023, uf = "AC", month = 12,
                     vars = c("CD_OPERADORA", "TP_SEXO"), cache_dir = d)
  expect_true("CD_OPERADORA" %in% names(result))
  expect_true("TP_SEXO" %in% names(result))
  expect_true("year" %in% names(result))
  expect_false("SG_UF" %in% names(result))
})


# ============================================================================
# ans_operators (mocked via cache)
# ============================================================================

test_that("ans_operators returns cached active data", {
  d <- tempfile()
  dir.create(d, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE))

  fake <- tibble::tibble(
    REGISTRO_OPERADORA = c("111", "222"),
    CNPJ = c("aaa", "bbb"),
    Razao_Social = c("Op1", "Op2")
  )
  .cache_write(fake, d, "ans_operators_active")

  result <- ans_operators(status = "active", cache_dir = d)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
})

test_that("ans_operators status=all combines active and cancelled", {
  d <- tempfile()
  dir.create(d, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE))

  active <- tibble::tibble(REGISTRO_OPERADORA = "111", CNPJ = "aaa")
  cancelled <- tibble::tibble(REGISTRO_OPERADORA = "222", CNPJ = "bbb")
  .cache_write(active, d, "ans_operators_active")
  .cache_write(cancelled, d, "ans_operators_cancelled")

  result <- ans_operators(status = "all", cache_dir = d)
  expect_equal(nrow(result), 2)
  expect_true("status" %in% names(result))
  expect_equal(sort(result$status), c("active", "cancelled"))
})

test_that("ans_operators vars selects columns", {
  d <- tempfile()
  dir.create(d, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE))

  fake <- tibble::tibble(
    REGISTRO_OPERADORA = "111", CNPJ = "aaa", UF = "SP"
  )
  .cache_write(fake, d, "ans_operators_active")

  result <- ans_operators(vars = c("REGISTRO_OPERADORA", "UF"), cache_dir = d)
  expect_true("REGISTRO_OPERADORA" %in% names(result))
  expect_true("UF" %in% names(result))
  expect_false("CNPJ" %in% names(result))
})


# ============================================================================
# lazy evaluation
# ============================================================================

test_that("ans_data lazy=TRUE returns lazy object", {
  d <- tempfile()
  dir.create(d, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE))

  skip_if_not_installed("arrow")

  fake_data <- tibble::tibble(
    year = 2023L, month = 12L, uf_source = "AC",
    CD_OPERADORA = "123456"
  )
  .cache_append_partitioned(fake_data, d, "ans_beneficiaries_data",
                            c("uf_source", "year", "month"))

  result <- ans_data(year = 2023, uf = "AC", month = 12,
                     lazy = TRUE, cache_dir = d)
  expect_false(inherits(result, "tbl_df"))
  collected <- dplyr::collect(result)
  expect_s3_class(collected, "tbl_df")
})


# ============================================================================
# integration tests (require network, opt-in)
# ============================================================================

test_that("integration: beneficiaries AC 2023/12", {
  skip_if_no_integration()
  d <- tempfile()
  on.exit(unlink(d, recursive = TRUE))

  result <- ans_data(year = 2023, uf = "AC", month = 12, cache_dir = d)
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true("CD_OPERADORA" %in% names(result))
  expect_true("QT_BENEFICIARIO_ATIVO" %in% names(result))
  expect_true("year" %in% names(result))
  expect_true("month" %in% names(result))
  expect_true("uf_source" %in% names(result))
})

test_that("integration: complaints 2011", {
  skip_if_no_integration()
  d <- tempfile()
  on.exit(unlink(d, recursive = TRUE))

  result <- ans_data(year = 2011, type = "complaints", cache_dir = d)
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true("NUMERO_DA_DEMANDA" %in% names(result))
  expect_true("year" %in% names(result))
})

test_that("integration: financial 2023 Q1", {
  skip_if_no_integration()
  d <- tempfile()
  on.exit(unlink(d, recursive = TRUE))

  result <- ans_data(year = 2023, type = "financial", quarter = 1,
                     cache_dir = d)
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true("REG_ANS" %in% names(result))
  expect_true("year" %in% names(result))
  expect_true("quarter" %in% names(result))
})

test_that("integration: operators active", {
  skip_if_no_integration()
  d <- tempfile()
  on.exit(unlink(d, recursive = TRUE))

  result <- ans_operators(cache_dir = d)
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true("REGISTRO_OPERADORA" %in% names(result))
  expect_true("CNPJ" %in% names(result))
})

test_that("integration: operators all", {
  skip_if_no_integration()
  d <- tempfile()
  on.exit(unlink(d, recursive = TRUE))

  result <- ans_operators(status = "all", cache_dir = d)
  expect_s3_class(result, "tbl_df")
  expect_true("status" %in% names(result))
  expect_true("active" %in% result$status)
  expect_true("cancelled" %in% result$status)
})

test_that("integration: beneficiaries cache hit", {
  skip_if_no_integration()
  skip_if_not_installed("arrow")
  d <- tempfile()
  on.exit(unlink(d, recursive = TRUE))

  # first download
  r1 <- ans_data(year = 2023, uf = "AC", month = 12, cache_dir = d)
  # second should be from cache (instant)
  t0 <- proc.time()["elapsed"]
  r2 <- ans_data(year = 2023, uf = "AC", month = 12, cache_dir = d)
  elapsed <- proc.time()["elapsed"] - t0
  expect_equal(nrow(r1), nrow(r2))
  expect_true(elapsed < 5) # cache should be fast
})
