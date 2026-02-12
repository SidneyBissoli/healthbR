# Get Census data from SIDRA API

Queries the IBGE SIDRA API to retrieve any Census table. This is the
most flexible function, allowing full control over SIDRA query
parameters.

## Usage

``` r
censo_sidra_data(
  table,
  territorial_level = "brazil",
  geo_code = "all",
  year = NULL,
  variable = NULL,
  classifications = NULL,
  raw = FALSE
)
```

## Arguments

- table:

  Numeric or character. SIDRA table code. Use
  [`censo_sidra_tables`](https://sidneybissoli.github.io/healthbR/reference/censo_sidra_tables.md)
  or
  [`censo_sidra_search`](https://sidneybissoli.github.io/healthbR/reference/censo_sidra_search.md)
  to find codes.

- territorial_level:

  Character. Geographic level: `"brazil"` (N1), `"region"` (N2),
  `"state"` (N3), `"municipality"` (N6). Default `"brazil"`.

- geo_code:

  Character. IBGE code(s) for specific localities. `"all"` returns all
  localities at the chosen level. Default `"all"`.

- year:

  Numeric or character. Year(s) to query. NULL returns all available
  periods.

- variable:

  Numeric or character. SIDRA variable ID(s). NULL returns all variables
  excluding metadata. Default NULL.

- classifications:

  Named list. SIDRA classification filters. Example:
  `list("2" = "allxt")` for sex breakdown. NULL returns default
  aggregation. Default NULL.

- raw:

  Logical. If TRUE, returns raw API output without cleaning. Default
  FALSE.

## Value

A tibble with queried data.

## Examples

``` r
# \donttest{
# population by state from 2022 Census
censo_sidra_data(
  table = 9514,
  territorial_level = "state",
  year = 2022,
  variable = 93
)
#> ℹ Querying SIDRA API for table "9514"...
#> ✔ Retrieved 27 rows from SIDRA table "9514"
#> # A tibble: 27 × 17
#>    nc    nn         mc    mn         v d1c   d1n   d2c   d2n   d3c   d3n   d4c  
#>    <chr> <chr>      <chr> <chr>  <dbl> <chr> <chr> <chr> <chr> <chr> <chr> <chr>
#>  1 3     Unidade d… 45    Pess… 1.58e6 11    Rond… 93    Popu… 2022  2022  6794 
#>  2 3     Unidade d… 45    Pess… 8.30e5 12    Acre  93    Popu… 2022  2022  6794 
#>  3 3     Unidade d… 45    Pess… 3.94e6 13    Amaz… 93    Popu… 2022  2022  6794 
#>  4 3     Unidade d… 45    Pess… 6.37e5 14    Rora… 93    Popu… 2022  2022  6794 
#>  5 3     Unidade d… 45    Pess… 8.12e6 15    Pará  93    Popu… 2022  2022  6794 
#>  6 3     Unidade d… 45    Pess… 7.34e5 16    Amapá 93    Popu… 2022  2022  6794 
#>  7 3     Unidade d… 45    Pess… 1.51e6 17    Toca… 93    Popu… 2022  2022  6794 
#>  8 3     Unidade d… 45    Pess… 6.78e6 21    Mara… 93    Popu… 2022  2022  6794 
#>  9 3     Unidade d… 45    Pess… 3.27e6 22    Piauí 93    Popu… 2022  2022  6794 
#> 10 3     Unidade d… 45    Pess… 8.79e6 23    Ceará 93    Popu… 2022  2022  6794 
#> # ℹ 17 more rows
#> # ℹ 5 more variables: d4n <chr>, d5c <chr>, d5n <chr>, d6c <chr>, d6n <chr>

# population by race, Brazil level
censo_sidra_data(
  table = 9605,
  territorial_level = "brazil",
  year = 2022,
  variable = 93,
  classifications = list("86" = "allxt")
)
#> ℹ Querying SIDRA API for table "9605"...
#> ✔ Retrieved 5 rows from SIDRA table "9605"
#> # A tibble: 5 × 13
#>   nc    nn    mc    mn         v d1c   d1n   d2c   d2n   d3c   d3n   d4c   d4n  
#>   <chr> <chr> <chr> <chr>  <dbl> <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr>
#> 1 1     Bras… 45    Pess… 8.83e7 1     Bras… 93    Popu… 2022  2022  2776  Bran…
#> 2 1     Bras… 45    Pess… 2.07e7 1     Bras… 93    Popu… 2022  2022  2777  Preta
#> 3 1     Bras… 45    Pess… 8.50e5 1     Bras… 93    Popu… 2022  2022  2778  Amar…
#> 4 1     Bras… 45    Pess… 9.21e7 1     Bras… 93    Popu… 2022  2022  2779  Parda
#> 5 1     Bras… 45    Pess… 1.23e6 1     Bras… 93    Popu… 2022  2022  2780  Indí…
# }
```
