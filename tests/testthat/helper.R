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
