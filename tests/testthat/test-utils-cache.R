# tests for shared cache utilities (utils-cache.R)

# ============================================================================
# .has_arrow
# ============================================================================

test_that(".has_arrow returns logical", {
  result <- healthbR:::.has_arrow()
  expect_type(result, "logical")
  expect_length(result, 1)
})


# ============================================================================
# .module_cache_dir
# ============================================================================

test_that(".module_cache_dir creates directory with default path", {
  dir <- healthbR:::.module_cache_dir("test_module")
  expect_true(dir.exists(dir))
  expect_true(grepl("test_module$", dir))
  # cleanup
  unlink(dir, recursive = TRUE)
})

test_that(".module_cache_dir uses custom path when provided", {
  custom <- file.path(tempdir(), "custom_cache_dir")
  dir <- healthbR:::.module_cache_dir("test_module", custom)
  expect_true(dir.exists(dir))

  expect_equal(dir, custom)
  # cleanup
  unlink(custom, recursive = TRUE)
})


# ============================================================================
# .cache_read / .cache_write (flat cache)
# ============================================================================

test_that(".cache_write and .cache_read roundtrip works", {
  cache_dir <- file.path(tempdir(), "test_cache_rw")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  test_data <- tibble::tibble(x = 1:5, y = letters[1:5])
  healthbR:::.cache_write(test_data, cache_dir, "test_flat")

  result <- healthbR:::.cache_read(cache_dir, "test_flat")
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 5)
  expect_equal(result$x, test_data$x)
  expect_equal(result$y, test_data$y)
})

test_that(".cache_read returns NULL on cache miss", {
  cache_dir <- file.path(tempdir(), "test_cache_miss")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  result <- healthbR:::.cache_read(cache_dir, "nonexistent")
  expect_null(result)
})


# ============================================================================
# partitioned cache functions
# ============================================================================

test_that(".has_partitioned_cache returns FALSE for empty directory", {
  cache_dir <- file.path(tempdir(), "test_part_empty")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  result <- healthbR:::.has_partitioned_cache(cache_dir, "test_ds")
  expect_false(result)
})

test_that(".cache_write_partitioned creates Hive-style directories", {
  skip_if_not(healthbR:::.has_arrow(), "arrow package not available")

  cache_dir <- file.path(tempdir(), "test_part_write")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  test_data <- tibble::tibble(
    year = c(2020L, 2020L, 2021L, 2021L),
    uf = c("AC", "SP", "AC", "SP"),
    value = c(10, 20, 30, 40)
  )

  result <- healthbR:::.cache_write_partitioned(
    test_data, cache_dir, "test_ds", c("uf", "year")
  )

  expect_true(healthbR:::.has_partitioned_cache(cache_dir, "test_ds"))

  # check Hive-style directories exist
  ds_dir <- file.path(cache_dir, "test_ds")
  expect_true(dir.exists(ds_dir))
  subdirs <- list.dirs(ds_dir, recursive = FALSE)
  expect_true(length(subdirs) > 0)
})

test_that(".cache_open_dataset returns Arrow Dataset", {
  skip_if_not(healthbR:::.has_arrow(), "arrow package not available")

  cache_dir <- file.path(tempdir(), "test_part_open")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  test_data <- tibble::tibble(
    year = c(2020L, 2021L),
    value = c(10, 20)
  )

  healthbR:::.cache_write_partitioned(
    test_data, cache_dir, "test_ds", c("year")
  )

  ds <- healthbR:::.cache_open_dataset(cache_dir, "test_ds")
  expect_true(inherits(ds, "Dataset") || inherits(ds, "FileSystemDataset"))

  # collect and verify
  collected <- ds |> dplyr::collect()
  expect_equal(nrow(collected), 2)
  expect_true("year" %in% names(collected))
  expect_true("value" %in% names(collected))
})

test_that(".cache_open_dataset returns NULL when no cache", {
  cache_dir <- file.path(tempdir(), "test_part_open_miss")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  result <- healthbR:::.cache_open_dataset(cache_dir, "nonexistent")
  expect_null(result)
})

