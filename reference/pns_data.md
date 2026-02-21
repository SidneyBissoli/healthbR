# Download PNS microdata

Downloads and returns PNS microdata for specified years from the IBGE
FTP. Data is cached locally to avoid repeated downloads. When the
`arrow` package is installed, data is cached in parquet format for
faster subsequent reads.

## Usage

``` r
pns_data(
  year = NULL,
  vars = NULL,
  cache_dir = NULL,
  refresh = FALSE,
  lazy = FALSE,
  backend = c("arrow", "duckdb")
)
```

## Arguments

- year:

  Numeric or vector. Year(s) to download (2013, 2019). Use NULL to
  download all available years. Default is NULL.

- vars:

  Character vector. Variables to select. Use NULL for all variables.
  Default is NULL.

- cache_dir:

  Character. Directory for caching downloaded files. Default uses
  `tools::R_user_dir("healthbR", "cache")`.

- refresh:

  Logical. If TRUE, re-download even if file exists in cache. Default is
  FALSE.

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

A tibble with PNS microdata.

## Details

The PNS (Pesquisa Nacional de Saude) is a household survey conducted by
IBGE in partnership with the Ministry of Health. It provides
comprehensive data on health conditions, lifestyle, and healthcare
access of the Brazilian population.

### Survey design variables

For proper statistical analysis with complex survey design, use the
following weight variables with the `srvyr` or `survey` packages:

- `V0028`: household weight

- `V0029`: selected person weight

- `V0030`: person weight with non-response adjustment

- `UPA_PNS`: primary sampling unit

- `V0024`: stratum

### Parallel downloads

When downloading multiple years, install furrr and future and set a
parallel plan to speed up downloads:
`future::plan(future::multisession, workers = 4)`. See
[`vignette("healthbR")`](https://sidneybissoli.github.io/healthbR/articles/healthbR.md)
for details.

## Data source

Data is downloaded from the IBGE FTP server:
`https://ftp.ibge.gov.br/PNS/`

## Examples

``` r
if (FALSE) { # interactive()
# download PNS 2019 data
df <- pns_data(year = 2019, cache_dir = tempdir())

# download all years
df_all <- pns_data(cache_dir = tempdir())

# select specific variables
df_subset <- pns_data(
  year = 2019,
  vars = c("V0001", "C006", "C008", "V0028"),
  cache_dir = tempdir()
)
}
```
