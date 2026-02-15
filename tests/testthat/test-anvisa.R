# Tests for ANVISA module (Agencia Nacional de Vigilancia Sanitaria)

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

test_that("anvisa_base_url is correct", {
  expect_equal(anvisa_base_url, "https://dados.anvisa.gov.br/dados")
})

test_that("anvisa_valid_types has 14 types", {
  expect_equal(nrow(anvisa_valid_types), 14)
  expect_true(all(c("code", "name", "description", "category") %in%
                    names(anvisa_valid_types)))
})

test_that("anvisa_valid_types contains all expected codes", {
  expected <- c(
    "medicines", "medical_devices", "food", "cosmetics", "sanitizers",
    "tobacco", "pesticides", "hemovigilance", "technovigilance",
    "vigimed_notifications", "vigimed_medicines", "vigimed_reactions",
    "sngpc", "sngpc_compounded"
  )
  expect_equal(anvisa_valid_types$code, expected)
})

test_that("anvisa_valid_types categories are valid", {
  valid_cats <- c("product_registration", "reference", "surveillance", "sngpc")
  expect_true(all(anvisa_valid_types$category %in% valid_cats))
})

test_that("anvisa_snapshot_types has 12 types", {
  expect_equal(length(anvisa_snapshot_types), 12)
  expect_false("sngpc" %in% anvisa_snapshot_types)
  expect_false("sngpc_compounded" %in% anvisa_snapshot_types)
})

test_that("anvisa_sngpc_types has 2 types", {
  expect_equal(anvisa_sngpc_types, c("sngpc", "sngpc_compounded"))
})

test_that("anvisa_type_files maps all snapshot types", {
  expect_equal(length(anvisa_type_files), 12)
  expect_true(all(anvisa_snapshot_types %in% names(anvisa_type_files)))
})

test_that("anvisa_type_files has correct filenames", {
  expect_equal(anvisa_type_files[["medicines"]], "DADOS_ABERTOS_MEDICAMENTOS.csv")
  expect_equal(anvisa_type_files[["medical_devices"]], "TA_PRODUTO_SAUDE_SITE.csv")
  expect_equal(anvisa_type_files[["food"]], "DADOS_ABERTOS_ALIMENTO.csv")
  expect_equal(anvisa_type_files[["cosmetics"]], "DADOS_ABERTOS_COSMETICO.csv")
  expect_equal(anvisa_type_files[["sanitizers"]], "DADOS_ABERTOS_REGISTROS_SANEANTES.CSV")
  expect_equal(anvisa_type_files[["tobacco"]], "DADOS_ABERTOS_PRODUTO_FUMIGENO.csv")
  expect_equal(anvisa_type_files[["pesticides"]], "TA_MONOGRAFIA_AGROTOXICO.csv")
  expect_equal(anvisa_type_files[["hemovigilance"]], "DADOS_ABERTOS_HEMOVIGILANCIA.csv")
  expect_equal(anvisa_type_files[["technovigilance"]], "DADOS_ABERTOS_TECNOVIGILANCIA.csv")
  expect_equal(anvisa_type_files[["vigimed_notifications"]], "VigiMed_Notificacoes.csv")
  expect_equal(anvisa_type_files[["vigimed_medicines"]], "VigiMed_Medicamentos.csv")
  expect_equal(anvisa_type_files[["vigimed_reactions"]], "VigiMed_Reacoes.csv")
})

test_that("anvisa_sngpc_subdirs has correct values", {
  expect_equal(anvisa_sngpc_subdirs[["sngpc"]], "Industrializados")
  expect_equal(anvisa_sngpc_subdirs[["sngpc_compounded"]], "Manipulados")
})

test_that("anvisa_sngpc_prefixes has correct values", {
  expect_equal(anvisa_sngpc_prefixes[["sngpc"]], "EDA_Industrializados_")
  expect_equal(anvisa_sngpc_prefixes[["sngpc_compounded"]], "EDA_Manipulados_")
})

test_that("anvisa_csv_delim has entries for all 14 types", {
  all_types <- c(anvisa_snapshot_types, anvisa_sngpc_types)
  expect_true(all(all_types %in% names(anvisa_csv_delim)))
})

