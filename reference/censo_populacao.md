# Get Census population data

Retrieves population data from the Brazilian Demographic Census via
SIDRA API. Automatically selects the correct SIDRA table based on year
and requested variables.

## Usage

``` r
censo_populacao(
  year,
  variables = "total",
  territorial_level = "state",
  geo_code = "all",
  raw = FALSE
)
```

## Arguments

- year:

  Numeric. Census year (1970, 1980, 1991, 2000, 2010, or 2022).

- variables:

  Character. Type of breakdown:

  - `"total"`: Total population only

  - `"sex"`: By sex (male/female)

  - `"age"`: By age groups

  - `"age_sex"`: By age groups and sex

  - `"race"`: By race/color (only 2000, 2010, 2022)

  - `"situation"`: By urban/rural situation

  Default is `"total"`.

- territorial_level:

  Character. Geographic level: `"brazil"`, `"region"`, `"state"`, or
  `"municipality"`. Default is `"state"`.

- geo_code:

  Character. IBGE code(s) for specific localities. `"all"` returns all
  localities at the chosen level. Default is `"all"`.

- raw:

  Logical. If TRUE, returns raw API output without cleaning. Default is
  FALSE.

## Value

A tibble with population data.

## Details

This function provides an easy interface for the most common Census
queries. It automatically resolves the correct SIDRA table:

- Table 200: Historical population 1970-2010 (by sex, age, situation)

- Table 9514: Census 2022 population by sex and age

- Table 136: Population by race 2000-2010

- Table 9605: Population by race 2022

- Table 9515: Population by urban/rural 2022

For more flexibility, use
[`censo_sidra_data`](https://sidneybissoli.github.io/healthbR/reference/censo_sidra_data.md)
to query any table with custom parameters.

## Data source

Data is retrieved from IBGE SIDRA API: <https://sidra.ibge.gov.br/>

## Examples

``` r
# \donttest{
# total population by state, 2022
censo_populacao(year = 2022)
#> ℹ Querying SIDRA API for table "9514"...
#> ✔ Retrieved 27 rows: Census 2022, total level
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

# population by sex, Brazil level
censo_populacao(year = 2022, variables = "sex", territorial_level = "brazil")
#> ℹ Querying SIDRA API for table "9514"...
#> ✔ Retrieved 2 rows: Census 2022, sex level
#> # A tibble: 2 × 17
#>   nc    nn    mc    mn         v d1c   d1n   d2c   d2n   d3c   d3n   d4c   d4n  
#>   <chr> <chr> <chr> <chr>  <dbl> <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr>
#> 1 1     Bras… 45    Pess… 9.85e7 1     Bras… 93    Popu… 2022  2022  4     Home…
#> 2 1     Bras… 45    Pess… 1.05e8 1     Bras… 93    Popu… 2022  2022  5     Mulh…
#> # ℹ 4 more variables: d5c <chr>, d5n <chr>, d6c <chr>, d6n <chr>

# population by age and sex, 2010
censo_populacao(year = 2010, variables = "age_sex")
#> ℹ Querying SIDRA API for table "200"...
#> ✔ Retrieved 2646 rows: Census 2010, age_sex level
#> # A tibble: 2,646 × 17
#>    nc    nn    mc    mn        v d1c   d1n   d2c   d2n   d3c   d3n   d4c   d4n  
#>    <chr> <chr> <chr> <chr> <dbl> <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr>
#>  1 3     Unid… 45    Pess… 65352 11    Rond… 93    Popu… 2010  2010  4     Home…
#>  2 3     Unid… 45    Pess… 13256 11    Rond… 93    Popu… 2010  2010  4     Home…
#>  3 3     Unid… 45    Pess…    NA 11    Rond… 93    Popu… 2010  2010  4     Home…
#>  4 3     Unid… 45    Pess… 12881 11    Rond… 93    Popu… 2010  2010  4     Home…
#>  5 3     Unid… 45    Pess… 12242 11    Rond… 93    Popu… 2010  2010  4     Home…
#>  6 3     Unid… 45    Pess… 12766 11    Rond… 93    Popu… 2010  2010  4     Home…
#>  7 3     Unid… 45    Pess… 14208 11    Rond… 93    Popu… 2010  2010  4     Home…
#>  8 3     Unid… 45    Pess… 71249 11    Rond… 93    Popu… 2010  2010  4     Home…
#>  9 3     Unid… 45    Pess… 13959 11    Rond… 93    Popu… 2010  2010  4     Home…
#> 10 3     Unid… 45    Pess… 13737 11    Rond… 93    Popu… 2010  2010  4     Home…
#> # ℹ 2,636 more rows
#> # ℹ 4 more variables: d5c <chr>, d5n <chr>, d6c <chr>, d6n <chr>

# population by race, 2022
censo_populacao(year = 2022, variables = "race")
#> ℹ Querying SIDRA API for table "9605"...
#> ✔ Retrieved 135 rows: Census 2022, race level
#> # A tibble: 135 × 13
#>    nc    nn         mc    mn         v d1c   d1n   d2c   d2n   d3c   d3n   d4c  
#>    <chr> <chr>      <chr> <chr>  <dbl> <chr> <chr> <chr> <chr> <chr> <chr> <chr>
#>  1 3     Unidade d… 45    Pess… 486123 11    Rond… 93    Popu… 2022  2022  2776 
#>  2 3     Unidade d… 45    Pess… 136793 11    Rond… 93    Popu… 2022  2022  2777 
#>  3 3     Unidade d… 45    Pess…   4257 11    Rond… 93    Popu… 2022  2022  2778 
#>  4 3     Unidade d… 45    Pess… 936708 11    Rond… 93    Popu… 2022  2022  2779 
#>  5 3     Unidade d… 45    Pess…  17278 11    Rond… 93    Popu… 2022  2022  2780 
#>  6 3     Unidade d… 45    Pess… 177992 12    Acre  93    Popu… 2022  2022  2776 
#>  7 3     Unidade d… 45    Pess…  71086 12    Acre  93    Popu… 2022  2022  2777 
#>  8 3     Unidade d… 45    Pess…   1878 12    Acre  93    Popu… 2022  2022  2778 
#>  9 3     Unidade d… 45    Pess… 549889 12    Acre  93    Popu… 2022  2022  2779 
#> 10 3     Unidade d… 45    Pess…  29163 12    Acre  93    Popu… 2022  2022  2780 
#> # ℹ 125 more rows
#> # ℹ 1 more variable: d4n <chr>
# }
```
