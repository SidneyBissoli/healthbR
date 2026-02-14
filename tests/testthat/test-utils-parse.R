# tests for utils-parse.R — shared column type parsing utilities

# ============================================================================
# .convert_column
# ============================================================================

test_that(".convert_column handles character type (no-op)", {
  x <- c("abc", "def", NA)
  result <- .convert_column(x, "character")
  expect_identical(result, x)
})

test_that(".convert_column converts to integer", {
  x <- c("1", "2", "3", NA, "")
  result <- .convert_column(x, "integer")
  expect_type(result, "integer")
  expect_equal(result[1:3], c(1L, 2L, 3L))
  expect_true(is.na(result[4]))
  expect_true(is.na(result[5]))
})

test_that(".convert_column converts to double", {
  x <- c("1.5", "2.7", "3.0", NA, "")
  result <- .convert_column(x, "double")
  expect_type(result, "double")
  expect_equal(result[1:3], c(1.5, 2.7, 3.0))
  expect_true(is.na(result[4]))
  expect_true(is.na(result[5]))
})

test_that(".convert_column handles invalid numeric gracefully", {
  x <- c("abc", "123", "")
  result <- .convert_column(x, "integer")
  expect_true(is.na(result[1]))
  expect_equal(result[2], 123L)
  expect_true(is.na(result[3]))
})

test_that(".convert_column converts date_dmy", {
  x <- c("25122022", "01012020", NA, "")
  result <- .convert_column(x, "date_dmy")
  expect_s3_class(result, "Date")
  expect_equal(result[1], as.Date("2022-12-25"))
  expect_equal(result[2], as.Date("2020-01-01"))
  expect_true(is.na(result[3]))
  expect_true(is.na(result[4]))
})

test_that(".convert_column converts date_ymd", {
  x <- c("20221225", "20200101", NA, "")
  result <- .convert_column(x, "date_ymd")
  expect_s3_class(result, "Date")
  expect_equal(result[1], as.Date("2022-12-25"))
  expect_equal(result[2], as.Date("2020-01-01"))
  expect_true(is.na(result[3]))
  expect_true(is.na(result[4]))
})

test_that(".convert_column converts date_ym", {
  x <- c("202212", "202001", NA, "")
  result <- .convert_column(x, "date_ym")
  expect_s3_class(result, "Date")
  expect_equal(result[1], as.Date("2022-12-01"))
  expect_equal(result[2], as.Date("2020-01-01"))
  expect_true(is.na(result[3]))
  expect_true(is.na(result[4]))
})

test_that(".convert_column converts date (ISO)", {
  x <- c("2022-12-25", "2020-01-01", NA, "")
  result <- .convert_column(x, "date")
  expect_s3_class(result, "Date")
  expect_equal(result[1], as.Date("2022-12-25"))
  expect_equal(result[2], as.Date("2020-01-01"))
  expect_true(is.na(result[3]))
  expect_true(is.na(result[4]))
})

test_that(".convert_column normalizes whitespace to NA", {
  x <- c("  ", "\t", " 123 ")
  result_int <- .convert_column(x, "integer")
  expect_true(is.na(result_int[1]))
  expect_true(is.na(result_int[2]))
  # " 123 " should still convert (trimming isn't needed for as.integer)
  expect_equal(result_int[3], 123L)
})

test_that(".convert_column warns on unknown type", {
  x <- c("abc")
  expect_warning(
    result <- .convert_column(x, "unknown_type"),
    "Unknown type"
  )
  expect_equal(result, x)
})

# ============================================================================
# .build_type_spec
# ============================================================================

test_that(".build_type_spec extracts named vector", {
  meta <- tibble::tibble(
    variable = c("A", "B", "C"),
    description = c("desc1", "desc2", "desc3"),
    type = c("integer", "character", "date_dmy"),
    section = c("s1", "s1", "s2")
  )
  spec <- .build_type_spec(meta)
  expect_type(spec, "character")
  expect_named(spec, c("A", "B", "C"))
  expect_equal(unname(spec), c("integer", "character", "date_dmy"))
})

# ============================================================================
# .parse_columns
# ============================================================================

test_that(".parse_columns converts multiple columns", {
  data <- data.frame(
    A = c("1", "2", "3"),
    B = c("10.5", "20.3", "30.1"),
    C = c("abc", "def", "ghi"),
    stringsAsFactors = FALSE
  )
  spec <- c(A = "integer", B = "double", C = "character")
  result <- .parse_columns(data, spec)

  expect_type(result$A, "integer")
  expect_type(result$B, "double")
  expect_type(result$C, "character")
  expect_equal(result$A, c(1L, 2L, 3L))
  expect_equal(result$B, c(10.5, 20.3, 30.1))
})

test_that(".parse_columns applies col_types overrides", {
  data <- data.frame(
    A = c("1", "2", "3"),
    B = c("10.5", "20.3", "30.1"),
    stringsAsFactors = FALSE
  )
  spec <- c(A = "integer", B = "double")
  result <- .parse_columns(data, spec, col_types = list(A = "character"))

  # A should remain character due to override
  expect_type(result$A, "character")
  # B should still be double
  expect_type(result$B, "double")
})

test_that(".parse_columns ignores columns not in data", {
  data <- data.frame(A = c("1", "2"), stringsAsFactors = FALSE)
  spec <- c(A = "integer", MISSING = "double")
  result <- .parse_columns(data, spec)
  expect_type(result$A, "integer")
  expect_false("MISSING" %in% names(result))
})

test_that(".parse_columns ignores columns not in spec", {
  data <- data.frame(
    A = c("1", "2"),
    EXTRA = c("x", "y"),
    stringsAsFactors = FALSE
  )
  spec <- c(A = "integer")
  result <- .parse_columns(data, spec)
  expect_type(result$A, "integer")
  expect_type(result$EXTRA, "character")
})

test_that(".parse_columns handles empty data frame", {
  data <- data.frame(A = character(0), B = character(0),
                     stringsAsFactors = FALSE)
  spec <- c(A = "integer", B = "double")
  result <- .parse_columns(data, spec)
  expect_equal(nrow(result), 0)
})

test_that(".parse_columns col_types can add new columns to spec", {
  data <- data.frame(
    A = c("1", "2"),
    B = c("x", "y"),
    stringsAsFactors = FALSE
  )
  spec <- c(A = "integer")
  # B is not in spec but user overrides it
  result <- .parse_columns(data, spec, col_types = list(B = "character"))
  expect_type(result$A, "integer")
  expect_type(result$B, "character")
})

# ============================================================================
# .parse_date helpers
# ============================================================================

test_that(".parse_date_dmy handles valid and invalid dates", {
  expect_equal(.parse_date_dmy("25122022"), as.Date("2022-12-25"))
  expect_true(is.na(.parse_date_dmy(NA)))
  expect_true(is.na(.parse_date_dmy("99999999")))
})

test_that(".parse_date_ymd handles valid and invalid dates", {
  expect_equal(.parse_date_ymd("20221225"), as.Date("2022-12-25"))
  expect_true(is.na(.parse_date_ymd(NA)))
})

test_that(".parse_date_ym handles valid dates", {
  expect_equal(.parse_date_ym("202212"), as.Date("2022-12-01"))
  expect_true(is.na(.parse_date_ym(NA)))
})

test_that(".parse_date_iso handles valid dates", {
  expect_equal(.parse_date_iso("2022-12-25"), as.Date("2022-12-25"))
  expect_true(is.na(.parse_date_iso(NA)))
})
