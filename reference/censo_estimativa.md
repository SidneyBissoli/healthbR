# Get intercensitary population estimates

Retrieves population estimates for intercensitary years (2001-2021) from
SIDRA table 6579. These estimates provide population denominators for
years between censuses.

## Usage

``` r
censo_estimativa(
  year,
  territorial_level = "state",
  geo_code = "all",
  raw = FALSE
)
```

## Arguments

- year:

  Numeric or vector. Year(s) between 2001 and 2021.

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

A tibble with population estimates.

## Details

Table 6579 provides total population estimates (no sex/age breakdown).
These estimates are published annually by IBGE and are widely used as
denominators for health indicator calculations.

For census years with full demographic breakdowns, use
[`censo_populacao`](https://sidneybissoli.github.io/healthbR/reference/censo_populacao.md)
instead.

## Data source

Data is retrieved from IBGE SIDRA API, table 6579:
<https://sidra.ibge.gov.br/tabela/6579>

## Examples

``` r
# \donttest{
# estimates for 2020 by state
censo_estimativa(year = 2020)
#> ℹ Querying SIDRA API for table "6579"...
#> ✔ Retrieved 27 rows: Population estimates for 1 year
#> # A tibble: 27 × 11
#>    nc    nn               mc    mn         v d1c   d1n   d2c   d2n   d3c   d3n  
#>    <chr> <chr>            <chr> <chr>  <dbl> <chr> <chr> <chr> <chr> <chr> <chr>
#>  1 3     Unidade da Fede… 45    Pess… 1.80e6 11    Rond… 9324  Popu… 2020  2020 
#>  2 3     Unidade da Fede… 45    Pess… 8.94e5 12    Acre  9324  Popu… 2020  2020 
#>  3 3     Unidade da Fede… 45    Pess… 4.21e6 13    Amaz… 9324  Popu… 2020  2020 
#>  4 3     Unidade da Fede… 45    Pess… 6.31e5 14    Rora… 9324  Popu… 2020  2020 
#>  5 3     Unidade da Fede… 45    Pess… 8.69e6 15    Pará  9324  Popu… 2020  2020 
#>  6 3     Unidade da Fede… 45    Pess… 8.62e5 16    Amapá 9324  Popu… 2020  2020 
#>  7 3     Unidade da Fede… 45    Pess… 1.59e6 17    Toca… 9324  Popu… 2020  2020 
#>  8 3     Unidade da Fede… 45    Pess… 7.11e6 21    Mara… 9324  Popu… 2020  2020 
#>  9 3     Unidade da Fede… 45    Pess… 3.28e6 22    Piauí 9324  Popu… 2020  2020 
#> 10 3     Unidade da Fede… 45    Pess… 9.19e6 23    Ceará 9324  Popu… 2020  2020 
#> # ℹ 17 more rows

# estimates for multiple years, Brazil level
censo_estimativa(year = 2015:2020, territorial_level = "brazil")
#> ℹ Querying SIDRA API for table "6579"...
#> ✔ Retrieved 6 rows: Population estimates for 6 years
#> # A tibble: 6 × 11
#>   nc    nn     mc    mn              v d1c   d1n    d2c   d2n        d3c   d3n  
#>   <chr> <chr>  <chr> <chr>       <dbl> <chr> <chr>  <chr> <chr>      <chr> <chr>
#> 1 1     Brasil 45    Pessoas 204450049 1     Brasil 9324  População… 2015  2015 
#> 2 1     Brasil 45    Pessoas 206081432 1     Brasil 9324  População… 2016  2016 
#> 3 1     Brasil 45    Pessoas 207660929 1     Brasil 9324  População… 2017  2017 
#> 4 1     Brasil 45    Pessoas 208494900 1     Brasil 9324  População… 2018  2018 
#> 5 1     Brasil 45    Pessoas 210147125 1     Brasil 9324  População… 2019  2019 
#> 6 1     Brasil 45    Pessoas 211755692 1     Brasil 9324  População… 2020  2020 

# estimates by municipality
censo_estimativa(year = 2021, territorial_level = "municipality")
#> ℹ Querying SIDRA API for table "6579"...
#> ✔ Retrieved 5571 rows: Population estimates for 1 year
#> # A tibble: 5,571 × 11
#>    nc    nn        mc    mn           v d1c     d1n      d2c   d2n   d3c   d3n  
#>    <chr> <chr>     <chr> <chr>    <dbl> <chr>   <chr>    <chr> <chr> <chr> <chr>
#>  1 6     Município 45    Pessoas  22516 1100015 Alta Fl… 9324  Popu… 2021  2021 
#>  2 6     Município 45    Pessoas 111148 1100023 Ariquem… 9324  Popu… 2021  2021 
#>  3 6     Município 45    Pessoas   5067 1100031 Cabixi … 9324  Popu… 2021  2021 
#>  4 6     Município 45    Pessoas  86416 1100049 Cacoal … 9324  Popu… 2021  2021 
#>  5 6     Município 45    Pessoas  16088 1100056 Cerejei… 9324  Popu… 2021  2021 
#>  6 6     Município 45    Pessoas  15213 1100064 Colorad… 9324  Popu… 2021  2021 
#>  7 6     Município 45    Pessoas   7052 1100072 Corumbi… 9324  Popu… 2021  2021 
#>  8 6     Município 45    Pessoas  19255 1100080 Costa M… 9324  Popu… 2021  2021 
#>  9 6     Município 45    Pessoas  33009 1100098 Espigão… 9324  Popu… 2021  2021 
#> 10 6     Município 45    Pessoas  46930 1100106 Guajará… 9324  Popu… 2021  2021 
#> # ℹ 5,561 more rows
# }
```
