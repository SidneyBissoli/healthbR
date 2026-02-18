# tests for pns functions
# tests for PNS (Pesquisa Nacional de Saude) module

# ============================================================================
# basic info functions
# ============================================================================

test_that("pns_years returns expected years", {
  years <- pns_years()

  expect_type(years, "character")
  expect_equal(length(years), 2L)
  expect_true("2013" %in% years)
  expect_true("2019" %in% years)
})

test_that("pns_info returns expected structure", {
  info <- pns_info()

  expect_type(info, "list")
  expect_true("name" %in% names(info))
  expect_true("available_years" %in% names(info))
  expect_true("sidra_tables" %in% names(info))
  expect_true("url" %in% names(info))
  expect_equal(info$available_years, pns_years())
  expect_equal(info$sidra_tables, 2222)
})

test_that("pns_info accepts year parameter", {
  info <- pns_info(2019)

  expect_true("year_details" %in% names(info))
  expect_true("sample_size" %in% names(info$year_details))
  expect_true("reference_period" %in% names(info$year_details))
})

# ============================================================================
# modules functions
# ============================================================================

test_that("pns_modules returns tibble with expected columns", {
  modules <- pns_modules()

  expect_s3_class(modules, "tbl_df")
  expect_true(all(c("module", "name", "name_en") %in% names(modules)))
  expect_true(nrow(modules) > 0)
})

test_that("pns_modules filters by year correctly", {
  modules_2013 <- pns_modules(year = 2013)
  modules_2019 <- pns_modules(year = 2019)
  modules_all <- pns_modules()

  expect_true(nrow(modules_2013) > 0)
  expect_true(nrow(modules_2019) > 0)
  # 2019 has Y and Z modules not in 2013
  expect_true("Y" %in% modules_2019$module)
  expect_true("Z" %in% modules_2019$module)
})

test_that("pns_modules validates year parameter", {
  expect_error(pns_modules(year = 1999), "Invalid year")
})

# ============================================================================
# dictionary and variables functions
# ============================================================================

test_that("pns_dictionary validates year parameter", {
  expect_error(
    pns_dictionary(year = 1999, cache_dir = tempdir()),
    "Invalid year"
  )
})

test_that("pns_dictionary downloads and returns tibble", {
  skip_on_cran()
  skip_if_no_integration()

  dict <- pns_dictionary(year = 2019, cache_dir = tempdir())

  expect_s3_class(dict, "tbl_df")
  expect_true(nrow(dict) > 0)
  expect_true("year" %in% names(dict))
})

test_that("pns_dictionary uses cache on second call", {
  skip_on_cran()
  skip_if_no_integration()

  test_cache <- file.path(tempdir(), "test_pns_dict_cache")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # first call downloads
  dict1 <- pns_dictionary(year = 2019, cache_dir = test_cache)

  # verify cache exists
  cache_files <- list.files(test_cache, pattern = "pns_dictionary_2019")
  expect_true(length(cache_files) > 0)

  # second call should use cache
  dict2 <- pns_dictionary(year = 2019, cache_dir = test_cache)

  expect_equal(nrow(dict1), nrow(dict2))
})

test_that("pns_variables returns tibble", {
  skip_on_cran()
  skip_if_no_integration()

  vars <- pns_variables(year = 2019, cache_dir = tempdir())

  expect_s3_class(vars, "tbl_df")
  expect_true(nrow(vars) > 0)
  expect_true("year" %in% names(vars))
})

# ============================================================================
# validation functions
# ============================================================================

test_that("validate_pns_year validates correctly", {
  # valid years
  expect_equal(validate_pns_year(2013), 2013L)
  expect_equal(validate_pns_year(2019), 2019L)
  expect_equal(validate_pns_year(c(2013, 2019)), c(2013L, 2019L))

  # NULL returns all
  expect_equal(validate_pns_year(NULL), c(2013L, 2019L))

  # invalid years
  expect_error(validate_pns_year(2015), "Invalid year")
  expect_error(validate_pns_year(2020), "Invalid year")
  expect_error(validate_pns_year(c(2013, 2020)), "Invalid year")
})

test_that("pns_data validates year parameter", {
  expect_error(
    pns_data(year = 1999, cache_dir = tempdir()),
    "Invalid year"
  )
  expect_error(
    pns_data(year = 2020, cache_dir = tempdir()),
    "Invalid year"
  )
})

# ============================================================================
# cache functions
# ============================================================================

test_that("pns_cache_dir creates directory", {
  dir <- pns_cache_dir()

  expect_type(dir, "character")
  expect_true(dir.exists(dir))
})

test_that("pns_cache_dir respects custom cache_dir", {
  custom_dir <- file.path(tempdir(), "custom_pns_cache")
  on.exit(unlink(custom_dir, recursive = TRUE), add = TRUE)

  dir <- pns_cache_dir(custom_dir)

  expect_true(dir.exists(dir))
  expect_match(dir, "pns")
})

test_that("pns_cache_status returns tibble", {
  status <- pns_cache_status()

  expect_s3_class(status, "tbl_df")
  expect_true(all(c("file", "size_mb", "modified") %in% names(status)))
})

test_that("pns_clear_cache handles empty cache", {
  temp_cache <- file.path(tempdir(), "empty_pns_test")
  on.exit(unlink(temp_cache, recursive = TRUE), add = TRUE)

  expect_no_error(pns_clear_cache(cache_dir = temp_cache))
})

# ============================================================================
# SIDRA functions - catalog
# ============================================================================

test_that("pns_sidra_tables returns tibble with expected columns", {
  result <- pns_sidra_tables()

  expect_s3_class(result, "tbl_df")
  expect_true(all(
    c("table_code", "table_name", "theme", "theme_label") %in% names(result)
  ))
  expect_true(nrow(result) > 0)
})

test_that("pns_sidra_tables filters by theme", {
  result <- pns_sidra_tables(theme = "chronic_diseases")

  expect_true(all(result$theme == "chronic_diseases"))
  expect_true(nrow(result) > 0)
})

test_that("pns_sidra_tables handles invalid theme", {
  expect_error(pns_sidra_tables(theme = "nonexistent"), "Invalid theme")
})

test_that("pns_sidra_tables filters by year", {
  result_2019 <- pns_sidra_tables(year = 2019)
  result_2013 <- pns_sidra_tables(year = 2013)

  expect_true(nrow(result_2019) > 0)
  expect_true(nrow(result_2013) > 0)
})

test_that("pns_sidra_tables returns multiple themes", {
  result <- pns_sidra_tables()
  expect_true(length(unique(result$theme)) > 1)
})

