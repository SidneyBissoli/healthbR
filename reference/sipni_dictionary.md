# SI-PNI Data Dictionary

Returns a tibble with the data dictionary for the SI-PNI, including
variable descriptions and category labels.

## Usage

``` r
sipni_dictionary(variable = NULL)
```

## Arguments

- variable:

  Character. If provided, returns dictionary for a specific variable
  only. Default: NULL (returns all variables).

## Value

A tibble with columns: variable, description, code, label.

## See also

Other sipni:
[`sipni_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sipni_cache_status.md),
[`sipni_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sipni_clear_cache.md),
[`sipni_data()`](https://sidneybissoli.github.io/healthbR/reference/sipni_data.md),
[`sipni_info()`](https://sidneybissoli.github.io/healthbR/reference/sipni_info.md),
[`sipni_variables()`](https://sidneybissoli.github.io/healthbR/reference/sipni_variables.md),
[`sipni_years()`](https://sidneybissoli.github.io/healthbR/reference/sipni_years.md)

## Examples

``` r
sipni_dictionary()
#> # A tibble: 36 × 4
#>    variable description              code  label                    
#>    <chr>    <chr>                    <chr> <chr>                    
#>  1 IMUNO    Código do imunobiológico 09    BCG                      
#>  2 IMUNO    Código do imunobiológico 21    Hepatite B               
#>  3 IMUNO    Código do imunobiológico 22    Tríplice bacteriana (DTP)
#>  4 IMUNO    Código do imunobiológico 23    Poliomielite oral (VOP)  
#>  5 IMUNO    Código do imunobiológico 24    Sarampo                  
#>  6 IMUNO    Código do imunobiológico 28    Febre amarela            
#>  7 IMUNO    Código do imunobiológico 29    Tríplice viral (SCR)     
#>  8 IMUNO    Código do imunobiológico 39    Dupla adulto (dT)        
#>  9 IMUNO    Código do imunobiológico 42    Tetravalente (DTP+Hib)   
#> 10 IMUNO    Código do imunobiológico 46    Rotavírus humano         
#> # ℹ 26 more rows
sipni_dictionary("IMUNO")
#> # A tibble: 20 × 4
#>    variable description              code  label                       
#>    <chr>    <chr>                    <chr> <chr>                       
#>  1 IMUNO    Código do imunobiológico 09    BCG                         
#>  2 IMUNO    Código do imunobiológico 21    Hepatite B                  
#>  3 IMUNO    Código do imunobiológico 22    Tríplice bacteriana (DTP)   
#>  4 IMUNO    Código do imunobiológico 23    Poliomielite oral (VOP)     
#>  5 IMUNO    Código do imunobiológico 24    Sarampo                     
#>  6 IMUNO    Código do imunobiológico 28    Febre amarela               
#>  7 IMUNO    Código do imunobiológico 29    Tríplice viral (SCR)        
#>  8 IMUNO    Código do imunobiológico 39    Dupla adulto (dT)           
#>  9 IMUNO    Código do imunobiológico 42    Tetravalente (DTP+Hib)      
#> 10 IMUNO    Código do imunobiológico 46    Rotavírus humano            
#> 11 IMUNO    Código do imunobiológico 56    Pneumocócica 10-valente     
#> 12 IMUNO    Código do imunobiológico 63    Meningocócica C conjugada   
#> 13 IMUNO    Código do imunobiológico 81    Pentavalente (DTP+HB+Hib)   
#> 14 IMUNO    Código do imunobiológico 82    Poliomielite inativada (VIP)
#> 15 IMUNO    Código do imunobiológico 83    Hepatite A                  
#> 16 IMUNO    Código do imunobiológico 84    Pneumocócica 23-valente     
#> 17 IMUNO    Código do imunobiológico 85    HPV quadrivalente           
#> 18 IMUNO    Código do imunobiológico 86    dTpa (gestante)             
#> 19 IMUNO    Código do imunobiológico 87    Varicela                    
#> 20 IMUNO    Código do imunobiológico 99    Outros imunobiológicos      
sipni_dictionary("DOSE")
#> # A tibble: 6 × 4
#>   variable description  code  label     
#>   <chr>    <chr>        <chr> <chr>     
#> 1 DOSE     Tipo de dose 1     1ª dose   
#> 2 DOSE     Tipo de dose 2     2ª dose   
#> 3 DOSE     Tipo de dose 3     3ª dose   
#> 4 DOSE     Tipo de dose 4     4ª dose   
#> 5 DOSE     Tipo de dose R     Reforço   
#> 6 DOSE     Tipo de dose U     Dose única
```
