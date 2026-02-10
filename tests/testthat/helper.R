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
