# Tests for shared validation helpers in utils-validate.R

# ============================================================================
# .validate_year
# ============================================================================

test_that(".validate_year errors on NULL", {
  expect_error(.validate_year(NULL, 2020:2024), "year")
})

test_that(".validate_year errors on empty vector", {
  expect_error(.validate_year(integer(0), 2020:2024), "year")
})

test_that(".validate_year accepts valid years", {
  expect_equal(.validate_year(2022, 2020:2024), 2022L)
  expect_equal(.validate_year(c(2020, 2022), 2020:2024), c(2020L, 2022L))
})

test_that(".validate_year coerces to integer", {
  expect_equal(.validate_year(2022.5, 2020:2024), 2022L)
  expect_equal(.validate_year("2022", 2020:2024), 2022L)
})

test_that(".validate_year errors on invalid years", {
  expect_error(.validate_year(1999, 2020:2024), "not available")
  expect_error(.validate_year(c(2020, 1999), 2020:2024), "not available")
})

test_that(".validate_year includes hint in error when provided", {
  expect_error(
    .validate_year(1999, 2020:2024, years_fn_hint = "my_years()"),
    "my_years"
  )
})

test_that(".validate_year omits hint when not provided", {
  tryCatch(
    .validate_year(1999, 2020:2024),
    error = function(e) {
      expect_false(grepl("Use", conditionMessage(e)))
    }
  )
})

test_that(".validate_year shows available range in error", {
  expect_error(.validate_year(1999, 2020:2024), "2020")
  expect_error(.validate_year(1999, 2020:2024), "2024")
})


# ============================================================================
# .validate_month
# ============================================================================

test_that(".validate_month returns 1:12 for NULL", {
  expect_equal(.validate_month(NULL), 1L:12L)
})

test_that(".validate_month accepts valid months", {
  expect_equal(.validate_month(1), 1L)
  expect_equal(.validate_month(12), 12L)
  expect_equal(.validate_month(c(1, 6, 12)), c(1L, 6L, 12L))
})

test_that(".validate_month coerces to integer", {
  expect_equal(.validate_month(6.5), 6L)
})

test_that(".validate_month errors on invalid months", {
  expect_error(.validate_month(0), "Invalid")
  expect_error(.validate_month(13), "Invalid")
  expect_error(.validate_month(-1), "Invalid")
})

test_that(".validate_month errors on mixed valid/invalid", {
  expect_error(.validate_month(c(1, 13)), "Invalid")
})

test_that(".validate_month errors on NA", {
  expect_error(.validate_month(NA), "Invalid")
})

test_that(".validate_month boundary checks", {
  expect_equal(.validate_month(1), 1L)
  expect_equal(.validate_month(12), 12L)
  expect_error(.validate_month(0), "Invalid")
  expect_error(.validate_month(13), "Invalid")
})


# ============================================================================
# .validate_uf
# ============================================================================

test_that(".validate_uf accepts valid UFs", {
  valid <- c("AC", "SP", "RJ")
  expect_equal(.validate_uf("AC", valid), "AC")
  expect_equal(.validate_uf(c("AC", "SP"), valid), c("AC", "SP"))
})

test_that(".validate_uf is case insensitive", {
  valid <- c("AC", "SP", "RJ")
  expect_equal(.validate_uf("ac", valid), "AC")
  expect_equal(.validate_uf("sp", valid), "SP")
  expect_equal(.validate_uf(c("ac", "rj"), valid), c("AC", "RJ"))
})

test_that(".validate_uf errors on invalid UFs", {
  valid <- c("AC", "SP", "RJ")
  expect_error(.validate_uf("XX", valid), "Invalid")
  expect_error(.validate_uf(c("AC", "XX"), valid), "Invalid")
})

test_that(".validate_uf error shows valid values", {
  valid <- c("AC", "SP", "RJ")
  expect_error(.validate_uf("XX", valid), "AC")
})
