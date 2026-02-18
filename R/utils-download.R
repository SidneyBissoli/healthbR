# Shared download utilities for healthbR
# Provides consistent download functions with retry logic for all modules

# ============================================================================
# Shared retry loop helper
# ============================================================================

#' Download a file with retry and exponential backoff (internal)
#'
#' Generic retry wrapper used by `.datasus_download()`, `.http_download()`,
#' and `.http_download_resumable()`. On each attempt, calls
#' `download_fn(url, destfile)` which should write the file and return TRUE
#' on success. On error, retries with exponential backoff.
#'
#' @param url Character. URL of the file to download.
#' @param destfile Character. Path to save the downloaded file.
#' @param retries Integer. Number of retry attempts.
#' @param download_fn Function. Takes `(url, destfile)`, writes the file, and
#'   returns TRUE on success.
#' @param fail_msg Character vector. Message parts for `cli::cli_abort()` on
#'   total failure (after all retries exhausted).
#'
#' @return The destfile path (invisibly) on success.
#'   Throws an error on failure.
#'
#' @noRd
.retry_download_loop <- function(url, destfile, retries, download_fn,
                                 fail_msg) {
  for (i in seq_len(retries)) {
    result <- tryCatch({
      download_fn(url, destfile)
      TRUE
    }, error = .make_retry_handler(i, retries))

    if (.download_succeeded(result, destfile)) {
      return(invisible(destfile))
    }
  }

  # all retries failed
  .cleanup_failed_download(destfile, fail_msg, environment())
}

#' Create an error handler for download retry (internal)
#'
#' Returns a function that logs retry info on non-final attempts and returns
#' FALSE. Used by `.retry_download_loop()`.
#'
#' @param attempt Integer. Current attempt number.
#' @param retries Integer. Total number of retry attempts.
#'
#' @return A function suitable for `tryCatch(error = ...)`.
#'
#' @noRd
.make_retry_handler <- function(attempt, retries) {
  function(e) {
    if (attempt < retries) {
      wait_time <- 2^attempt
      cli::cli_inform(c(
        "i" = "Download attempt {attempt}/{retries} failed. Retrying in {wait_time}s...",
        "x" = "{e$message}"
      ))
      Sys.sleep(wait_time)
    }
    FALSE
  }
}

#' Check if a download attempt succeeded (internal)
#'
#' Verifies that the download function returned TRUE and the file exists
#' with non-zero size.
#'
#' @param result Logical or other. The return value from `tryCatch()`.
#' @param destfile Character. Path to the downloaded file.
#'
#' @return TRUE if download succeeded, FALSE otherwise.
#'
#' @noRd
.download_succeeded <- function(result, destfile) {
  isTRUE(result) && file.exists(destfile) && file.size(destfile) > 0
}

#' Clean up after all download retries are exhausted (internal)
#'
#' Removes the destfile if it exists and aborts with the provided message.
#'
#' @param destfile Character. Path to the file to clean up.
#' @param fail_msg Character vector. Message parts for `cli::cli_abort()`.
#' @param envir Environment for evaluating cli glue expressions in `fail_msg`.
#'
#' @noRd
.cleanup_failed_download <- function(destfile, fail_msg, envir) {
  if (file.exists(destfile)) file.remove(destfile)
  cli::cli_abort(fail_msg, .envir = envir)
}


# ============================================================================
# DATASUS FTP download with retry
# ============================================================================

#' Download a file from DATASUS FTP with retry (internal)
#'
#' Downloads a file from the DATASUS FTP server with exponential backoff
#' retry logic.
#'
#' @param url Character. URL of the file to download.
#' @param destfile Character. Path to save the downloaded file.
#' @param retries Integer. Number of retry attempts. Default: 3.
#' @param timeout Integer. Download timeout in seconds. Default: 120.
#'
#' @return The destfile path (invisibly) on success.
#'   Throws an error on failure.
#'
#' @noRd
.datasus_download <- function(url, destfile, retries = 3L, timeout = 120L) {
  .retry_download_loop(
    url = url,
    destfile = destfile,
    retries = retries,
    download_fn = function(u, d) {
      curl::curl_download(
        u, d,
        handle = curl::new_handle(
          connecttimeout = 30,
          timeout = timeout,
          ftp_use_epsv = FALSE
        ),
        quiet = TRUE
      )
    },
    fail_msg = c(
      "Failed to download file from DATASUS FTP after {retries} attempts.",
      "x" = "URL: {.url {url}}",
      "i" = "Check your internet connection.",
      "i" = "The DATASUS FTP server may be temporarily unavailable."
    )
  )
}


# ============================================================================
# HTTP download wrapper
# ============================================================================