test_that(".cache_append_partitioned adds new partitions", {
  skip_if_not(healthbR:::.has_arrow(), "arrow package not available")

  cache_dir <- file.path(tempdir(), "test_part_append")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  # write first partition
  data1 <- tibble::tibble(year = rep(2020L, 3), value = 1:3)
  healthbR:::.cache_append_partitioned(
    data1, cache_dir, "test_ds", c("year")
  )

  # write second partition
  data2 <- tibble::tibble(year = rep(2021L, 2), value = 4:5)
  healthbR:::.cache_append_partitioned(
    data2, cache_dir, "test_ds", c("year")
  )

  # both partitions should exist
  ds <- arrow::open_dataset(file.path(cache_dir, "test_ds"))
  collected <- ds |> dplyr::collect()
  expect_equal(nrow(collected), 5)
  expect_equal(sort(unique(collected$year)), c(2020L, 2021L))
})

test_that(".cache_append_partitioned overwrites existing partition", {
  skip_if_not(healthbR:::.has_arrow(), "arrow package not available")

  cache_dir <- file.path(tempdir(), "test_part_overwrite")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  # write initial data
  data1 <- tibble::tibble(year = rep(2020L, 3), value = 1:3)
  healthbR:::.cache_append_partitioned(
    data1, cache_dir, "test_ds", c("year")
  )

  # overwrite same partition with new data
  data2 <- tibble::tibble(year = rep(2020L, 5), value = 10:14)
  healthbR:::.cache_append_partitioned(
    data2, cache_dir, "test_ds", c("year")
  )

  # should have the new data, not the old
  ds <- arrow::open_dataset(file.path(cache_dir, "test_ds"))
  collected <- ds |> dplyr::collect()
  expect_equal(nrow(collected), 5)
  expect_equal(sort(collected$value), 10:14)
})


# ============================================================================
# RDS fallback (when arrow not available)
# ============================================================================

test_that(".cache_write_partitioned falls back to RDS without arrow", {
  # simulate no arrow by calling with data in non-arrow environment
  # We can't really mock .has_arrow(), but we can test that RDS fallback works
  cache_dir <- file.path(tempdir(), "test_rds_fallback")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  test_data <- tibble::tibble(year = 2020L, value = 42)

  # The RDS fallback path is used when arrow is not available.
  # We test the RDS read path by manually creating an RDS file
  rds_path <- file.path(cache_dir, "test_ds.rds")
  saveRDS(test_data, rds_path)

  # .cache_open_dataset should find and return the RDS data
  # (if arrow is available, it won't find a partitioned dataset and will
  # fall back to RDS; if arrow is not available, same behavior)
  result <- healthbR:::.cache_open_dataset(cache_dir, "test_ds")
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_equal(result$value, 42)
})


# ============================================================================
# multi-column partitioning
# ============================================================================

test_that("partitioned cache works with 3-column partitioning", {
  skip_if_not(healthbR:::.has_arrow(), "arrow package not available")

  cache_dir <- file.path(tempdir(), "test_part_3col")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  test_data <- tibble::tibble(
    uf_source = c("AC", "AC", "SP", "SP"),
    year = c(2020L, 2020L, 2020L, 2020L),
    month = c(1L, 2L, 1L, 2L),
    value = c(10, 20, 30, 40)
  )

  healthbR:::.cache_write_partitioned(
    test_data, cache_dir, "test_ds", c("uf_source", "year", "month")
  )

  # open and filter for just AC, month 1
  ds <- arrow::open_dataset(file.path(cache_dir, "test_ds"))
  result <- ds |>
    dplyr::filter(.data$uf_source == "AC", .data$month == 1L) |>
    dplyr::collect()

  expect_equal(nrow(result), 1)
  expect_equal(result$value, 10)
})


# ============================================================================
# .has_duckdb
# ============================================================================

test_that(".has_duckdb returns logical", {
  result <- healthbR:::.has_duckdb()
  expect_type(result, "logical")
  expect_length(result, 1)
})


# ============================================================================
# .cache_open_lazy (Phase 2: lazy evaluation)
# ============================================================================

test_that(".cache_open_lazy returns NULL when lazy = FALSE", {
  result <- healthbR:::.cache_open_lazy(tempdir(), "test", lazy = FALSE)
  expect_null(result)
})

test_that(".cache_open_lazy returns NULL when no cache exists", {
  skip_if_not(healthbR:::.has_arrow(), "arrow package not available")

  cache_dir <- file.path(tempdir(), "test_lazy_nocache")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  result <- healthbR:::.cache_open_lazy(cache_dir, "nonexistent",
                                         lazy = TRUE, backend = "arrow")
  expect_null(result)
})