test_that("anvisa_csv_delim sanitizers uses comma", {
  expect_equal(anvisa_csv_delim[["sanitizers"]], ",")
})

test_that("anvisa_csv_delim most types use semicolon", {
  semicolon_types <- setdiff(names(anvisa_csv_delim), "sanitizers")
  for (t in semicolon_types) {
    expect_equal(anvisa_csv_delim[[t]], ";", info = t)
  }
})

test_that("anvisa_sngpc_years spans 2014 to 2026", {
  expect_equal(min(anvisa_sngpc_years), 2014L)
  expect_equal(max(anvisa_sngpc_years), 2026L)
})


# ============================================================================
# variable metadata
# ============================================================================

test_that("anvisa_medicines_metadata has 11 variables", {
  expect_equal(nrow(anvisa_medicines_metadata), 11)
  expect_true("TIPO_PRODUTO" %in% anvisa_medicines_metadata$variable)
  expect_true("PRINCIPIO_ATIVO" %in% anvisa_medicines_metadata$variable)
})

test_that("anvisa_medical_devices_metadata has 12 variables", {
  expect_equal(nrow(anvisa_medical_devices_metadata), 12)
  expect_true("NUMERO_REGISTRO_CADASTRO" %in% anvisa_medical_devices_metadata$variable)
  expect_true("CLASSE_RISCO" %in% anvisa_medical_devices_metadata$variable)
})

test_that("anvisa_food_metadata has 10 variables", {
  expect_equal(nrow(anvisa_food_metadata), 10)
  expect_true("NO_PRODUTO" %in% anvisa_food_metadata$variable)
})

test_that("anvisa_cosmetics_metadata has 10 variables", {
  expect_equal(nrow(anvisa_cosmetics_metadata), 10)
  expect_true("NO_PRODUTO" %in% anvisa_cosmetics_metadata$variable)
})

test_that("anvisa_sanitizers_metadata has 6 variables", {
  expect_equal(nrow(anvisa_sanitizers_metadata), 6)
  expect_true("NOME_PRODUTO" %in% anvisa_sanitizers_metadata$variable)
})

test_that("anvisa_tobacco_metadata has 9 variables", {
  expect_equal(nrow(anvisa_tobacco_metadata), 9)
  expect_true("DS_TIPO_PRODUTO" %in% anvisa_tobacco_metadata$variable)
})

test_that("anvisa_pesticides_metadata has 15 variables", {
  expect_equal(nrow(anvisa_pesticides_metadata), 15)
  expect_true("NO_SUBSTANCIA" %in% anvisa_pesticides_metadata$variable)
  expect_true("NU_CAS" %in% anvisa_pesticides_metadata$variable)
})

test_that("anvisa_hemovigilance_metadata has 16 variables", {
  expect_equal(nrow(anvisa_hemovigilance_metadata), 16)
  expect_true("NU_NOTIFICACAO" %in% anvisa_hemovigilance_metadata$variable)
  expect_true("TIPO_REACAO_TRANSFUSIONAL" %in% anvisa_hemovigilance_metadata$variable)
})

test_that("anvisa_technovigilance_metadata has 18 variables", {
  expect_equal(nrow(anvisa_technovigilance_metadata), 18)
  expect_true("ANO_NOTIFICACAO" %in% anvisa_technovigilance_metadata$variable)
  expect_true("CLASSE_RISCO" %in% anvisa_technovigilance_metadata$variable)
})

test_that("anvisa_vigimed_notifications_metadata has 29 variables", {
  expect_equal(nrow(anvisa_vigimed_notifications_metadata), 29)
  expect_true("IDENTIFICACAO_NOTIFICACAO" %in% anvisa_vigimed_notifications_metadata$variable)
  expect_true("SEXO" %in% anvisa_vigimed_notifications_metadata$variable)
})

test_that("anvisa_vigimed_medicines_metadata has 22 variables", {
  expect_equal(nrow(anvisa_vigimed_medicines_metadata), 22)
  expect_true("IDENTIFICACAO_NOTIFICACAO" %in% anvisa_vigimed_medicines_metadata$variable)
  expect_true("CODIGO_ATC" %in% anvisa_vigimed_medicines_metadata$variable)
})

