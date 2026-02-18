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


# ============================================================================
# ADDITIONAL COVERAGE TESTS
# ============================================================================

# --- censo_info --- additional coverage ---

test_that("censo_info returns invisible list", {

  result <- censo_info()
  expect_type(result, "list")
  expect_true("institution" %in% names(result))
  expect_true("description" %in% names(result))
  expect_true("sidra_url" %in% names(result))
  expect_true("citation" %in% names(result))
})

test_that("censo_info with invalid year has no year_details", {
  info <- censo_info(9999)
  expect_false("year_details" %in% names(info))
})

test_that("censo_info with year 2010 returns year_details", {
  info <- censo_info(2010)
  expect_true("year_details" %in% names(info))
  expect_true("population" %in% names(info$year_details))
  expect_true("notes" %in% names(info$year_details))
})

test_that("censo_info with each valid year returns year_details", {
  for (yr in c(1970, 1980, 1991, 2000, 2010, 2022)) {
    info <- censo_info(yr)
    expect_true("year_details" %in% names(info),
                info = paste("year_details missing for", yr))
  }
})

# --- censo_years --- additional coverage ---

test_that("censo_years returns correct number of years", {
  years <- censo_years()
  expect_equal(length(years), 6)
  expect_equal(years, c("1970", "1980", "1991", "2000", "2010", "2022"))
})

# --- .censo_validate_year --- additional coverage ---

test_that(".censo_validate_year converts to integer", {
  result <- .censo_validate_year("2022")
  expect_type(result, "integer")
  expect_equal(result, 2022L)
})

test_that(".censo_validate_year validates all valid years", {
  all_valid <- c(1970, 1980, 1991, 2000, 2010, 2022)
  result <- .censo_validate_year(all_valid)
  expect_equal(result, as.integer(all_valid))
})

# --- .censo_validate_estimativa_year --- additional coverage ---

test_that(".censo_validate_estimativa_year converts to integer", {
  result <- .censo_validate_estimativa_year("2015")
  expect_type(result, "integer")
  expect_equal(result, 2015L)
})

test_that(".censo_validate_estimativa_year accepts boundary years", {
  expect_equal(.censo_validate_estimativa_year(2001), 2001L)
  expect_equal(.censo_validate_estimativa_year(2021), 2021L)
})

test_that(".censo_validate_estimativa_year rejects boundary + 1", {
  expect_error(.censo_validate_estimativa_year(2000), "Invalid estimate year")
  expect_error(.censo_validate_estimativa_year(2022), "Invalid estimate year")
})

# --- .censo_resolve_table --- additional coverage ---

test_that(".censo_resolve_table resolves age_sex for 2022", {
  res <- .censo_resolve_table(2022, "age_sex")
  expect_equal(res$table, "9514")
  expect_true("2" %in% names(res$classifications))
  expect_true("287" %in% names(res$classifications))
})

test_that(".censo_resolve_table resolves age_sex for historical years", {
  res <- .censo_resolve_table(2010, "age_sex")
  expect_equal(res$table, "200")
  expect_true("2" %in% names(res$classifications))
  expect_true("58" %in% names(res$classifications))
})

test_that(".censo_resolve_table resolves situation for 2022", {
  res <- .censo_resolve_table(2022, "situation")
  expect_equal(res$table, "9515")
  expect_true("1" %in% names(res$classifications))
})

test_that(".censo_resolve_table resolves situation for historical years", {
  res <- .censo_resolve_table(2010, "situation")
  expect_equal(res$table, "200")
  expect_true("1" %in% names(res$classifications))
})

test_that(".censo_resolve_table errors for race on 1980", {
  expect_error(.censo_resolve_table(1980, "race"), "only available")
})

test_that(".censo_resolve_table race works for 2000", {
  res <- .censo_resolve_table(2000, "race")
  expect_equal(res$table, "136")
  expect_true("86" %in% names(res$classifications))
})

test_that(".censo_resolve_table result has variable field", {
  res <- .censo_resolve_table(2022, "total")
  expect_equal(res$variable, "93")
})

# --- .censo_fetch_sidra --- validation ---

test_that(".censo_fetch_sidra errors on invalid territorial_level", {
  expect_error(
    .censo_fetch_sidra("9514", "invalid_level", "all", "93", "2022", NULL),
    "Invalid territorial_level"
  )
})

# --- .censo_clean_populacao --- empty input ---

