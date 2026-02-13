# Changelog

## healthbR 0.10.0

### New modules

- **SISAB (Sistema de Informacao em Saude para a Atencao Basica)**:
  Added module for accessing primary care coverage indicators from the
  relatorioaps REST API.
  - [`sisab_years()`](https://sidneybissoli.github.io/healthbR/reference/sisab_years.md),
    [`sisab_info()`](https://sidneybissoli.github.io/healthbR/reference/sisab_info.md)
    for module metadata
  - [`sisab_variables()`](https://sidneybissoli.github.io/healthbR/reference/sisab_variables.md)
    for variable exploration
  - [`sisab_data()`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md)
    for downloading coverage data
  - [`sisab_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sisab_cache_status.md),
    [`sisab_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sisab_clear_cache.md)
    for cache management
  - **4 report types**: aps (APS coverage, default), sb (Oral health),
    acs (Community health agents), pns (PNS coverage). Use `type`
    parameter to select.
  - **4 geographic levels**: brazil, region, uf, municipality. Use
    `level` parameter to select.
  - **REST API access**: Unlike other DATASUS modules, SISAB uses a
    public REST API (no FTP, no .dbc/.dbf files). No authentication
    required.
  - **Aggregated data**: Coverage indicators per geographic unit and
    period (competencia CNES), not individual-level microdata.
  - Output includes `year` and `type` columns to identify the source
  - Column names preserved from API (camelCase)

## healthbR 0.9.0

### New modules

- **SI-PNI (Sistema de Informacao do Programa Nacional de
  Imunizacoes)**: Added module for accessing aggregated vaccination data
  from DATASUS FTP as plain .DBF files (1994-2019).
  - [`sipni_years()`](https://sidneybissoli.github.io/healthbR/reference/sipni_years.md),
    [`sipni_info()`](https://sidneybissoli.github.io/healthbR/reference/sipni_info.md)
    for module metadata
  - [`sipni_variables()`](https://sidneybissoli.github.io/healthbR/reference/sipni_variables.md),
    [`sipni_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sipni_dictionary.md)
    for variable exploration
  - [`sipni_data()`](https://sidneybissoli.github.io/healthbR/reference/sipni_data.md)
    for downloading vaccination data per state (UF)
  - [`sipni_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sipni_cache_status.md),
    [`sipni_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sipni_clear_cache.md)
    for cache management
  - **2 file types**: DPNI (doses applied, default) and CPNI
    (vaccination coverage). Use `type` parameter to select.
  - **Aggregated data**: Unlike other DATASUS modules, SI-PNI contains
    dose counts and coverage rates per municipality/vaccine/age group,
    not individual-level microdata.
  - **Plain .DBF files**: No DBC decompression needed (files are
    uncompressed).
  - Output includes `year` and `uf_source` columns
  - CPNI coverage field (`COBERT`) decimal separator automatically
    converted from comma to dot
  - Data on DATASUS FTP frozen at 2019; post-2019 requires SI-PNI web
    API (future work)

## healthbR 0.8.0

### New modules

- **SINAN (Sistema de Informacao de Agravos de Notificacao)**: Added
  module for accessing notifiable diseases surveillance microdata from
  DATASUS FTP as .dbc files (2007-2024).
  - [`sinan_years()`](https://sidneybissoli.github.io/healthbR/reference/sinan_years.md),
    [`sinan_info()`](https://sidneybissoli.github.io/healthbR/reference/sinan_info.md)
    for module metadata
  - [`sinan_diseases()`](https://sidneybissoli.github.io/healthbR/reference/sinan_diseases.md)
    for listing available diseases (agravos)
  - [`sinan_variables()`](https://sidneybissoli.github.io/healthbR/reference/sinan_variables.md),
    [`sinan_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sinan_dictionary.md)
    for variable exploration
  - [`sinan_data()`](https://sidneybissoli.github.io/healthbR/reference/sinan_data.md)
    for downloading disease notification microdata
  - [`sinan_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sinan_cache_status.md),
    [`sinan_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sinan_clear_cache.md)
    for cache management
  - **31 diseases**: DENG (Dengue, default), CHIK, ZIKA, TUBE, HANS,
    HEPA, MALA, SIFA, SIFC, SIFG, LEIV, LEIT, LEPT, MENI, and more. Use
    `disease` parameter to select.
  - **National files**: SINAN files are national (not per-state). Filter
    by UF using `SG_UF_NOT` or `ID_MUNICIP` columns after download.
  - Output includes `year` and `disease` columns
  - Reuses shared DBC infrastructure (`.dbc2dbf()`, `.read_dbc()`,
    `.datasus_download()`)

## healthbR 0.7.0

### New modules

- **CNES (Cadastro Nacional de Estabelecimentos de Saude)**: Added
  module for accessing the national health facility registry from
  DATASUS FTP as .dbc files (2005-2024).
  - [`cnes_years()`](https://sidneybissoli.github.io/healthbR/reference/cnes_years.md),
    [`cnes_info()`](https://sidneybissoli.github.io/healthbR/reference/cnes_info.md)
    for module metadata
  - [`cnes_variables()`](https://sidneybissoli.github.io/healthbR/reference/cnes_variables.md),
    [`cnes_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/cnes_dictionary.md)
    for variable exploration
  - [`cnes_data()`](https://sidneybissoli.github.io/healthbR/reference/cnes_data.md)
    for downloading health facility data per state (UF)
  - [`cnes_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/cnes_cache_status.md),
    [`cnes_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/cnes_clear_cache.md)
    for cache management
  - **13 file types**: ST (default), LT, PF, DC, EQ, SR, HB, EP, RC, IN,
    EE, EF, GM. Use `type` parameter to select.
  - **Monthly data**: CNES data is organized per month (one .dbc file
    per type/UF/month). Use `month` parameter to select specific months.
  - Output includes `year`, `month`, and `uf_source` columns
  - Reuses shared DBC infrastructure (`.dbc2dbf()`, `.read_dbc()`,
    `.datasus_download()`)

## healthbR 0.6.1

### Bug fixes

- Fixed POF dictionary parsing failure on Linux/Ubuntu.
  [`utils::unzip()`](https://rdrr.io/r/utils/unzip.html) creates
  filenames with invalid UTF-8 bytes on non-Windows systems, which
  caused [`grepl()`](https://rdrr.io/r/base/grep.html) and
  [`nchar()`](https://rdrr.io/r/base/nchar.html) to silently fail.
  Dictionary file lookup now uses byte-level matching
  (`useBytes = TRUE`, `nchar(type = "bytes")`) and renames extracted
  files to ASCII-safe names to prevent downstream encoding errors.

- Moved POF register validation before download in
  [`pof_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/pof_dictionary.md),
  so invalid register names are caught immediately without triggering a
  download.

### Documentation

- Replaced `\donttest{}` with `@examplesIf interactive()` across all 9
  modules (VIGITEL, PNS, PNADC, POF, Censo, SIM, SINASC, SIH, SIA).
  Examples that download data now only run in interactive sessions,
  following current CRAN guidelines.

- Marked internal `utils` topic with `@keywords internal` to fix pkgdown
  reference index build.

## healthbR 0.6.0

### New modules

- **SIA (Sistema de Informacoes Ambulatoriais)**: Added module for
  accessing outpatient production microdata from DATASUS FTP as .dbc
  files (2008-2024).
  - [`sia_years()`](https://sidneybissoli.github.io/healthbR/reference/sia_years.md),
    [`sia_info()`](https://sidneybissoli.github.io/healthbR/reference/sia_info.md)
    for module metadata
  - [`sia_variables()`](https://sidneybissoli.github.io/healthbR/reference/sia_variables.md),
    [`sia_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sia_dictionary.md)
    for variable exploration
  - [`sia_data()`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md)
    for downloading outpatient production microdata per state (UF)
  - [`sia_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sia_cache_status.md),
    [`sia_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sia_clear_cache.md)
    for cache management
  - **13 file types**: PA (default), BI, AD, AM, AN, AQ, AR, AB, ACF,
    ATD, AMP, SAD, PS. Use `type` parameter to select.
  - **Monthly data**: SIA data is organized per month (one .dbc file per
    type/UF/month). Use `month` parameter to select specific months.
  - Procedure filtering by SIGTAP code (`procedure` parameter)
  - Diagnosis filtering by CID-10 code (`diagnosis` parameter)
  - Output includes `year`, `month`, and `uf_source` columns
  - Reuses shared DBC infrastructure (`.dbc2dbf()`, `.read_dbc()`,
    `.datasus_download()`)

## healthbR 0.5.0

### New modules

- **SIH (Sistema de Informacoes Hospitalares)**: Added module for
  accessing hospital admission microdata from DATASUS FTP as .dbc files
  (2008-2024).
  - [`sih_years()`](https://sidneybissoli.github.io/healthbR/reference/sih_years.md),
    [`sih_info()`](https://sidneybissoli.github.io/healthbR/reference/sih_info.md)
    for module metadata
  - [`sih_variables()`](https://sidneybissoli.github.io/healthbR/reference/sih_variables.md),
    [`sih_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sih_dictionary.md)
    for variable exploration
  - [`sih_data()`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md)
    for downloading hospital admission microdata per state (UF)
  - [`sih_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sih_cache_status.md),
    [`sih_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sih_clear_cache.md)
    for cache management
  - **Monthly data**: SIH data is organized per month (one .dbc file per
    UF per month). Use `month` parameter to select specific months.
  - Principal diagnosis filtering by CID-10 code (`diagnosis` parameter)
  - Output includes `year`, `month`, and `uf_source` columns
  - Reuses shared DBC infrastructure (`.dbc2dbf()`, `.read_dbc()`,
    `.datasus_download()`)

## healthbR 0.4.0

### New modules

- **SINASC (Sistema de Informacoes sobre Nascidos Vivos)**: Added module
  for accessing live birth microdata from DATASUS FTP as .dbc files
  (1996-2024).
  - [`sinasc_years()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_years.md),
    [`sinasc_info()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_info.md)
    for module metadata
  - [`sinasc_variables()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_variables.md),
    [`sinasc_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_dictionary.md)
    for variable exploration
  - [`sinasc_data()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_data.md)
    for downloading live birth microdata per state (UF)
  - [`sinasc_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_cache_status.md),
    [`sinasc_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_clear_cache.md)
    for cache management
  - Congenital anomaly filtering by CID-10 code (`anomaly` parameter)
  - Reuses shared DBC infrastructure (`.dbc2dbf()`, `.read_dbc()`,
    `.datasus_download()`)

## healthbR 0.3.0

### New modules

- **SIM (Sistema de Informacoes sobre Mortalidade)**: Added module for
  accessing mortality microdata from DATASUS FTP as .dbc files (CID-10,
  1996-2024).
  - [`sim_years()`](https://sidneybissoli.github.io/healthbR/reference/sim_years.md),
    [`sim_info()`](https://sidneybissoli.github.io/healthbR/reference/sim_info.md)
    for module metadata
  - [`sim_variables()`](https://sidneybissoli.github.io/healthbR/reference/sim_variables.md),
    [`sim_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sim_dictionary.md)
    for variable exploration
  - [`sim_data()`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md)
    for downloading mortality microdata per state (UF)
  - [`sim_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sim_cache_status.md),
    [`sim_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sim_clear_cache.md)
    for cache management
  - Automatic age decoding from the IDADE variable (`decode_age = TRUE`)
  - Cause-of-death filtering by CID-10 code (`cause` parameter)
  - Efficient per-state downloads (e.g., ~1 MB for Acre vs ~150 MB for
    all)
  - Parquet caching when `arrow` is installed, .rds fallback otherwise

### New infrastructure

- **DBC decompression**: Added shared C infrastructure for reading
  DATASUS .dbc files (PKWare DCL compressed DBF). This enables future
  modules for SIH, SINASC, CNES, SIA, and SINAN.
  - Vendored `blast.c`/`blast.h` from Mark Adler (zlib license)
  - `dbc2dbf.c` written from scratch (MIT license)
  - Internal functions: `.dbc2dbf()`, `.read_dbc()`,
    `.datasus_download()`

### Dependencies

- Added `foreign` to Imports (for reading .dbf files after
  decompression).

## healthbR 0.2.0

### New modules

- **Censo Demografico**: Added module for accessing population
  denominators from the IBGE SIDRA API, covering Census years 1970-2022
  and intercensitary estimates 2001-2021.

  - [`censo_years()`](https://sidneybissoli.github.io/healthbR/reference/censo_years.md),
    [`censo_info()`](https://sidneybissoli.github.io/healthbR/reference/censo_info.md)
    for Census metadata
  - [`censo_populacao()`](https://sidneybissoli.github.io/healthbR/reference/censo_populacao.md)
    for population by sex, age, race, urban/rural
  - [`censo_estimativa()`](https://sidneybissoli.github.io/healthbR/reference/censo_estimativa.md)
    for intercensitary population estimates
  - [`censo_sidra_tables()`](https://sidneybissoli.github.io/healthbR/reference/censo_sidra_tables.md),
    [`censo_sidra_search()`](https://sidneybissoli.github.io/healthbR/reference/censo_sidra_search.md)
    for table discovery
  - [`censo_sidra_data()`](https://sidneybissoli.github.io/healthbR/reference/censo_sidra_data.md)
    for querying any Census SIDRA table
  - Shared SIDRA utilities extracted to `utils-sidra.R` (used by PNS and
    Census)
  - Added vignette: “Population Denominators from the Census with
    healthbR”

- **POF (Pesquisa de Orçamentos Familiares)**: Added complete module for
  accessing POF microdata from IBGE FTP, covering editions 2002-2003,
  2008-2009, and 2017-2018.

  - [`pof_years()`](https://sidneybissoli.github.io/healthbR/reference/pof_years.md),
    [`pof_info()`](https://sidneybissoli.github.io/healthbR/reference/pof_info.md),
    [`pof_registers()`](https://sidneybissoli.github.io/healthbR/reference/pof_registers.md)
    for survey metadata
  - [`pof_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/pof_dictionary.md),
    [`pof_variables()`](https://sidneybissoli.github.io/healthbR/reference/pof_variables.md)
    for variable exploration
  - [`pof_data()`](https://sidneybissoli.github.io/healthbR/reference/pof_data.md)
    for downloading and importing microdata
  - [`pof_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/pof_cache_status.md),
    [`pof_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/pof_clear_cache.md)
    for cache management
  - Survey design support via `as_survey = TRUE` (requires `srvyr`)
  - Health-focused data: food security (EBIA), food consumption,
    anthropometry, and health expenses
  - Parquet caching when `arrow` is installed
  - Added vignette: “Analyzing Health Data from POF with healthbR”

- **PNADC (PNAD Contínua)**: Added module for health-related
  supplementary modules from PNAD Contínua (deficiência, habitação,
  moradores, APS).

- **PNS (Pesquisa Nacional de Saúde)**: Added module for PNS microdata
  and SIDRA tabulated data access (2013, 2019).

### Breaking changes

- Complete refactoring of VIGITEL functions due to Ministry of Health
  website restructuring. Data is now distributed as a single
  consolidated file containing all years (2006-2024) instead of separate
  files per year.

- [`vigitel_data()`](https://sidneybissoli.github.io/healthbR/reference/vigitel_data.md)
  API changed:

  - New `format` parameter to choose between Stata (.dta) and CSV
    formats
  - `year` parameter now defaults to NULL (returns all years)
  - Removed `lazy` and `parallel` parameters (replaced by automatic
    parquet caching)
  - Removed `force_download` parameter (replaced by `force`)

- Removed `vigitel_download()` and `vigitel_convert_to_parquet()`
  functions. These are no longer needed as data processing is handled
  automatically.

- [`vigitel_variables()`](https://sidneybissoli.github.io/healthbR/reference/vigitel_variables.md)
  no longer requires a `year` parameter. Returns the full data
  dictionary.

### New features

- Added 2022 and 2024 data (newly available from Ministry of Health).
  Available years now span 2006-2024 (19 years).

- [`vigitel_data()`](https://sidneybissoli.github.io/healthbR/reference/vigitel_data.md)
  now supports downloading data in Stata (.dta) or CSV format via the
  `format` parameter. Stata format is recommended as it preserves
  variable labels.

- Automatic partitioned parquet caching: when the `arrow` package is
  installed, data is automatically cached in partitioned parquet format.
  This enables efficient reading of specific years without loading the
  entire dataset.

- Performance improvement: reading a single year from cache is now
  extremely fast as only that year’s partition is loaded.

- Added `haven` and `readr` to Imports for reading Stata and CSV files.

- Added `survey` to Suggests for complex survey analysis support.

### Bug fixes

- Fixed CRAN check issues related to `arrow` dependency and cache files.

## healthbR 0.1.1

CRAN release: 2026-02-04

### Changes

- Moved `arrow` package from `Imports` to `Suggests` for better
  cross-platform compatibility. The package now checks for `arrow`
  availability and provides informative error messages with installation
  instructions when needed.

- Added `cache_dir` parameter to all data fetching functions
  ([`vigitel_data()`](https://sidneybissoli.github.io/healthbR/reference/vigitel_data.md),
  `vigitel_download()`,
  [`vigitel_variables()`](https://sidneybissoli.github.io/healthbR/reference/vigitel_variables.md),
  [`vigitel_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/vigitel_dictionary.md),
  [`vigitel_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/vigitel_cache_status.md),
  [`vigitel_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/vigitel_clear_cache.md)).
  This allows using [`tempdir()`](https://rdrr.io/r/base/tempfile.html)
  for temporary storage that doesn’t persist after the R session.

- Updated examples to use `cache_dir = tempdir()` to avoid leaving files
  on the system during CRAN checks.

## healthbR 0.1.0

CRAN release: 2026-02-03

### healthbR 0.0.0.9000

#### New features

- [`vigitel_years()`](https://sidneybissoli.github.io/healthbR/reference/vigitel_years.md) -
  list available VIGITEL survey years
- [`vigitel_variables()`](https://sidneybissoli.github.io/healthbR/reference/vigitel_variables.md) -
  list variables available in a specific year
- [`vigitel_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/vigitel_dictionary.md) -
  get the data dictionary with variable descriptions
- [`vigitel_data()`](https://sidneybissoli.github.io/healthbR/reference/vigitel_data.md) -
  download and load VIGITEL data with multiple options:
  - Support for single or multiple years
  - Automatic caching to avoid repeated downloads
  - Parquet conversion for faster subsequent loads
  - Parallel downloads with `furrr`
  - Lazy evaluation with Arrow for memory-efficient processing
- `vigitel_convert_to_parquet()` - convert cached Excel files to Parquet
  format

#### Performance

- Parquet format support for 10-20x faster data loading
- Parallel download support via `furrr` package
- Lazy evaluation via Arrow for processing large datasets without
  loading into RAM
