test_that("vigitel_years returns integer vector", {
  years <- vigitel_years()
  expect_type(years, "integer")
  expect_true(length(years) > 0)
  expect_true(2006 %in% years)
  expect_true(2023 %in% years)
})

test_that("vigitel_variables returns tibble", {
  skip_on_cran()
  vars <- vigitel_variables()
  expect_s3_class(vars, "tbl_df")
})

test_that("vigitel_variables validates year", {
  expect_error(
    vigitel_variables(year = 1990),
    "not available"
  )
  expect_error(
    vigitel_variables(year = 2050),
    "not available"
  )
})

test_that("vigitel_dictionary returns tibble", {
  skip_on_cran()

  # Without arguments
  dict_list <- vigitel_dictionary()
  expect_s3_class(dict_list, "tbl_df")
  expect_true("year" %in% names(dict_list))
})

test_that("vigitel_dictionary validates year", {
  expect_error(
    vigitel_dictionary(year = 1990),
    "not available"
  )
})

test_that("vigitel_data validates years", {
  expect_error(
    vigitel_data(years = 1990),
    "not available"
  )
  expect_error(
    vigitel_data(years = c(2020, 1990)),
    "not available"
  )
})
