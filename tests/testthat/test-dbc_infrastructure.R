# tests for DBC infrastructure functions

# ============================================================================
# .dbc2dbf
# ============================================================================

test_that(".dbc2dbf errors on nonexistent file", {
  expect_error(.dbc2dbf("nonexistent.dbc", "out.dbf"), "not found")
})

test_that(".dbc2dbf decompresses a .dbc file (integration)", {
  skip_if_no_integration()

  # download a small .dbc file for testing
  url <- "ftp://ftp.datasus.gov.br/dissemin/publicos/SIM/CID10/DORES/DOAC2022.dbc"
  temp_dbc <- tempfile(fileext = ".dbc")
  temp_dbf <- tempfile(fileext = ".dbf")
  on.exit({
    if (file.exists(temp_dbc)) file.remove(temp_dbc)
    if (file.exists(temp_dbf)) file.remove(temp_dbf)
  })

  .datasus_download(url, temp_dbc)

  result <- .dbc2dbf(temp_dbc, temp_dbf)
  expect_true(result)
  expect_true(file.exists(temp_dbf))
  expect_gt(file.size(temp_dbf), 0)
})

# ============================================================================
# .read_dbc
# ============================================================================

test_that(".read_dbc errors on nonexistent file", {
  expect_error(.read_dbc("nonexistent.dbc"), "not found")
})

test_that(".read_dbc returns tibble with character columns (integration)", {
  skip_if_no_integration()

  url <- "ftp://ftp.datasus.gov.br/dissemin/publicos/SIM/CID10/DORES/DOAC2022.dbc"
  temp_dbc <- tempfile(fileext = ".dbc")
  on.exit(if (file.exists(temp_dbc)) file.remove(temp_dbc))

  .datasus_download(url, temp_dbc)

  data <- .read_dbc(temp_dbc)
  expect_s3_class(data, "tbl_df")
  expect_gt(nrow(data), 0)
  expect_true(all(vapply(data, is.character, logical(1))))
  # should contain typical SIM columns
  expect_true("CAUSABAS" %in% names(data))
  expect_true("DTOBITO" %in% names(data))
})

# ============================================================================
# .datasus_download
# ============================================================================

test_that(".datasus_download errors on bad URL (integration)", {
  skip_if_no_integration()

  expect_error(
    .datasus_download(
      "ftp://ftp.datasus.gov.br/nonexistent/file.dbc",
      tempfile(),
      retries = 1L,
      timeout = 10L
    ),
    "Failed to download"
  )
})
