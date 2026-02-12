# List PNS variables

Returns a list of available variables in the PNS microdata with their
labels. This is a convenience wrapper around
[`pns_dictionary`](https://sidneybissoli.github.io/healthbR/reference/pns_dictionary.md)
that returns only unique variable names and labels.

## Usage

``` r
pns_variables(year = 2019, module = NULL, cache_dir = NULL, refresh = FALSE)
```

## Arguments

- year:

  Numeric. Year to get variables for (2013 or 2019). Default is 2019.

- module:

  Character. Filter by module code (e.g., "J", "K", "L"). NULL returns
  all modules. Default is NULL.

- cache_dir:

  Character. Directory for caching downloaded files. Default uses
  `tools::R_user_dir("healthbR", "cache")`.

- refresh:

  Logical. If TRUE, re-download even if file exists in cache. Default is
  FALSE.

## Value

A tibble with variable names and labels.

## Examples

``` r
# \donttest{
# list all variables for 2019
pns_variables(year = 2019, cache_dir = tempdir())
#> Loading PNS 2019 dictionary from cache...
#> Dictionary structure not recognized, returning raw structure.
#> # A tibble: 5,223 × 8
#>    year  dicionario_das_variaveis_da_pns_2…¹ x2    x3    x4    x5    x6    x7   
#>    <chr> <chr>                               <chr> <chr> <chr> <chr> <chr> <chr>
#>  1 2019  Posição inicial                     Tama… "Cód… Ques… NA    Cate… NA   
#>  2 2019  NA                                  NA     NA   nº    desc… Tipo  Desc…
#>  3 2019  NA                                  NA     NA   NA    NA    NA    NA   
#>  4 2019  Parte 1 - Identificação e Controle  NA     NA   NA    NA    NA    NA   
#>  5 2019  1                                   2     "V00… NA    Unid… 11    Rond…
#>  6 2019  NA                                  NA     NA   NA    NA    12    Acre 
#>  7 2019  NA                                  NA     NA   NA    NA    13    Amaz…
#>  8 2019  NA                                  NA     NA   NA    NA    14    Rora…
#>  9 2019  NA                                  NA     NA   NA    NA    15    Pará 
#> 10 2019  NA                                  NA     NA   NA    NA    16    Amapá
#> # ℹ 5,213 more rows
#> # ℹ abbreviated name: ¹​dicionario_das_variaveis_da_pns_2019

# list variables for a specific module
pns_variables(year = 2019, module = "J", cache_dir = tempdir())
#> Loading PNS 2019 dictionary from cache...
#> Dictionary structure not recognized, returning raw structure.
#> # A tibble: 5,223 × 8
#>    year  dicionario_das_variaveis_da_pns_2…¹ x2    x3    x4    x5    x6    x7   
#>    <chr> <chr>                               <chr> <chr> <chr> <chr> <chr> <chr>
#>  1 2019  Posição inicial                     Tama… "Cód… Ques… NA    Cate… NA   
#>  2 2019  NA                                  NA     NA   nº    desc… Tipo  Desc…
#>  3 2019  NA                                  NA     NA   NA    NA    NA    NA   
#>  4 2019  Parte 1 - Identificação e Controle  NA     NA   NA    NA    NA    NA   
#>  5 2019  1                                   2     "V00… NA    Unid… 11    Rond…
#>  6 2019  NA                                  NA     NA   NA    NA    12    Acre 
#>  7 2019  NA                                  NA     NA   NA    NA    13    Amaz…
#>  8 2019  NA                                  NA     NA   NA    NA    14    Rora…
#>  9 2019  NA                                  NA     NA   NA    NA    15    Pará 
#> 10 2019  NA                                  NA     NA   NA    NA    16    Amapá
#> # ℹ 5,213 more rows
#> # ℹ abbreviated name: ¹​dicionario_das_variaveis_da_pns_2019
# }
```