#' Download a file via HTTP/HTTPS with retry (internal)
#'
#' General-purpose HTTP download with exponential backoff retry logic.
#' Unlike `.datasus_download()`, this does not set FTP-specific options.
#'
#' @param url Character. URL of the file to download.
#' @param destfile Character. Path to save the downloaded file.
#' @param retries Integer. Number of retry attempts. Default: 3.
#' @param timeout Integer. Download timeout in seconds. Default: 300.
#' @param quiet Logical. Suppress download progress. Default: TRUE.
#' @param ssl_verifypeer Logical. Verify SSL certificates. Default: TRUE.
#'   Set to FALSE for servers with certificate issues (e.g., ANVISA portal).
#'
#' @return The destfile path (invisibly) on success.
#'   Throws an error on failure.
#'
#' @noRd
.http_download <- function(url, destfile, retries = 3L, timeout = 300L,
                           quiet = TRUE, ssl_verifypeer = TRUE) {
  .retry_download_loop(
    url = url,
    destfile = destfile,
    retries = retries,
    download_fn = function(u, d) {
      curl::curl_download(
        u, d,
        handle = curl::new_handle(
          connecttimeout = 30,
          timeout = timeout,
          followlocation = TRUE,
          ssl_verifypeer = ssl_verifypeer
        ),
        quiet = quiet
      )
    },
    fail_msg = c(
      "Failed to download file after {retries} attempts.",
      "x" = "URL: {.url {url}}",
      "i" = "Check your internet connection."
    )
  )
}


# ============================================================================
# Resumable HTTP download helpers
# ============================================================================

#' Attempt to resume a partial HTTP download (internal)
#'
#' Handles the case where a partial file already exists at `destfile`.
#' Sends an HTTP Range request and handles three response cases:
#' - 416: server doesn't support Range; falls back to full download.
#' - 200: server ignored Range and sent the full file; overwrites destfile.
#' - 206: server sent partial content; appends to existing destfile.
#'
#' @param url Character. URL of the file to download.
#' @param destfile Character. Path to the existing partial file.
#' @param existing_size Numeric. Size of the existing partial file in bytes.
#' @param timeout Integer. Download timeout in seconds.
#'
#' @return TRUE on success, FALSE on unexpected status code.
#'
#' @noRd
.http_resume_partial <- function(url, destfile, existing_size, timeout) {
  h <- curl::new_handle(
    connecttimeout = 30,
    timeout = timeout,
    followlocation = TRUE
  )
  curl::handle_setopt(h, range = paste0(existing_size, "-"))

  tmp_part <- tempfile(fileext = ".part")
  on.exit(if (file.exists(tmp_part)) file.remove(tmp_part), add = TRUE)
  resp <- curl::curl_fetch_disk(url, tmp_part, handle = h)

  if (resp$status_code == 416L) {
    return(.http_resume_fallback_full(url, destfile, tmp_part, timeout))
  }

  if (resp$status_code == 200L) {
    # server ignored Range, sent full file
    file.copy(tmp_part, destfile, overwrite = TRUE)
    if (file.exists(tmp_part)) file.remove(tmp_part)
    return(TRUE)
  }

  if (resp$status_code == 206L) {
    # 206 Partial Content: append to existing file
    .http_append_partial(tmp_part, destfile)
    if (file.exists(tmp_part)) file.remove(tmp_part)
    return(TRUE)
  }

  # unexpected status code
  if (file.exists(tmp_part)) file.remove(tmp_part)
  FALSE
}

#' Fall back to a full download when Range request returns 416 (internal)
#'
#' Cleans up the partial temp file and existing destfile, then performs a
#' fresh full download.
#'
#' @param url Character. URL of the file to download.
#' @param destfile Character. Path to save the downloaded file.
#' @param tmp_part Character. Path to the temp .part file to clean up.
#' @param timeout Integer. Download timeout in seconds.
#'
#' @return TRUE on success.
#'
#' @noRd
.http_resume_fallback_full <- function(url, destfile, tmp_part, timeout) {
  if (file.exists(tmp_part)) file.remove(tmp_part)
  if (file.exists(destfile)) file.remove(destfile)
  curl::curl_download(url, destfile,
                      handle = curl::new_handle(
                        connecttimeout = 30, timeout = timeout,
                        followlocation = TRUE
                      ), quiet = TRUE)
  TRUE
}

#' Append partial download content to an existing file (internal)
#'
#' Reads the temp .part file in 1MB chunks and appends to destfile.
#'
#' @param tmp_part Character. Path to the temp .part file with new content.
#' @param destfile Character. Path to the existing file to append to.
#'
#' @return NULL (called for side effects).
#'
#' @noRd
.http_append_partial <- function(tmp_part, destfile) {
  con_in <- file(tmp_part, "rb")
  con_out <- file(destfile, "ab")
  on.exit({
    close(con_in)
    close(con_out)
  }, add = TRUE)
  while (length(chunk <- readBin(con_in, "raw", n = 1048576L)) > 0) {
    writeBin(chunk, con_out)
  }
}


