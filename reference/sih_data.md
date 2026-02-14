# Download SIH Hospital Admission Microdata

Downloads and returns hospital admission microdata from DATASUS FTP.
Each row represents one hospital admission record (AIH). Data is
organized monthly – one .dbc file per state (UF) per month.

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
  backend = c("arrow", "duckdb")
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

## Value

A tibble with hospital admission microdata. Includes columns `year`,
`month`, and `uf_source` to identify the source when multiple
years/months/states are combined.

## Details

Data is downloaded from DATASUS FTP as .dbc files (one per state per
month). The .dbc format is decompressed internally using vendored C code
from the blast library. No external dependencies are required.

SIH data is monthly, so downloading an entire year for all states
requires 324 files (27 UFs x 12 months). Use `uf` and `month` to limit
downloads.

## See also

[`censo_populacao()`](https://sidneybissoli.github.io/healthbR/reference/censo_populacao.md)
for population denominators to calculate hospitalization rates.

Other sih:
[`sih_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sih_cache_status.md),
[`sih_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sih_clear_cache.md),
[`sih_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sih_dictionary.md),
[`sih_info()`](https://sidneybissoli.github.io/healthbR/reference/sih_info.md),
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