# ============================================================================
# SIDRA functions - search
# ============================================================================

test_that("pns_sidra_search finds tables by keyword", {
  result <- pns_sidra_search("diabetes")

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
})

test_that("pns_sidra_search is case-insensitive", {
  result_lower <- pns_sidra_search("diabetes")
  result_upper <- pns_sidra_search("DIABETES")

  expect_equal(nrow(result_lower), nrow(result_upper))
})

test_that("pns_sidra_search returns empty tibble for no match", {
  result <- pns_sidra_search("xyznonexistent")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("pns_sidra_search requires minimum keyword length", {
  expect_error(pns_sidra_search("a"), "at least 2 characters")
})

test_that("pns_sidra_search handles accent-insensitive search", {
  result1 <- pns_sidra_search("hipertensao")
  result2 <- pns_sidra_search("hipertens")

  expect_true(nrow(result1) > 0 || nrow(result2) > 0)
})

# ============================================================================
# SIDRA functions - data retrieval
# ============================================================================

test_that("pns_sidra_data validates territorial_level", {
  expect_error(
    pns_sidra_data(table = 4751, territorial_level = "invalid"),
    "Invalid territorial_level"
  )
})

test_that("pns_sidra_data returns tibble from API", {
  skip_on_cran()
  skip_if_no_integration()

  result <- pns_sidra_data(
    table = 4751,
    territorial_level = "brazil",
    year = 2019
  )

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
})

test_that("pns_sidra_data returns data by state", {
  skip_on_cran()
  skip_if_no_integration()

  result <- pns_sidra_data(
    table = 4751,
    territorial_level = "state",
    year = 2019
  )

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  # should have multiple rows (one per state or more)
  expect_true(nrow(result) > 1)
})

test_that("pns_sidra_data raw parameter works", {
  skip_on_cran()
  skip_if_no_integration()

  result_raw <- pns_sidra_data(
    table = 4751,
    territorial_level = "brazil",
    year = 2019,
    raw = TRUE
  )
  result_clean <- pns_sidra_data(
    table = 4751,
    territorial_level = "brazil",
    year = 2019,
    raw = FALSE
  )

  # raw has header row, so >= clean
  expect_true(nrow(result_raw) >= nrow(result_clean))
})

test_that("pns_sidra_data handles multiple years", {
  skip_on_cran()
  skip_if_no_integration()

  result <- pns_sidra_data(
    table = 4751,
    territorial_level = "brazil",
    year = c(2013, 2019)
  )

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
})

test_that("pns_sidra_data warns for unknown table", {
  skip_on_cran()
  skip_if_no_integration()

  # table 99999 should not exist in catalog - expect warning about catalog
  # and then an error from the API (invalid table)
  expect_warning(
    tryCatch(
      pns_sidra_data(table = 99999, territorial_level = "brazil", year = 2019),
      error = function(e) NULL
    ),
    "not found in internal catalog"
  )
})

# ============================================================================
# microdata download - integration tests
# ============================================================================

test_that("pns_data downloads and returns tibble", {
  skip_on_cran()
  skip_if_no_integration()

  test_cache <- file.path(tempdir(), "test_pns_download")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # test with 2019 (smaller file)
  df <- pns_data(year = 2019, cache_dir = test_cache)

  expect_s3_class(df, "tbl_df")
  expect_true(nrow(df) > 0)
  expect_true(ncol(df) > 0)
  expect_true("year" %in% names(df))
})

test_that("pns_data handles variable selection", {
  skip_on_cran()
  skip_if_no_integration()

  test_cache <- file.path(tempdir(), "test_pns_vars")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # get full data first
  df_full <- pns_data(year = 2019, cache_dir = test_cache)

  # select specific variables (make sure to pick fewer than total)
  all_vars <- setdiff(names(df_full), "year")
  vars_to_select <- head(all_vars, min(5, length(all_vars) - 1))

  df <- pns_data(
    year = 2019,
    vars = vars_to_select,
    cache_dir = test_cache
  )

  expect_true("year" %in% names(df))
  expect_true(all(toupper(vars_to_select) %in% names(df)))
  # should have year + selected vars = 6 columns (or fewer if data has < 6 vars)
  expect_equal(ncol(df), length(vars_to_select) + 1)  # +1 for year column
})

test_that("pns_data uses cache on second call", {
  skip_on_cran()
  skip_if_no_integration()

  test_cache <- file.path(tempdir(), "test_pns_cache_reuse")
  unlink(test_cache, recursive = TRUE)
  on.exit(unlink(test_cache, recursive = TRUE), add = TRUE)

  # first call downloads
  df1 <- pns_data(year = 2019, cache_dir = test_cache)

  # verify partitioned cache exists
  cache_files <- list.files(file.path(test_cache, "pns_data"),
                            recursive = TRUE, pattern = "\\.parquet$")
  expect_true(length(cache_files) > 0)

  # second call should use cache
  df2 <- pns_data(year = 2019, cache_dir = test_cache)

  expect_equal(nrow(df1), nrow(df2))
  expect_equal(ncol(df1), ncol(df2))
})

# ============================================================================
# additional unit tests for coverage (no HTTP downloads)
# ============================================================================

# ----------------------------------------------------------------------------
# pns_info() — year-specific branches
# ----------------------------------------------------------------------------

test_that("pns_info returns invisible list", {
  result <- pns_info()
  expect_type(result, "list")
  expect_false(is.null(result$name))
})

test_that("pns_info with year=2013 includes year_details", {
  info <- pns_info(2013)

  expect_true("year_details" %in% names(info))
  expect_equal(info$year_details$notes, "First edition of PNS")
  expect_true("sample_size" %in% names(info$year_details))
  expect_true("reference_period" %in% names(info$year_details))
  expect_true("modules" %in% names(info$year_details))
})

test_that("pns_info with year=2019 includes year_details", {
  info <- pns_info(2019)

  expect_true("year_details" %in% names(info))
  expect_equal(info$year_details$notes, "Second edition with expanded sample")
  expect_match(info$year_details$sample_size, "100,000")
})

test_that("pns_info with invalid year has no year_details", {
  info <- pns_info(9999)

  expect_false("year_details" %in% names(info))
})

test_that("pns_info invisible return contains expected fields", {
  info <- pns_info()

  expect_equal(info$name, "Pesquisa Nacional de Sa\u00fade (PNS)")
  expect_equal(info$name_en, "National Health Survey")
  expect_equal(info$institution, "IBGE - Instituto Brasileiro de Geografia e Estat\u00edstica")
  expect_equal(info$partner, "Minist\u00e9rio da Sa\u00fade")
  expect_equal(info$sidra_tables, 2222)
  expect_type(info$description, "character")
  expect_type(info$citation, "character")
})

# ----------------------------------------------------------------------------
# pns_years()
# ----------------------------------------------------------------------------

test_that("pns_years returns character vector of length 2", {
  years <- pns_years()
  expect_type(years, "character")
  expect_equal(years, c("2013", "2019"))
})

# ----------------------------------------------------------------------------
# pns_modules() — more branches
# ----------------------------------------------------------------------------

test_that("pns_modules returns all modules when year is NULL", {
  modules <- pns_modules()
  expect_s3_class(modules, "tbl_df")
  expect_true(nrow(modules) == 23)
  expect_equal(names(modules), c("module", "name", "name_en"))
})

test_that("pns_modules with both years returns all modules", {
  modules <- pns_modules(year = c(2013, 2019))
  expect_equal(nrow(modules), 23)
})

test_that("pns_modules 2013 excludes Y and Z modules", {
  modules_2013 <- pns_modules(year = 2013)
  expect_false("Y" %in% modules_2013$module)
  expect_false("Z" %in% modules_2013$module)
  # 2013 has D, H, I modules
  expect_true("D" %in% modules_2013$module)
})

test_that("pns_modules 2019 excludes D, H, I modules", {
  modules_2019 <- pns_modules(year = 2019)
  expect_false("D" %in% modules_2019$module)
  expect_false("H" %in% modules_2019$module)
  expect_false("I" %in% modules_2019$module)
  expect_true("Y" %in% modules_2019$module)
  expect_true("Z" %in% modules_2019$module)
})

# ----------------------------------------------------------------------------
# validate_pns_year()
# ----------------------------------------------------------------------------

test_that("validate_pns_year accepts numeric 2013", {
  expect_equal(validate_pns_year(2013), 2013L)
})

test_that("validate_pns_year accepts numeric 2019", {
  expect_equal(validate_pns_year(2019), 2019L)
})

test_that("validate_pns_year accepts character", {
  expect_equal(validate_pns_year("2013"), 2013L)
  expect_equal(validate_pns_year("2019"), 2019L)
})

test_that("validate_pns_year returns both when NULL", {
  expect_equal(validate_pns_year(NULL), c(2013L, 2019L))
})

test_that("validate_pns_year errors on single invalid", {
  expect_error(validate_pns_year(2000), "Invalid year")
})

test_that("validate_pns_year errors on mixed valid/invalid", {
  expect_error(validate_pns_year(c(2013, 2025)), "Invalid year")
})

test_that("validate_pns_year accepts vector of both valid years", {
  expect_equal(validate_pns_year(c(2013, 2019)), c(2013L, 2019L))
})

# ----------------------------------------------------------------------------
# pns_url_patterns constant
# ----------------------------------------------------------------------------

test_that("pns_url_patterns has correct structure", {
  patterns <- healthbR:::pns_url_patterns
  expect_type(patterns, "list")
  expect_true("2013" %in% names(patterns))
  expect_true("2019" %in% names(patterns))
  expect_true("base_url" %in% names(patterns))

  expect_true("data" %in% names(patterns[["2013"]]))
  expect_true("dict" %in% names(patterns[["2013"]]))
  expect_true("data" %in% names(patterns[["2019"]]))
  expect_true("dict" %in% names(patterns[["2019"]]))
})

test_that("pns_url_patterns URLs are valid IBGE FTP URLs", {
  patterns <- healthbR:::pns_url_patterns
  expect_match(patterns[["2013"]]$data, "^https://ftp\\.ibge\\.gov\\.br/PNS")
  expect_match(patterns[["2013"]]$dict, "^https://ftp\\.ibge\\.gov\\.br/PNS")
  expect_match(patterns[["2019"]]$data, "^https://ftp\\.ibge\\.gov\\.br/PNS")
  expect_match(patterns[["2019"]]$dict, "^https://ftp\\.ibge\\.gov\\.br/PNS")
})

# ----------------------------------------------------------------------------
# sidra_theme_labels constant
# ----------------------------------------------------------------------------

test_that("sidra_theme_labels has expected themes", {
  labels <- healthbR:::sidra_theme_labels
  expect_type(labels, "character")
  expect_true(length(labels) >= 14)
  expect_true("chronic_diseases" %in% names(labels))
  expect_true("mental_health" %in% names(labels))
  expect_true("tobacco" %in% names(labels))
  expect_true("health_perception" %in% names(labels))
})

# ----------------------------------------------------------------------------
# pns_sidra_catalog_internal constant
# ----------------------------------------------------------------------------

test_that("pns_sidra_catalog_internal has expected structure", {
  catalog <- healthbR:::pns_sidra_catalog_internal
  expect_s3_class(catalog, "tbl_df")
  expect_true(all(c("table_code", "table_name", "theme", "theme_label",
                     "years", "territorial_levels") %in% names(catalog)))
  expect_true(nrow(catalog) == 69)
})

test_that("all catalog themes have labels", {
  catalog <- healthbR:::pns_sidra_catalog_internal
  expect_false(any(is.na(catalog$theme_label)))
})

# ----------------------------------------------------------------------------
# pns_cache_dir()
# ----------------------------------------------------------------------------

test_that("pns_cache_dir creates directory with custom path", {
  temp <- withr::local_tempdir()
  custom <- file.path(temp, "my_pns_cache")
  result <- healthbR:::pns_cache_dir(custom)
  expect_true(dir.exists(result))
  expect_equal(result, custom)
})

test_that("pns_cache_dir uses default when NULL", {
  result <- healthbR:::pns_cache_dir(NULL)
  expect_type(result, "character")
  expect_true(nchar(result) > 0)
})

# ----------------------------------------------------------------------------
# pns_cache_status() — with temp dir
# ----------------------------------------------------------------------------

test_that("pns_cache_status returns empty tibble for empty dir", {
  temp <- withr::local_tempdir()
  status <- pns_cache_status(cache_dir = temp)
  expect_s3_class(status, "tbl_df")
  expect_equal(nrow(status), 0)
  expect_true(all(c("file", "size_mb", "modified") %in% names(status)))
})

test_that("pns_cache_status reports files in cache", {
  temp <- withr::local_tempdir()
  cache <- healthbR:::pns_cache_dir(temp)
  writeLines("test data", file.path(cache, "test_file.rds"))

  status <- pns_cache_status(cache_dir = temp)
  expect_s3_class(status, "tbl_df")
  expect_equal(nrow(status), 1)
  expect_equal(status$file, "test_file.rds")
  expect_true(status$size_mb >= 0)
  expect_s3_class(status$modified, "POSIXct")
})

# ----------------------------------------------------------------------------
# pns_clear_cache() — with temp dir
# ----------------------------------------------------------------------------

test_that("pns_clear_cache handles empty cache", {
  temp <- withr::local_tempdir()
  result <- pns_clear_cache(cache_dir = temp)
  expect_null(result)
})

test_that("pns_clear_cache removes files and recreates directory", {
  temp <- withr::local_tempdir()
  cache <- healthbR:::pns_cache_dir(temp)
  writeLines("test", file.path(cache, "dummy.rds"))
  expect_true(length(list.files(cache)) > 0)

  pns_clear_cache(cache_dir = temp)

  # directory should still exist but be empty
  expect_true(dir.exists(cache))
  expect_equal(length(list.files(cache, recursive = TRUE)), 0)
})

# ----------------------------------------------------------------------------
# pns_sidra_tables() — additional branches
# ----------------------------------------------------------------------------

test_that("pns_sidra_tables returns expected columns", {
  result <- pns_sidra_tables()
  expect_true(all(c("table_code", "table_name", "theme", "theme_label",
                     "years", "territorial_levels") %in% names(result)))
})

test_that("pns_sidra_tables with multiple themes", {
  result <- pns_sidra_tables(theme = c("chronic_diseases", "tobacco"))
  expect_true(all(result$theme %in% c("chronic_diseases", "tobacco")))
  expect_true(nrow(result) > 0)
})

test_that("pns_sidra_tables filters by year 2019 only", {
  result <- pns_sidra_tables(year = 2019)
  # every row should have 2019 in its years list
  has_2019 <- purrr::map_lgl(result$years, ~ "2019" %in% .x)
  expect_true(all(has_2019))
})

test_that("pns_sidra_tables filters by year 2013", {
  result_2013 <- pns_sidra_tables(year = 2013)
  has_2013 <- purrr::map_lgl(result_2013$years, ~ "2013" %in% .x)
  expect_true(all(has_2013))
})

test_that("pns_sidra_tables with year returns subset", {
  # anthropometry tables are 2019-only
  all_tables <- pns_sidra_tables()
  tables_2013 <- pns_sidra_tables(year = 2013)
  expect_true(nrow(tables_2013) <= nrow(all_tables))
})

test_that("pns_sidra_tables invalid theme errors", {
  expect_error(pns_sidra_tables(theme = "nonexistent"), "Invalid theme")
})

test_that("pns_sidra_tables combined theme and year filter", {
  result <- pns_sidra_tables(theme = "chronic_diseases", year = 2019)
  expect_true(all(result$theme == "chronic_diseases"))
  has_2019 <- purrr::map_lgl(result$years, ~ "2019" %in% .x)
  expect_true(all(has_2019))
})

# ----------------------------------------------------------------------------
# pns_sidra_search() — additional branches
# ----------------------------------------------------------------------------

test_that("pns_sidra_search validates missing keyword", {
  expect_error(pns_sidra_search(), "at least 2 characters")
})

test_that("pns_sidra_search validates NULL keyword", {
  expect_error(pns_sidra_search(NULL), "at least 2 characters")
})

test_that("pns_sidra_search validates single-char keyword", {
  expect_error(pns_sidra_search("x"), "at least 2 characters")
})

test_that("pns_sidra_search filters by year", {
  # mental health tables 7891-7895 are 2019-only
  result_all <- pns_sidra_search("mental")
  result_2013 <- pns_sidra_search("mental", year = 2013)
  expect_true(nrow(result_all) >= nrow(result_2013))
})

test_that("pns_sidra_search returns sorted by table_code", {
  result <- pns_sidra_search("diabetes")
  if (nrow(result) > 1) {
    expect_true(all(diff(as.numeric(result$table_code)) >= 0))
  }
})

# ----------------------------------------------------------------------------
# .pns_sidra_build_url() — URL construction
# ----------------------------------------------------------------------------

test_that(".pns_sidra_build_url builds basic URL", {
  url <- healthbR:::.pns_sidra_build_url(
    table = "4751",
    territorial_level = "brazil",
    geo_code = "all",
    variable = NULL,
    year = NULL,
    classifications = NULL
  )
  expect_match(url, "^https://apisidra\\.ibge\\.gov\\.br/values")
  expect_match(url, "/t/4751")
  expect_match(url, "/n1/all")
  expect_match(url, "/v/allxp")
  expect_match(url, "/p/all")
})

test_that(".pns_sidra_build_url handles state level", {
  url <- healthbR:::.pns_sidra_build_url(
    table = "4416",
    territorial_level = "state",
    geo_code = "all",
    variable = NULL,
    year = NULL,
    classifications = NULL
  )
  expect_match(url, "/n3/all")
})

test_that(".pns_sidra_build_url handles region level", {
  url <- healthbR:::.pns_sidra_build_url(
    table = "4416",
    territorial_level = "region",
    geo_code = "all",
    variable = NULL,
    year = NULL,
    classifications = NULL
  )
  expect_match(url, "/n2/all")
})

test_that(".pns_sidra_build_url handles municipality level", {
  url <- healthbR:::.pns_sidra_build_url(
    table = "4416",
    territorial_level = "municipality",
    geo_code = "3550308",
    variable = NULL,
    year = NULL,
    classifications = NULL
  )
  expect_match(url, "/n6/3550308")
})

test_that(".pns_sidra_build_url with specific variables", {
  url <- healthbR:::.pns_sidra_build_url(
    table = "4751",
    territorial_level = "brazil",
    geo_code = "all",
    variable = c(93, 1000093),
    year = NULL,
    classifications = NULL
  )
  expect_match(url, "/v/93,1000093")
})

test_that(".pns_sidra_build_url with specific year", {
  url <- healthbR:::.pns_sidra_build_url(
    table = "4751",
    territorial_level = "brazil",
    geo_code = "all",
    variable = NULL,
    year = 2019,
    classifications = NULL
  )
  expect_match(url, "/p/2019")
})

test_that(".pns_sidra_build_url with multiple years", {
  url <- healthbR:::.pns_sidra_build_url(
    table = "4751",
    territorial_level = "brazil",
    geo_code = "all",
    variable = NULL,
    year = c(2013, 2019),
    classifications = NULL
  )
  expect_match(url, "/p/2013,2019")
})

test_that(".pns_sidra_build_url with classifications", {
  url <- healthbR:::.pns_sidra_build_url(
    table = "4751",
    territorial_level = "brazil",
    geo_code = "all",
    variable = NULL,
    year = 2019,
    classifications = list("2" = "6794", "58" = "2795")
  )
  expect_match(url, "/c2/6794")
  expect_match(url, "/c58/2795")
})

test_that(".pns_sidra_build_url with multiple classification values", {
  url <- healthbR:::.pns_sidra_build_url(
    table = "4751",
    territorial_level = "brazil",
    geo_code = "all",
    variable = NULL,
    year = NULL,
    classifications = list("2" = c("6794", "6795"))
  )
  expect_match(url, "/c2/6794,6795")
})

test_that(".pns_sidra_build_url errors on invalid territorial_level", {
  expect_error(
    healthbR:::.pns_sidra_build_url(
      table = "4751",
      territorial_level = "invalid_level",
      geo_code = "all",
      variable = NULL,
      year = NULL,
      classifications = NULL
    ),
    "Invalid territorial_level"
  )
})

# ----------------------------------------------------------------------------
# pns_sidra_data() — parameter validation (no HTTP)
# ----------------------------------------------------------------------------

test_that("pns_sidra_data validates territorial_level", {
  expect_error(
    pns_sidra_data(table = 4751, territorial_level = "galaxy"),
    "Invalid territorial_level"
  )
})

test_that("pns_sidra_data warns for unknown table code", {
  # Mock the curl call to avoid HTTP
  local_mocked_bindings(
    curl_fetch_memory = function(...) {
      list(status_code = 200, content = charToRaw("[]"))
    },
    .package = "curl"
  )
  expect_warning(
    pns_sidra_data(table = 99999, territorial_level = "brazil", year = 2019),
    "not found in internal catalog"
  )
})

# ----------------------------------------------------------------------------
# .pns_try_lazy() — returns NULL when no cache
# ----------------------------------------------------------------------------

test_that(".pns_try_lazy returns NULL when lazy is FALSE", {
  result <- healthbR:::.pns_try_lazy(
    year = 2019, vars = NULL, lazy = FALSE,
    backend = "arrow", cache_dir = tempdir()
  )
  expect_null(result)
})

test_that(".pns_try_lazy returns NULL when cache does not exist", {
  temp <- withr::local_tempdir()
  result <- healthbR:::.pns_try_lazy(
    year = 2019, vars = NULL, lazy = TRUE,
    backend = "arrow", cache_dir = temp
  )
  expect_null(result)
})

test_that(".pns_try_lazy with vars passes select_cols", {
  temp <- withr::local_tempdir()
  # no cache, so returns NULL regardless, but exercises the code path
  result <- healthbR:::.pns_try_lazy(
    year = 2019, vars = c("V0001", "C006"), lazy = TRUE,
    backend = "arrow", cache_dir = temp
  )
  expect_null(result)
})

test_that(".pns_try_lazy with NULL year passes NULL filter", {
  temp <- withr::local_tempdir()
  result <- healthbR:::.pns_try_lazy(
    year = NULL, vars = NULL, lazy = TRUE,
    backend = "arrow", cache_dir = temp
  )
  expect_null(result)
})

# ----------------------------------------------------------------------------
# .pns_select_vars() — variable selection from mock tibble
# ----------------------------------------------------------------------------

test_that(".pns_select_vars returns all columns when vars is NULL", {
  mock_data <- tibble::tibble(year = 2019L, V0001 = "11", C006 = "1", X001 = "2")
  result <- healthbR:::.pns_select_vars(mock_data, NULL)
  expect_equal(ncol(result), 4)
  expect_equal(names(result), c("year", "V0001", "C006", "X001"))
})

test_that(".pns_select_vars selects specified variables", {
  mock_data <- tibble::tibble(year = 2019L, V0001 = "11", C006 = "1", X001 = "2")
  result <- healthbR:::.pns_select_vars(mock_data, c("V0001", "C006"))
  expect_equal(ncol(result), 3)
  expect_true(all(c("year", "V0001", "C006") %in% names(result)))
  expect_false("X001" %in% names(result))
})

test_that(".pns_select_vars uppercases variable names", {
  mock_data <- tibble::tibble(year = 2019L, V0001 = "11", C006 = "1")
  result <- healthbR:::.pns_select_vars(mock_data, c("v0001"))
  expect_true("V0001" %in% names(result))
})

test_that(".pns_select_vars warns about missing variables", {
  mock_data <- tibble::tibble(year = 2019L, V0001 = "11")
  expect_warning(
    healthbR:::.pns_select_vars(mock_data, c("V0001", "NONEXISTENT")),
    "not found"
  )
})

test_that(".pns_select_vars keeps year column even if not requested", {
  mock_data <- tibble::tibble(year = 2019L, V0001 = "11", C006 = "1")
  result <- healthbR:::.pns_select_vars(mock_data, c("V0001"))
  expect_true("year" %in% names(result))
})

test_that(".pns_select_vars handles all missing variables", {
  mock_data <- tibble::tibble(year = 2019L, V0001 = "11")
  expect_warning(
    result <- healthbR:::.pns_select_vars(mock_data, c("NONEXISTENT")),
    "not found"
  )
  # should still have year
  expect_true("year" %in% names(result))
})

# ----------------------------------------------------------------------------
# .pns_download_loop() — mock download function
# ----------------------------------------------------------------------------

test_that(".pns_download_loop calls download and returns list", {
  mock_data <- tibble::tibble(year = 2019L, V0001 = "SP", C006 = "1")
  temp <- withr::local_tempdir()
  cache <- healthbR:::pns_cache_dir(temp)

  local_mocked_bindings(
    .has_arrow = function() FALSE,
    pns_download_data = function(y, cache_dir, refresh) "fake_path.zip",
    pns_read_microdata = function(zip_path, year) mock_data,
    .cache_append_partitioned = function(...) invisible(NULL)
  )

  result <- healthbR:::.pns_download_loop(2019L, cache, FALSE, "pns_data")
  expect_type(result, "list")
  expect_length(result, 1)
  expect_s3_class(result[[1]], "tbl_df")
  expect_equal(nrow(result[[1]]), 1)
})

test_that(".pns_download_loop handles multiple years", {
  mock_2013 <- tibble::tibble(year = 2013L, V0001 = "RJ")
  mock_2019 <- tibble::tibble(year = 2019L, V0001 = "SP")
  temp <- withr::local_tempdir()
  cache <- healthbR:::pns_cache_dir(temp)

  local_mocked_bindings(
    .has_arrow = function() FALSE,
    pns_download_data = function(y, cache_dir, refresh) paste0("fake_", y, ".zip"),
    pns_read_microdata = function(zip_path, year) {
      if (year == 2013L || year == "2013") mock_2013 else mock_2019
    },
    .cache_append_partitioned = function(...) invisible(NULL)
  )

  result <- healthbR:::.pns_download_loop(c(2013L, 2019L), cache, FALSE, "pns_data")
  expect_length(result, 2)
  expect_equal(result[[1]]$year, 2013L)
  expect_equal(result[[2]]$year, 2019L)
})

# ----------------------------------------------------------------------------
# pns_download_data() — mock curl (no HTTP)
# ----------------------------------------------------------------------------

test_that("pns_download_data uses cached file when present", {
  temp <- withr::local_tempdir()
  cache <- healthbR:::pns_cache_dir(temp)
  # create a fake cached zip file
  zip_name <- basename(healthbR:::pns_url_patterns[["2019"]]$data)
  writeLines("fake zip", file.path(cache, zip_name))

  result <- healthbR:::pns_download_data(2019, cache, refresh = FALSE)
  expect_equal(basename(result), zip_name)
  expect_true(file.exists(result))
})

test_that("pns_download_data errors on invalid year with no URL pattern", {
  temp <- withr::local_tempdir()
  cache <- healthbR:::pns_cache_dir(temp)
  expect_error(
    healthbR:::pns_download_data(9999, cache, refresh = FALSE),
    "No URL pattern"
  )
})

test_that("pns_download_data handles download failure", {
  temp <- withr::local_tempdir()
  cache <- healthbR:::pns_cache_dir(temp)

  local_mocked_bindings(
    curl_download = function(...) stop("Network error"),
    .package = "curl"
  )

  expect_error(
    healthbR:::pns_download_data(2019, cache, refresh = TRUE),
    "Download failed"
  )
})

# ----------------------------------------------------------------------------
# .pns_download_dictionary() — validation
# ----------------------------------------------------------------------------

test_that(".pns_download_dictionary errors on invalid year", {
  temp <- withr::local_tempdir()
  expect_error(
    healthbR:::.pns_download_dictionary(9999, temp, FALSE),
    "No dictionary URL"
  )
})

test_that(".pns_download_dictionary errors on download failure", {
  temp <- withr::local_tempdir()
  cache <- healthbR:::pns_cache_dir(temp)

  local_mocked_bindings(
    curl_download = function(...) stop("Connection refused"),
    .package = "curl"
  )

  expect_error(
    healthbR:::.pns_download_dictionary(2019, cache, refresh = TRUE),
    "Download failed"
  )
})

# ----------------------------------------------------------------------------
# .pns_parse_dictionary() — mock extracted files
# ----------------------------------------------------------------------------

test_that(".pns_parse_dictionary returns NULL for no matching files", {
  temp <- withr::local_tempdir()
  # create a non-dictionary file
  writeLines("hello", file.path(temp, "readme.txt"))
  result <- healthbR:::.pns_parse_dictionary(file.path(temp, "readme.txt"), 2019)
  expect_null(result)
})

test_that(".pns_parse_dictionary reads txt dictionary file", {
  temp <- withr::local_tempdir()
  dict_file <- file.path(temp, "dicionario_pns.txt")
  writeLines("col1;col2;col3\nA;B;C\nD;E;F", dict_file)

  result <- healthbR:::.pns_parse_dictionary(dict_file, 2019)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
})

test_that(".pns_parse_dictionary prefers xlsx over txt", {
  skip_if_not_installed("readxl")
  temp <- withr::local_tempdir()

  # create a txt file

  txt_file <- file.path(temp, "dicionario.txt")
  writeLines("a;b\n1;2", txt_file)

  # create a mock xlsx (this won't be real xlsx, so it should fail but try xlsx first)
  xlsx_file <- file.path(temp, "dicionario.xlsx")
  writeLines("fake", xlsx_file)

  files <- c(xlsx_file, txt_file)
  # xlsx will fail (not real xlsx), should fall back to txt
  result <- suppressWarnings(healthbR:::.pns_parse_dictionary(files, 2019))
  # should get the txt result since xlsx fails
  expect_s3_class(result, "tbl_df")
})

# ----------------------------------------------------------------------------
# pns_dictionary() — validation
# ----------------------------------------------------------------------------

test_that("pns_dictionary validates year parameter", {
  expect_error(pns_dictionary(year = 1999, cache_dir = tempdir()), "Invalid year")
  expect_error(pns_dictionary(year = 2020, cache_dir = tempdir()), "Invalid year")
})

test_that("pns_dictionary uses first year when multiple are given", {
  temp <- withr::local_tempdir()
  # mock the download to avoid HTTP
  local_mocked_bindings(
    .pns_download_dictionary = function(year, cache_dir, refresh) {
      # create a mock txt file
      tdir <- file.path(tempdir(), paste0("pns_dict_mock_", year))
      dir.create(tdir, showWarnings = FALSE)
      dict_file <- file.path(tdir, "dicionario.txt")
      writeLines("variavel;descricao\nV0001;UF\nC006;Sexo", dict_file)
      list(extracted_files = dict_file, temp_dir = tdir)
    }
  )

  # passing both years should use 2013 (first)
  expect_message(
    dict <- pns_dictionary(year = c(2013, 2019), cache_dir = temp),
    "Using year 2013"
  )
  expect_s3_class(dict, "tbl_df")
  expect_equal(dict$year[1], 2013L)
})

test_that("pns_dictionary caches result as RDS", {
  temp <- withr::local_tempdir()
  cache <- healthbR:::pns_cache_dir(temp)

  local_mocked_bindings(
    .pns_download_dictionary = function(year, cache_dir, refresh) {
      tdir <- file.path(tempdir(), paste0("pns_dict_cache_test_", year))
      dir.create(tdir, showWarnings = FALSE)
      dict_file <- file.path(tdir, "dicionario.txt")
      writeLines("variavel;descricao\nV0001;UF", dict_file)
      list(extracted_files = dict_file, temp_dir = tdir)
    }
  )

  dict <- pns_dictionary(year = 2019, cache_dir = temp)
  # check that RDS file was created
  rds_file <- file.path(cache, "pns_dictionary_2019.rds")
  expect_true(file.exists(rds_file))

  # second call should use RDS cache (no download)
  dict2 <- pns_dictionary(year = 2019, cache_dir = temp)
  expect_equal(nrow(dict), nrow(dict2))
})

test_that("pns_dictionary errors when parse fails", {
  temp <- withr::local_tempdir()

  local_mocked_bindings(
    .pns_download_dictionary = function(year, cache_dir, refresh) {
      tdir <- file.path(tempdir(), paste0("pns_dict_fail_", year))
      dir.create(tdir, showWarnings = FALSE)
      # create a file that won't parse as dictionary
      f <- file.path(tdir, "readme.pdf")
      writeLines("not a dict", f)
      list(extracted_files = f, temp_dir = tdir)
    }
  )

  expect_error(
    pns_dictionary(year = 2019, cache_dir = temp, refresh = TRUE),
    "Could not find or read dictionary"
  )
})

# ----------------------------------------------------------------------------
# pns_variables() — offline tests with mock dictionary
# ----------------------------------------------------------------------------

test_that("pns_variables returns dictionary when columns not recognized", {
  temp <- withr::local_tempdir()

  local_mocked_bindings(
    pns_dictionary = function(year, cache_dir, refresh) {
      tibble::tibble(
        year = 2019L,
        weird_col1 = c("A", "B"),
        weird_col2 = c("D1", "D2")
      )
    }
  )

  result <- pns_variables(year = 2019, cache_dir = temp)
  # should return raw structure since columns don't match
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
})

test_that("pns_variables identifies variable column", {
  temp <- withr::local_tempdir()

  local_mocked_bindings(
    pns_dictionary = function(year, cache_dir, refresh) {
      tibble::tibble(
        year = 2019L,
        variavel = c("V0001", "V0001", "C006"),
        descricao = c("UF", "UF", "Sexo")
      )
    }
  )

  result <- pns_variables(year = 2019, cache_dir = temp)
  expect_s3_class(result, "tbl_df")
  expect_true("variable" %in% names(result))
  expect_true("label" %in% names(result))
  # should return distinct values
  expect_equal(nrow(result), 2)
})

test_that("pns_variables filters by module", {
  temp <- withr::local_tempdir()

  local_mocked_bindings(
    pns_dictionary = function(year, cache_dir, refresh) {
      tibble::tibble(
        year = 2019L,
        variavel = c("J001", "J002", "K001", "L001"),
        descricao = c("Perc saude", "Estado saude", "Acidentes", "Estilo vida")
      )
    }
  )

  result <- pns_variables(year = 2019, module = "J", cache_dir = temp)
  expect_equal(nrow(result), 2)
  expect_true(all(grepl("^J", result$variable)))
})

test_that("pns_variables module filter is case-insensitive", {
  temp <- withr::local_tempdir()

  local_mocked_bindings(
    pns_dictionary = function(year, cache_dir, refresh) {
      tibble::tibble(
        year = 2019L,
        variavel = c("J001", "K001"),
        descricao = c("Perc", "Acidentes")
      )
    }
  )

  result_lower <- pns_variables(year = 2019, module = "j", cache_dir = temp)
  result_upper <- pns_variables(year = 2019, module = "J", cache_dir = temp)
  expect_equal(nrow(result_lower), nrow(result_upper))
})

test_that("pns_variables with var_col but no label_col", {
  temp <- withr::local_tempdir()

  local_mocked_bindings(
    pns_dictionary = function(year, cache_dir, refresh) {
      tibble::tibble(
        year = 2019L,
        variavel = c("V0001", "C006"),
        some_other_col = c("X", "Y")
      )
    }
  )

  result <- pns_variables(year = 2019, cache_dir = temp)
  expect_s3_class(result, "tbl_df")
  expect_true("variable" %in% names(result))
  # no label column
  expect_false("label" %in% names(result))
})

# ----------------------------------------------------------------------------
# pns_data() — parameter validation (no HTTP)
# ----------------------------------------------------------------------------

test_that("pns_data validates year parameter", {
  expect_error(pns_data(year = 1999, cache_dir = tempdir()), "Invalid year")
  expect_error(pns_data(year = 2020, cache_dir = tempdir()), "Invalid year")
  expect_error(pns_data(year = 2050, cache_dir = tempdir()), "Invalid year")
})

test_that("pns_data validates backend parameter", {
  expect_error(
    pns_data(year = 2019, cache_dir = tempdir(), backend = "sqlite"),
    "should be one of"
  )
})

test_that("pns_data with lazy=TRUE returns NULL when no cache", {
  temp <- withr::local_tempdir()
  # this should fall through to download, which we mock to return data
  mock_data <- tibble::tibble(year = 2019L, V0001 = "SP")

  local_mocked_bindings(
    .pns_try_lazy = function(...) NULL,
    .pns_download_loop = function(year, cache_dir, refresh, dataset_name) {
      list(mock_data)
    }
  )

  result <- pns_data(year = 2019, cache_dir = temp)
  expect_s3_class(result, "tbl_df")
})

test_that("pns_data with vars selects columns", {
  temp <- withr::local_tempdir()
  mock_data <- tibble::tibble(year = 2019L, V0001 = "SP", C006 = "1", X001 = "A")

  local_mocked_bindings(
    .pns_try_lazy = function(...) NULL,
    .pns_download_loop = function(year, cache_dir, refresh, dataset_name) {
      list(mock_data)
    }
  )

  result <- pns_data(year = 2019, vars = c("V0001"), cache_dir = temp)
  expect_true("V0001" %in% names(result))
  expect_true("year" %in% names(result))
  expect_false("X001" %in% names(result))
})

test_that("pns_data returns lazy query when .pns_try_lazy succeeds", {
  temp <- withr::local_tempdir()
  fake_lazy <- structure(list(message = "lazy"), class = "fake_lazy_query")

  local_mocked_bindings(
    .pns_try_lazy = function(year, vars, lazy, backend, cache_dir) {
      if (isTRUE(lazy)) fake_lazy else NULL
    }
  )

  result <- pns_data(year = 2019, lazy = TRUE, cache_dir = temp)
  expect_equal(result, fake_lazy)
})

# ----------------------------------------------------------------------------
# pns_read_microdata() — mock extraction
# ----------------------------------------------------------------------------

test_that("pns_read_microdata errors when no data files found", {
  temp <- withr::local_tempdir()
  # create a zip with only a pdf
  zip_dir <- file.path(temp, "zip_content")
  dir.create(zip_dir)
  writeLines("readme", file.path(zip_dir, "readme.pdf"))
  zip_path <- file.path(temp, "test.zip")
  old_wd <- getwd()
  setwd(zip_dir)
  utils::zip(zip_path, files = "readme.pdf")
  setwd(old_wd)

  expect_error(
    healthbR:::pns_read_microdata(zip_path, 2019),
    "Could not find data files"
  )
})

test_that("pns_read_microdata reads CSV data from zip", {
  temp <- withr::local_tempdir()
  # create a zip with CSV data
  zip_dir <- file.path(temp, "zip_content")
  dir.create(zip_dir)
  csv_content <- "V0001,C006,C008\n11,1,25\n33,2,30"
  writeLines(csv_content, file.path(zip_dir, "PNS_2019.csv"))
  zip_path <- file.path(temp, "PNS_2019.zip")
  old_wd <- getwd()
  setwd(zip_dir)
  utils::zip(zip_path, files = "PNS_2019.csv")
  setwd(old_wd)

  result <- healthbR:::pns_read_microdata(zip_path, 2019)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_true("year" %in% names(result))
  expect_equal(result$year[1], 2019L)
})

# ----------------------------------------------------------------------------
# pns_read_fwf() — mock input file parsing
# ----------------------------------------------------------------------------

test_that("pns_read_fwf parses input file correctly", {
  temp <- withr::local_tempdir()

  # create input file with IBGE format
  input_content <- c(
    "@1 V0001 $2.",
    "@3 V0002 $5.",
    "@8 V0003 $3."
  )
  input_file <- file.path(temp, "input_PNS.txt")
  writeLines(input_content, input_file)

  # create fixed-width data file
  # V0001=2 chars, V0002=5 chars, V0003=3 chars
  data_content <- c(
    "SP12345ABC",
    "RJ67890DEF"
  )
  data_file <- file.path(temp, "PNS_2019.txt")
  writeLines(data_content, data_file)

  result <- healthbR:::pns_read_fwf(data_file, input_file)
  expect_s3_class(result, "tbl_df")
  expect_equal(ncol(result), 3)
  expect_equal(names(result), c("V0001", "V0002", "V0003"))
})

test_that("pns_read_fwf falls back to delimited when no @ lines", {
  temp <- withr::local_tempdir()

  input_content <- c("some format", "not ibge style")
  input_file <- file.path(temp, "input.txt")
  writeLines(input_content, input_file)

  data_content <- "col1;col2\nA;B\nC;D"
  data_file <- file.path(temp, "data.txt")
  writeLines(data_content, data_file)

  expect_warning(
    result <- healthbR:::pns_read_fwf(data_file, input_file),
    "Could not parse input file format"
  )
  expect_s3_class(result, "tbl_df")
})

test_that("pns_read_fwf falls back when @ lines don't match pattern", {
  temp <- withr::local_tempdir()

  # @ lines exist but don't match the expected pattern
  input_content <- c("@weird format", "@another weird line")
  input_file <- file.path(temp, "input2.txt")
  writeLines(input_content, input_file)

  data_content <- "col1;col2\nA;B"
  data_file <- file.path(temp, "data2.txt")
  writeLines(data_content, data_file)

  expect_warning(
    result <- healthbR:::pns_read_fwf(data_file, input_file),
    "Could not parse column specifications"
  )
  expect_s3_class(result, "tbl_df")
})

# ----------------------------------------------------------------------------
# pns_sidra_data() — mock API response
# ----------------------------------------------------------------------------

test_that("pns_sidra_data handles empty response", {
  local_mocked_bindings(
    curl_fetch_memory = function(...) {
      list(status_code = 200, content = charToRaw("[]"))
    },
    .package = "curl"
  )

  result <- pns_sidra_data(table = 4751, territorial_level = "brazil", year = 2019)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("pns_sidra_data handles non-200 status", {
  local_mocked_bindings(
    curl_fetch_memory = function(...) {
      list(status_code = 500, content = charToRaw("Internal Server Error"))
    },
    .package = "curl"
  )

  expect_error(
    pns_sidra_data(table = 4751, territorial_level = "brazil"),
    "status"
  )
})

test_that("pns_sidra_data handles connection error", {
  local_mocked_bindings(
    curl_fetch_memory = function(...) stop("Connection refused"),
    .package = "curl"
  )

  expect_error(
    pns_sidra_data(table = 4751, territorial_level = "brazil"),
    "SIDRA API request failed"
  )
})

test_that("pns_sidra_data raw parameter returns unprocessed data", {
  mock_json <- jsonlite::toJSON(
    data.frame(
      V = c("header", "value1"),
      D1C = c("header2", "code1"),
      stringsAsFactors = FALSE
    )
  )
  local_mocked_bindings(
    curl_fetch_memory = function(...) {
      list(status_code = 200, content = charToRaw(as.character(mock_json)))
    },
    .package = "curl"
  )

  result <- pns_sidra_data(
    table = 4751, territorial_level = "brazil", raw = TRUE
  )
  expect_s3_class(result, "tbl_df")
  # raw should include the header row
  expect_equal(nrow(result), 2)
})

# ----------------------------------------------------------------------------
# pns_read_microdata() — txt (delimited) path
# ----------------------------------------------------------------------------

test_that("pns_read_microdata reads delimited txt when no csv and no input file", {
  temp <- withr::local_tempdir()
  zip_dir <- file.path(temp, "zip_txt")
  dir.create(zip_dir)
  # create txt file (not csv, not input)
  txt_content <- "V0001;C006;C008\n11;1;25\n33;2;30"
  writeLines(txt_content, file.path(zip_dir, "PNS_2019_dados.txt"))
  zip_path <- file.path(temp, "PNS_2019_txt.zip")
  old_wd <- getwd()
  setwd(zip_dir)
  utils::zip(zip_path, files = "PNS_2019_dados.txt")
  setwd(old_wd)

  result <- healthbR:::pns_read_microdata(zip_path, 2019)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_true("year" %in% names(result))
})

test_that("pns_read_microdata reads fwf when input file present", {
  temp <- withr::local_tempdir()
  zip_dir <- file.path(temp, "zip_fwf")
  dir.create(zip_dir)

  # create input file
  input_content <- c("@1 V0001 $2.", "@3 V0002 $3.")
  writeLines(input_content, file.path(zip_dir, "input_PNS2019.txt"))

  # create fixed-width data file
  data_content <- c("SP123", "RJ456")
  writeLines(data_content, file.path(zip_dir, "PNS_2019_dados.txt"))

  zip_path <- file.path(temp, "PNS_fwf.zip")
  old_wd <- getwd()
  setwd(zip_dir)
  utils::zip(zip_path, files = c("input_PNS2019.txt", "PNS_2019_dados.txt"))
  setwd(old_wd)

  result <- healthbR:::pns_read_microdata(zip_path, 2019)
  expect_s3_class(result, "tbl_df")
  expect_true("year" %in% names(result))
  expect_equal(result$year[1], 2019L)
})
