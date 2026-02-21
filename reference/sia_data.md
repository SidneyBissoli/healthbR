# Download SIA Outpatient Production Microdata

Downloads and returns outpatient production microdata from DATASUS FTP.
Each row represents one outpatient production record. Data is organized
monthly – one .dbc file per type, state (UF), and month.

## Usage

``` r
sia_data(
  year,
  type = "PA",
  month = NULL,
  vars = NULL,
  uf = NULL,
  procedure = NULL,
  diagnosis = NULL,
  parse = TRUE,
  col_types = NULL,
  cache = TRUE,
  cache_dir = NULL,
  lazy = FALSE,
  backend = c("arrow", "duckdb")
)
```

## Arguments

- year:

  Integer. Year(s) of the data. Required.

- type:

  Character. File type to download. Default: `"PA"` (outpatient
  production). See
  [`sia_info()`](https://sidneybissoli.github.io/healthbR/reference/sia_info.md)
  for all 13 types.

- month:

  Integer. Month(s) of the data (1-12). If NULL (default), downloads all
  12 months. Example: `1` (January), `1:6` (first semester).

- vars:

  Character vector. Variables to keep. If NULL (default), returns all
  available variables. Use
  [`sia_variables()`](https://sidneybissoli.github.io/healthbR/reference/sia_variables.md)
  to see available variables.

- uf:

  Character. Two-letter state abbreviation(s) to download. If NULL
  (default), downloads all 27 states. Example: `"SP"`, `c("SP", "RJ")`.

- procedure:

  Character. SIGTAP procedure code pattern(s) to filter by
  (`PA_PROC_ID`). Supports partial matching (prefix). If NULL (default),
  returns all procedures. Example: `"0301"` (consultations).

- diagnosis:

  Character. CID-10 code pattern(s) to filter by principal diagnosis
  (`PA_CIDPRI`). Supports partial matching (prefix). If NULL (default),
  returns all diagnoses. Example: `"J"` (respiratory diseases).

- parse:

  Logical. If TRUE (default), converts columns to appropriate types
  (integer, double, Date) based on the variable metadata. Use
  [`sia_variables()`](https://sidneybissoli.github.io/healthbR/reference/sia_variables.md)
  to see the target type for each variable. Set to FALSE for
  backward-compatible all-character output.

- col_types:

  Named list. Override the default type for specific columns. Names are
  column names, values are type strings: `"character"`, `"integer"`,
  `"double"`, `"date_dmy"`, `"date_ymd"`, `"date_ym"`, `"date"`.
  Example: `list(PA_VALAPR = "character")` to keep PA_VALAPR as
  character.

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

## Value

A tibble with outpatient production microdata. Includes columns `year`,
`month`, and `uf_source` to identify the source when multiple
years/months/states are combined.

## Details

Data is downloaded from DATASUS FTP as .dbc files (one per
type/state/month). The .dbc format is decompressed internally using
vendored C code from the blast library. No external dependencies are
required.

SIA data is monthly, so downloading an entire year for all states
requires 324 files (27 UFs x 12 months) per type. Use `uf` and `month`
to limit downloads.

The SIA has 13 file types. The default `"PA"` (outpatient production) is
the most commonly used. Use
[`sia_info()`](https://sidneybissoli.github.io/healthbR/reference/sia_info.md)
to see all types.

### Parallel downloads

When downloading multiple files (e.g., several months or states),
install furrr and future and set a parallel plan to speed up downloads:
`future::plan(future::multisession, workers = 4)`. See
[`vignette("healthbR")`](https://sidneybissoli.github.io/healthbR/articles/healthbR.md)
for details.

## See also

[`sia_info()`](https://sidneybissoli.github.io/healthbR/reference/sia_info.md)
for file type descriptions,
[`censo_populacao()`](https://sidneybissoli.github.io/healthbR/reference/censo_populacao.md)
for population denominators.

Other sia:
[`sia_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sia_cache_status.md),
[`sia_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sia_clear_cache.md),
[`sia_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sia_dictionary.md),
[`sia_info()`](https://sidneybissoli.github.io/healthbR/reference/sia_info.md),
[`sia_variables()`](https://sidneybissoli.github.io/healthbR/reference/sia_variables.md),
[`sia_years()`](https://sidneybissoli.github.io/healthbR/reference/sia_years.md)

## Examples

``` r
if (FALSE) { # interactive()
# all outpatient production in Acre, January 2022
ac_jan <- sia_data(year = 2022, month = 1, uf = "AC")

# filter by procedure code
consult <- sia_data(year = 2022, month = 1, uf = "AC",
                    procedure = "0301")

# filter by diagnosis (CID-10)
resp <- sia_data(year = 2022, month = 1, uf = "AC",
                 diagnosis = "J")

# only key variables
sia_data(year = 2022, month = 1, uf = "AC",
         vars = c("PA_PROC_ID", "PA_CIDPRI", "PA_SEXO",
                  "PA_IDADE", "PA_VALAPR"))

# different file type (APAC Medicamentos)
med <- sia_data(year = 2022, month = 1, uf = "AC", type = "AM")
}
```
