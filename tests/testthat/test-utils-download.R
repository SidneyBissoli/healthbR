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


# ============================================================================
# ADDITIONAL COVERAGE TESTS
# ============================================================================

# --- .datasus_download --- mocked error handling ---

test_that(".datasus_download errors after all retries exhausted with mock", {
  local_mocked_bindings(
    curl_download = function(...) stop("Connection refused"),
    .package = "curl"
  )

  dest <- tempfile(fileext = ".dbc")
  on.exit(if (file.exists(dest)) file.remove(dest))

  expect_error(
    .datasus_download(
      "ftp://fake.server/file.dbc", dest,
      retries = 1L, timeout = 5L
    ),
    "Failed to download"
  )
})

test_that(".datasus_download cleans up partial file on failure", {
  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      # Create a partial file then fail
      writeLines("partial", destfile)
      stop("Connection timeout")
    },
    .package = "curl"
  )

  dest <- tempfile(fileext = ".dbc")
  on.exit(if (file.exists(dest)) file.remove(dest))

  tryCatch(
    .datasus_download(
      "ftp://fake.server/file.dbc", dest,
      retries = 1L, timeout = 5L
    ),
    error = function(e) NULL
  )

  # File should be cleaned up
  expect_false(file.exists(dest))
})

# --- .http_download --- mocked error handling ---

test_that(".http_download errors after all retries exhausted with mock", {
  local_mocked_bindings(
    curl_download = function(...) stop("SSL error"),
    .package = "curl"
  )

  dest <- tempfile(fileext = ".csv")
  on.exit(if (file.exists(dest)) file.remove(dest))

  expect_error(
    .http_download(
      "https://fake.server/file.csv", dest,
      retries = 1L, timeout = 5L
    ),
    "Failed to download"
  )
})

test_that(".http_download cleans up partial file on failure", {
  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      writeLines("partial", destfile)
      stop("Connection timeout")
    },
    .package = "curl"
  )

  dest <- tempfile(fileext = ".csv")
  on.exit(if (file.exists(dest)) file.remove(dest))

  tryCatch(
    .http_download(
      "https://fake.server/file.csv", dest,
      retries = 1L, timeout = 5L
    ),
    error = function(e) NULL
  )

  expect_false(file.exists(dest))
})

# --- .report_download_failures --- additional tests ---

test_that(".report_download_failures with single failure", {
  data <- tibble::tibble(x = 1:3)
  expect_warning(
    result <- .report_download_failures(data, "AC 2022", "SIM"),
    "SIM: 1 file failed"
  )
  expect_equal(attr(result, "download_failures"), "AC 2022")
})

test_that(".report_download_failures preserves data structure", {
  data <- tibble::tibble(x = 1:3, y = c("a", "b", "c"))
  result <- suppressWarnings(
    .report_download_failures(data, c("AC 2022"), "TEST")
  )
  expect_equal(ncol(result), 2)
  expect_equal(names(result), c("x", "y"))
  expect_equal(nrow(result), 3)
})

test_that(".report_download_failures with many failures", {
  data <- tibble::tibble(x = 1)
  failed <- paste("UF", 1:10)
  expect_warning(
    result <- .report_download_failures(data, failed, "TEST"),
    "TEST: 10 files failed"
  )
  expect_equal(length(attr(result, "download_failures")), 10)
})


# ============================================================================
# ADDITIONAL COVERAGE: .datasus_download success path (mocked)
# ============================================================================

test_that(".datasus_download succeeds on first try with mock", {
  dest <- tempfile(fileext = ".dbc")
  on.exit(if (file.exists(dest)) file.remove(dest))

  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      writeBin(as.raw(1:200), destfile)
      invisible(destfile)
    },
    .package = "curl"
  )

  result <- .datasus_download("ftp://fake.server/file.dbc", dest,
                               retries = 3L, timeout = 5L)
  expect_true(file.exists(dest))
  expect_gt(file.size(dest), 0)
})

test_that(".datasus_download succeeds after retry with mock", {
  dest <- tempfile(fileext = ".dbc")
  on.exit(if (file.exists(dest)) file.remove(dest))

  call_count <- 0L
  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      call_count <<- call_count + 1L
      if (call_count < 2L) stop("Connection refused")
      writeBin(as.raw(1:200), destfile)
      invisible(destfile)
    },
    .package = "curl"
  )

  result <- .datasus_download("ftp://fake.server/file.dbc", dest,
                               retries = 3L, timeout = 5L)
  expect_true(file.exists(dest))
  expect_equal(call_count, 2L)
})

