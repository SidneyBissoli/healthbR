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
  cache = TRUE,
  cache_dir = NULL
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

- cache:

  Logical. If TRUE (default), caches downloaded data for faster future
  access.

- cache_dir:

  Character. Directory for caching. Default:
  `tools::R_user_dir("healthbR", "cache")`.

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