test_that(".censo_clean_populacao returns empty tibble for empty input", {
  empty_tbl <- tibble::tibble()
  # clean_sidra_response returns empty tibble for <= 1 row
  result <- .censo_clean_populacao(tibble::tibble(V = "header"), "200")
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

# --- .censo_clean_estimativa --- empty input ---

test_that(".censo_clean_estimativa returns empty tibble for empty input", {
  result <- .censo_clean_estimativa(tibble::tibble(V = "header"), "6579")
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

# --- censo_sidra_tables --- additional coverage ---

test_that("censo_sidra_tables filters by multiple themes", {
  result <- censo_sidra_tables(theme = c("population", "race"))
  expect_true(all(result$theme %in% c("population", "race")))
  expect_true(nrow(result) >= 4)
})

test_that("censo_sidra_tables year filter returns subset", {
  all_tables <- censo_sidra_tables()
  tables_1970 <- censo_sidra_tables(year = 1970)
  expect_true(nrow(tables_1970) < nrow(all_tables))
})

test_that("censo_sidra_tables year=2022 includes quilombola", {
  result <- censo_sidra_tables(year = 2022)
  expect_true("quilombola" %in% result$theme)
})

# --- censo_sidra_search --- additional coverage ---

test_that("censo_sidra_search with year filter", {
  result <- censo_sidra_search("populacao", year = 2022)
  expect_s3_class(result, "tbl_df")
  # should have results since population tables have 2022 data
  expect_true(nrow(result) > 0)
})

test_that("censo_sidra_search with NULL keyword errors", {
  expect_error(censo_sidra_search(NULL), "at least 2 characters")
})

test_that("censo_sidra_search with missing keyword errors", {
  expect_error(censo_sidra_search(), "at least 2 characters")
})

# --- censo_populacao --- additional validation ---

test_that("censo_populacao validates variables case-insensitively", {
  # Mock the SIDRA fetch to avoid real API calls
  local_mocked_bindings(
    .censo_fetch_sidra = function(...) tibble::tibble(V = c("header", "100"), D1C = c("h", "1"))
  )
  # "Total" should be lowered to "total" and accepted
  result <- censo_populacao(year = 2022, variables = "Total",
                            territorial_level = "brazil")
  expect_s3_class(result, "tbl_df")
})

# --- censo_sidra_data --- additional coverage ---

test_that("censo_sidra_data handles NULL year", {
  local_mocked_bindings(
    .censo_fetch_sidra = function(table, territorial_level, geo_code,
                                  variable, period, classifications) {
      # period should be NULL when year is NULL
      expect_null(period)
      tibble::tibble(V = c("header", "100"), D1C = c("h", "1"))
    }
  )
  result <- censo_sidra_data(table = 9514, territorial_level = "brazil",
                              year = NULL, variable = 93)
  expect_s3_class(result, "tbl_df")
})

test_that("censo_sidra_data handles NULL variable", {
  local_mocked_bindings(
    .censo_fetch_sidra = function(table, territorial_level, geo_code,
                                  variable, period, classifications) {
      # variable should be NULL when not specified
      expect_null(variable)
      tibble::tibble(V = c("header", "100"), D1C = c("h", "1"))
    }
  )
  result <- censo_sidra_data(table = 9514, territorial_level = "brazil",
                              year = 2022)
  expect_s3_class(result, "tbl_df")
})

test_that("censo_sidra_data raw=TRUE returns raw data", {
  mock_raw <- tibble::tibble(V = c("header", "100"), D1C = c("h", "1"))
  local_mocked_bindings(
    .censo_fetch_sidra = function(...) mock_raw
  )
  result <- censo_sidra_data(table = 9514, territorial_level = "brazil",
                              year = 2022, raw = TRUE)
  expect_equal(result, mock_raw)
})

test_that("censo_sidra_data returns empty tibble for empty API response", {
  local_mocked_bindings(
    .censo_fetch_sidra = function(...) tibble::tibble()
  )
  result <- censo_sidra_data(table = 9514, territorial_level = "brazil",
                              year = 2022)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

# --- censo_populacao --- additional mocked tests ---

test_that("censo_populacao raw=TRUE returns raw data", {
  mock_raw <- tibble::tibble(V = c("header", "100"), D1C = c("h", "1"))
  local_mocked_bindings(
    .censo_fetch_sidra = function(...) mock_raw
  )
  result <- censo_populacao(year = 2022, variables = "total",
                            territorial_level = "brazil", raw = TRUE)
  expect_equal(result, mock_raw)
})

test_that("censo_populacao returns empty tibble when API returns no data", {
  local_mocked_bindings(
    .censo_fetch_sidra = function(...) tibble::tibble()
  )
  result <- censo_populacao(year = 2022, variables = "total",
                            territorial_level = "brazil")
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

# --- censo_estimativa --- additional mocked tests ---

test_that("censo_estimativa raw=TRUE returns raw data", {
  mock_raw <- tibble::tibble(V = c("header", "100"), D1C = c("h", "1"))
  local_mocked_bindings(
    .censo_fetch_sidra = function(...) mock_raw
  )
  result <- censo_estimativa(year = 2020, territorial_level = "brazil",
                              raw = TRUE)
  expect_equal(result, mock_raw)
})

test_that("censo_estimativa returns empty tibble when API returns no data", {
  local_mocked_bindings(
    .censo_fetch_sidra = function(...) tibble::tibble()
  )
  result <- censo_estimativa(year = 2020, territorial_level = "brazil")
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})
