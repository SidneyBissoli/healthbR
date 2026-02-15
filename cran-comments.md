## R CMD check results

0 errors | 0 warnings | 0 notes

* Resubmission of 0.2.0 addressing reviewer feedback:
  - Removed all Brazilian government URLs from vignettes and Rd files
    to avoid timeout/SSL NOTEs (these servers are frequently unreliable
    from outside Brazil). Domain names are preserved as plain text for
    reference.

## Changes since last CRAN release (0.1.1)

* Added 7 new data modules: CNES (health facilities), SINAN (notifiable
  diseases), SI-PNI (vaccination), SISAB (primary care coverage), ANS
  (supplementary health), ANVISA (health surveillance), and extended SI-PNI
  with post-2019 OpenDataSUS CSV support. Total: 16 modules.
* Added Hive-style partitioned parquet caching, lazy evaluation (Arrow/DuckDB),
  parallel downloads, smart type parsing for DATASUS modules.
* Extracted shared helpers for validation, search, cache, and return logic.
* Removed deprecated flat cache migration infrastructure.

## Test environments

* Local: Windows 11 Pro, R 4.5.2
* GitHub Actions:
  - Ubuntu Linux 22.04, R release
  - Ubuntu Linux 22.04, R devel
  - Ubuntu Linux 22.04, R oldrel-1
  - Windows Server 2022, R release
  - macOS (ARM64), R release

## Notes

The package includes compiled C code (`src/blast.c`, `src/dbc2dbf.c`) for
decompressing DATASUS .dbc files (PKWare DCL compressed DBF). The vendored
`blast.c`/`blast.h` are from Mark Adler (zlib license); `dbc2dbf.c` is
original code (MIT license). Both are documented in `inst/COPYRIGHTS`.

All examples that download data are wrapped in `@examplesIf interactive()`
to avoid network access during R CMD check.

## Existing CRAN NOTE (r-oldrel-macos-x86_64)

The NOTE "Package suggested but not available for checking: 'arrow'" on
r-oldrel-macos-x86_64 is expected. `arrow` is in Suggests and all code
checks its availability with `requireNamespace()` before use, falling
back to .rds caching when unavailable.
