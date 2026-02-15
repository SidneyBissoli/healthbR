# Download PNADC microdata

Downloads and returns PNADC microdata for the specified module and
year(s) from the IBGE FTP. Data is cached locally to avoid repeated
downloads. When the `arrow` package is installed, data is cached in
parquet format for faster subsequent reads.

## Usage

``` r
pnadc_data(
  module,
  year = NULL,
  vars = NULL,
  as_survey = FALSE,
  cache_dir = NULL,
  refresh = FALSE,
  lazy = FALSE,
  backend = c("arrow", "duckdb")
)
```

## Arguments

- module:

  Character. The module identifier. Use
  [`pnadc_modules`](https://sidneybissoli.github.io/healthbR/reference/pnadc_modules.md)
  to see available modules. Required.

- year:

  Numeric or vector. Year(s) to download. Use NULL for all available
  years for the module. Default is NULL.

- vars:

  Character vector. Variables to select. Use NULL for all variables.
  Survey design variables (UPA, Estrato, V1028) and key demographic
  variables are always included. Default is NULL.

- as_survey:

  Logical. If TRUE, returns a survey design object (requires the `srvyr`
  package). Default is FALSE.

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

A tibble with PNADC microdata, or a `srvyr` survey design object if
`as_survey = TRUE`.

## Details

PNAD Continua (Pesquisa Nacional por Amostra de Domicilios Continua) is
a quarterly household survey conducted by IBGE. This function provides
access to supplementary modules with health-related content.

### Available modules

- `deficiencia`: Persons with disabilities (2019, 2022, 2024)

- `habitacao`: Housing characteristics (2012-2019, 2022-2024)

- `moradores`: General characteristics of residents (2012-2019,
  2022-2024)

- `aps`: Primary health care (2022)

### Survey design variables

For proper statistical analysis with complex survey design, the
following variables are always included:

- `UPA`: Primary sampling unit

- `Estrato`: Stratum

- `V1028`: Survey weight

Use `as_survey = TRUE` to get a properly weighted survey design object
for analysis with the `srvyr` package.

## Data source

Data is downloaded from the IBGE FTP server:
`https://ftp.ibge.gov.br/Trabalho_e_Rendimento/Pesquisa_Nacional_por_Amostra_de_Domicilios_continua/`

## Examples

``` r
if (FALSE) { # interactive()
# download deficiencia module for 2022
df <- pnadc_data(module = "deficiencia", year = 2022, cache_dir = tempdir())

# download with survey design
svy <- pnadc_data(
  module = "deficiencia",
  year = 2022,
  as_survey = TRUE,
  cache_dir = tempdir()
)

# select specific variables
df_subset <- pnadc_data(
  module = "deficiencia",
  year = 2022,
  vars = c("S11001", "S11002"),
  cache_dir = tempdir()
)
}
```