test_that("anvisa_vigimed_reactions_metadata has 12 variables", {
  expect_equal(nrow(anvisa_vigimed_reactions_metadata), 12)
  expect_true("IDENTIFICACAO_NOTIFICACAO" %in% anvisa_vigimed_reactions_metadata$variable)
  expect_true("SOC" %in% anvisa_vigimed_reactions_metadata$variable)
})

test_that("anvisa_sngpc_metadata has 15 variables", {
  expect_equal(nrow(anvisa_sngpc_metadata), 15)
  expect_true("NU_ANO_VENDA" %in% anvisa_sngpc_metadata$variable)
  expect_true("DS_PRINCIPIO_ATIVO" %in% anvisa_sngpc_metadata$variable)
})

test_that("anvisa_sngpc_compounded_metadata has 17 variables", {
  expect_equal(nrow(anvisa_sngpc_compounded_metadata), 17)
  expect_true("DS_DCB" %in% anvisa_sngpc_compounded_metadata$variable)
  expect_true("QT_ATIVO_POR_UNID_FARMACOTEC" %in% anvisa_sngpc_compounded_metadata$variable)
})

test_that("all metadata tibbles have required columns", {
  all_types <- anvisa_valid_types$code
  for (type in all_types) {
    meta <- .anvisa_get_metadata(type)
    expect_true(all(c("variable", "description") %in% names(meta)),
                info = type)
    expect_true(nrow(meta) > 0, info = type)
  }
})

test_that(".anvisa_get_metadata returns correct metadata for each type", {
  expect_identical(.anvisa_get_metadata("medicines"), anvisa_medicines_metadata)
  expect_identical(.anvisa_get_metadata("sngpc"), anvisa_sngpc_metadata)
  expect_identical(.anvisa_get_metadata("vigimed_reactions"),
                   anvisa_vigimed_reactions_metadata)
})


# ============================================================================
# .anvisa_validate_type
# ============================================================================

test_that(".anvisa_validate_type accepts all 14 valid types", {
  for (type in anvisa_valid_types$code) {
    expect_equal(.anvisa_validate_type(type), type)
  }
})

test_that(".anvisa_validate_type is case insensitive", {
  expect_equal(.anvisa_validate_type("MEDICINES"), "medicines")
  expect_equal(.anvisa_validate_type("Hemovigilance"), "hemovigilance")
  expect_equal(.anvisa_validate_type("SNGPC"), "sngpc")
})

test_that(".anvisa_validate_type errors on invalid type", {
  expect_error(.anvisa_validate_type("invalid"), "Invalid")
  expect_error(.anvisa_validate_type("drugs"), "Invalid")
  expect_error(.anvisa_validate_type(""), "Invalid")
})

test_that(".anvisa_validate_type error message mentions anvisa_types()", {
  expect_error(.anvisa_validate_type("invalid"), "anvisa_types")
})


# ============================================================================
# .anvisa_validate_sngpc_year
# ============================================================================

test_that(".anvisa_validate_sngpc_year accepts valid years", {
  expect_equal(.anvisa_validate_sngpc_year(2014), 2014L)
  expect_equal(.anvisa_validate_sngpc_year(2020), 2020L)
  expect_equal(.anvisa_validate_sngpc_year(2026), 2026L)
})

test_that(".anvisa_validate_sngpc_year accepts multiple years", {
  expect_equal(.anvisa_validate_sngpc_year(c(2014, 2015)), c(2014L, 2015L))
})

test_that(".anvisa_validate_sngpc_year errors on invalid year", {
  expect_error(.anvisa_validate_sngpc_year(2013), "not available")
  expect_error(.anvisa_validate_sngpc_year(2027), "not available")
})


# ============================================================================
# .anvisa_validate_sngpc_month
# ============================================================================

test_that(".anvisa_validate_sngpc_month accepts valid months", {
  expect_equal(.anvisa_validate_sngpc_month(1), 1L)
  expect_equal(.anvisa_validate_sngpc_month(12), 12L)
})

test_that(".anvisa_validate_sngpc_month returns all 12 for NULL", {
  expect_equal(.anvisa_validate_sngpc_month(NULL), 1L:12L)
})

test_that(".anvisa_validate_sngpc_month errors on invalid month", {
  expect_error(.anvisa_validate_sngpc_month(0))
  expect_error(.anvisa_validate_sngpc_month(13))
})


