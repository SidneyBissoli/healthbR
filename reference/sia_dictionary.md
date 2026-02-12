# SIA Data Dictionary

Returns a tibble with the complete data dictionary for the SIA,
including variable descriptions and category labels.

## Usage

``` r
sia_dictionary(variable = NULL)
```

## Arguments

- variable:

  Character. If provided, returns dictionary for a specific variable
  only. Default: NULL (returns all variables).

## Value

A tibble with columns: variable, description, code, label.

## See also

Other sia:
[`sia_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sia_cache_status.md),
[`sia_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sia_clear_cache.md),
[`sia_data()`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md),
[`sia_info()`](https://sidneybissoli.github.io/healthbR/reference/sia_info.md),
[`sia_variables()`](https://sidneybissoli.github.io/healthbR/reference/sia_variables.md),
[`sia_years()`](https://sidneybissoli.github.io/healthbR/reference/sia_years.md)

## Examples

``` r
sia_dictionary()
#> # A tibble: 22 × 4
#>    variable   description          code  label              
#>    <chr>      <chr>                <chr> <chr>              
#>  1 PA_SEXO    Sexo do paciente     1     Masculino          
#>  2 PA_SEXO    Sexo do paciente     2     Feminino           
#>  3 PA_RACACOR Raça/cor do paciente 01    Branca             
#>  4 PA_RACACOR Raça/cor do paciente 02    Preta              
#>  5 PA_RACACOR Raça/cor do paciente 03    Amarela            
#>  6 PA_RACACOR Raça/cor do paciente 04    Parda              
#>  7 PA_RACACOR Raça/cor do paciente 05    Indígena           
#>  8 PA_CONDIC  Condição de gestão   EP    Estado plena       
#>  9 PA_CONDIC  Condição de gestão   EC    Estado convencional
#> 10 PA_CONDIC  Condição de gestão   MP    Municipal plena    
#> # ℹ 12 more rows
sia_dictionary("PA_SEXO")
#> # A tibble: 2 × 4
#>   variable description      code  label    
#>   <chr>    <chr>            <chr> <chr>    
#> 1 PA_SEXO  Sexo do paciente 1     Masculino
#> 2 PA_SEXO  Sexo do paciente 2     Feminino 
sia_dictionary("PA_RACACOR")
#> # A tibble: 5 × 4
#>   variable   description          code  label   
#>   <chr>      <chr>                <chr> <chr>   
#> 1 PA_RACACOR Raça/cor do paciente 01    Branca  
#> 2 PA_RACACOR Raça/cor do paciente 02    Preta   
#> 3 PA_RACACOR Raça/cor do paciente 03    Amarela 
#> 4 PA_RACACOR Raça/cor do paciente 04    Parda   
#> 5 PA_RACACOR Raça/cor do paciente 05    Indígena
```
