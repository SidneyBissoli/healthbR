# dbc infrastructure for healthbR package
# shared functions for reading DATASUS .dbc files
# used by SIM, SIH, SINASC, CNES, and other DATASUS modules

# ============================================================================
# .dbc2dbf - decompress .dbc to .dbf
# ============================================================================

#' Decompress a .dbc file to .dbf (internal)
#'
#' Calls the vendored C code (blast library) to decompress a DATASUS .dbc
#' file into a standard .dbf file.
#'
#' @param input_file Character. Path to the input .dbc file.
#' @param output_file Character. Path to the output .dbf file.
#'
#' @return Logical. TRUE if decompression succeeded, FALSE otherwise.
#'
#' @noRd
.dbc2dbf <- function(input_file, output_file) {
  if (!file.exists(input_file)) {
    cli::cli_abort("File not found: {.file {input_file}}")
  }

  result <- .C(
    "healthbR_dbc2dbf",
    input = as.character(normalizePath(input_file, mustWork = TRUE)),
    output = as.character(path.expand(output_file)),
    ret_code = as.integer(0L),
    error_str = as.character("")
  )

  if (result$ret_code != 0L) {
    cli::cli_warn(c(
      "DBC decompression failed.",
      "x" = "Error: {result$error_str}",
      "i" = "File: {.file {input_file}}"
    ))
    return(FALSE)
  }

  file.exists(output_file) && file.size(output_file) > 0
}


# ============================================================================
# .read_dbc - read a .dbc file into a tibble
# ============================================================================

#' Read a .dbc file into a tibble (internal)
#'
#' Decompresses a DATASUS .dbc file to a temporary .dbf, reads it with
#' foreign::read.dbf(), and converts all columns to character for safety.
#'
#' @param file Character. Path to the .dbc file.
#'
#' @return A tibble with all columns as character.
#'
#' @noRd
.read_dbc <- function(file) {
  if (!file.exists(file)) {
    cli::cli_abort("File not found: {.file {file}}")
  }

  # create temporary .dbf file
  temp_dbf <- tempfile(fileext = ".dbf")
  on.exit(if (file.exists(temp_dbf)) file.remove(temp_dbf), add = TRUE)

  # decompress .dbc to .dbf
  success <- .dbc2dbf(file, temp_dbf)

  if (!success) {
    cli::cli_abort(c(
      "Failed to decompress .dbc file.",
      "x" = "File: {.file {file}}",
      "i" = "The file may be corrupted or in an unexpected format."
    ))
  }

  # read .dbf with foreign::read.dbf (returns data.frame)
  df <- foreign::read.dbf(temp_dbf, as.is = TRUE)

  # convert all columns to character (preserves leading zeros, etc.)
  df[] <- lapply(df, as.character)

  # return as tibble
  tibble::as_tibble(df)
}


# ============================================================================
# .datasus_download - download from DATASUS FTP with retry
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