# ============================================================================
# .anvisa_validate_vars
# ============================================================================

test_that(".anvisa_validate_vars warns on unknown variables", {
  expect_warning(
    .anvisa_validate_vars(c("TIPO_PRODUTO", "FAKE_VAR"), "medicines"),
    "FAKE_VAR"
  )
})

test_that(".anvisa_validate_vars silent on known variables", {
  expect_silent(.anvisa_validate_vars("TIPO_PRODUTO", "medicines"))
  expect_silent(.anvisa_validate_vars("NU_NOTIFICACAO", "hemovigilance"))
})


# ============================================================================
# URL builders
# ============================================================================

test_that(".anvisa_snapshot_url builds correct URLs", {
  expect_equal(
    .anvisa_snapshot_url("medicines"),
    "https://dados.anvisa.gov.br/dados/DADOS_ABERTOS_MEDICAMENTOS.csv"
  )
  expect_equal(
    .anvisa_snapshot_url("sanitizers"),
    "https://dados.anvisa.gov.br/dados/DADOS_ABERTOS_REGISTROS_SANEANTES.CSV"
  )
  expect_equal(
    .anvisa_snapshot_url("vigimed_notifications"),
    "https://dados.anvisa.gov.br/dados/VigiMed_Notificacoes.csv"
  )
})

test_that(".anvisa_sngpc_url builds correct URLs", {
  expect_equal(
    .anvisa_sngpc_url("sngpc", 2020, 1),
    "https://dados.anvisa.gov.br/dados/SNGPC/Industrializados/EDA_Industrializados_202001.csv"
  )
  expect_equal(
    .anvisa_sngpc_url("sngpc_compounded", 2021, 10),
    "https://dados.anvisa.gov.br/dados/SNGPC/Manipulados/EDA_Manipulados_202110.csv"
  )
  expect_equal(
    .anvisa_sngpc_url("sngpc", 2014, 2),
    "https://dados.anvisa.gov.br/dados/SNGPC/Industrializados/EDA_Industrializados_201402.csv"
  )
})

test_that(".anvisa_sngpc_url zero-pads single-digit months", {
  url <- .anvisa_sngpc_url("sngpc", 2020, 3)
  expect_true(grepl("202003", url))
})


# ============================================================================
# anvisa_types()
# ============================================================================

test_that("anvisa_types() returns valid types tibble", {
  result <- anvisa_types()
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 14)
  expect_true(all(c("code", "name", "description", "category") %in%
                    names(result)))
})


# ============================================================================
# anvisa_info()
# ============================================================================

test_that("anvisa_info() returns list invisibly", {
  expect_invisible(result <- anvisa_info())
  expect_type(result, "list")
  expect_true("name" %in% names(result))
  expect_true("n_types" %in% names(result))
  expect_equal(result$n_types, 14)
})


# ============================================================================
# anvisa_variables()
# ============================================================================

test_that("anvisa_variables() returns tibble for all types", {
  for (type in anvisa_valid_types$code) {
    result <- anvisa_variables(type = type)
    expect_true(inherits(result, "tbl_df"))
    expect_true(nrow(result) > 0)
    expect_true("variable" %in% names(result))
    expect_true("description" %in% names(result))
  }
})

test_that("anvisa_variables() default is medicines", {
  result <- anvisa_variables()
  expect_equal(nrow(result), 11)
  expect_true("PRINCIPIO_ATIVO" %in% result$variable)
})

test_that("anvisa_variables() search filters results", {
  result <- anvisa_variables(type = "medicines", search = "registro")
  expect_true(nrow(result) > 0)
  expect_true(nrow(result) < 11)
})

test_that("anvisa_variables() errors on invalid type", {
  expect_error(anvisa_variables(type = "invalid"), "Invalid")
})


# ============================================================================
# anvisa_data() parameter validation
# ============================================================================

test_that("anvisa_data() errors when SNGPC type given without year", {
  expect_error(anvisa_data(type = "sngpc"), "year.*required")
})

test_that("anvisa_data() errors when SNGPC type given without year (compounded)", {
  expect_error(anvisa_data(type = "sngpc_compounded"), "year.*required")
})

