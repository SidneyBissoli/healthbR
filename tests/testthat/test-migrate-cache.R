# Tests for healthbR_migrate_cache()

# ============================================================================
# setup helper
# ============================================================================

skip_if_no_arrow <- function() {
  skip_if_not_installed("arrow")
}

# Create a fake flat parquet file in the given module cache dir
create_fake_flat <- function(cache_dir, module, filename, data) {
  mod_dir <- file.path(cache_dir, module)
  dir.create(mod_dir, recursive = TRUE, showWarnings = FALSE)
  fpath <- file.path(mod_dir, filename)
  ext <- tools::file_ext(filename)
  if (ext == "parquet") {
    arrow::write_parquet(data, fpath)
  } else {
    saveRDS(data, fpath)
  }
  fpath
}


# ============================================================================
# requires arrow
# ============================================================================

test_that("healthbR_migrate_cache aborts without arrow", {
  # temporarily hide arrow
  mockr_env <- new.env(parent = emptyenv())
  local_mocked_bindings(
    .has_arrow = function() FALSE,
    .package = "healthbR"
  )
  expect_error(
    healthbR_migrate_cache(cache_dir = tempdir()),
    "arrow"
  )
})


# ============================================================================
# empty cache
# ============================================================================

test_that("healthbR_migrate_cache handles missing cache dir", {
  skip_if_no_arrow()
  nonexistent <- file.path(tempdir(), "healthbR_test_no_cache_dir_xyz")
  unlink(nonexistent, recursive = TRUE)

  expect_message(
    result <- healthbR_migrate_cache(cache_dir = nonexistent),
    "Nothing to migrate"
  )
  expect_equal(result$migrated, 0L)
  expect_equal(result$skipped, 0L)
})