test_that(".datasus_download returns invisible destfile on success", {
  dest <- tempfile(fileext = ".dbc")
  on.exit(if (file.exists(dest)) file.remove(dest))

  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      writeBin(as.raw(1:200), destfile)
      invisible(destfile)
    },
    .package = "curl"
  )

  vis_result <- withVisible(.datasus_download(
    "ftp://fake.server/file.dbc", dest, retries = 1L, timeout = 5L
  ))
  expect_false(vis_result$visible)
  expect_equal(vis_result$value, dest)
})

# ============================================================================
# ADDITIONAL COVERAGE: .http_download success path and ssl_verifypeer
# ============================================================================

test_that(".http_download succeeds on first try with mock", {
  dest <- tempfile(fileext = ".csv")
  on.exit(if (file.exists(dest)) file.remove(dest))

  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      writeBin(as.raw(1:200), destfile)
      invisible(destfile)
    },
    .package = "curl"
  )

  result <- .http_download("https://fake.server/file.csv", dest,
                            retries = 1L, timeout = 5L)
  expect_true(file.exists(dest))
  expect_gt(file.size(dest), 0)
})

test_that(".http_download accepts ssl_verifypeer=FALSE without error", {
  dest <- tempfile(fileext = ".csv")
  on.exit(if (file.exists(dest)) file.remove(dest))

  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      writeBin(as.raw(1:200), destfile)
      invisible(destfile)
    },
    .package = "curl"
  )

  # just verify the function runs without error when ssl_verifypeer=FALSE
  result <- .http_download("https://fake.server/file.csv", dest,
                            retries = 1L, timeout = 5L,
                            ssl_verifypeer = FALSE)
  expect_true(file.exists(dest))
  expect_gt(file.size(dest), 0)
})

test_that(".http_download succeeds after retry with mock", {
  dest <- tempfile(fileext = ".csv")
  on.exit(if (file.exists(dest)) file.remove(dest))

  call_count <- 0L
  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      call_count <<- call_count + 1L
      if (call_count < 2L) stop("Timeout")
      writeBin(as.raw(1:200), destfile)
      invisible(destfile)
    },
    .package = "curl"
  )

  result <- .http_download("https://fake.server/file.csv", dest,
                            retries = 3L, timeout = 5L)
  expect_true(file.exists(dest))
  expect_equal(call_count, 2L)
})

test_that(".http_download returns invisible destfile on success", {
  dest <- tempfile(fileext = ".csv")
  on.exit(if (file.exists(dest)) file.remove(dest))

  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      writeBin(as.raw(1:200), destfile)
      invisible(destfile)
    },
    .package = "curl"
  )

  vis_result <- withVisible(.http_download(
    "https://fake.server/file.csv", dest, retries = 1L, timeout = 5L
  ))
  expect_false(vis_result$visible)
  expect_equal(vis_result$value, dest)
})

# ============================================================================
# ADDITIONAL COVERAGE: .http_download_resumable (mocked paths)
# ============================================================================

test_that(".http_download_resumable fresh download with mock", {
  dest <- tempfile(fileext = ".bin")
  on.exit(if (file.exists(dest)) file.remove(dest))

  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      writeBin(as.raw(1:200), destfile)
      invisible(destfile)
    },
    .package = "curl"
  )

  result <- .http_download_resumable(
    "https://fake.server/file.bin", dest,
    retries = 1L, timeout = 5L
  )
  expect_true(file.exists(dest))
  expect_gt(file.size(dest), 0)
})

test_that(".http_download_resumable detects existing partial file size", {
  dest <- tempfile(fileext = ".bin")
  on.exit(if (file.exists(dest)) file.remove(dest))

  # write partial file first
  writeBin(as.raw(1:50), dest)
  expect_equal(file.size(dest), 50)

  # mock: the function will try curl_fetch_disk for resume
  # but we mock at curl_download level (fresh path won't trigger since
  # existing_size > 0). Instead test that the function eventually
  # errors out after failing to resume (all retries exhausted).
  local_mocked_bindings(
    curl_fetch_disk = function(url, path, handle) {
      stop("Resume not supported by mock server")
    },
    curl_download = function(url, destfile, ...) {
      stop("Also fails")
    },
    .package = "curl"
  )

  # Should clean up and error
  expect_error(
    .http_download_resumable(
      "https://fake.server/file.bin", dest,
      retries = 1L, timeout = 5L
    ),
    "Failed to download"
  )
})

