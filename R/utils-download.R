# Shared download utilities for healthbR
# Provides consistent download functions with retry logic for all modules

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
  for (i in seq_len(retries)) {
    result <- tryCatch({
      curl::curl_download(
        url, destfile,
        handle = curl::new_handle(
          connecttimeout = 30,
          timeout = timeout,
          ftp_use_epsv = FALSE
        ),
        quiet = TRUE
      )
      TRUE
    }, error = function(e) {
      if (i < retries) {
        wait_time <- 2^i
        cli::cli_inform(c(
          "i" = "Download attempt {i}/{retries} failed. Retrying in {wait_time}s...",
          "x" = "{e$message}"
        ))
        Sys.sleep(wait_time)
      }
      FALSE
    })

    if (isTRUE(result) && file.exists(destfile) && file.size(destfile) > 0) {
      return(invisible(destfile))
    }
  }

  # all retries failed
  if (file.exists(destfile)) file.remove(destfile)
  cli::cli_abort(c(
    "Failed to download file from DATASUS FTP after {retries} attempts.",
    "x" = "URL: {.url {url}}",
    "i" = "Check your internet connection.",
    "i" = "The DATASUS FTP server may be temporarily unavailable."
  ))
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
#'
#' @return The destfile path (invisibly) on success.
#'   Throws an error on failure.
#'
#' @noRd
.http_download <- function(url, destfile, retries = 3L, timeout = 300L,
                           quiet = TRUE) {
  for (i in seq_len(retries)) {
    result <- tryCatch({
      curl::curl_download(
        url, destfile,
        handle = curl::new_handle(
          connecttimeout = 30,
          timeout = timeout,
          followlocation = TRUE
        ),
        quiet = quiet
      )
      TRUE
    }, error = function(e) {
      if (i < retries) {
        wait_time <- 2^i
        cli::cli_inform(c(
          "i" = "Download attempt {i}/{retries} failed. Retrying in {wait_time}s...",
          "x" = "{e$message}"
        ))
        Sys.sleep(wait_time)
      }
      FALSE
    })

    if (isTRUE(result) && file.exists(destfile) && file.size(destfile) > 0) {
      return(invisible(destfile))
    }
  }

  # all retries failed
  if (file.exists(destfile)) file.remove(destfile)
  cli::cli_abort(c(
    "Failed to download file after {retries} attempts.",
    "x" = "URL: {.url {url}}",
    "i" = "Check your internet connection."
  ))
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
  for (i in seq_len(retries)) {
    existing_size <- if (file.exists(destfile)) file.size(destfile) else 0L

    result <- tryCatch({
      h <- curl::new_handle(
        connecttimeout = 30,
        timeout = timeout,
        followlocation = TRUE
      )

      if (existing_size > 0) {
        curl::handle_setopt(h, range = paste0(existing_size, "-"))
      }

      # use curl_fetch_disk for resume (appends when Range used)
      if (existing_size > 0) {
        # open file in append mode via temp + concatenation
        tmp_part <- tempfile(fileext = ".part")
        on.exit(if (file.exists(tmp_part)) file.remove(tmp_part), add = TRUE)
        resp <- curl::curl_fetch_disk(url, tmp_part, handle = h)

        if (resp$status_code == 416L) {
          # server doesn't support Range or file already complete
          # retry as full download
          if (file.exists(tmp_part)) file.remove(tmp_part)
          if (file.exists(destfile)) file.remove(destfile)
          curl::handle_setopt(h, range = NULL)
          curl::curl_download(url, destfile,
                              handle = curl::new_handle(
                                connecttimeout = 30, timeout = timeout,
                                followlocation = TRUE
                              ), quiet = TRUE)
          TRUE
        } else if (resp$status_code %in% c(200L, 206L)) {
          if (resp$status_code == 200L) {
            # server ignored Range, sent full file
            file.copy(tmp_part, destfile, overwrite = TRUE)
          } else {
            # 206 Partial Content: append to existing file
            con_in <- file(tmp_part, "rb")
            con_out <- file(destfile, "ab")
            on.exit(close(con_in), add = TRUE)
            on.exit(close(con_out), add = TRUE)
            while (length(chunk <- readBin(con_in, "raw", n = 1048576L)) > 0) {
              writeBin(chunk, con_out)
            }
            close(con_in)
            close(con_out)
            on.exit(NULL) # clear the close on.exit handlers
          }
          if (file.exists(tmp_part)) file.remove(tmp_part)
          TRUE
        } else {
          if (file.exists(tmp_part)) file.remove(tmp_part)
          FALSE
        }
      } else {
        curl::curl_download(url, destfile, handle = h, quiet = TRUE)
        TRUE
      }
    }, error = function(e) {
      if (i < retries) {
        wait_time <- 2^i
        cli::cli_inform(c(
          "i" = "Download attempt {i}/{retries} failed. Retrying in {wait_time}s...",
          "x" = "{e$message}"
        ))
        Sys.sleep(wait_time)
      }
      FALSE
    })

    if (isTRUE(result) && file.exists(destfile) && file.size(destfile) > 0) {
      return(invisible(destfile))
    }
  }

  # all retries failed
  if (file.exists(destfile)) file.remove(destfile)
  cli::cli_abort(c(
    "Failed to download file after {retries} attempts.",
    "x" = "URL: {.url {url}}",
    "i" = "Check your internet connection."
  ))
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