test_that("anvisa_data() warns when year given for snapshot type", {
  # Wrap in tryCatch to avoid actual download
  expect_warning(
    tryCatch(
      anvisa_data(type = "medicines", year = 2020, cache = FALSE),
      error = function(e) NULL
    ),
    "year.*ignored"
  )
})

test_that("anvisa_data() warns when month given for snapshot type", {
  expect_warning(
    tryCatch(
      anvisa_data(type = "medicines", month = 1, cache = FALSE),
      error = function(e) NULL
    ),
    "month.*ignored"
  )
})

test_that("anvisa_data() warns when lazy given for snapshot type", {
  expect_warning(
    tryCatch(
      anvisa_data(type = "medicines", lazy = TRUE, cache = FALSE),
      error = function(e) NULL
    ),
    "lazy.*ignored"
  )
})

test_that("anvisa_data() validates SNGPC year", {
  expect_error(
    anvisa_data(type = "sngpc", year = 2013),
    "not available"
  )
})

test_that("anvisa_data() validates SNGPC month", {
  expect_error(
    anvisa_data(type = "sngpc", year = 2020, month = 13)
  )
})

test_that("anvisa_data() validates type", {
  expect_error(anvisa_data(type = "invalid"), "Invalid")
})

test_that("anvisa_data() type is case insensitive", {
  # just validate the type parsing, not the download
  expect_error(
    anvisa_data(type = "SNGPC"),
    "year.*required"
  )
})


# ============================================================================
# anvisa_cache_status / anvisa_clear_cache
# ============================================================================

test_that("anvisa_cache_status() works with empty cache", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  result <- anvisa_cache_status(cache_dir = temp_dir)
  expect_s3_class(result, "tbl_df")
})

test_that("anvisa_clear_cache() works with empty cache", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  expect_no_error(anvisa_clear_cache(cache_dir = temp_dir))
})


# ============================================================================
# snapshot download with mocking
# ============================================================================

test_that(".anvisa_download_snapshot reads CSV correctly", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  # create a mock CSV file (semicolon delimiter)
  csv_content <- "COL1;COL2;COL3\nval1;val2;val3\nval4;val5;val6\n"
  mock_csv <- file.path(temp_dir, "mock.csv")
  writeLines(csv_content, mock_csv)

  # mock .http_download to copy our mock file
  local_mocked_bindings(
    .http_download = function(url, destfile, ...) {
      file.copy(mock_csv, destfile, overwrite = TRUE)
      invisible(destfile)
    }
  )

  result <- .anvisa_download_snapshot("medicines", cache = FALSE,
                                     cache_dir = temp_dir)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_equal(ncol(result), 3)
  expect_equal(names(result), c("COL1", "COL2", "COL3"))
})

test_that(".anvisa_download_snapshot handles comma delimiter for sanitizers", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  # create a mock CSV file (comma delimiter)
  csv_content <- "COL1,COL2,COL3\nval1,val2,val3\n"
  mock_csv <- file.path(temp_dir, "mock.csv")
  writeLines(csv_content, mock_csv)

  local_mocked_bindings(
    .http_download = function(url, destfile, ...) {
      file.copy(mock_csv, destfile, overwrite = TRUE)
      invisible(destfile)
    }
  )

  result <- .anvisa_download_snapshot("sanitizers", cache = FALSE,
                                     cache_dir = temp_dir)
  expect_equal(nrow(result), 1)
  expect_equal(ncol(result), 3)
})

test_that(".anvisa_download_snapshot caches and retrieves data", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  csv_content <- "COL1;COL2\nval1;val2\n"
  mock_csv <- file.path(temp_dir, "mock.csv")
  writeLines(csv_content, mock_csv)

  download_count <- 0L
  local_mocked_bindings(
    .http_download = function(url, destfile, ...) {
      download_count <<- download_count + 1L
      file.copy(mock_csv, destfile, overwrite = TRUE)
      invisible(destfile)
    }
  )

  # first call: downloads
  result1 <- .anvisa_download_snapshot("medicines", cache = TRUE,
                                      cache_dir = temp_dir)
  expect_equal(download_count, 1L)

  # second call: from cache
  result2 <- .anvisa_download_snapshot("medicines", cache = TRUE,
                                      cache_dir = temp_dir)
  expect_equal(download_count, 1L)  # no new download
  expect_equal(nrow(result2), nrow(result1))
})


