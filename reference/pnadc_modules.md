# List available PNADC modules

Returns information about the available supplementary modules in PNAD
Continua that are supported by this package.

## Usage

``` r
pnadc_modules()
```

## Value

A tibble with module information including name, available years, and
descriptions.

## Examples

``` r
pnadc_modules()
#> # A tibble: 4 × 6
#>   module      name                             name_en years quarter description
#>   <chr>       <chr>                            <chr>   <lis>   <int> <chr>      
#> 1 deficiencia Pessoas com Deficiência          Person… <int>       3 Módulo sup…
#> 2 habitacao   Características da Habitação     Housin… <int>      NA Módulo sob…
#> 3 moradores   Características Gerais dos Mora… Genera… <int>      NA Módulo com…
#> 4 aps         Atenção Primária à Saúde         Primar… <int>       2 Módulo sup…
```
