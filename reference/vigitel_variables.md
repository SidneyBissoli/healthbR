# List VIGITEL variables

Returns a tibble with information about available variables in the
VIGITEL dataset.

## Usage

``` r
vigitel_variables(cache_dir = NULL, force = FALSE)
```

## Arguments

- cache_dir:

  Character. Directory for caching downloaded files. Default uses
  `tools::R_user_dir("healthbR", "cache")`.

- force:

  Logical. If TRUE, re-download even if file exists in cache. Default is
  FALSE.

## Value

A tibble with variable information from the dictionary.

## Examples

``` r
# \donttest{
vars <- vigitel_variables(cache_dir = tempdir())
#> New names:
#> • `` -> `...2`
#> • `` -> `...3`
#> • `` -> `...4`
#> • `` -> `...5`
#> • `` -> `...6`
#> • `` -> `...7`
head(vars)
#> # A tibble: 6 × 7
#>   variaveis_vigitel x2           x3             x4           x5      x6    x7   
#>   <chr>             <chr>        <chr>          <chr>        <chr>   <chr> <chr>
#> 1 NA                NA           NA             NA           NA      NA    NA   
#> 2 Variable name     storage type display format value  label Variab… Códi… Label
#> 3 chave             str11        %11s           NA           chave   NA    NA   
#> 4 ano               int          %8.0g          NA           ano     NA    NA   
#> 5 cidade            byte         %8.0g          cidade       cidade  1     arac…
#> 6 NA                NA           NA             NA           NA      2     belem
# }
```
