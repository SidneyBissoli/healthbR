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

# ============================================================================
# .delay parameter
# ============================================================================

test_that(".map_parallel with .delay returns correct results", {
  result <- healthbR:::.map_parallel(1:4, function(x) x * 10, .delay = 0.01)
  expect_equal(result, list(10, 20, 30, 40))
})

test_that(".map_parallel with .delay actually sleeps", {
  elapsed <- system.time({
    healthbR:::.map_parallel(1:3, identity, .delay = 0.2)
  })[["elapsed"]]
  # 2 delays of 0.2s each (no delay before first element)
  expect_gte(elapsed, 0.3)
})

test_that(".map_parallel with .delay skips sleep for single element", {
  elapsed <- system.time({
    healthbR:::.map_parallel(list(1), identity, .delay = 1)
  })[["elapsed"]]
  expect_lt(elapsed, 0.5)
})

test_that(".map_parallel with .delay skips sleep for empty input", {
  elapsed <- system.time({
    result <- healthbR:::.map_parallel(list(), identity, .delay = 1)
  })[["elapsed"]]
  expect_equal(result, list())
  expect_lt(elapsed, 0.5)
})

test_that(".map_parallel with .delay passes extra arguments", {
  add_n <- function(x, n) x + n
  result <- healthbR:::.map_parallel(1:3, add_n, n = 100, .delay = 0.01)
  expect_equal(result, list(101, 102, 103))
})

test_that(".map_parallel with .delay = NULL behaves like no delay", {
  result <- healthbR:::.map_parallel(1:3, function(x) x + 1, .delay = NULL)
  expect_equal(result, list(2, 3, 4))
})

test_that(".map_parallel with .delay = 0 behaves like no delay", {
  result <- healthbR:::.map_parallel(1:3, function(x) x + 1, .delay = 0)
  expect_equal(result, list(2, 3, 4))
})