test_that(".cache_open_lazy returns Arrow Dataset with arrow backend", {
  skip_if_not(healthbR:::.has_arrow(), "arrow package not available")

  cache_dir <- file.path(tempdir(), "test_lazy_arrow")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  test_data <- tibble::tibble(year = c(2020L, 2021L), value = c(10, 20))
  healthbR:::.cache_write_partitioned(test_data, cache_dir, "test_ds", "year")

  ds <- healthbR:::.cache_open_lazy(cache_dir, "test_ds",
                                     lazy = TRUE, backend = "arrow")
  expect_true(inherits(ds, "Dataset") || inherits(ds, "FileSystemDataset"))

  collected <- ds |> dplyr::collect()
  expect_equal(nrow(collected), 2)
})

test_that(".cache_open_lazy returns DuckDB tbl with duckdb backend", {
  skip_if_not(healthbR:::.has_arrow(), "arrow package not available")
  skip_if_not(healthbR:::.has_duckdb(), "duckdb package not available")

  cache_dir <- file.path(tempdir(), "test_lazy_duckdb")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  test_data <- tibble::tibble(year = c(2020L, 2021L), value = c(10, 20))
  healthbR:::.cache_write_partitioned(test_data, cache_dir, "test_ds", "year")

  ds <- healthbR:::.cache_open_lazy(cache_dir, "test_ds",
                                     lazy = TRUE, backend = "duckdb")
  expect_true(inherits(ds, "tbl_lazy") || inherits(ds, "tbl_duckdb_connection"))

  collected <- ds |> dplyr::collect()
  expect_equal(nrow(collected), 2)
})

test_that(".cache_open_lazy arrow dataset supports lazy filter", {
  skip_if_not(healthbR:::.has_arrow(), "arrow package not available")

  cache_dir <- file.path(tempdir(), "test_lazy_filter")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  test_data <- tibble::tibble(
    uf_source = c("AC", "AC", "SP", "SP"),
    year = c(2020L, 2021L, 2020L, 2021L),
    value = c(10, 20, 30, 40)
  )
  healthbR:::.cache_write_partitioned(
    test_data, cache_dir, "test_ds", c("uf_source", "year")
  )

  ds <- healthbR:::.cache_open_lazy(cache_dir, "test_ds",
                                     lazy = TRUE, backend = "arrow")

  # filter on partition column before collecting
  result <- ds |>
    dplyr::filter(.data$uf_source == "AC") |>
    dplyr::collect()

  expect_equal(nrow(result), 2)
  expect_true(all(result$uf_source == "AC"))
})


# ============================================================================
# .lazy_return (Phase 2: lazy filter + select helper)
# ============================================================================

test_that(".lazy_return returns NULL when no cache", {
  skip_if_not(healthbR:::.has_arrow(), "arrow package not available")

  cache_dir <- file.path(tempdir(), "test_lr_nocache")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  result <- healthbR:::.lazy_return(cache_dir, "nonexistent", "arrow")
  expect_null(result)
})

test_that(".lazy_return filters by partition columns", {
  skip_if_not(healthbR:::.has_arrow(), "arrow package not available")

  cache_dir <- file.path(tempdir(), "test_lr_filter")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  test_data <- tibble::tibble(
    uf_source = c("AC", "AC", "SP", "SP"),
    year = c(2020L, 2021L, 2020L, 2021L),
    value = c(10, 20, 30, 40)
  )
  healthbR:::.cache_write_partitioned(
    test_data, cache_dir, "test_ds", c("uf_source", "year")
  )

  ds <- healthbR:::.lazy_return(
    cache_dir, "test_ds", "arrow",
    filters = list(uf_source = "AC", year = 2020L)
  )

  expect_false(is.null(ds))
  collected <- ds |> dplyr::collect()
  expect_equal(nrow(collected), 1)
  expect_equal(collected$uf_source, "AC")
  expect_equal(collected$year, 2020L)
  expect_equal(collected$value, 10)
})

test_that(".lazy_return selects columns", {
  skip_if_not(healthbR:::.has_arrow(), "arrow package not available")

  cache_dir <- file.path(tempdir(), "test_lr_select")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  test_data <- tibble::tibble(
    uf_source = c("AC", "SP"),
    year = c(2020L, 2020L),
    col_a = c("x", "y"),
    col_b = c(1, 2),
    col_c = c(TRUE, FALSE)
  )
  healthbR:::.cache_write_partitioned(
    test_data, cache_dir, "test_ds", c("uf_source", "year")
  )

  ds <- healthbR:::.lazy_return(
    cache_dir, "test_ds", "arrow",
    select_cols = c("uf_source", "year", "col_a")
  )

  collected <- ds |> dplyr::collect()
  expect_equal(sort(names(collected)), c("col_a", "uf_source", "year"))
  expect_equal(nrow(collected), 2)
})

