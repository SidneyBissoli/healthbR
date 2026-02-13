# SINAN Data Dictionary

Returns a tibble with the complete data dictionary for the SINAN,
including variable descriptions and category labels.

## Usage

``` r
sinan_dictionary(variable = NULL)
```

## Arguments

- variable:

  Character. If provided, returns dictionary for a specific variable
  only. Default: NULL (returns all variables).

## Value

A tibble with columns: variable, description, code, label.

## See also

Other sinan:
[`sinan_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sinan_cache_status.md),
[`sinan_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sinan_clear_cache.md),
[`sinan_data()`](https://sidneybissoli.github.io/healthbR/reference/sinan_data.md),
[`sinan_diseases()`](https://sidneybissoli.github.io/healthbR/reference/sinan_diseases.md),
[`sinan_info()`](https://sidneybissoli.github.io/healthbR/reference/sinan_info.md),
[`sinan_variables()`](https://sidneybissoli.github.io/healthbR/reference/sinan_variables.md),
[`sinan_years()`](https://sidneybissoli.github.io/healthbR/reference/sinan_years.md)

## Examples

``` r
sinan_dictionary()
#> # A tibble: 51 × 4
#>    variable description         code  label     
#>    <chr>    <chr>               <chr> <chr>     
#>  1 TP_NOT   Tipo de notificação 1     Negativa  
#>  2 TP_NOT   Tipo de notificação 2     Individual
#>  3 TP_NOT   Tipo de notificação 3     Surto     
#>  4 TP_NOT   Tipo de notificação 4     Agregado  
#>  5 CS_SEXO  Sexo                M     Masculino 
#>  6 CS_SEXO  Sexo                F     Feminino  
#>  7 CS_SEXO  Sexo                I     Ignorado  
#>  8 CS_RACA  Raça/cor            1     Branca    
#>  9 CS_RACA  Raça/cor            2     Preta     
#> 10 CS_RACA  Raça/cor            3     Amarela   
#> # ℹ 41 more rows
sinan_dictionary("CS_SEXO")
#> # A tibble: 3 × 4
#>   variable description code  label    
#>   <chr>    <chr>       <chr> <chr>    
#> 1 CS_SEXO  Sexo        M     Masculino
#> 2 CS_SEXO  Sexo        F     Feminino 
#> 3 CS_SEXO  Sexo        I     Ignorado 
sinan_dictionary("EVOLUCAO")
#> # A tibble: 4 × 4
#>   variable description      code  label                       
#>   <chr>    <chr>            <chr> <chr>                       
#> 1 EVOLUCAO Evolução do caso 1     Cura                        
#> 2 EVOLUCAO Evolução do caso 2     Óbito pelo agravo notificado
#> 3 EVOLUCAO Evolução do caso 3     Óbito por outras causas     
#> 4 EVOLUCAO Evolução do caso 9     Ignorado                    
```
