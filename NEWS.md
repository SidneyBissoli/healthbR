# healthbR 0.2.0

## Breaking changes

* Complete refactoring of VIGITEL functions due to Ministry of Health website
  restructuring. Data is now distributed as a single consolidated file containing
  all years (2006-2024) instead of separate files per year.

* `vigitel_data()` API changed:
  - New `format` parameter to choose between Stata (.dta) and CSV formats
  - `year` parameter now defaults to NULL (returns all years)
  - Removed `lazy` and `parallel` parameters (replaced by automatic parquet caching)
  - Removed `force_download` parameter (replaced by `force`)

* Removed `vigitel_download()` and `vigitel_convert_to_parquet()` functions.
  These are no longer needed as data processing is handled automatically.

* `vigitel_variables()` no longer requires a `year` parameter. Returns the
  full data dictionary.

## New features

* Added 2022 and 2024 data (newly available from Ministry of Health).
  Available years now span 2006-2024 (19 years).

* `vigitel_data()` now supports downloading data in Stata (.dta) or CSV format
  via the `format` parameter. Stata format is recommended as it preserves
  variable labels.

* Automatic partitioned parquet caching: when the `arrow` package is installed,
  data is automatically cached in partitioned parquet format. This enables
  efficient reading of specific years without loading the entire dataset.

* Performance improvement: reading a single year from cache is now extremely
  fast as only that year's partition is loaded.

* Added `haven` and `readr` to Imports for reading Stata and CSV files.

## Bug fixes

* Fixed CRAN check issues related to `arrow` dependency and cache files.

# healthbR 0.1.1

## Changes

* Moved `arrow` package from `Imports` to `Suggests` for better cross-platform
  compatibility. The package now checks for `arrow` availability and provides
  informative error messages with installation instructions when needed.

* Added `cache_dir` parameter to all data fetching functions (`vigitel_data()`,
  `vigitel_download()`, `vigitel_variables()`, `vigitel_dictionary()`,
  `vigitel_cache_status()`, `vigitel_clear_cache()`). This allows using
  `tempdir()` for temporary storage that doesn't persist after the R session.

* Updated examples to use `cache_dir = tempdir()` to avoid leaving files on the
  system during CRAN checks.

# healthbR 0.1.0

## healthbR 0.0.0.9000

### New features

* `vigitel_years()` - list available VIGITEL survey years
* `vigitel_variables()` - list variables available in a specific year
* `vigitel_dictionary()` - get the data dictionary with variable descriptions
* `vigitel_data()` - download and load VIGITEL data with multiple options:
  - Support for single or multiple years
  - Automatic caching to avoid repeated downloads
  - Parquet conversion for faster subsequent loads
  - Parallel downloads with `furrr`
  - Lazy evaluation with Arrow for memory-efficient processing
* `vigitel_convert_to_parquet()` - convert cached Excel files to Parquet format

### Performance

* Parquet format support for 10-20x faster data loading
* Parallel download support via `furrr` package
* Lazy evaluation via Arrow for processing large datasets without loading into RAM