test_that("healthbR_migrate_cache handles empty module dirs", {
  skip_if_no_arrow()
  cache_dir <- file.path(tempdir(), "healthbR_test_empty_mods")
  dir.create(file.path(cache_dir, "sim"), recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  expect_message(
    result <- healthbR_migrate_cache(cache_dir = cache_dir),
    "0 files migrated"
  )
  expect_equal(result$migrated, 0L)
})


# ============================================================================
# dry_run mode
# ============================================================================

test_that("dry_run lists files without modifying them", {
  skip_if_no_arrow()
  cache_dir <- file.path(tempdir(), "healthbR_test_dry_run")
  on.exit(unlink(cache_dir, recursive = TRUE))

  data <- data.frame(COL1 = "A", COL2 = "B", stringsAsFactors = FALSE)
  fpath <- create_fake_flat(cache_dir, "sim", "sim_AC_2022.parquet", data)

  expect_message(
    result <- healthbR_migrate_cache(cache_dir = cache_dir, dry_run = TRUE),
    "Would migrate"
  )
  expect_equal(result$migrated, 1L)
  # file should still exist

  expect_true(file.exists(fpath))
})

test_that("dry_run reports correct count for multiple files", {
  skip_if_no_arrow()
  cache_dir <- file.path(tempdir(), "healthbR_test_dry_multi")
  on.exit(unlink(cache_dir, recursive = TRUE))

  data <- data.frame(COL1 = "A", stringsAsFactors = FALSE)
  create_fake_flat(cache_dir, "sim", "sim_AC_2022.parquet", data)
  create_fake_flat(cache_dir, "sim", "sim_SP_2021.parquet", data)

  result <- suppressMessages(
    healthbR_migrate_cache(cache_dir = cache_dir, dry_run = TRUE)
  )
  expect_equal(result$migrated, 2L)
})


# ============================================================================
# SIM migration
# ============================================================================

test_that("migrates SIM flat parquet to partitioned dataset", {
  skip_if_no_arrow()
  cache_dir <- file.path(tempdir(), "healthbR_test_sim_migrate")
  on.exit(unlink(cache_dir, recursive = TRUE))

  data <- data.frame(IDADE = "4050", SEXO = "1", stringsAsFactors = FALSE)
  fpath <- create_fake_flat(cache_dir, "sim", "sim_AC_2022.parquet", data)

  suppressMessages(
    result <- healthbR_migrate_cache(cache_dir = cache_dir)
  )

  expect_equal(result$migrated, 1L)
  expect_false(file.exists(fpath))

  # verify partitioned dataset is readable
  ds <- arrow::open_dataset(file.path(cache_dir, "sim", "sim_data"))
  df <- dplyr::collect(ds)
  expect_equal(nrow(df), 1)
  expect_true("uf_source" %in% names(df))
  expect_true("year" %in% names(df))
  expect_equal(df$uf_source, "AC")
  expect_equal(df$year, 2022L)
})

test_that("migrates SIM flat RDS to partitioned dataset", {
  skip_if_no_arrow()
  cache_dir <- file.path(tempdir(), "healthbR_test_sim_rds")
  on.exit(unlink(cache_dir, recursive = TRUE))

  data <- data.frame(IDADE = "4050", SEXO = "1", stringsAsFactors = FALSE)
  fpath <- create_fake_flat(cache_dir, "sim", "sim_RJ_2020.rds", data)

  suppressMessages(
    result <- healthbR_migrate_cache(cache_dir = cache_dir)
  )

  expect_equal(result$migrated, 1L)
  expect_false(file.exists(fpath))

  ds <- arrow::open_dataset(file.path(cache_dir, "sim", "sim_data"))
  df <- dplyr::collect(ds)
  expect_equal(df$uf_source, "RJ")
  expect_equal(df$year, 2020L)
})


# ============================================================================
# SINASC migration
# ============================================================================

test_that("migrates SINASC flat file to partitioned dataset", {
  skip_if_no_arrow()
  cache_dir <- file.path(tempdir(), "healthbR_test_sinasc_migrate")
  on.exit(unlink(cache_dir, recursive = TRUE))

  data <- data.frame(PESO = "3200", stringsAsFactors = FALSE)
  create_fake_flat(cache_dir, "sinasc", "sinasc_SP_2021.parquet", data)

  suppressMessages(
    result <- healthbR_migrate_cache(cache_dir = cache_dir)
  )
  expect_equal(result$migrated, 1L)

  ds <- arrow::open_dataset(file.path(cache_dir, "sinasc", "sinasc_data"))
  df <- dplyr::collect(ds)
  expect_equal(df$uf_source, "SP")
  expect_equal(df$year, 2021L)
})


# ============================================================================
# SIH migration (year + month)
# ============================================================================

test_that("migrates SIH flat file with year-month", {
  skip_if_no_arrow()
  cache_dir <- file.path(tempdir(), "healthbR_test_sih_migrate")
  on.exit(unlink(cache_dir, recursive = TRUE))

  data <- data.frame(DIAG_PRINC = "J18", stringsAsFactors = FALSE)
  create_fake_flat(cache_dir, "sih", "sih_AC_202201.parquet", data)

  suppressMessages(
    result <- healthbR_migrate_cache(cache_dir = cache_dir)
  )
  expect_equal(result$migrated, 1L)

  ds <- arrow::open_dataset(file.path(cache_dir, "sih", "sih_data"))
  df <- dplyr::collect(ds)
  expect_equal(df$uf_source, "AC")
  expect_equal(df$year, 2022L)
  expect_equal(df$month, 1L)
})


# ============================================================================
# SIA migration (type + UF + year-month)
# ============================================================================

test_that("migrates SIA flat file (type prefix)", {
  skip_if_no_arrow()
  cache_dir <- file.path(tempdir(), "healthbR_test_sia_migrate")
  on.exit(unlink(cache_dir, recursive = TRUE))

  data <- data.frame(PA_PROC_ID = "0301010", stringsAsFactors = FALSE)
  create_fake_flat(cache_dir, "sia", "sia_PA_AC_202301.parquet", data)

  suppressMessages(
    result <- healthbR_migrate_cache(cache_dir = cache_dir)
  )
  expect_equal(result$migrated, 1L)

  ds <- arrow::open_dataset(file.path(cache_dir, "sia", "sia_data"))
  df <- dplyr::collect(ds)
  expect_equal(df$uf_source, "AC")
  expect_equal(df$year, 2023L)
  expect_equal(df$month, 1L)
})


# ============================================================================
# SINAN migration
# ============================================================================

test_that("migrates SINAN flat file (disease + year)", {
  skip_if_no_arrow()
  cache_dir <- file.path(tempdir(), "healthbR_test_sinan_migrate")
  on.exit(unlink(cache_dir, recursive = TRUE))

  data <- data.frame(CS_SEXO = "M", stringsAsFactors = FALSE)
  create_fake_flat(cache_dir, "sinan", "sinan_DENG_2022.parquet", data)

  suppressMessages(
    result <- healthbR_migrate_cache(cache_dir = cache_dir)
  )
  expect_equal(result$migrated, 1L)

  ds <- arrow::open_dataset(file.path(cache_dir, "sinan", "sinan_data"))
  df <- dplyr::collect(ds)
  expect_equal(df$disease, "DENG")
  expect_equal(df$year, 2022L)
})


# ============================================================================
# CNES migration
# ============================================================================

test_that("migrates CNES flat file (type + UF + year-month)", {
  skip_if_no_arrow()
  cache_dir <- file.path(tempdir(), "healthbR_test_cnes_migrate")
  on.exit(unlink(cache_dir, recursive = TRUE))

  data <- data.frame(CNES = "1234567", stringsAsFactors = FALSE)
  create_fake_flat(cache_dir, "cnes", "cnes_ST_AC_202301.parquet", data)

  suppressMessages(
    result <- healthbR_migrate_cache(cache_dir = cache_dir)
  )
  expect_equal(result$migrated, 1L)

  ds <- arrow::open_dataset(file.path(cache_dir, "cnes", "cnes_data"))
  df <- dplyr::collect(ds)
  expect_equal(df$uf_source, "AC")
  expect_equal(df$year, 2023L)
  expect_equal(df$month, 1L)
})


# ============================================================================
# SI-PNI FTP migration
# ============================================================================

test_that("migrates SI-PNI FTP flat file", {
  skip_if_no_arrow()
  cache_dir <- file.path(tempdir(), "healthbR_test_sipni_ftp_migrate")
  on.exit(unlink(cache_dir, recursive = TRUE))

  data <- data.frame(IMUNO = "BCG", stringsAsFactors = FALSE)
  create_fake_flat(cache_dir, "sipni", "sipni_DPNI_AC_2019.parquet", data)

  suppressMessages(
    result <- healthbR_migrate_cache(cache_dir = cache_dir)
  )
  expect_equal(result$migrated, 1L)

  ds <- arrow::open_dataset(file.path(cache_dir, "sipni", "sipni_ftp_data"))
  df <- dplyr::collect(ds)
  expect_equal(df$uf_source, "AC")
  expect_equal(df$year, 2019L)
})


# ============================================================================
# SI-PNI CSV migration
# ============================================================================

test_that("migrates SI-PNI CSV flat file", {
  skip_if_no_arrow()
  cache_dir <- file.path(tempdir(), "healthbR_test_sipni_csv_migrate")
  on.exit(unlink(cache_dir, recursive = TRUE))

  data <- data.frame(vacina_nome = "COVID", stringsAsFactors = FALSE)
  create_fake_flat(cache_dir, "sipni", "sipni_API_AC_202401.parquet", data)

  suppressMessages(
    result <- healthbR_migrate_cache(cache_dir = cache_dir)
  )
  expect_equal(result$migrated, 1L)

  ds <- arrow::open_dataset(file.path(cache_dir, "sipni", "sipni_csv_data"))
  df <- dplyr::collect(ds)
  expect_equal(df$uf_source, "AC")
  expect_equal(df$year, 2024L)
  expect_equal(df$month, 1L)
})


# ============================================================================
# PNS migration
# ============================================================================

test_that("migrates PNS flat file", {
  skip_if_no_arrow()
  cache_dir <- file.path(tempdir(), "healthbR_test_pns_migrate")
  on.exit(unlink(cache_dir, recursive = TRUE))

  data <- data.frame(V0001 = "AC", stringsAsFactors = FALSE)
  create_fake_flat(cache_dir, "pns", "pns_2019.parquet", data)

  suppressMessages(
    result <- healthbR_migrate_cache(cache_dir = cache_dir)
  )
  expect_equal(result$migrated, 1L)

  ds <- arrow::open_dataset(file.path(cache_dir, "pns", "pns_data"))
  df <- dplyr::collect(ds)
  expect_equal(df$year, 2019L)
})


# ============================================================================
# PNADC migration
# ============================================================================

test_that("migrates PNADC flat file", {
  skip_if_no_arrow()
  cache_dir <- file.path(tempdir(), "healthbR_test_pnadc_migrate")
  on.exit(unlink(cache_dir, recursive = TRUE))

  data <- data.frame(UF = "12", stringsAsFactors = FALSE)
  create_fake_flat(cache_dir, "pnadc", "pnadc_deficiencia_2022.parquet", data)

  suppressMessages(
    result <- healthbR_migrate_cache(cache_dir = cache_dir)
  )
  expect_equal(result$migrated, 1L)

  ds <- arrow::open_dataset(file.path(cache_dir, "pnadc", "pnadc_data"))
  df <- dplyr::collect(ds)
  expect_equal(df$year, 2022L)
})


# ============================================================================
# POF migration (dynamic dataset name)
# ============================================================================

test_that("migrates POF flat file with dynamic dataset name", {
  skip_if_no_arrow()
  cache_dir <- file.path(tempdir(), "healthbR_test_pof_migrate")
  on.exit(unlink(cache_dir, recursive = TRUE))

  data <- data.frame(V0001 = "12", stringsAsFactors = FALSE)
  create_fake_flat(cache_dir, "pof", "pof_2017-2018_morador.parquet", data)

  suppressMessages(
    result <- healthbR_migrate_cache(cache_dir = cache_dir)
  )
  expect_equal(result$migrated, 1L)

  ds <- arrow::open_dataset(file.path(cache_dir, "pof", "pof_morador_data"))
  df <- dplyr::collect(ds)
  expect_equal(df$year, "2017-2018")
})


# ============================================================================
# unrecognized files left alone
# ============================================================================

test_that("unrecognized files are not touched", {
  skip_if_no_arrow()
  cache_dir <- file.path(tempdir(), "healthbR_test_unrecognized")
  on.exit(unlink(cache_dir, recursive = TRUE))

  # recognized file
  data <- data.frame(COL1 = "A", stringsAsFactors = FALSE)
  create_fake_flat(cache_dir, "sim", "sim_AC_2022.parquet", data)

  # unrecognized file
  random_path <- file.path(cache_dir, "sim", "random_file.parquet")
  arrow::write_parquet(data, random_path)

  suppressMessages(
    result <- healthbR_migrate_cache(cache_dir = cache_dir)
  )
  expect_equal(result$migrated, 1L)
  # unrecognized file still exists
  expect_true(file.exists(random_path))
})


# ============================================================================
# multiple modules in one run
# ============================================================================

test_that("migrates files from multiple modules in one run", {
  skip_if_no_arrow()
  cache_dir <- file.path(tempdir(), "healthbR_test_multi_module")
  on.exit(unlink(cache_dir, recursive = TRUE))

  data <- data.frame(COL1 = "A", stringsAsFactors = FALSE)
  create_fake_flat(cache_dir, "sim", "sim_AC_2022.parquet", data)
  create_fake_flat(cache_dir, "sinasc", "sinasc_SP_2021.parquet", data)
  create_fake_flat(cache_dir, "sih", "sih_RJ_202106.parquet", data)

  suppressMessages(
    result <- healthbR_migrate_cache(cache_dir = cache_dir)
  )
  expect_equal(result$migrated, 3L)
  expect_equal(result$skipped, 0L)
})
