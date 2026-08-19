# helper functions for tests

# skip if no internet connection
skip_if_offline <- function() {
  tryCatch(
    {
      con <- url("https://svs.aids.gov.br", "r")
      close(con)
    },
    error = function(e) {
      skip("No internet connection available")
    }
  )
}

# skip integration tests that download large files
# Set HEALTHBR_INTEGRATION=true to run these tests:
#   Sys.setenv(HEALTHBR_INTEGRATION = "true")
#   devtools::check()
skip_if_no_integration <- function() {
  if (!identical(Sys.getenv("HEALTHBR_INTEGRATION"), "true")) {
    skip("Integration tests skipped. Set HEALTHBR_INTEGRATION=true to run.")
  }
  skip_if_offline()
}


# skip if an external test service (e.g. httpbin.org) is unreachable --
# skip_if_offline() only probes general connectivity, not the service itself
skip_if_service_down <- function(url) {
  ok <- tryCatch({
    h <- curl::new_handle(nobody = TRUE, timeout = 10, followlocation = TRUE)
    r <- curl::curl_fetch_memory(url, handle = h)
    r$status_code < 500
  }, error = function(e) FALSE)
  if (!ok) {
    testthat::skip(paste0("External service unreachable: ", url))
  }
}