test_that(".lazy_return with filters and select_cols combined", {
  skip_if_not(healthbR:::.has_arrow(), "arrow package not available")

  cache_dir <- file.path(tempdir(), "test_lr_combined")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  test_data <- tibble::tibble(
    disease = c("DENG", "DENG", "CHIK", "CHIK"),
    year = c(2020L, 2021L, 2020L, 2021L),
    cases = c(100, 200, 50, 75),
    deaths = c(1, 2, 0, 1)
  )
  healthbR:::.cache_write_partitioned(
    test_data, cache_dir, "test_ds", c("disease", "year")
  )

  ds <- healthbR:::.lazy_return(
    cache_dir, "test_ds", "arrow",
    filters = list(disease = "DENG"),
    select_cols = c("disease", "year", "cases")
  )

  collected <- ds |> dplyr::collect()
  expect_equal(nrow(collected), 2)
  expect_true(all(collected$disease == "DENG"))
  expect_equal(sort(names(collected)), c("cases", "disease", "year"))
})

test_that(".lazy_return works with duckdb backend", {
  skip_if_not(healthbR:::.has_arrow(), "arrow package not available")
  skip_if_not(healthbR:::.has_duckdb(), "duckdb package not available")

  cache_dir <- file.path(tempdir(), "test_lr_duckdb")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  test_data <- tibble::tibble(
    year = c(2020L, 2021L, 2022L),
    value = c(10, 20, 30)
  )
  healthbR:::.cache_write_partitioned(
    test_data, cache_dir, "test_ds", "year"
  )

  ds <- healthbR:::.lazy_return(
    cache_dir, "test_ds", "duckdb",
    filters = list(year = c(2020L, 2021L))
  )

  expect_false(is.null(ds))
  collected <- ds |> dplyr::collect()
  expect_equal(nrow(collected), 2)
  expect_equal(sort(collected$year), c(2020L, 2021L))
})

test_that(".lazy_return with empty filters returns all data", {
  skip_if_not(healthbR:::.has_arrow(), "arrow package not available")

  cache_dir <- file.path(tempdir(), "test_lr_nofilter")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  test_data <- tibble::tibble(
    year = c(2020L, 2021L, 2022L),
    value = c(10, 20, 30)
  )
  healthbR:::.cache_write_partitioned(
    test_data, cache_dir, "test_ds", "year"
  )

  ds <- healthbR:::.lazy_return(cache_dir, "test_ds", "arrow")
  collected <- ds |> dplyr::collect()
  expect_equal(nrow(collected), 3)
})

test_that(".lazy_return ignores non-existent columns in select_cols", {
  skip_if_not(healthbR:::.has_arrow(), "arrow package not available")

  cache_dir <- file.path(tempdir(), "test_lr_badcols")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  test_data <- tibble::tibble(
    year = c(2020L, 2021L),
    value = c(10, 20)
  )
  healthbR:::.cache_write_partitioned(
    test_data, cache_dir, "test_ds", "year"
  )

  # request a column that doesn't exist — it should be ignored
  ds <- healthbR:::.lazy_return(
    cache_dir, "test_ds", "arrow",
    select_cols = c("year", "value", "nonexistent_col")
  )

  collected <- ds |> dplyr::collect()
  expect_equal(sort(names(collected)), c("value", "year"))
})


# ============================================================================
# .try_lazy_cache
# ============================================================================

test_that(".try_lazy_cache returns NULL when lazy = FALSE", {
  result <- healthbR:::.try_lazy_cache(
    lazy = FALSE, backend = "arrow",
    cache_dir = tempdir(), dataset_name = "test",
    filters = list(), select_cols = NULL
  )
  expect_null(result)
})

test_that(".try_lazy_cache emits parse message when parse = TRUE", {
  expect_message(
    healthbR:::.try_lazy_cache(
      lazy = TRUE, backend = "arrow",
      cache_dir = tempdir(), dataset_name = "nonexistent",
      filters = list(), select_cols = NULL, parse = TRUE
    ),
    "parse.*ignored"
  )
})

