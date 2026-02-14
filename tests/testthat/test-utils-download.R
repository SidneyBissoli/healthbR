# tests for shared download utilities (utils-download.R)

# ============================================================================
# .http_download_resumable
# ============================================================================

test_that(".http_download_resumable downloads a small file", {
  skip_on_cran()
  skip_if_offline()

  dest <- tempfile(fileext = ".txt")
  on.exit(if (file.exists(dest)) file.remove(dest))

  # use a small, stable URL
  url <- "https://httpbin.org/bytes/1024"
  result <- healthbR:::.http_download_resumable(url, dest, retries = 2L,
                                                timeout = 30L)
  expect_true(file.exists(dest))
  expect_gt(file.size(dest), 0)
})

test_that(".http_download_resumable errors on invalid URL", {
  dest <- tempfile(fileext = ".txt")
  on.exit(if (file.exists(dest)) file.remove(dest))

  expect_error(
    healthbR:::.http_download_resumable(
      "https://httpbin.org/status/404", dest, retries = 1L, timeout = 10L
    ),
    "Failed to download"
  )
})

test_that(".http_download_resumable resumes partial file", {
  skip_on_cran()
  skip_if_offline()

  dest <- tempfile(fileext = ".bin")
  on.exit(if (file.exists(dest)) file.remove(dest))

  # create a partial file (simulating interrupted download)
  writeBin(raw(100), dest)
  expect_equal(file.size(dest), 100)

  # download a file that's bigger than 100 bytes

  url <- "https://httpbin.org/bytes/2048"
  result <- healthbR:::.http_download_resumable(url, dest, retries = 2L,
                                                timeout = 30L)
  expect_true(file.exists(dest))
  # file should be larger than the initial partial
  expect_gt(file.size(dest), 100)
})


# ============================================================================
# .multi_download
# ============================================================================

test_that(".multi_download returns empty data frame for empty input", {
  result <- healthbR:::.multi_download(character(0), character(0))
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
  expect_true(all(c("success", "url", "destfile", "status_code", "error") %in%
                    names(result)))
})

test_that(".multi_download downloads multiple files", {
  skip_on_cran()
  skip_if_offline()

  urls <- c(
    "https://httpbin.org/bytes/512",
    "https://httpbin.org/bytes/256"
  )
  dests <- c(tempfile(fileext = ".bin"), tempfile(fileext = ".bin"))
  on.exit(for (d in dests) if (file.exists(d)) file.remove(d))

  result <- healthbR:::.multi_download(urls, dests, max_concurrent = 2L,
                                        timeout = 30L)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  expect_true(all(result$success))
  expect_true(all(file.exists(dests)))
})

test_that(".multi_download handles mixed success/failure", {
  skip_on_cran()
  skip_if_offline()

  urls <- c(
    "https://httpbin.org/bytes/256",
    "https://httpbin.org/status/404"
  )
  dests <- c(tempfile(fileext = ".bin"), tempfile(fileext = ".bin"))
  on.exit(for (d in dests) if (file.exists(d)) file.remove(d))

  result <- healthbR:::.multi_download(urls, dests, max_concurrent = 2L,
                                        timeout = 30L)
  expect_equal(nrow(result), 2)
  # first should succeed
  expect_true(result$success[1])
  # second may or may not be marked as success depending on curl behavior
  # but the file should exist (even if empty for 404)
})

test_that(".multi_download validates input lengths", {
  expect_error(
    healthbR:::.multi_download(c("a", "b"), c("x")),
    "length"
  )
})


# ============================================================================
# .datasus_download (existing function)
# ============================================================================

test_that(".datasus_download errors on invalid FTP URL", {
  dest <- tempfile(fileext = ".dbc")
  on.exit(if (file.exists(dest)) file.remove(dest))

  expect_error(
    healthbR:::.datasus_download(
      "ftp://ftp.datasus.gov.br/nonexistent/file.dbc", dest,
      retries = 1L, timeout = 10L
    ),
    "Failed to download"
  )
})


# ============================================================================
# .http_download (existing function)
# ============================================================================

test_that(".http_download errors on invalid URL", {
  dest <- tempfile(fileext = ".txt")
  on.exit(if (file.exists(dest)) file.remove(dest))

  expect_error(
    healthbR:::.http_download(
      "https://httpbin.org/status/404", dest,
      retries = 1L, timeout = 10L
    ),
    "Failed to download"
  )
})

test_that(".http_download downloads a small file", {
  skip_on_cran()
  skip_if_offline()

  dest <- tempfile(fileext = ".txt")
  on.exit(if (file.exists(dest)) file.remove(dest))

  result <- healthbR:::.http_download(
    "https://httpbin.org/bytes/512", dest,
    retries = 2L, timeout = 30L
  )
  expect_true(file.exists(dest))
  expect_gt(file.size(dest), 0)
})


# ============================================================================
# .report_download_failures() tests
# ============================================================================

test_that(".report_download_failures returns data unchanged when no failures", {
  data <- tibble::tibble(x = 1:3)
  result <- .report_download_failures(data, character(0), "TEST")
  expect_identical(result, data)
  expect_null(attr(result, "download_failures"))
})

test_that(".report_download_failures attaches attribute on failure", {
  data <- tibble::tibble(x = 1:3)
  failed <- c("AC 2022", "SP 2023")
  result <- suppressWarnings(
    .report_download_failures(data, failed, "TEST")
  )
  expect_equal(result$x, data$x)
  expect_equal(nrow(result), nrow(data))
  expect_equal(attr(result, "download_failures"), failed)
})

test_that(".report_download_failures warns with correct message", {
  data <- tibble::tibble(x = 1:3)
  failed <- c("AC 2022", "SP 2023")
  expect_warning(
    .report_download_failures(data, failed, "SIM"),
    "SIM: 2 files failed"
  )
})
