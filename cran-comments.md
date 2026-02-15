## R CMD check results

0 errors | 0 warnings | 0 notes

* Resubmission of 0.2.0 addressing reviewer feedback:
  - Fixed 301 redirect URL (wiki.saude.gov.br/sigtap/) in three vignettes.
  - Added single quotes around non-English proper nouns, acronyms, and
    technical terms in DESCRIPTION to resolve spelling NOTE.

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

FTP URLs (`ftp://ftp.datasus.gov.br/...`) are intentional -- DATASUS
distributes public health microdata exclusively via FTP. These may time
out during URL checks but are functional.

The ANVISA open data portal (`https://dados.anvisa.gov.br/dados/`) has
a self-signed or misconfigured SSL certificate. The URL is correct and
functional; the package uses `ssl_verifypeer = FALSE` as a workaround
(documented in code). This may cause SSL verification failure during
URL checks.

## Existing CRAN NOTE (r-oldrel-macos-x86_64)

The NOTE "Package suggested but not available for checking: 'arrow'" on
r-oldrel-macos-x86_64 is expected. `arrow` is in Suggests and all code
checks its availability with `requireNamespace()` before use, falling
back to .rds caching when unavailable.
