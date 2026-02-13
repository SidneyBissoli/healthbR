# SIM Data Dictionary

Returns a tibble with the complete data dictionary for the SIM,
including variable descriptions and category labels.

## Usage

``` r
sim_dictionary(variable = NULL)
```

## Arguments

- variable:

  Character. If provided, returns dictionary for a specific variable
  only. Default: NULL (returns all variables).

## Value

A tibble with columns: variable, description, code, label.

## See also

Other sim:
[`sim_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sim_cache_status.md),
[`sim_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sim_clear_cache.md),
[`sim_data()`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md),
[`sim_info()`](https://sidneybissoli.github.io/healthbR/reference/sim_info.md),
[`sim_variables()`](https://sidneybissoli.github.io/healthbR/reference/sim_variables.md),
[`sim_years()`](https://sidneybissoli.github.io/healthbR/reference/sim_years.md)

## Examples

``` r
sim_dictionary()
#> # A tibble: 56 × 4
#>    variable description   code  label    
#>    <chr>    <chr>         <chr> <chr>    
#>  1 TIPOBITO Tipo do óbito 1     Fetal    
#>  2 TIPOBITO Tipo do óbito 2     Não fetal
#>  3 SEXO     Sexo          M     Masculino
#>  4 SEXO     Sexo          F     Feminino 
#>  5 SEXO     Sexo          I     Ignorado 
#>  6 RACACOR  Raça/cor      1     Branca   
#>  7 RACACOR  Raça/cor      2     Preta    
#>  8 RACACOR  Raça/cor      3     Amarela  
#>  9 RACACOR  Raça/cor      4     Parda    
#> 10 RACACOR  Raça/cor      5     Indígena 
#> # ℹ 46 more rows
sim_dictionary("SEXO")
#> # A tibble: 3 × 4
#>   variable description code  label    
#>   <chr>    <chr>       <chr> <chr>    
#> 1 SEXO     Sexo        M     Masculino
#> 2 SEXO     Sexo        F     Feminino 
#> 3 SEXO     Sexo        I     Ignorado 
sim_dictionary("RACACOR")
#> # A tibble: 5 × 4
#>   variable description code  label   
#>   <chr>    <chr>       <chr> <chr>   
#> 1 RACACOR  Raça/cor    1     Branca  
#> 2 RACACOR  Raça/cor    2     Preta   
#> 3 RACACOR  Raça/cor    3     Amarela 
#> 4 RACACOR  Raça/cor    4     Parda   
#> 5 RACACOR  Raça/cor    5     Indígena
```
