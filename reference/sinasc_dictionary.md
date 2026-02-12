# SINASC Data Dictionary

Returns a tibble with the complete data dictionary for the SINASC,
including variable descriptions and category labels.

## Usage

``` r
sinasc_dictionary(variable = NULL)
```

## Arguments

- variable:

  Character. If provided, returns dictionary for a specific variable
  only. Default: NULL (returns all variables).

## Value

A tibble with columns: variable, description, code, label.

## See also

Other sinasc:
[`sinasc_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_cache_status.md),
[`sinasc_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_clear_cache.md),
[`sinasc_data()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_data.md),
[`sinasc_info()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_info.md),
[`sinasc_variables()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_variables.md),
[`sinasc_years()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_years.md)

## Examples

``` r
sinasc_dictionary()
#> # A tibble: 69 × 4
#>    variable   description               code  label    
#>    <chr>      <chr>                     <chr> <chr>    
#>  1 SEXO       Sexo do recém-nascido     1     Masculino
#>  2 SEXO       Sexo do recém-nascido     2     Feminino 
#>  3 SEXO       Sexo do recém-nascido     0     Ignorado 
#>  4 RACACOR    Raça/cor do recém-nascido 1     Branca   
#>  5 RACACOR    Raça/cor do recém-nascido 2     Preta    
#>  6 RACACOR    Raça/cor do recém-nascido 3     Amarela  
#>  7 RACACOR    Raça/cor do recém-nascido 4     Parda    
#>  8 RACACOR    Raça/cor do recém-nascido 5     Indígena 
#>  9 RACACORMAE Raça/cor da mãe           1     Branca   
#> 10 RACACORMAE Raça/cor da mãe           2     Preta    
#> # ℹ 59 more rows
sinasc_dictionary("SEXO")
#> # A tibble: 3 × 4
#>   variable description           code  label    
#>   <chr>    <chr>                 <chr> <chr>    
#> 1 SEXO     Sexo do recém-nascido 1     Masculino
#> 2 SEXO     Sexo do recém-nascido 2     Feminino 
#> 3 SEXO     Sexo do recém-nascido 0     Ignorado 
sinasc_dictionary("PARTO")
#> # A tibble: 3 × 4
#>   variable description   code  label   
#>   <chr>    <chr>         <chr> <chr>   
#> 1 PARTO    Tipo de parto 1     Vaginal 
#> 2 PARTO    Tipo de parto 2     Cesáreo 
#> 3 PARTO    Tipo de parto 9     Ignorado
```
