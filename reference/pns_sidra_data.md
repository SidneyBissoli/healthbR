# Get PNS tabulated data from SIDRA API

Queries the IBGE SIDRA API to retrieve tabulated PNS indicators. Returns
pre-aggregated data (prevalences, means, proportions) with confidence
intervals and coefficients of variation.

## Usage

``` r
pns_sidra_data(
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
  [`pns_sidra_tables()`](https://sidneybissoli.github.io/healthbR/reference/pns_sidra_tables.md)
  or
  [`pns_sidra_search()`](https://sidneybissoli.github.io/healthbR/reference/pns_sidra_search.md)
  to find codes.

- territorial_level:

  Character. Geographic level: "brazil" (N1), "region" (N2), "state"
  (N3), "municipality" (N6). Default "brazil".

- geo_code:

  Character. IBGE code(s) for specific localities. "all" returns all
  localities at the chosen level. Default "all".

- year:

  Numeric. Year(s) to query. NULL returns all available periods.

- variable:

  Numeric or character. SIDRA variable ID(s). NULL returns all variables
  excluding metadata. Default NULL.

- classifications:

  Named list. SIDRA classification filters. Example: list("2" = "6794")
  for sex = total. NULL returns default aggregation. Default NULL.

- raw:

  Logical. If TRUE, returns raw API output without cleaning. Default
  FALSE.

## Value

A tibble with queried indicators.

## Examples

``` r
# \donttest{
# self-rated health by state, 2019
pns_sidra_data(
  table = 4751,
  territorial_level = "state",
  year = 2019
)
#> ℹ Querying SIDRA API for table "4751"...
#> ✔ Retrieved 216 rows from SIDRA table "4751"
#> # A tibble: 216 × 15
#>    nc    nn         mc    mn         v d1c   d1n   d2c   d2n   d3c   d3n   d4c  
#>    <chr> <chr>      <chr> <chr>  <dbl> <chr> <chr> <chr> <chr> <chr> <chr> <chr>
#>  1 3     Unidade d… 1572  Mil … 771228 11    Rond… 4735  Pess… 2019  2019  6795 
#>  2 3     Unidade d… 1572  Mil … 737062 11    Rond… 4736  Pess… 2019  2019  6795 
#>  3 3     Unidade d… 1572  Mil … 805394 11    Rond… 4737  Pess… 2019  2019  6795 
#>  4 3     Unidade d… 2     %         23 11    Rond… 4974  Coef… 2019  2019  6795 
#>  5 3     Unidade d… 2     %        614 11    Rond… 4738  Perc… 2019  2019  6795 
#>  6 3     Unidade d… 2     %        587 11    Rond… 4739  Perc… 2019  2019  6795 
#>  7 3     Unidade d… 2     %        641 11    Rond… 4740  Perc… 2019  2019  6795 
#>  8 3     Unidade d… 2     %         23 11    Rond… 4975  Coef… 2019  2019  6795 
#>  9 3     Unidade d… 1572  Mil … 354679 12    Acre  4735  Pess… 2019  2019  6795 
#> 10 3     Unidade d… 1572  Mil … 338804 12    Acre  4736  Pess… 2019  2019  6795 
#> # ℹ 206 more rows
#> # ℹ 3 more variables: d4n <chr>, d5c <chr>, d5n <chr>

# same table, Brazil-level, both years
pns_sidra_data(
  table = 4751,
  territorial_level = "brazil",
  year = c(2013, 2019)
)
#> ℹ Querying SIDRA API for table "4751"...
#> ✔ Retrieved 16 rows from SIDRA table "4751"
#> # A tibble: 16 × 15
#>    nc    nn     mc    mn             v d1c   d1n   d2c   d2n   d3c   d3n   d4c  
#>    <chr> <chr>  <chr> <chr>      <dbl> <chr> <chr> <chr> <chr> <chr> <chr> <chr>
#>  1 1     Brasil 1572  Mil pess… 9.64e7 1     Bras… 4735  Pess… 2013  2013  6795 
#>  2 1     Brasil 1572  Mil pess… 1.05e8 1     Bras… 4735  Pess… 2019  2019  6795 
#>  3 1     Brasil 1572  Mil pess… 9.54e7 1     Bras… 4736  Pess… 2013  2013  6795 
#>  4 1     Brasil 1572  Mil pess… 1.04e8 1     Bras… 4736  Pess… 2019  2019  6795 
#>  5 1     Brasil 1572  Mil pess… 9.74e7 1     Bras… 4737  Pess… 2013  2013  6795 
#>  6 1     Brasil 1572  Mil pess… 1.06e8 1     Bras… 4737  Pess… 2019  2019  6795 
#>  7 1     Brasil 2     %         5   e0 1     Bras… 4974  Coef… 2013  2013  6795 
#>  8 1     Brasil 2     %         5   e0 1     Bras… 4974  Coef… 2019  2019  6795 
#>  9 1     Brasil 2     %         6.62e2 1     Bras… 4738  Perc… 2013  2013  6795 
#> 10 1     Brasil 2     %         6.61e2 1     Bras… 4738  Perc… 2019  2019  6795 
#> 11 1     Brasil 2     %         6.55e2 1     Bras… 4739  Perc… 2013  2013  6795 
#> 12 1     Brasil 2     %         6.55e2 1     Bras… 4739  Perc… 2019  2019  6795 
#> 13 1     Brasil 2     %         6.69e2 1     Bras… 4740  Perc… 2013  2013  6795 
#> 14 1     Brasil 2     %         6.67e2 1     Bras… 4740  Perc… 2019  2019  6795 
#> 15 1     Brasil 2     %         5   e0 1     Bras… 4975  Coef… 2013  2013  6795 
#> 16 1     Brasil 2     %         5   e0 1     Bras… 4975  Coef… 2019  2019  6795 
#> # ℹ 3 more variables: d4n <chr>, d5c <chr>, d5n <chr>

# hypertension data
pns_sidra_data(
  table = 4416,
  territorial_level = "brazil"
)
#> ℹ Querying SIDRA API for table "4416"...
#> ✔ Retrieved 8 rows from SIDRA table "4416"
#> # A tibble: 8 × 13
#>   nc    nn     mc    mn              v d1c   d1n   d2c   d2n   d3c   d3n   d4c  
#>   <chr> <chr>  <chr> <chr>       <dbl> <chr> <chr> <chr> <chr> <chr> <chr> <chr>
#> 1 1     Brasil 1572  Mil pess…  2.77e7 1     Bras… 4396  Pess… 2013  2013  33065
#> 2 1     Brasil 1572  Mil pess…  2.69e7 1     Bras… 4397  Pess… 2013  2013  33065
#> 3 1     Brasil 1572  Mil pess…  2.84e7 1     Bras… 4398  Pess… 2013  2013  33065
#> 4 1     Brasil 2     %          1.4 e1 1     Bras… 4861  Coef… 2013  2013  33065
#> 5 1     Brasil 2     %          1   e3 1     Bras… 4399  Perc… 2013  2013  33065
#> 6 1     Brasil 2     %         NA      1     Bras… 4400  Perc… 2013  2013  33065
#> 7 1     Brasil 2     %         NA      1     Bras… 4401  Perc… 2013  2013  33065
#> 8 1     Brasil 2     %         NA      1     Bras… 4862  Coef… 2013  2013  33065
#> # ℹ 1 more variable: d4n <chr>
# }
```
