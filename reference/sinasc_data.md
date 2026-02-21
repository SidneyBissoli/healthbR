# Download SINASC Live Birth Microdata

Downloads and returns live birth microdata from DATASUS FTP. Each row
represents one live birth record (Declaracao de Nascido Vivo). Data is
downloaded per state (UF) as compressed .dbc files, decompressed
internally, and returned as a tibble.

## Usage

``` r
sinasc_data(
  year,
  vars = NULL,
  uf = NULL,
  anomaly = NULL,
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

- vars:

  Character vector. Variables to keep. If NULL (default), returns all
  available variables. Use
  [`sinasc_variables()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_variables.md)
  to see available variables.

- uf:

  Character. Two-letter state abbreviation(s) to download. If NULL
  (default), downloads all 27 states. Example: `"SP"`, `c("SP", "RJ")`.

- anomaly:

  Character. CID-10 code pattern(s) to filter by congenital anomaly
  (`CODANOMAL`). Supports partial matching (prefix). If NULL (default),
  returns all records. Example: `"Q90"` (Down syndrome), `"Q"` (all
  anomalies).

- parse:

  Logical. If TRUE (default), converts columns to appropriate types
  (integer, double, Date) based on the variable metadata. Use
  [`sinasc_variables()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_variables.md)
  to see the target type for each variable. Set to FALSE for
  backward-compatible all-character output.

- col_types:

  Named list. Override the default type for specific columns. Names are
  column names, values are type strings: `"character"`, `"integer"`,
  `"double"`, `"date_dmy"`, `"date_ymd"`, `"date_ym"`, `"date"`.
  Example: `list(PESO = "character")` to keep PESO as character.

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

A tibble with live birth microdata. Includes columns `year` and
`uf_source` to identify the source when multiple years/states are
combined.

## Details

Data is downloaded from DATASUS FTP as .dbc files (one per state per
year). The .dbc format is decompressed internally using vendored C code
from the blast library. No external dependencies are required.

When `uf` is specified, only the requested state(s) are downloaded,
making the operation much faster than downloading the entire country.

### Parallel downloads

When downloading multiple files (e.g., several years or states), install
furrr and future and set a parallel plan to speed up downloads:
`future::plan(future::multisession, workers = 4)`. See
[`vignette("healthbR")`](https://sidneybissoli.github.io/healthbR/articles/healthbR.md)
for details.

## See also

[`censo_populacao()`](https://sidneybissoli.github.io/healthbR/reference/censo_populacao.md)
for population denominators to calculate birth rates.

Other sinasc:
[`sinasc_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_cache_status.md),
[`sinasc_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_clear_cache.md),
[`sinasc_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_dictionary.md),
[`sinasc_info()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_info.md),
[`sinasc_variables()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_variables.md),
[`sinasc_years()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_years.md)

## Examples

``` r
if (FALSE) { # interactive()
# all births in Acre, 2022
ac_2022 <- sinasc_data(year = 2022, uf = "AC")

# births with anomalies in Sao Paulo, 2020-2022
anomalies_sp <- sinasc_data(year = 2020:2022, uf = "SP", anomaly = "Q")

# only key variables, Rio de Janeiro, 2022
sinasc_data(year = 2022, uf = "RJ",
            vars = c("DTNASC", "SEXO", "PESO",
                     "IDADEMAE", "PARTO", "CONSULTAS"))
}
```
