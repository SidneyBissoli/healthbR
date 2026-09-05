# SIH via the healthbr-data R2 mirror (sih_r2.R + the source chain in sih.R)

fake_manifest <- list(
  manifest_version = "1.0.0",
  dataset = "sih/rd",
  last_updated = "2026-08-18T12:33:31",
  partitions = list(
    "2024-04-RR" = list(
      source_url = "ftp://ftp.datasus.gov.br/dissemin/publicos/SIHSUS/200801_/Dados/RDRR2404.dbc",
      total_records = 4001, processing_timestamp = "2026-03-09 04:10:00",
      source_hash_md5 = "md5-rr-2404", source_size_bytes = 300000
    ),
    "2023-01-AC" = list(
      source_url = "ftp://ftp.datasus.gov.br/dissemin/publicos/SIHSUS/200801_/Dados/RDAC2301.dbc",
      total_records = 4165, processing_timestamp = "2026-03-09 03:02:56",
      source_hash_md5 = "md5-ac-2301", source_size_bytes = 294939
    )
  )
)

# ---- pure logic --------------------------------------------------------------

test_that("sih_data rejects an unknown source", {
  expect_error(
    sih_data(2023, month = 1, uf = "AC", source = "ftp"),
    "Invalid"
  )
})

test_that(".sih_r2_manifest_summary turns the manifest into one row per partition", {
  local_mocked_bindings(.r2_manifest = function(...) fake_manifest)
  s <- .sih_r2_manifest_summary(tempdir())
  expect_s3_class(s, "tbl_df")
  expect_equal(nrow(s), 2)
  # sorted by year, month, uf
  expect_equal(s$year, c(2023L, 2024L))
  expect_equal(s$month, c(1L, 4L))
  expect_equal(s$uf, c("AC", "RR"))
  expect_equal(s$records, c(4165, 4001))
  expect_equal(s$source_hash_md5, c("md5-ac-2301", "md5-rr-2404"))
  expect_equal(s$source_size_bytes, c(294939, 300000))
  expect_true(all(grepl("^ftp://ftp\\.datasus\\.gov\\.br/", s$source_url)))
  expect_equal(unique(s$dataset), "sih_rd")
})

test_that(".sih_r2_provenance keeps only the partitions a call touched", {
  local_mocked_bindings(.r2_manifest = function(...) fake_manifest)
  prov <- .sih_r2_provenance(2023, 1:12, "AC", tempdir())
  expect_equal(nrow(prov), 1)
  expect_equal(prov$uf, "AC")
  expect_null(.sih_r2_provenance(2020, 1, "SP", tempdir()))
  # never errors
  local_mocked_bindings(.r2_manifest = function(...) stop("boom"))
  expect_null(.sih_r2_provenance(2023, 1, "AC", tempdir()))
})

test_that("sih_status warns and returns a typed empty tibble when the manifest is unreachable", {
  local_mocked_bindings(.r2_manifest = function(...) NULL)
  expect_warning(st <- sih_status(cache_dir = tempdir()), "manifest")
  expect_equal(nrow(st), 0)
  expect_named(st, c("dataset", "year", "month", "uf", "records",
                     "processing_timestamp", "source_url",
                     "source_hash_md5", "source_size_bytes"))
})

test_that(".sih_r2_shape mirrors the FTP path's columns", {
  df <- tibble::tibble(N_AIH = c("1", "2"), DT_INTER = c("20230105", "20221228"),
                       mes = c("01", "01"), uf = c("AC", "AC"))
  out <- .sih_r2_shape(df, 2023L, 1L)
  expect_equal(names(out)[1:3], c("year", "month", "uf_source"))
  expect_false(any(c("mes", "uf") %in% names(out)))
  expect_equal(out$year, c(2023L, 2023L))
  expect_equal(out$month, c(1L, 1L))
  expect_equal(out$uf_source, c("AC", "AC"))
  # raw columns untouched (all character, as published)
  expect_type(out$DT_INTER, "character")
})

test_that(".sih_fetch falls back to datasus when the mirror yields nothing", {
  local_mocked_bindings(
    .sih_r2_fetch = function(...) list(results = list(), failed_labels = "AC 2023/01"),
    .sih_download_loop = function(...) list(
      data = tibble::tibble(year = 2023L, month = 1L, uf_source = "AC", N_AIH = "1"),
      failed_labels = character(0)
    )
  )
  expect_warning(
    res <- .sih_fetch(c("r2", "datasus"), 2023, 1, "AC", FALSE, tempdir(), NULL),
    "falling back"
  )
  expect_equal(res$source, "datasus")
  expect_equal(nrow(res$data), 1)
})