# ============================================================================
# Resumable HTTP download
# ============================================================================

#' Download a file via HTTP/HTTPS with resume support (internal)
#'
#' Like `.http_download()`, but resumes partial downloads using HTTP Range
#' headers. If a partial file exists at `destfile`, the download continues
#' from where it left off. Falls back to a full download if the server does
#' not support Range requests (HTTP 416).
#'
#' @param url Character. URL of the file to download.
#' @param destfile Character. Path to save the downloaded file.
#' @param retries Integer. Number of retry attempts. Default: 3.
#' @param timeout Integer. Download timeout in seconds. Default: 600.
#'
#' @return The destfile path (invisibly) on success.
#'   Throws an error on failure.
#'
#' @noRd
.http_download_resumable <- function(url, destfile, retries = 3L,
                                     timeout = 600L) {
  .retry_download_loop(
    url = url,
    destfile = destfile,
    retries = retries,
    download_fn = function(u, d) {
      existing_size <- if (file.exists(d)) file.size(d) else 0L
      if (existing_size > 0) {
        .http_resume_partial(u, d, existing_size, timeout)
      } else {
        curl::curl_download(
          u, d,
          handle = curl::new_handle(
            connecttimeout = 30, timeout = timeout, followlocation = TRUE
          ),
          quiet = TRUE
        )
        TRUE
      }
    },
    fail_msg = c(
      "Failed to download file after {retries} attempts.",
      "x" = "URL: {.url {url}}",
      "i" = "Check your internet connection."
    )
  )
}


# ============================================================================
# Concurrent HTTP downloads
# ============================================================================

#' Download multiple files concurrently via HTTP/HTTPS (internal)
#'
#' Wrapper around `curl::multi_download()` for downloading multiple files
#' concurrently over HTTP/HTTPS. Only for HTTP/HTTPS URLs (not FTP).
#'
#' @param urls Character vector. URLs to download.
#' @param destfiles Character vector. Destination file paths (same length as
#'   `urls`).
#' @param max_concurrent Integer. Maximum number of concurrent connections.
#'   Default: 6.
#' @param timeout Integer. Per-file download timeout in seconds. Default: 600.
#'
#' @return A data frame with columns `success` (logical), `url`, `destfile`,
#'   `status_code`, and `error` (character or NA). One row per URL.
#'
#' @noRd
.multi_download <- function(urls, destfiles, max_concurrent = 6L,
                            timeout = 600L) {
  stopifnot(length(urls) == length(destfiles))
  if (length(urls) == 0L) {
    return(data.frame(
      success = logical(0), url = character(0), destfile = character(0),
      status_code = integer(0), error = character(0),
      stringsAsFactors = FALSE
    ))
  }

  # ensure destination directories exist
  dest_dirs <- unique(dirname(destfiles))
  for (d in dest_dirs) {
    dir.create(d, recursive = TRUE, showWarnings = FALSE)
  }

  res <- curl::multi_download(
    urls = urls,
    destfiles = destfiles,
    multiplex = TRUE,
    timeout = timeout
  )

  data.frame(
    success = res$success,
    url = res$url,
    destfile = res$destfile,
    status_code = res$status_code,
    error = ifelse(is.na(res$error), NA_character_, as.character(res$error)),
    stringsAsFactors = FALSE
  )
}


# ============================================================================
# Consolidated download failure reporting
# ============================================================================

#' Report download failures as a single consolidated warning (internal)
#'
#' Replaces per-file warnings with a single summary warning listing all
#' failed downloads. Attaches the failed labels as the `"download_failures"`
#' attribute on the returned data so programmatic users can inspect them.
#'
#' @param data Data frame. The successfully downloaded and combined data.
#' @param failed_labels Character vector. Labels of the files that failed
#'   (e.g., `"AC 2022"`, `"DENG 2022"`). If empty, `data` is returned
#'   unchanged.
#' @param module_name Character. Module name for the warning message
#'   (e.g., `"SIM"`, `"SINAN"`).
#'
#' @return The input `data`, with `attr(data, "download_failures")` set
#'   to `failed_labels` when there are failures.
#'
#' @noRd
.report_download_failures <- function(data, failed_labels, module_name) {
  if (length(failed_labels) == 0L) return(data)
  n_failed <- length(failed_labels)
  cli::cli_warn(c(
    "!" = "{module_name}: {n_failed} file{?s} failed to download.",
    "i" = "Failed: {.val {failed_labels}}"
  ))
  attr(data, "download_failures") <- failed_labels
  data
}