# ============================================================================
# SNGPC download with mocking
# ============================================================================

test_that(".anvisa_download_sngpc reads CSV and adds partition columns", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  csv_content <- paste0(
    "NU_ANO_VENDA;NU_MES_VENDA;SG_UF_VENDA;DS_PRINCIPIO_ATIVO\n",
    "\"2020\";\"01\";\"SP\";\"CLONAZEPAM\"\n"
  )
  mock_csv <- file.path(temp_dir, "mock.csv")
  writeLines(csv_content, mock_csv)

  local_mocked_bindings(
    .http_download = function(url, destfile, ...) {
      file.copy(mock_csv, destfile, overwrite = TRUE)
      invisible(destfile)
    }
  )

  result <- .anvisa_download_sngpc("sngpc", 2020, 1,
                                   cache = FALSE, cache_dir = temp_dir)
  expect_s3_class(result, "tbl_df")
  expect_true("year" %in% names(result))
  expect_true("month" %in% names(result))
  expect_equal(result$year[1], 2020L)
  expect_equal(result$month[1], 1L)
})

test_that(".anvisa_download_sngpc URL includes ssl_verifypeer=FALSE", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  csv_content <- "COL1;COL2\nval1;val2\n"
  mock_csv <- file.path(temp_dir, "mock.csv")
  writeLines(csv_content, mock_csv)

  captured_ssl <- NULL
  local_mocked_bindings(
    .http_download = function(url, destfile, ssl_verifypeer = TRUE, ...) {
      captured_ssl <<- ssl_verifypeer
      file.copy(mock_csv, destfile, overwrite = TRUE)
      invisible(destfile)
    }
  )

  .anvisa_download_sngpc("sngpc", 2020, 1, cache = FALSE,
                         cache_dir = temp_dir)
  expect_false(captured_ssl)
})


# ============================================================================
# routing tests via anvisa_data()
# ============================================================================

test_that("anvisa_data routes snapshot types to .anvisa_data_snapshot", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  csv_content <- "COL1;COL2\nval1;val2\n"
  mock_csv <- file.path(temp_dir, "mock.csv")
  writeLines(csv_content, mock_csv)

  local_mocked_bindings(
    .http_download = function(url, destfile, ...) {
      file.copy(mock_csv, destfile, overwrite = TRUE)
      invisible(destfile)
    }
  )

  result <- anvisa_data(type = "medicines", cache = FALSE,
                        cache_dir = temp_dir)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
})

test_that("anvisa_data routes SNGPC types to .anvisa_data_sngpc", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  csv_content <- "COL1;COL2\nval1;val2\n"
  mock_csv <- file.path(temp_dir, "mock.csv")
  writeLines(csv_content, mock_csv)

  local_mocked_bindings(
    .http_download = function(url, destfile, ...) {
      file.copy(mock_csv, destfile, overwrite = TRUE)
      invisible(destfile)
    }
  )

  result <- anvisa_data(type = "sngpc", year = 2020, month = 1,
                        cache = FALSE, cache_dir = temp_dir)
  expect_s3_class(result, "tbl_df")
  expect_true("year" %in% names(result))
  expect_true("month" %in% names(result))
})

test_that("anvisa_data snapshot with vars selects columns", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  csv_content <- "TIPO_PRODUTO;NOME_PRODUTO;PRINCIPIO_ATIVO\nMED;Test;Aspirin\n"
  mock_csv <- file.path(temp_dir, "mock.csv")
  writeLines(csv_content, mock_csv)

  local_mocked_bindings(
    .http_download = function(url, destfile, ...) {
      file.copy(mock_csv, destfile, overwrite = TRUE)
      invisible(destfile)
    }
  )

  result <- anvisa_data(type = "medicines",
                        vars = c("TIPO_PRODUTO", "PRINCIPIO_ATIVO"),
                        cache = FALSE, cache_dir = temp_dir)
  expect_equal(ncol(result), 2)
  expect_equal(names(result), c("TIPO_PRODUTO", "PRINCIPIO_ATIVO"))
})

