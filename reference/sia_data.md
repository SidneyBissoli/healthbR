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
  cache = TRUE,
  cache_dir = NULL
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

- cache:

  Logical. If TRUE (default), caches downloaded data for faster future
  access.

- cache_dir:

  Character. Directory for caching. Default:
  `tools::R_user_dir("healthbR", "cache")`.

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
# \donttest{
# all outpatient production in Acre, January 2022
ac_jan <- sia_data(year = 2022, month = 1, uf = "AC")
#> ℹ Downloading SIA data: PA AC 2022/01...
#> ℹ Download attempt 1/3 failed. Retrying in 2s...
#> ✖ Timeout was reached [ftp.datasus.gov.br]: Failed to connect to
#>   ftp.datasus.gov.br port 21 after 30002 ms: Timeout was reached
#> ℹ Download attempt 2/3 failed. Retrying in 4s...
#> ✖ Timeout was reached [ftp.datasus.gov.br]: Failed to connect to
#>   ftp.datasus.gov.br port 21 after 30002 ms: Timeout was reached
#> Warning: ! Failed to download/read SIA data for PA AC 2022/01.
#> ✖ Failed to download file from DATASUS FTP after 3 attempts.
#> Error in sia_data(year = 2022, month = 1, uf = "AC"): No data could be downloaded for the requested year(s)/month(s)/UF(s).

# filter by procedure code
consult <- sia_data(year = 2022, month = 1, uf = "AC",
                    procedure = "0301")
#> ℹ Downloading SIA data: PA AC 2022/01...
#> ℹ Download attempt 1/3 failed. Retrying in 2s...
#> ✖ Timeout was reached [ftp.datasus.gov.br]: Failed to connect to
#>   ftp.datasus.gov.br port 21 after 30002 ms: Couldn't connect to server
#> ℹ Download attempt 2/3 failed. Retrying in 4s...
#> ✖ Timeout was reached [ftp.datasus.gov.br]: Failed to connect to
#>   ftp.datasus.gov.br port 21 after 30002 ms: Timeout was reached
#> Warning: ! Failed to download/read SIA data for PA AC 2022/01.
#> ✖ Failed to download file from DATASUS FTP after 3 attempts.
#> Error in sia_data(year = 2022, month = 1, uf = "AC", procedure = "0301"): No data could be downloaded for the requested year(s)/month(s)/UF(s).

# filter by diagnosis (CID-10)
resp <- sia_data(year = 2022, month = 1, uf = "AC",
                 diagnosis = "J")
#> ℹ Downloading SIA data: PA AC 2022/01...
#> ℹ Download attempt 1/3 failed. Retrying in 2s...
#> ✖ Timeout was reached [ftp.datasus.gov.br]: Failed to connect to
#>   ftp.datasus.gov.br port 21 after 30000 ms: Couldn't connect to server
#> ℹ Download attempt 2/3 failed. Retrying in 4s...
#> ✖ Timeout was reached [ftp.datasus.gov.br]: Failed to connect to
#>   ftp.datasus.gov.br port 21 after 30002 ms: Timeout was reached
#> Warning: ! Failed to download/read SIA data for PA AC 2022/01.
#> ✖ Failed to download file from DATASUS FTP after 3 attempts.
#> Error in sia_data(year = 2022, month = 1, uf = "AC", diagnosis = "J"): No data could be downloaded for the requested year(s)/month(s)/UF(s).

# only key variables
sia_data(year = 2022, month = 1, uf = "AC",
         vars = c("PA_PROC_ID", "PA_CIDPRI", "PA_SEXO",
                  "PA_IDADE", "PA_VALAPR"))
#> ℹ Downloading SIA data: PA AC 2022/01...
#> ℹ Download attempt 1/3 failed. Retrying in 2s...
#> ✖ Timeout was reached [ftp.datasus.gov.br]: Failed to connect to
#>   ftp.datasus.gov.br port 21 after 30002 ms: Couldn't connect to server
#> ℹ Download attempt 2/3 failed. Retrying in 4s...
#> ✖ Timeout was reached [ftp.datasus.gov.br]: Failed to connect to
#>   ftp.datasus.gov.br port 21 after 30002 ms: Timeout was reached
#> Warning: ! Failed to download/read SIA data for PA AC 2022/01.
#> ✖ Failed to download file from DATASUS FTP after 3 attempts.
#> Error in sia_data(year = 2022, month = 1, uf = "AC", vars = c("PA_PROC_ID",     "PA_CIDPRI", "PA_SEXO", "PA_IDADE", "PA_VALAPR")): No data could be downloaded for the requested year(s)/month(s)/UF(s).

# different file type (APAC Medicamentos)
med <- sia_data(year = 2022, month = 1, uf = "AC", type = "AM")
#> ℹ Downloading SIA data: AM AC 2022/01...
# }
```
