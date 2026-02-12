# CNES Data Dictionary

Returns a tibble with the complete data dictionary for the CNES,
including variable descriptions and category labels.

## Usage

``` r
cnes_dictionary(variable = NULL)
```

## Arguments

- variable:

  Character. If provided, returns dictionary for a specific variable
  only. Default: NULL (returns all variables).

## Value

A tibble with columns: variable, description, code, label.

## See also

Other cnes:
[`cnes_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/cnes_cache_status.md),
[`cnes_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/cnes_clear_cache.md),
[`cnes_data()`](https://sidneybissoli.github.io/healthbR/reference/cnes_data.md),
[`cnes_info()`](https://sidneybissoli.github.io/healthbR/reference/cnes_info.md),
[`cnes_variables()`](https://sidneybissoli.github.io/healthbR/reference/cnes_variables.md),
[`cnes_years()`](https://sidneybissoli.github.io/healthbR/reference/cnes_years.md)

## Examples

``` r
cnes_dictionary()
#> # A tibble: 34 × 4
#>    variable description                     code  label                         
#>    <chr>    <chr>                           <chr> <chr>                         
#>  1 TP_UNID  Tipo de unidade/estabelecimento 01    Posto de saúde                
#>  2 TP_UNID  Tipo de unidade/estabelecimento 02    Centro de saúde/unidade básica
#>  3 TP_UNID  Tipo de unidade/estabelecimento 04    Policlínica                   
#>  4 TP_UNID  Tipo de unidade/estabelecimento 05    Hospital geral                
#>  5 TP_UNID  Tipo de unidade/estabelecimento 07    Hospital especializado        
#>  6 TP_UNID  Tipo de unidade/estabelecimento 09    Pronto socorro geral          
#>  7 TP_UNID  Tipo de unidade/estabelecimento 15    Unidade mista                 
#>  8 TP_UNID  Tipo de unidade/estabelecimento 20    Pronto socorro especializado  
#>  9 TP_UNID  Tipo de unidade/estabelecimento 21    Consultoria médica            
#> 10 TP_UNID  Tipo de unidade/estabelecimento 22    Unidade de apoio diagnóstico  
#> # ℹ 24 more rows
cnes_dictionary("TP_UNID")
#> # A tibble: 22 × 4
#>    variable description                     code  label                         
#>    <chr>    <chr>                           <chr> <chr>                         
#>  1 TP_UNID  Tipo de unidade/estabelecimento 01    Posto de saúde                
#>  2 TP_UNID  Tipo de unidade/estabelecimento 02    Centro de saúde/unidade básica
#>  3 TP_UNID  Tipo de unidade/estabelecimento 04    Policlínica                   
#>  4 TP_UNID  Tipo de unidade/estabelecimento 05    Hospital geral                
#>  5 TP_UNID  Tipo de unidade/estabelecimento 07    Hospital especializado        
#>  6 TP_UNID  Tipo de unidade/estabelecimento 09    Pronto socorro geral          
#>  7 TP_UNID  Tipo de unidade/estabelecimento 15    Unidade mista                 
#>  8 TP_UNID  Tipo de unidade/estabelecimento 20    Pronto socorro especializado  
#>  9 TP_UNID  Tipo de unidade/estabelecimento 21    Consultoria médica            
#> 10 TP_UNID  Tipo de unidade/estabelecimento 22    Unidade de apoio diagnóstico  
#> # ℹ 12 more rows
cnes_dictionary("ESFERA_A")
#> # A tibble: 4 × 4
#>   variable description           code  label    
#>   <chr>    <chr>                 <chr> <chr>    
#> 1 ESFERA_A Esfera administrativa 1     Federal  
#> 2 ESFERA_A Esfera administrativa 2     Estadual 
#> 3 ESFERA_A Esfera administrativa 3     Municipal
#> 4 ESFERA_A Esfera administrativa 4     Privada  
```
