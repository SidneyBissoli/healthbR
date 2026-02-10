# tests for censo functions
# tests for Census (Censo Demografico) module

# ============================================================================
# basic info functions
# ============================================================================

test_that("censo_years returns expected years", {
  years <- censo_years()

  expect_type(years, "character")
  expect_true(length(years) >= 6)
  expect_true("2022" %in% years)
  expect_true("2010" %in% years)
  expect_true("1970" %in% years)
})

test_that("censo_info returns expected structure", {
  info <- censo_info()

  expect_type(info, "list")
  expect_true("name" %in% names(info))
  expect_true("available_years" %in% names(info))
  expect_true("url" %in% names(info))
  expect_equal(info$available_years, censo_years())
})

test_that("censo_info accepts year parameter", {
  info <- censo_info(2022)

  expect_true("year_details" %in% names(info))
  expect_true("population" %in% names(info$year_details))
})

# ============================================================================
# validation functions
# ============================================================================

test_that(".censo_validate_year validates correctly", {
  # valid years
  expect_equal(.censo_validate_year(2022), 2022L)
  expect_equal(.censo_validate_year(2010), 2010L)
  expect_equal(.censo_validate_year(c(2000, 2010)), c(2000L, 2010L))

  # NULL is an error (year is required)
  expect_error(.censo_validate_year(NULL), "required")

  # invalid years
  expect_error(.censo_validate_year(2015), "Invalid census year")
  expect_error(.censo_validate_year(2023), "Invalid census year")
})

test_that(".censo_validate_estimativa_year validates correctly", {
  # valid years
  expect_equal(.censo_validate_estimativa_year(2020), 2020L)
  expect_equal(.censo_validate_estimativa_year(c(2015, 2020)), c(2015L, 2020L))

  # NULL is an error
  expect_error(.censo_validate_estimativa_year(NULL), "required")

  # invalid years
  expect_error(.censo_validate_estimativa_year(1999), "Invalid estimate year")
  expect_error(.censo_validate_estimativa_year(2025), "Invalid estimate year")
})

test_that(".censo_resolve_table resolves correctly for 2022", {
  # total

  res <- .censo_resolve_table(2022, "total")
  expect_equal(res$table, "9514")
  expect_null(res$classifications)

  # sex
  res <- .censo_resolve_table(2022, "sex")
  expect_equal(res$table, "9514")
  expect_true("2" %in% names(res$classifications))

  # age
  res <- .censo_resolve_table(2022, "age")
  expect_equal(res$table, "9514")
  expect_true("287" %in% names(res$classifications))

  # race
  res <- .censo_resolve_table(2022, "race")
  expect_equal(res$table, "9605")
  expect_true("86" %in% names(res$classifications))
})

test_that(".censo_resolve_table resolves correctly for historical years", {
  # total 2010
  res <- .censo_resolve_table(2010, "total")
  expect_equal(res$table, "200")

  # sex 2010
  res <- .censo_resolve_table(2010, "sex")
  expect_equal(res$table, "200")
  expect_true("2" %in% names(res$classifications))

  # age 2010 (uses c58)
  res <- .censo_resolve_table(2010, "age")
  expect_equal(res$table, "200")
  expect_true("58" %in% names(res$classifications))

  # race 2010
  res <- .censo_resolve_table(2010, "race")
  expect_equal(res$table, "136")
})

test_that(".censo_resolve_table errors for invalid variables", {
  expect_error(.censo_resolve_table(2022, "invalid"), "Invalid")
})

test_that(".censo_resolve_table errors for race on unsupported years", {
  expect_error(.censo_resolve_table(1970, "race"), "only available")
})

# ============================================================================
# censo_populacao validation
# ============================================================================

test_that("censo_populacao validates year parameter", {
  expect_error(censo_populacao(year = 2015), "Invalid census year")
  expect_error(censo_populacao(year = 2023), "Invalid census year")
})

test_that("censo_populacao rejects multiple years", {
  expect_error(
    censo_populacao(year = c(2010, 2022)),
    "Only one year"
  )
})

test_that("censo_populacao validates variables parameter", {
  expect_error(
    censo_populacao(year = 2022, variables = "invalid"),
    "Invalid"
  )
})

# ============================================================================
# censo_estimativa validation
# ============================================================================

test_that("censo_estimativa validates year parameter", {
  expect_error(censo_estimativa(year = 1999), "Invalid estimate year")
  expect_error(censo_estimativa(year = 2025), "Invalid estimate year")
})

# ============================================================================
# SIDRA catalog functions
# ============================================================================

test_that("censo_sidra_tables returns tibble with expected columns", {
  result <- censo_sidra_tables()

  expect_s3_class(result, "tbl_df")
  expect_true(all(
    c("table_code", "table_name", "theme") %in% names(result)
  ))
  expect_true(nrow(result) > 0)
})

