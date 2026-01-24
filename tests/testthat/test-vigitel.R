# tests for vigitel functions

test_that("vigitel_years returns expected years", {
  years <- vigitel_years()
  
  expect_type(years, "integer")
  expect_true(2006L %in% years)
  expect_true(2023L %in% years)
  expect_false(2022L %in% years)  # 2022 is not available
})

test_that("vigitel_base_url returns valid URL", {
  url <- vigitel_base_url()
  
  expect_type(url, "character")
  expect_match(url, "^https://")
  expect_match(url, "Vigitel")
})

test_that("vigitel_file_url builds correct URLs", {
  url_2023 <- vigitel_file_url(2023)
  url_2021 <- vigitel_file_url(2021)
  
  expect_match(url_2023, "\\.xlsx$")
  expect_match(url_2021, "\\.xls$")
  expect_match(url_2023, "2023")
})

test_that("vigitel_file_url errors for invalid years", {
  expect_error(vigitel_file_url(2022))
  expect_error(vigitel_file_url(2005))
  expect_error(vigitel_file_url(2030))
})

test_that("vigitel_info returns expected structure", {
  info <- vigitel_info()
  
  expect_type(info, "list")
  expect_true("name" %in% names(info))
  expect_true("years_available" %in% names(info))
  expect_true("weight_variable" %in% names(info))
  expect_equal(info$weight_variable, "pesorake")
})

test_that("vigitel_cache_dir creates directory", {
  dir <- vigitel_cache_dir()
  
  expect_type(dir, "character")
  expect_true(dir.exists(dir))
})
