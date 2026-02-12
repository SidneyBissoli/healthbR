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
# \donttest{
# all deaths in Acre, 2022
ac_2022 <- sim_data(year = 2022, uf = "AC")
#> ℹ Downloading SIM data: AC 2022...
#> ℹ Download attempt 1/3 failed. Retrying in 2s...
#> ✖ Timeout was reached [ftp.datasus.gov.br]: Failed to connect to
#>   ftp.datasus.gov.br port 21 after 30002 ms: Timeout was reached
#> ℹ Download attempt 2/3 failed. Retrying in 4s...
#> ✖ Timeout was reached [ftp.datasus.gov.br]: Failed to connect to
#>   ftp.datasus.gov.br port 21 after 30001 ms: Timeout was reached
#> Warning: ! Failed to download/read SIM data for AC 2022.
#> ✖ Failed to download file from DATASUS FTP after 3 attempts.
#> Error in sim_data(year = 2022, uf = "AC"): No data could be downloaded for the requested year(s)/UF(s).

# deaths by infarct in Sao Paulo, 2020-2022
infarct_sp <- sim_data(year = 2020:2022, uf = "SP", cause = "I21")
#> ℹ Downloading 3 file(s) (1 UF(s) x 3 year(s))...
#> ℹ Downloading SIM data: SP 2020...
#> ℹ Downloading SIM data: SP 2021...
#> ℹ Download attempt 1/3 failed. Retrying in 2s...
#> ✖ Timeout was reached [ftp.datasus.gov.br]: Failed to connect to
#>   ftp.datasus.gov.br port 21 after 30001 ms: Timeout was reached
#> ℹ Download attempt 2/3 failed. Retrying in 4s...
#> ✖ Timeout was reached [ftp.datasus.gov.br]: Failed to connect to
#>   ftp.datasus.gov.br port 21 after 30001 ms: Timeout was reached
#> Warning: ! Failed to download/read SIM data for SP 2021.
#> ✖ Failed to download file from DATASUS FTP after 3 attempts.
#> ℹ Downloading SIM data: SP 2022...
#> ℹ Download attempt 1/3 failed. Retrying in 2s...
#> ✖ Timeout was reached [ftp.datasus.gov.br]: Failed to connect to
#>   ftp.datasus.gov.br port 21 after 30002 ms: Timeout was reached
#> ℹ Download attempt 2/3 failed. Retrying in 4s...
#> ✖ Timeout was reached [ftp.datasus.gov.br]: Failed to connect to
#>   ftp.datasus.gov.br port 21 after 30002 ms: Timeout was reached
#> Warning: ! Failed to download/read SIM data for SP 2022.
#> ✖ Failed to download file from DATASUS FTP after 3 attempts.

# only key variables, Rio de Janeiro, 2022
sim_data(year = 2022, uf = "RJ",
         vars = c("DTOBITO", "SEXO", "IDADE",
                  "RACACOR", "CODMUNRES", "CAUSABAS"))
#> ℹ Downloading SIM data: RJ 2022...
#> ℹ Download attempt 1/3 failed. Retrying in 2s...
#> ✖ Timeout was reached [ftp.datasus.gov.br]: Failed to connect to
#>   ftp.datasus.gov.br port 21 after 30002 ms: Timeout was reached
#> ℹ Download attempt 2/3 failed. Retrying in 4s...
#> ✖ Timeout was reached [ftp.datasus.gov.br]: Failed to connect to
#>   ftp.datasus.gov.br port 21 after 30002 ms: Timeout was reached
#> Warning: ! Failed to download/read SIM data for RJ 2022.
#> ✖ Failed to download file from DATASUS FTP after 3 attempts.
#> Error in sim_data(year = 2022, uf = "RJ", vars = c("DTOBITO", "SEXO",     "IDADE", "RACACOR", "CODMUNRES", "CAUSABAS")): No data could be downloaded for the requested year(s)/UF(s).
# }
```
