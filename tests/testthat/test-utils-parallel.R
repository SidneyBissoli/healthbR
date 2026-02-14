# tests for shared parallel processing utilities (utils-parallel.R)

# ============================================================================
# .map_parallel
# ============================================================================

test_that(".map_parallel returns same results as purrr::map", {
  result <- healthbR:::.map_parallel(1:5, function(x) x * 2)
  expected <- purrr::map(1:5, function(x) x * 2)
  expect_equal(result, expected)
})

test_that(".map_parallel works with character input", {
  result <- healthbR:::.map_parallel(c("a", "b", "c"), toupper)
  expect_equal(result, list("A", "B", "C"))
})

test_that(".map_parallel works with empty input", {
  result <- healthbR:::.map_parallel(list(), identity)
  expect_equal(result, list())
})

test_that(".map_parallel works with single element", {
  result <- healthbR:::.map_parallel(list(42), function(x) x + 1)
  expect_equal(result, list(43))
})

test_that(".map_parallel passes extra arguments to .f", {
  add_n <- function(x, n) x + n
  result <- healthbR:::.map_parallel(1:3, add_n, n = 10)
  expect_equal(result, list(11, 12, 13))
})

test_that(".map_parallel preserves names", {
  input <- list(a = 1, b = 2, c = 3)
  result <- healthbR:::.map_parallel(input, function(x) x * 2)
  expect_named(result, c("a", "b", "c"))
})

test_that(".map_parallel returns a list", {
  result <- healthbR:::.map_parallel(1:3, identity)
  expect_type(result, "list")
  expect_length(result, 3)
})

test_that(".map_parallel uses sequential when furrr not configured", {
  # by default (no future::plan set), should use purrr fallback

  result <- healthbR:::.map_parallel(1:3, function(x) x^2)
  expect_equal(result, list(1, 4, 9))
})
