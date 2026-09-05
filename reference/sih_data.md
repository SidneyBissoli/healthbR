# Download SIH Hospital Admission Microdata

Returns hospital admission microdata (SIH-RD, "AIH reduzida"). Each row
represents one hospital admission record (AIH). Data is organized
monthly – one file per state (UF) per billing competence (month).

## Usage

``` r
sih_data(
  year,
  month = NULL,
  vars = NULL,
  uf = NULL,
  diagnosis = NULL,
  parse = TRUE,
  col_types = NULL,
  cache = TRUE,
  cache_dir = NULL,
  lazy = FALSE,
  backend = c("arrow", "duckdb"),
  source = c("r2", "datasus"),
  r2_credentials = NULL
)
```

## Arguments

- year:

  Integer. Year(s) of the data. Required.

- month:

  Integer. Month(s) of the data (1-12). If NULL (default), downloads all
  12 months. Example: `1` (January), `1:6` (first semester).

- vars:

  Character vector. Variables to keep. If NULL (default), returns all
  available variables. Use
  [`sih_variables()`](https://sidneybissoli.github.io/healthbR/reference/sih_variables.md)
  to see available variables.

- uf:

  Character. Two-letter state abbreviation(s) to download. If NULL
  (default), downloads all 27 states. Example: `"SP"`, `c("SP", "RJ")`.

- diagnosis:

  Character. CID-10 code pattern(s) to filter by principal diagnosis
  (`DIAG_PRINC`). Supports partial matching (prefix). If NULL (default),
  returns all diagnoses. Example: `"I21"` (acute myocardial infarction),
  `"J"` (respiratory).

- parse:

  Logical. If TRUE (default), converts columns to appropriate types
  (integer, double, Date) based on the variable metadata. Use
  [`sih_variables()`](https://sidneybissoli.github.io/healthbR/reference/sih_variables.md)
  to see the target type for each variable. Set to FALSE for
  backward-compatible all-character output.

- col_types:

  Named list. Override the default type for specific columns. Names are
  column names, values are type strings: `"character"`, `"integer"`,
  `"double"`, `"date_dmy"`, `"date_ymd"`, `"date_ym"`, `"date"`.
  Example: `list(VAL_TOT = "character")` to keep VAL_TOT as character.

- cache:

  Logical. If TRUE (default), caches downloaded data for faster future
  access.

- cache_dir:

  Character. Directory for caching. Default:
  `tools::R_user_dir("healthbR", "cache")`.

- lazy:

  Logical. If TRUE, returns a lazy query object instead of a tibble.
  Requires the arrow package. The lazy object supports dplyr verbs
  (filter, select, mutate, etc.) which are pushed down to the query
  engine before collecting into memory. Call
  [`dplyr::collect()`](https://dplyr.tidyverse.org/reference/compute.html)
  to materialize the result. Default: FALSE.

- backend:

  Character. Backend for lazy evaluation: `"arrow"` (default) or
  `"duckdb"`. Only used when `lazy = TRUE`. DuckDB backend requires the
  duckdb package.

- source:

  Character. Source priority: `c("r2", "datasus")` (default) reads from
  the healthbr-data R2 mirror and falls back to the DATASUS FTP if the
  mirror yields nothing; `"r2"` or `"datasus"` alone pins a source. The
  R2 source requires the arrow package; without it the package uses the
  FTP directly.

- r2_credentials:

  List or NULL. Credentials for the R2 bucket (`access_key_id`,
  `secret_access_key`, optionally `endpoint` and `bucket`). NULL
  (default) uses the public read-only token of the healthbr-data mirror.

## Value

A tibble with hospital admission microdata. Includes columns `year`,
`month`, and `uf_source` to identify the source file when multiple
years/months/states are combined: `year`/`month` are the BILLING
COMPETENCE of the AIH (the month the account was processed), not the
admission date, which is `DT_INTER`; `uf_source` is the state of the
hospital, not of the patient's residence (`MUNIC_RES`). Two attributes
record where the data came from: `attr(x, "healthbr_source")` (`"r2"` or
`"datasus"`) and, for the mirror, `attr(x, "healthbr_provenance")`, a
tibble with one row per source file read (competence, UF, DATASUS URL,
MD5, size, record count and processing timestamp) – see
[`sih_status()`](https://sidneybissoli.github.io/healthbR/reference/sih_status.md).

## Details

By default data are read from the **healthbr-data R2 mirror** (Parquet
on Cloudflare R2, values byte-identical to the Ministry's `.dbc` files,
with provenance metadata for every file) and the package falls back to
the DATASUS FTP if the mirror is unreachable – see `source`. Both
transports share the same local cache, because the content is the same
by construction.

### Sources

The mirror stores each DATASUS file `RD{UF}{yy}{mm}.dbc` as one Parquet
partition `sih/rd/ano=YYYY/mes=MM/uf=XX/`, all columns as character, and
publishes a manifest with the MD5 and size of every source file. Reading
from it needs no decompression and transfers only the columns actually
used. The FTP path downloads the `.dbc` (decompressed internally with
vendored C code from the blast library; no external dependencies).

### Competence versus admission date

A file of competence `2023-01` holds the admissions billed in January
2023, including admissions that started months earlier; conversely the
admissions of December 2023 are spread over the competences of December
2023 to April 2024. Measured on the whole mirror (2016-2026), the four
competences following a year close 99.7-99.9% of that year's admissions.
To count admissions by the date they started, filter on `DT_INTER` after
reading a window of competences.

### Lazy evaluation with R2

With `lazy = TRUE` and the R2 source first, the returned object is a
remote dataset over the mirror: nothing is downloaded until
[`dplyr::collect()`](https://dplyr.tidyverse.org/reference/compute.html),
and filters/column selections are pushed down to the Parquet files.
Listing the mirror takes a few seconds. With `source = "datasus"`, lazy
evaluation works over the local cache as before.

SIH data is monthly, so an entire year for all states means 324 files
(27 UFs x 12 months). Use `uf` and `month` to limit reads.

### Parallel downloads

When downloading multiple files (e.g., several months or states),
install furrr and future and set a parallel plan to speed up downloads:
`future::plan(future::multisession, workers = 4)`. See
[`vignette("healthbR")`](https://sidneybissoli.github.io/healthbR/articles/healthbR.md)
for details.

## See also

[`censo_populacao()`](https://sidneybissoli.github.io/healthbR/reference/censo_populacao.md)
for population denominators to calculate hospitalization rates.

Other sih:
[`sih_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sih_cache_status.md),
[`sih_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sih_clear_cache.md),
[`sih_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sih_dictionary.md),
[`sih_info()`](https://sidneybissoli.github.io/healthbR/reference/sih_info.md),
[`sih_status()`](https://sidneybissoli.github.io/healthbR/reference/sih_status.md),
[`sih_variables()`](https://sidneybissoli.github.io/healthbR/reference/sih_variables.md),
[`sih_years()`](https://sidneybissoli.github.io/healthbR/reference/sih_years.md)

## Examples

``` r
if (FALSE) { # interactive()
# all admissions in Acre, January 2022
ac_jan <- sih_data(year = 2022, month = 1, uf = "AC")

# heart attacks in Sao Paulo, first semester 2022
infarct_sp <- sih_data(year = 2022, month = 1:6, uf = "SP",
                        diagnosis = "I21")

# only key variables, Rio de Janeiro, March 2022
sih_data(year = 2022, month = 3, uf = "RJ",
         vars = c("DIAG_PRINC", "DT_INTER", "SEXO",
                  "IDADE", "MORTE", "VAL_TOT"))
}
```
