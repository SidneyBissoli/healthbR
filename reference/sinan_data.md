# Download SINAN Notifiable Disease Microdata

Downloads and returns notifiable disease microdata from DATASUS FTP.
Each row represents one notification record (Ficha de Notificacao). Data
is downloaded as national .dbc files (one file per disease per year),
decompressed internally, and returned as a tibble.

## Usage

``` r
sinan_data(
  year,
  disease = "DENG",
  vars = NULL,
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

- disease:

  Character. Disease code to download. Default: `"DENG"` (Dengue). Use
  [`sinan_diseases()`](https://sidneybissoli.github.io/healthbR/reference/sinan_diseases.md)
  to see all available codes.

- vars:

  Character vector. Variables to keep. If NULL (default), returns all
  available variables. Use
  [`sinan_variables()`](https://sidneybissoli.github.io/healthbR/reference/sinan_variables.md)
  to see available variables.

- parse:

  Logical. If TRUE (default), converts columns to appropriate types
  (integer, double, Date) based on the variable metadata. Use
  [`sinan_variables()`](https://sidneybissoli.github.io/healthbR/reference/sinan_variables.md)
  to see the target type for each variable. Set to FALSE for
  backward-compatible all-character output.

- col_types:

  Named list. Override the default type for specific columns. Names are
  column names, values are type strings: `"character"`, `"integer"`,
  `"double"`, `"date_dmy"`, `"date_ymd"`, `"date_ym"`, `"date"`.
  Example: `list(DT_NOTIFIC = "character")` to keep DT_NOTIFIC as
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

A tibble with notifiable disease microdata. Includes columns `year` and
`disease` to identify the source when multiple years are combined.

## Details

SINAN files are national (not per-state). Each file contains all
notifications for a given disease in a given year across all of Brazil.
To filter by state, use the `SG_UF_NOT` (UF of notification) or
`ID_MUNICIP` (municipality code) columns after download.

Data is downloaded from DATASUS FTP as .dbc files. The .dbc format is
decompressed internally using vendored C code from the blast library. No
external dependencies are required.

## See also

Other sinan:
[`sinan_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sinan_cache_status.md),
[`sinan_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sinan_clear_cache.md),
[`sinan_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sinan_dictionary.md),
[`sinan_diseases()`](https://sidneybissoli.github.io/healthbR/reference/sinan_diseases.md),
[`sinan_info()`](https://sidneybissoli.github.io/healthbR/reference/sinan_info.md),
[`sinan_variables()`](https://sidneybissoli.github.io/healthbR/reference/sinan_variables.md),
[`sinan_years()`](https://sidneybissoli.github.io/healthbR/reference/sinan_years.md)

## Examples

``` r
if (FALSE) { # interactive()
# dengue notifications, 2022
dengue_2022 <- sinan_data(year = 2022)

# tuberculosis, 2020-2022
tb <- sinan_data(year = 2020:2022, disease = "TUBE")

# only key variables
sinan_data(year = 2022, disease = "DENG",
           vars = c("DT_NOTIFIC", "CS_SEXO", "NU_IDADE_N",
                    "CS_RACA", "ID_MUNICIP", "CLASSI_FIN"))
}
```
