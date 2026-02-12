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
  cache = TRUE,
  cache_dir = NULL
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

- cache:

  Logical. If TRUE (default), caches downloaded data for faster future
  access.

- cache_dir:

  Character. Directory for caching. Default:
  `tools::R_user_dir("healthbR", "cache")`.

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
# \donttest{
# all admissions in Acre, January 2022
ac_jan <- sih_data(year = 2022, month = 1, uf = "AC")
#> ℹ Downloading SIH data: AC 2022/01...

# heart attacks in Sao Paulo, first semester 2022
infarct_sp <- sih_data(year = 2022, month = 1:6, uf = "SP",
                        diagnosis = "I21")
#> ℹ Downloading 6 file(s) (1 UF(s) x 1 year(s) x 6 month(s))...
#> ℹ Downloading SIH data: SP 2022/01...
#> ℹ Downloading SIH data: SP 2022/02...
#> ℹ Downloading SIH data: SP 2022/03...
#> ℹ Downloading SIH data: SP 2022/04...
#> ℹ Downloading SIH data: SP 2022/05...
#> ℹ Downloading SIH data: SP 2022/06...

# only key variables, Rio de Janeiro, March 2022
sih_data(year = 2022, month = 3, uf = "RJ",
         vars = c("DIAG_PRINC", "DT_INTER", "SEXO",
                  "IDADE", "MORTE", "VAL_TOT"))
#> ℹ Downloading SIH data: RJ 2022/03...
#> # A tibble: 66,933 × 9
#>     year month uf_source DIAG_PRINC DT_INTER SEXO  IDADE MORTE VAL_TOT
#>    <int> <int> <chr>     <chr>      <chr>    <chr> <chr> <chr> <chr>  
#>  1  2022     3 RJ        I219       20220125 1     66    0     910.68 
#>  2  2022     3 RJ        I219       20220208 1     62    0     736.56 
#>  3  2022     3 RJ        I219       20220208 1     51    0     794.5  
#>  4  2022     3 RJ        I219       20220208 1     52    0     740.89 
#>  5  2022     3 RJ        I219       20220217 1     65    0     715.78 
#>  6  2022     3 RJ        I219       20220119 1     68    0     960.29 
#>  7  2022     3 RJ        I219       20220224 1     64    0     607.46 
#>  8  2022     3 RJ        S822       20211218 1     18    0     906.54 
#>  9  2022     3 RJ        S820       20220317 1     48    0     344.06 
#> 10  2022     3 RJ        I611       20220317 3     71    1     967.29 
#> # ℹ 66,923 more rows
# }
```