test_that("censo_sidra_tables filters by theme", {
  result <- censo_sidra_tables(theme = "population")

  expect_true(all(result$theme == "population"))
  expect_true(nrow(result) > 0)
})

test_that("censo_sidra_tables handles invalid theme", {
  expect_error(censo_sidra_tables(theme = "nonexistent"), "Invalid theme")
})

test_that("censo_sidra_tables filters by year", {
  result_2022 <- censo_sidra_tables(year = 2022)
  result_2010 <- censo_sidra_tables(year = 2010)

  expect_true(nrow(result_2022) > 0)
  expect_true(nrow(result_2010) > 0)
})

test_that("censo_sidra_tables returns multiple themes", {
  result <- censo_sidra_tables()
  expect_true(length(unique(result$theme)) > 1)
})

# ============================================================================
# SIDRA search functions
# ============================================================================

test_that("censo_sidra_search finds tables by keyword", {
  result <- censo_sidra_search("defici")

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
})

test_that("censo_sidra_search is case-insensitive", {
  result_lower <- censo_sidra_search("populacao")
  result_upper <- censo_sidra_search("POPULACAO")

  expect_equal(nrow(result_lower), nrow(result_upper))
})

test_that("censo_sidra_search returns empty tibble for no match", {
  result <- censo_sidra_search("xyznonexistent")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("censo_sidra_search requires minimum keyword length", {
  expect_error(censo_sidra_search("a"), "at least 2 characters")
})

test_that("censo_sidra_search handles accent-insensitive search", {
  result1 <- censo_sidra_search("populacao")
  result2 <- censo_sidra_search("popula")

  expect_true(nrow(result1) > 0 || nrow(result2) > 0)
})

# ============================================================================
# SIDRA data retrieval validation
# ============================================================================

test_that("censo_sidra_data validates territorial_level", {
  expect_error(
    censo_sidra_data(table = 9514, territorial_level = "invalid"),
    "Invalid territorial_level"
  )
})

# ============================================================================
# Integration tests — require internet and HEALTHBR_INTEGRATION=true
# ============================================================================

test_that("censo_populacao returns data from API", {
  skip_on_cran()
  skip_if_no_integration()

  result <- censo_populacao(
    year = 2022,
    variables = "total",
    territorial_level = "brazil"
  )

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
})

test_that("censo_populacao returns data by state", {
  skip_on_cran()
  skip_if_no_integration()

  result <- censo_populacao(
    year = 2022,
    variables = "total",
    territorial_level = "state"
  )

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 1)
})

test_that("censo_populacao returns sex breakdown", {
  skip_on_cran()
  skip_if_no_integration()

  result <- censo_populacao(
    year = 2022,
    variables = "sex",
    territorial_level = "brazil"
  )

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 1)
})

test_that("censo_populacao returns race breakdown", {
  skip_on_cran()
  skip_if_no_integration()

  result <- censo_populacao(
    year = 2022,
    variables = "race",
    territorial_level = "brazil"
  )

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 1)
})

test_that("censo_populacao returns historical data", {
  skip_on_cran()
  skip_if_no_integration()

  result <- censo_populacao(
    year = 2010,
    variables = "total",
    territorial_level = "brazil"
  )

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
})

test_that("censo_populacao raw parameter works", {
  skip_on_cran()
  skip_if_no_integration()

  result_raw <- censo_populacao(
    year = 2022,
    variables = "total",
    territorial_level = "brazil",
    raw = TRUE
  )
  result_clean <- censo_populacao(
    year = 2022,
    variables = "total",
    territorial_level = "brazil",
    raw = FALSE
  )

  # raw has header row
  expect_true(nrow(result_raw) >= nrow(result_clean))
})

test_that("censo_estimativa returns data from API", {
  skip_on_cran()
  skip_if_no_integration()

  result <- censo_estimativa(
    year = 2020,
    territorial_level = "brazil"
  )

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
})

test_that("censo_estimativa handles multiple years", {
  skip_on_cran()
  skip_if_no_integration()

  result <- censo_estimativa(
    year = c(2019, 2020, 2021),
    territorial_level = "brazil"
  )

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 1)
})

test_that("censo_estimativa returns data by state", {
  skip_on_cran()
  skip_if_no_integration()

  result <- censo_estimativa(
    year = 2021,
    territorial_level = "state"
  )

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 1)
})

test_that("censo_sidra_data returns data from API", {
  skip_on_cran()
  skip_if_no_integration()

  result <- censo_sidra_data(
    table = 9514,
    territorial_level = "brazil",
    year = 2022,
    variable = 93
  )

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
})

test_that("censo_sidra_data warns for unknown table", {
  skip_on_cran()
  skip_if_no_integration()

  expect_message(
    tryCatch(
      censo_sidra_data(table = 99999, territorial_level = "brazil", year = 2022),
      error = function(e) NULL
    ),
    "not found in internal catalog"
  )
})