test_that(".sih_fetch serves the mirror first and reports its source", {
  local_mocked_bindings(
    .sih_r2_fetch = function(...) list(
      results = list(tibble::tibble(year = 2023L, month = 1L, uf_source = "AC", N_AIH = "1")),
      failed_labels = character(0)
    ),
    .sih_download_loop = function(...) stop("must not be called")
  )
  res <- .sih_fetch(c("r2", "datasus"), 2023, 1, "AC", FALSE, tempdir(), NULL)
  expect_equal(res$source, "r2")
  expect_equal(res$data$N_AIH, "1")
})

test_that(".sih_fetch aborts when every source fails", {
  local_mocked_bindings(
    .sih_r2_fetch = function(...) list(results = list(), failed_labels = "AC 2023/01"),
    .sih_download_loop = function(...) cli::cli_abort("No data could be downloaded")
  )
  expect_error(
    suppressWarnings(.sih_fetch(c("r2", "datasus"), 2023, 1, "AC", FALSE, tempdir(), NULL)),
    "No data could be downloaded"
  )
})

# ---- live (HEALTHBR_INTEGRATION=true) -----------------------------------------

test_that("sih_data reads one competence from R2 with provenance", {
  skip_if_no_integration()
  skip_if_not_installed("arrow")
  cache <- withr::local_tempdir()
  st <- sih_status(cache_dir = cache)
  expected <- st$records[st$year == 2023 & st$month == 1 & st$uf == "RR"]
  expect_length(expected, 1)

  data <- sih_data(year = 2023, month = 1, uf = "RR", cache_dir = cache,
                   parse = FALSE)
  expect_s3_class(data, "tbl_df")
  expect_equal(nrow(data), expected)
  expect_equal(names(data)[1:3], c("year", "month", "uf_source"))
  expect_equal(unique(data$uf_source), "RR")
  expect_true(all(nchar(data$DT_INTER) == 8))
  expect_equal(attr(data, "healthbr_source"), "r2")
  prov <- attr(data, "healthbr_provenance")
  expect_equal(nrow(prov), 1)
  expect_true(grepl("RDRR2301\\.dbc$", prov$source_url))
  expect_true(!is.na(prov$source_hash_md5))

  # second call is served from the shared local cache, same rows
  again <- sih_data(year = 2023, month = 1, uf = "RR", cache_dir = cache,
                    parse = FALSE)
  expect_equal(nrow(again), expected)
})

test_that("sih_data parses types from the mirror like it does from the FTP", {
  skip_if_no_integration()
  skip_if_not_installed("arrow")
  cache <- withr::local_tempdir()
  data <- sih_data(year = 2023, month = 1, uf = "RR", cache_dir = cache,
                   vars = c("DT_INTER", "VAL_TOT", "DIAS_PERM", "SEXO"))
  expect_s3_class(data$DT_INTER, "Date")
  expect_type(data$VAL_TOT, "double")
  expect_type(data$DIAS_PERM, "integer")
  expect_type(data$SEXO, "character")
})

test_that("sih_data(lazy = TRUE) is a remote dataset over the mirror", {
  skip_if_no_integration()
  skip_if_not_installed("arrow")
  cache <- withr::local_tempdir()
  st <- sih_status(cache_dir = cache)
  expected <- st$records[st$year == 2023 & st$month == 1 & st$uf == "RR"]

  ds <- sih_data(year = 2023, month = 1, uf = "RR", cache_dir = cache,
                 lazy = TRUE, parse = FALSE)
  expect_false(is.data.frame(ds))
  expect_equal(names(ds)[1:3], c("year", "month", "uf_source"))
  n <- ds |> dplyr::count() |> dplyr::collect()
  expect_equal(n$n, expected)
})

test_that("sih_data(lazy = TRUE, backend = 'duckdb') works over the mirror", {
  skip_if_no_integration()
  skip_if_not_installed("arrow")
  skip_if_not_installed("duckdb")
  skip_if_not_installed("dbplyr")
  cache <- withr::local_tempdir()
  ds <- sih_data(year = 2023, month = 1, uf = "RR", cache_dir = cache,
                 lazy = TRUE, backend = "duckdb", parse = FALSE)
  n <- ds |> dplyr::summarise(n = dplyr::n()) |> dplyr::collect()
  expect_gt(n$n, 0)
})

test_that("sih_status lists the published competences", {
  skip_if_no_integration()
  st <- sih_status(cache_dir = withr::local_tempdir())
  expect_gt(nrow(st), 10000)
  expect_true(all(nchar(st$uf) == 2))
  expect_true(all(st$month %in% 1:12))
  expect_true(all(!is.na(st$source_hash_md5)))
})
