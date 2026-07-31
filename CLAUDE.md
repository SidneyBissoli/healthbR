# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## What this package is

healthbR is an R package providing access to Brazilian public health
data from 16 sources (DATASUS FTP, IBGE, Ministry of Health APIs,
ANS/ANVISA open data portals). It downloads, caches, and returns tidy
tibbles. Under rOpenSci review (ropensci/software-review#751);
CRAN-targeted, so `devtools::check()` must stay at 0 errors / 0 warnings
/ 0 notes.

## Commands

All development uses devtools from an R session:

``` r

devtools::document()       # regenerate man/ and NAMESPACE after roxygen changes
devtools::test()           # run all tests
devtools::test(filter = "sim")   # run one module's tests (tests/testthat/test-sim.R)
devtools::check()          # full R CMD check
covr::package_coverage()   # coverage (target >= 75%)
```

Integration tests (which download real data) are skipped unless
`HEALTHBR_INTEGRATION=true`:

``` r

Sys.setenv(HEALTHBR_INTEGRATION = "true")
devtools::test(filter = "sim")
```

**Windows gotcha on this machine**: multi-line `Rscript -e "..."`
commands can segfault. Write the code to a `.R` file and run
`Rscript file.R` instead.

## Architecture

### Module pattern

Each of the 16 modules (sim, sinasc, sih, sia, sinan, cnes, sipni,
sisab, ans, anvisa, vigitel, pns, pnadc, pof, censo, plus shared infra)
consists of two files:

- `R/<module>.R` — exported functions and module-specific helpers
- `R/<module>_data_internal.R` — static metadata: available years, UF
  codes, variable metadata tibbles, dictionary data

Every module exposes the same API surface: `*_years()`, `*_info()`,
`*_variables()`, `*_dictionary()`, `*_data()`, `*_cache_status()`,
`*_clear_cache()`. ANVISA uses
[`anvisa_types()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_types.md)
instead of `anvisa_years()` (most of its data is snapshot, not
time-series). ANS additionally has
[`ans_operators()`](https://sidneybissoli.github.io/healthbR/reference/ans_operators.md).

Internal functions use a dot prefix (`.sim_validate_year()`); most
module-level validators are 1-line delegates to shared helpers.

### Shared infrastructure (`R/utils-*.R`)

This is where cross-cutting behavior lives — change here affects all
modules:

- **`utils-cache.R`** — Hive-partitioned parquet datasets (e.g. SIM
  partitions on `c("uf_source", "year")`, SIH on
  `c("uf_source", "year", "month")`). Also flat cache
  (`.cache_read()`/`.cache_write()`) used by ANS, ANVISA, SISAB. Shared
  `.cache_status()`/`.clear_cache()` implementations. Lazy-eval helpers:
  `.try_lazy_cache()` (pre-download cache check) and `.data_return()`
  (post-download select/parse/return) — used by the 6 main DATASUS
  modules.
- **`utils-download.R`** — `.http_download()` (with `ssl_verifypeer`
  param for ANVISA), `.http_download_resumable()` (HTTP Range),
  `.multi_download()` (concurrent via
  [`curl::multi_download()`](https://jeroen.r-universe.dev/curl/reference/multi_download.html)),
  FTP download with exponential-backoff retry (`ftp_use_epsv=FALSE`
  required for DATASUS).
- **`utils-parallel.R`** — `.map_parallel()`: furrr when a future plan
  is set, purrr fallback otherwise; `.progress` param drives cli
  progress bars. All module download loops go through this.
- **`utils-validate.R`** — `.validate_year()`, `.validate_month()`,
  `.validate_uf()`, `.validate_quarter()`.
- **`utils-search.R`** — `.strip_accents()` (uses
  [`chartr()`](https://rdrr.io/r/base/chartr.html), see gotchas) and
  `.search_metadata()` backing all `*_variables(search=)`.
- **`utils-parse.R`** — smart type parsing (`parse = TRUE` in DATASUS
  `*_data()`): `.parse_columns()`, `.build_type_spec()`. Conservative —
  coded categorical fields stay character; only genuinely
  quantitative/date fields convert.
- **`utils-sidra.R`** — IBGE SIDRA API client (PNS, Censo).

### Data flow in a `*_data()` call

validate params → `.try_lazy_cache()` (return lazy arrow/duckdb query or
cached data if complete) → download missing files via `.map_parallel()`
→ decompress/read → write to partitioned parquet cache →
`.data_return()` (column select, type parse, failure report, tibble).
All cached data is stored all-character; typing happens at return time.
`lazy = TRUE` skips parsing and returns an arrow/duckdb query.

### DBC infrastructure (`src/` + `R/dbc_infrastructure.R`)

DATASUS distributes `.dbc` files (DBF compressed with PKWare DCL).
Vendored C code decompresses them: `blast.c`/`blast.h` (Mark Adler, zlib
license), `dbc2dbf.c` (written for this package, MIT). The DBF header
size lives at byte offset 8 (uint16 LE). Resulting `.dbf` is read with
`foreign::read.dbf(as.is = TRUE)`. Licensing details in
`inst/COPYRIGHTS`.

### Error-handling convention (intentional asymmetry)

DATASUS modules
[`cli::cli_abort()`](https://cli.r-lib.org/reference/cli_abort.html)
when all downloads fail; IBGE SIDRA modules warn and return an empty
tibble for valid-but-empty API queries. Don’t “unify” these.

## Coding conventions (from CONTRIBUTING.md)

- Native pipe `|>`, never `%>%`
- [`stringr::str_c()`](https://stringr.tidyverse.org/reference/str_c.html)
  instead of [`paste0()`](https://rdrr.io/r/base/paste.html)
- All user messages via
  [`cli::cli_inform()`](https://cli.r-lib.org/reference/cli_abort.html)/`cli_warn()`/`cli_abort()`
  — never [`cat()`](https://rdrr.io/r/base/cat.html),
  [`message()`](https://rdrr.io/r/base/message.html),
  [`warning()`](https://rdrr.io/r/base/warning.html),
  [`stop()`](https://rdrr.io/r/base/stop.html)
- Unicode escapes for non-ASCII in strings (`ç`, `ã`) — the package must
  stay ASCII-clean for CRAN
- Examples use `@examplesIf interactive()`, not `\donttest{}`
- Comments in English, lowercase after `#`

## Windows/encoding gotchas

- `iconv(x, to = "ASCII//TRANSLIT")` segfaults on Windows R — use
  [`chartr()`](https://rdrr.io/r/base/chartr.html) for accent stripping
  (already wrapped in `.strip_accents()`)
- [`utils::unzip()`](https://rdrr.io/r/utils/unzip.html) fails on ZIP
  entries with Portuguese characters in filenames — PowerShell
  `Expand-Archive` is the fallback
- [`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html)
  data masking: a column can shadow a same-named function parameter.
  Prefer base R subsetting (`df[tolower(df$col) == tolower(param), ]`)
  in those spots.
- CI:
  [`foreign::write.dbf()`](https://rdrr.io/pkg/foreign/man/write.dbf.html)
  fails silently on Ubuntu — tests use pre-computed base64 DBF bytes
  instead of writing DBFs at test time.