test_that(".http_download_resumable succeeds after partial failure then retry", {
  dest <- tempfile(fileext = ".bin")
  on.exit(if (file.exists(dest)) file.remove(dest))

  call_count <- 0L
  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      call_count <<- call_count + 1L
      if (call_count < 2L) stop("Temporary failure")
      writeBin(as.raw(1:200), destfile)
      invisible(destfile)
    },
    .package = "curl"
  )

  result <- .http_download_resumable(
    "https://fake.server/file.bin", dest,
    retries = 3L, timeout = 5L
  )
  expect_true(file.exists(dest))
  expect_gt(file.size(dest), 0)
  expect_equal(call_count, 2L)
})

test_that(".http_download_resumable returns invisible destfile", {
  dest <- tempfile(fileext = ".bin")
  on.exit(if (file.exists(dest)) file.remove(dest))

  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      writeBin(as.raw(1:200), destfile)
      invisible(destfile)
    },
    .package = "curl"
  )

  vis_result <- withVisible(.http_download_resumable(
    "https://fake.server/file.bin", dest, retries = 1L, timeout = 5L
  ))
  expect_false(vis_result$visible)
  expect_equal(vis_result$value, dest)
})

test_that(".http_download_resumable errors after all retries", {
  dest <- tempfile(fileext = ".bin")
  on.exit(if (file.exists(dest)) file.remove(dest))

  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      stop("Connection failed")
    },
    .package = "curl"
  )

  expect_error(
    .http_download_resumable(
      "https://fake.server/file.bin", dest,
      retries = 1L, timeout = 5L
    ),
    "Failed to download"
  )
})

test_that(".http_download_resumable cleans up destfile on total failure", {
  dest <- tempfile(fileext = ".bin")
  # create a file that will be cleaned up on failure
  writeBin(raw(50), dest)
  expect_true(file.exists(dest))

  local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      stop("Connection lost")
    },
    curl_fetch_disk = function(url, path, handle) {
      stop("Connection lost")
    },
    .package = "curl"
  )

  tryCatch(
    .http_download_resumable(
      "https://fake.server/file.bin", dest,
      retries = 1L, timeout = 5L
    ),
    error = function(e) NULL
  )

  # destfile should be removed after all retries exhausted
  expect_false(file.exists(dest))
})

# ============================================================================
# ADDITIONAL COVERAGE: .multi_download (mocked)
# ============================================================================

test_that(".multi_download creates destination directories", {
  temp_base <- withr::local_tempdir()
  subdir <- file.path(temp_base, "subdir1", "subdir2")

  local_mocked_bindings(
    multi_download = function(urls, destfiles, ...) {
      # simulate curl::multi_download response
      for (d in destfiles) writeBin(as.raw(1:100), d)
      data.frame(
        success = TRUE, url = urls, destfile = destfiles,
        status_code = 200L, error = NA_character_,
        stringsAsFactors = FALSE
      )
    },
    .package = "curl"
  )

  urls <- "https://fake.server/file.bin"
  dests <- file.path(subdir, "file.bin")

  result <- .multi_download(urls, dests, max_concurrent = 2L, timeout = 5L)

  expect_true(dir.exists(subdir))
  expect_equal(nrow(result), 1)
  expect_true(result$success[1])
})

test_that(".multi_download returns correct structure with mocked results", {
  local_mocked_bindings(
    multi_download = function(urls, destfiles, ...) {
      for (d in destfiles) writeBin(as.raw(1:100), d)
      data.frame(
        success = c(TRUE, FALSE),
        url = urls,
        destfile = destfiles,
        status_code = c(200L, 404L),
        error = c(NA, "Not found"),
        stringsAsFactors = FALSE
      )
    },
    .package = "curl"
  )

  dest1 <- tempfile(fileext = ".bin")
  dest2 <- tempfile(fileext = ".bin")
  on.exit({
    if (file.exists(dest1)) file.remove(dest1)
    if (file.exists(dest2)) file.remove(dest2)
  })

  result <- .multi_download(
    c("https://fake.server/a.bin", "https://fake.server/b.bin"),
    c(dest1, dest2), max_concurrent = 2L, timeout = 5L
  )

  expect_equal(nrow(result), 2)
  expect_true(result$success[1])
  expect_false(result$success[2])
  expect_equal(result$status_code, c(200L, 404L))
  expect_equal(result$error[2], "Not found")
  expect_true(is.na(result$error[1]))
})
