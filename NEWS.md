# healthbR (development version)

## DATASUS year coverage (fixes a broken download)

* **SINAN**: 2023, 2024 and 2025 were promoted by DATASUS from `PRELIM/` to
  `FINAIS/`; the package still built `PRELIM/` URLs for 2023-2024, which no
  longer exist on the FTP, so `sinan_data(2023)`/`sinan_data(2024)` failed.
  Year lists updated: final = 2007-2025, preliminary = 2026.
* **SIH**, **SIA**, **CNES**: 2025 and 2026 (files published through
  2026-05/06/07) are now accepted as preliminary years; 2024 is now final.

Detected by the portfolio source monitor (edition probing against the
DATASUS FTP); the year lists in `R/*_data_internal.R` remain the source of
truth until discovery is made dynamic.

# healthbR 0.3.1

## SI-PNI dictionary corrections (important)

* **The built-in SI-PNI dictionary and label maps were wrong** and have been
  regenerated from the Ministry's official .cnv/.dbf dictionary files (as
  published on the healthbr-data mirror). The 0.2.0 hand-written table
  mislabeled 19 of 20 IMUNO codes — e.g. data code `09` is *Haemophilus
  influenzae tipo b (Hib)* per the official .cnv, not *BCG* (BCG is data
  code `02`) — and used DOSE/FX_ETARIA codes that do not occur in the data
  at all. Any decoding done with the built-in dictionary of previous
  versions should be redone. Regeneration script: `data-raw/sipni-dictionaries.R`.
* **New `lookup = TRUE` in `sipni_dictionary()`**: returns a data-code
  lookup (one row per value as it appears in the data, expanding the .cnv
  `source_codes` — including comma lists like `88,45` and ranges like
  `11-31`), ready to join against `sipni_data()` results. Joining data
  against the .cnv `code` column decodes to wrong labels; the vignette
  examples were corrected accordingly. Overlapping categories are resolved
  by specificity — explicitly listed codes beat range catch-alls — so
  residuals like FX_ETARIA "Idade ignorada" (source codes `00-99`) only
  label codes no specific category claimed.

## Fixes and polish

* **Local partitioned caches are now opened with `unify_schemas = TRUE`**
  (all modules): when cached years carry different column sets — DPNI 1994
  has 7 columns, 2019 has 12 — reads used the first file's schema and
  silently dropped the extra columns of other years.
* Results served from the local cache now place the identifier columns
  (`year`, `month`, `uf_source`) first, matching fresh downloads.