test_that("anvisa_data SNGPC handles download failure gracefully", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  call_count <- 0L
  csv_content <- "COL1;COL2\nval1;val2\n"
  mock_csv <- file.path(temp_dir, "mock.csv")
  writeLines(csv_content, mock_csv)

  local_mocked_bindings(
    .http_download = function(url, destfile, ...) {
      call_count <<- call_count + 1L
      if (call_count == 1L) stop("Network error")
      file.copy(mock_csv, destfile, overwrite = TRUE)
      invisible(destfile)
    }
  )

  # month 1 fails, month 2 succeeds => partial result with warning
  warned <- FALSE
  result <- withCallingHandlers(
    anvisa_data(type = "sngpc", year = 2020, month = 1:2,
                cache = FALSE, cache_dir = temp_dir),
    warning = function(w) {
      if (grepl("failed", conditionMessage(w))) warned <<- TRUE
      invokeRestart("muffleWarning")
    },
    message = function(m) invokeRestart("muffleMessage")
  )
  expect_true(warned)
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true(!is.null(attr(result, "download_failures")))
})

test_that("anvisa_data SNGPC errors when all downloads fail", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  local_mocked_bindings(
    .http_download = function(url, destfile, ...) {
      stop("Network error")
    }
  )

  expect_error(
    anvisa_data(type = "sngpc", year = 2020, month = 1,
                cache = FALSE, cache_dir = temp_dir),
    "No data could be downloaded"
  )
})


# ============================================================================
# cache status / clear with actual files
# ============================================================================

test_that("anvisa_cache_status reports cached files", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  # create a fake cached file
  saveRDS(data.frame(a = 1), file.path(temp_dir, "anvisa_medicines.rds"))

  result <- anvisa_cache_status(cache_dir = temp_dir)
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
})

test_that("anvisa_clear_cache removes cached files", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  saveRDS(data.frame(a = 1), file.path(temp_dir, "anvisa_medicines.rds"))
  expect_true(file.exists(file.path(temp_dir, "anvisa_medicines.rds")))

  anvisa_clear_cache(cache_dir = temp_dir)
  expect_false(file.exists(file.path(temp_dir, "anvisa_medicines.rds")))
})


# ============================================================================
# integration tests
# ============================================================================

test_that("anvisa_data medicines downloads real data", {
  skip_if_no_integration()

  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  result <- anvisa_data(type = "medicines", cache = TRUE,
                        cache_dir = temp_dir)
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 1000)
  expect_true("PRINCIPIO_ATIVO" %in% names(result))
  expect_true("NOME_PRODUTO" %in% names(result))
})

test_that("anvisa_data hemovigilance downloads real data", {
  skip_if_no_integration()

  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  result <- anvisa_data(type = "hemovigilance", cache = TRUE,
                        cache_dir = temp_dir)
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 100)
  expect_true("NU_NOTIFICACAO" %in% names(result))
})

test_that("anvisa_data pesticides downloads real data", {
  skip_if_no_integration()

  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  result <- anvisa_data(type = "pesticides", cache = TRUE,
                        cache_dir = temp_dir)
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 100)
  expect_true("NO_SUBSTANCIA" %in% names(result))
})

test_that("anvisa_data sngpc downloads real data", {
  skip_if_no_integration()

  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  result <- anvisa_data(type = "sngpc", year = 2020, month = 1,
                        cache = TRUE, cache_dir = temp_dir)
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 100)
  expect_true("year" %in% names(result))
  expect_true("month" %in% names(result))
  expect_equal(unique(result$year), 2020L)
  expect_equal(unique(result$month), 1L)
})

test_that("anvisa_data vigimed_notifications downloads real data", {
  skip_if_no_integration()

  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  result <- anvisa_data(type = "vigimed_notifications", cache = TRUE,
                        cache_dir = temp_dir)
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 100)
  expect_true("IDENTIFICACAO_NOTIFICACAO" %in% names(result))
})

test_that("anvisa_data sanitizers downloads real data (comma delimiter)", {
  skip_if_no_integration()

  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  result <- tryCatch(
    anvisa_data(type = "sanitizers", cache = TRUE, cache_dir = temp_dir),
    error = function(e) {
      skip(paste("ANVISA server unavailable:", conditionMessage(e)))
    }
  )
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 100)
  expect_true("NOME_PRODUTO" %in% names(result))
})