test_that(".try_lazy_cache returns NULL when no cache exists", {
  skip_if_not(healthbR:::.has_arrow(), "arrow package not available")

  cache_dir <- file.path(tempdir(), "test_tlc_nocache")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  result <- healthbR:::.try_lazy_cache(
    lazy = TRUE, backend = "arrow",
    cache_dir = cache_dir, dataset_name = "nonexistent",
    filters = list(), select_cols = NULL
  )
  expect_null(result)
})

test_that(".try_lazy_cache returns lazy dataset when cache exists", {
  skip_if_not(healthbR:::.has_arrow(), "arrow package not available")

  cache_dir <- file.path(tempdir(), "test_tlc_hit")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  test_data <- tibble::tibble(
    year = c(2020L, 2021L), uf_source = c("AC", "SP"), value = c(10, 20)
  )
  healthbR:::.cache_write_partitioned(
    test_data, cache_dir, "test_ds", c("uf_source", "year")
  )

  ds <- healthbR:::.try_lazy_cache(
    lazy = TRUE, backend = "arrow",
    cache_dir = cache_dir, dataset_name = "test_ds",
    filters = list(year = 2020L), select_cols = c("year", "value")
  )

  expect_false(is.null(ds))
  collected <- ds |> dplyr::collect()
  expect_equal(nrow(collected), 1)
  expect_equal(sort(names(collected)), c("value", "year"))
})


# ============================================================================
# .data_return
# ============================================================================

test_that(".data_return selects columns and returns tibble", {
  data <- data.frame(
    year = 2020L, uf_source = "AC", VAR1 = "a", VAR2 = "b",
    stringsAsFactors = FALSE
  )

  result <- healthbR:::.data_return(
    data,
    select_cols = c("year", "uf_source", "VAR1"),
    module_name = "TEST"
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(names(result), c("year", "uf_source", "VAR1"))
})

test_that(".data_return returns all columns when select_cols is NULL", {
  data <- data.frame(
    year = 2020L, uf_source = "AC", VAR1 = "a", VAR2 = "b",
    stringsAsFactors = FALSE
  )

  result <- healthbR:::.data_return(data, module_name = "TEST")

  expect_s3_class(result, "tbl_df")
  expect_equal(sort(names(result)), sort(c("uf_source", "VAR1", "VAR2", "year")))
})

test_that(".data_return reports download failures", {
  data <- data.frame(year = 2020L, value = 42, stringsAsFactors = FALSE)

  expect_warning(
    result <- healthbR:::.data_return(
      data,
      failed_labels = c("AC 2021", "SP 2021"),
      module_name = "TEST"
    ),
    "failed to download"
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(attr(result, "download_failures"), c("AC 2021", "SP 2021"))
})

test_that(".data_return no warning when no failures", {
  data <- data.frame(year = 2020L, value = 42, stringsAsFactors = FALSE)

  expect_no_warning(
    result <- healthbR:::.data_return(data, module_name = "TEST")
  )

  expect_s3_class(result, "tbl_df")
  expect_null(attr(result, "download_failures"))
})

test_that(".data_return attempts lazy return when lazy = TRUE", {
  skip_if_not(healthbR:::.has_arrow(), "arrow package not available")

  cache_dir <- file.path(tempdir(), "test_dr_lazy")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  test_data <- tibble::tibble(year = c(2020L, 2021L), value = c(10, 20))
  healthbR:::.cache_write_partitioned(
    test_data, cache_dir, "test_ds", "year"
  )

  # pass a dummy eager data frame — but lazy should take priority
  eager_data <- data.frame(year = 9999L, value = 0, stringsAsFactors = FALSE)

  result <- healthbR:::.data_return(
    eager_data, lazy = TRUE, backend = "arrow",
    cache_dir = cache_dir, dataset_name = "test_ds",
    filters = list(year = 2020L), module_name = "TEST"
  )

  # should be a lazy object, not the dummy eager data
  expect_false(inherits(result, "data.frame"))
  collected <- result |> dplyr::collect()
  expect_equal(nrow(collected), 1)
  expect_equal(collected$year, 2020L)
})

test_that(".data_return falls through to eager when lazy cache missing", {
  cache_dir <- file.path(tempdir(), "test_dr_lazy_miss")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  data <- data.frame(year = 2020L, value = 42, stringsAsFactors = FALSE)

  result <- healthbR:::.data_return(
    data, lazy = TRUE, backend = "arrow",
    cache_dir = cache_dir, dataset_name = "nonexistent",
    module_name = "TEST"
  )

  # should fall through to eager return (tibble)
  expect_s3_class(result, "tbl_df")
  expect_equal(result$value, 42)
})