* `sipni_cache_status()` (and every module's `*_cache_status()`) now also
  reports hive-partitioned cache datasets, which were previously invisible.
* Roxygen comments no longer leak `\u` escapes into Rd files
  (R CMD check WARNING).
* Test hygiene: tests hitting httpbin.org now skip when the service is
  unreachable; `pnadc_apply_survey_design()` error tests skip without
  `srvyr`.

# healthbR 0.3.0

## SI-PNI: R2 backend (fixes #1)

The old OpenDataSUS host (`arquivosdadosabertos.saude.gov.br`) was
decommissioned and, as of 2026, the Ministry removed the 2020-2025 microdata
files from the new location as well — `sipni_data()` for years >= 2020 had
been failing with 404 (#1). This release makes the
[healthbr-data](https://github.com/SidneyBissoli/healthbr-data) mirror
(hive-partitioned Parquet on Cloudflare R2, values byte-identical to the
Ministry's files, complete 2020+ series) the default source for the whole
SI-PNI module:

* **`source` argument** in `sipni_data()` and `sipni_dictionary()`:
  `c("r2", "datasus")` (default) reads from the R2 mirror and falls back to
  the official DATASUS/OpenDataSUS sources automatically; pass a single
  value to pin a source. `r2_credentials` allows pointing at another
  S3-compatible bucket.
* **`sipni_status()`** (new): month/UF-level availability and provenance of
  the mirror, read from its `manifest.json` files (processing timestamp,
  Ministry source URL, record counts). Manifests are cached locally and
  revalidated by ETag.
* **Provenance attributes**: results carry `healthbr_source` (which source
  served each era) and, for R2 reads, `healthbr_provenance` (per-partition
  processing timestamp + source URL).
* **Column names for 2020+ differ by source**: the mirror publishes the
  Ministry's JSON exports (56 fields: `dt_vacina`, `ds_vacina`, ...), while
  the OpenDataSUS CSVs use different names (`data_vacina`,
  `descricao_vacina`, ...). Each source returns its columns exactly as
  published — no renaming. See `sipni_variables(type = "API", source =)`.
* **`lazy = TRUE` with R2** returns the remote arrow dataset itself: dplyr
  verbs are pushed down and only the touched partitions are transferred
  (partition columns keep the bucket layout: `ano`, `mes`, `uf`).
* **Aggregates (1994-2019) and dictionaries** are also served from the
  mirror by default (much faster than DATASUS FTP, which remains available
  via `source = "datasus"`); the R2 dictionaries are the full versions
  converted from the Ministry's original .cnv/.dbf files, with a
  `source_codes` traceability column.
* The DATASUS CSV URL was updated to the new CKAN S3 address (only the
  current year is published there).
* The R2 backend requires the `arrow` package (in Suggests); without it,
  `sipni_data()` falls back to DATASUS with a message.

# healthbR 0.2.0

## New modules

* **CNES (National Health Facility Registry)**: Health facility data from
  DATASUS FTP as .dbc files (2005-2024). 13 file types (ST, LT, PF, DC, EQ,
  SR, HB, EP, RC, IN, EE, EF, GM), monthly data per UF.

* **SINAN (Notifiable Diseases Surveillance)**: Disease notification microdata
  from DATASUS FTP as .dbc files (2007-2024). 31 diseases including DENG, CHIK,
  ZIKA, TUBE, HANS, HEPA, MALA, and more.

* **SI-PNI (National Immunization Program)**: Aggregated vaccination data from
  DATASUS FTP as .DBF files (1994-2019), plus individual-level microdata from
  OpenDataSUS CSV (2020-2025). Transparent year-based routing between sources.

* **SISAB (Primary Care Health Information)**: Coverage indicators from the
  relatorioaps REST API. 4 report types (aps, sb, acs, pns) at 4 geographic
  levels (brazil, region, uf, municipality).

* **ANS (Supplementary Health)**: Beneficiary, complaint, and financial data
  from the ANS open data portal. Plus `ans_operators()` for operator registry.

* **ANVISA (Health Surveillance)**: Product registrations, pharmacovigilance,
  hemovigilance, technovigilance, and controlled substance sales (SNGPC)
  from the ANVISA open data portal. 14 data types total.

* **POF (Household Budget Survey)**: Food security, consumption, and health
  expenditure microdata from IBGE FTP (2002-2003, 2008-2009, 2017-2018).

* **PNADC (PNAD Continua)**: Health-related supplementary modules from PNAD
  Continua (deficiencia, habitacao, moradores, APS).

* **PNS (National Health Survey)**: Microdata and SIDRA tabulated data
  (2013, 2019).

* **Censo Demografico**: Population denominators from the IBGE SIDRA API,
  covering Census years 1970-2022 and intercensitary estimates 2001-2021.

## Performance improvements

* Hive-style partitioned parquet caching for all DATASUS modules.

* Lazy evaluation with `lazy = TRUE` and `backend = "arrow"` or `"duckdb"`
  for out-of-memory queries.

* Parallel downloads via `.map_parallel()` (furrr when configured, purrr
  fallback).

* Download progress bars for all modules using `cli::cli_progress_bar()`.
  Shows spinner, current/total count, progress bar, and estimated time
  remaining (ETA) during multi-file downloads.

* Concurrent HTTP downloads for SI-PNI multi-month CSV requests via
  `curl::multi_download()`.

* Resumable HTTP downloads via Range headers for large files.

* Smart type parsing (`parse = TRUE`) for all 7 DATASUS modules, with
  automatic numeric and date column conversion. Use `col_types` for
  fine-grained control or `parse = FALSE` for all-character.

## Refactoring

* Extracted shared helpers for validation, search, cache management, and
  return logic, eliminating ~1100 lines of duplication across modules.

* Reduced cyclomatic complexity across 11 high-complexity functions by
  extracting internal subfunctions. All exported and internal functions now
  have cyclomatic complexity below 15.

* Removed deprecated flat cache migration infrastructure.

* Moved `readxl` and `haven` from Imports to Suggests.

* Removed unused `vroom` from Suggests.

## Documentation

* Added "Parallel downloads" section to all 12 `*_data()` help pages
  (`?sim_data`, `?sih_data`, etc.) explaining how to enable parallel
  processing via `future::plan()`.

* Added "Parallel downloads" section to README with a working example.

## Governance

* Added `CONTRIBUTING.md` with contributor guidelines.

* Added `CODE_OF_CONDUCT.md` (Contributor Covenant v2.1).

## Breaking changes

* Complete refactoring of VIGITEL functions due to Ministry of Health website
  restructuring. Data is now distributed as a single consolidated file
  containing all years (2006-2024) instead of separate files per year.

* `vigitel_data()` API changed: new `format` parameter, `year` defaults to

  NULL (all years), removed `lazy`/`parallel`/`force_download` parameters.

* Removed `vigitel_download()` and `vigitel_convert_to_parquet()` functions.

## Bug fixes

* Fixed PNS Arrow expression error with partition filtering.
* Fixed `pns_sidra_data()` unknown table warning.
* Fixed POF dictionary parsing failure on Linux/Ubuntu.
* Fixed SI-PNI download crash when DATASUS FTP file is missing or corrupted
  (added defensive `file.exists()` guard before `file.size()` check).

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
