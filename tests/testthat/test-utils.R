test_that("list_sources returns tibble with expected columns", {
  sources <- list_sources()
  expect_s3_class(sources, "tbl_df")
  expect_true(all(c("source", "name", "status") %in% names(sources)))
})

test_that("list_sources includes vigitel", {
  sources <- list_sources()
  expect_true("vigitel" %in% sources$source)
})

test_that(".clean_names converts to snake_case", {
  expect_equal(
    healthbR:::.clean_names(c("FirstName", "LAST NAME", "age.years")),
    c("firstname", "last_name", "age_years")
  )
})
