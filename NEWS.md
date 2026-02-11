# healthbR 0.4.0

## New modules

* **SINASC (Sistema de Informacoes sobre Nascidos Vivos)**: Added module for
  accessing live birth microdata from DATASUS FTP as .dbc files (1996-2024).
  - `sinasc_years()`, `sinasc_info()` for module metadata
  - `sinasc_variables()`, `sinasc_dictionary()` for variable exploration
  - `sinasc_data()` for downloading live birth microdata per state (UF)
  - `sinasc_cache_status()`, `sinasc_clear_cache()` for cache management
  - Congenital anomaly filtering by CID-10 code (`anomaly` parameter)
  - Reuses shared DBC infrastructure (`.dbc2dbf()`, `.read_dbc()`, `.datasus_download()`)

# healthbR 0.3.0

## New modules

* **SIM (Sistema de Informacoes sobre Mortalidade)**: Added module for
  accessing mortality microdata from DATASUS FTP as .dbc files (CID-10,
  1996-2024).
  - `sim_years()`, `sim_info()` for module metadata
  - `sim_variables()`, `sim_dictionary()` for variable exploration
  - `sim_data()` for downloading mortality microdata per state (UF)
  - `sim_cache_status()`, `sim_clear_cache()` for cache management
  - Automatic age decoding from the IDADE variable (`decode_age = TRUE`)
  - Cause-of-death filtering by CID-10 code (`cause` parameter)
  - Efficient per-state downloads (e.g., ~1 MB for Acre vs ~150 MB for all)
  - Parquet caching when `arrow` is installed, .rds fallback otherwise

## New infrastructure

* **DBC decompression**: Added shared C infrastructure for reading DATASUS
  .dbc files (PKWare DCL compressed DBF). This enables future modules for
  SIH, SINASC, CNES, SIA, and SINAN.
  - Vendored `blast.c`/`blast.h` from Mark Adler (zlib license)
  - `dbc2dbf.c` written from scratch (MIT license)
  - Internal functions: `.dbc2dbf()`, `.read_dbc()`, `.datasus_download()`

## Dependencies

* Added `foreign` to Imports (for reading .dbf files after decompression).

# healthbR 0.2.0

## New modules

* **Censo Demografico**: Added module for accessing population denominators
  from the IBGE SIDRA API, covering Census years 1970-2022 and intercensitary
  estimates 2001-2021.
  - `censo_years()`, `censo_info()` for Census metadata
  - `censo_populacao()` for population by sex, age, race, urban/rural
  - `censo_estimativa()` for intercensitary population estimates
  - `censo_sidra_tables()`, `censo_sidra_search()` for table discovery
  - `censo_sidra_data()` for querying any Census SIDRA table
  - Shared SIDRA utilities extracted to `utils-sidra.R` (used by PNS and Census)
  - Added vignette: "Population Denominators from the Census with healthbR"

* **POF (Pesquisa de Orçamentos Familiares)**: Added complete module for
  accessing POF microdata from IBGE FTP, covering editions 2002-2003,
  2008-2009, and 2017-2018.
  - `pof_years()`, `pof_info()`, `pof_registers()` for survey metadata
  - `pof_dictionary()`, `pof_variables()` for variable exploration
  - `pof_data()` for downloading and importing microdata
  - `pof_cache_status()`, `pof_clear_cache()` for cache management
  - Survey design support via `as_survey = TRUE` (requires `srvyr`)
  - Health-focused data: food security (EBIA), food consumption,
    anthropometry, and health expenses
  - Parquet caching when `arrow` is installed
  - Added vignette: "Analyzing Health Data from POF with healthbR"

* **PNADC (PNAD Contínua)**: Added module for health-related supplementary
  modules from PNAD Contínua (deficiência, habitação, moradores, APS).

* **PNS (Pesquisa Nacional de Saúde)**: Added module for PNS microdata and
  SIDRA tabulated data access (2013, 2019).

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

* Added `survey` to Suggests for complex survey analysis support.

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
