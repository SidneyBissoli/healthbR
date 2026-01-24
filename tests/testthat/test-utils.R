# tests for utility functions

test_that("list_sources returns tibble with expected columns", {
  sources <- list_sources()
  expect_s3_class(sources, "tbl_df")
  expect_true(all(c("source", "name", "status") %in% names(sources)))
})

test_that("list_sources includes vigitel", {
  sources <- list_sources()
  expect_true("vigitel" %in% sources$source)
})

test_that("list_sources shows vigitel as available", {
  sources <- list_sources()
  vigitel_row <- sources[sources$source == "vigitel", ]
  expect_equal(vigitel_row$status, "available")
})

test_that(".clean_names converts to snake_case", {
  result <- healthbR:::.clean_names(c("FirstName", "LAST NAME", "age.years"))
  expect_equal(result, c("firstname", "last_name", "age_years"))
})

test_that(".clean_names handles empty input", {
  result <- healthbR:::.clean_names(character(0))
  expect_equal(result, character(0))
})

test_that(".clean_names handles NA values", {
  result <- healthbR:::.clean_names(c("Name", NA, "Age"))
  expect_equal(length(result), 3)
})
