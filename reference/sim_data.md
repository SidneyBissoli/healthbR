# Download SIM Mortality Microdata

Downloads and returns mortality microdata from DATASUS FTP. Each row
represents one death record (Declaracao de Obito). Data is downloaded
per state (UF) as compressed .dbc files, decompressed internally, and
returned as a tibble.

## Usage

``` r
sim_data(
  year,
  vars = NULL,
  uf = NULL,
  cause = NULL,
  decode_age = TRUE,
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
  [`sim_variables()`](https://sidneybissoli.github.io/healthbR/reference/sim_variables.md)
  to see available variables.

- uf:

  Character. Two-letter state abbreviation(s) to download. If NULL
  (default), downloads all 27 states. Example: `"SP"`, `c("SP", "RJ")`.

- cause:

  Character. CID-10 code pattern(s) to filter by cause of death
  (`CAUSABAS`). Supports partial matching (prefix). If NULL (default),
  returns all causes. Example: `"I21"` (infarct), `"C"` (all neoplasms).

- decode_age:

  Logical. If TRUE (default), adds a numeric column `age_years` with age
  in years decoded from the `IDADE` variable.

- cache:

  Logical. If TRUE (default), caches downloaded data for faster future
  access.

- cache_dir:

  Character. Directory for caching. Default:
  `tools::R_user_dir("healthbR", "cache")`.

## Value

A tibble with mortality microdata. Includes columns `year` and
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
for population denominators to calculate mortality rates.

Other sim:
[`sim_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sim_cache_status.md),
[`sim_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sim_clear_cache.md),
[`sim_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sim_dictionary.md),
[`sim_info()`](https://sidneybissoli.github.io/healthbR/reference/sim_info.md),
[`sim_variables()`](https://sidneybissoli.github.io/healthbR/reference/sim_variables.md),
[`sim_years()`](https://sidneybissoli.github.io/healthbR/reference/sim_years.md)

## Examples

``` r
if (FALSE) { # interactive()
# all deaths in Acre, 2022
ac_2022 <- sim_data(year = 2022, uf = "AC")

# deaths by infarct in Sao Paulo, 2020-2022
infarct_sp <- sim_data(year = 2020:2022, uf = "SP", cause = "I21")

# only key variables, Rio de Janeiro, 2022
sim_data(year = 2022, uf = "RJ",
         vars = c("DTOBITO", "SEXO", "IDADE",
                  "RACACOR", "CODMUNRES", "CAUSABAS"))
}
```
