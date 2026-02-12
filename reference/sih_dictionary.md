# SIH Data Dictionary

Returns a tibble with the complete data dictionary for the SIH,
including variable descriptions and category labels.

## Usage

``` r
sih_dictionary(variable = NULL)
```

## Arguments

- variable:

  Character. If provided, returns dictionary for a specific variable
  only. Default: NULL (returns all variables).

## Value

A tibble with columns: variable, description, code, label.

## See also

Other sih:
[`sih_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sih_cache_status.md),
[`sih_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sih_clear_cache.md),
[`sih_data()`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md),
[`sih_info()`](https://sidneybissoli.github.io/healthbR/reference/sih_info.md),
[`sih_variables()`](https://sidneybissoli.github.io/healthbR/reference/sih_variables.md),
[`sih_years()`](https://sidneybissoli.github.io/healthbR/reference/sih_years.md)

## Examples

``` r
sih_dictionary()
#> # A tibble: 40 × 4
#>    variable  description                code  label         
#>    <chr>     <chr>                      <chr> <chr>         
#>  1 SEXO      Sexo do paciente           0     Ignorado      
#>  2 SEXO      Sexo do paciente           1     Masculino     
#>  3 SEXO      Sexo do paciente           3     Feminino      
#>  4 RACA_COR  Raça/cor do paciente       01    Branca        
#>  5 RACA_COR  Raça/cor do paciente       02    Preta         
#>  6 RACA_COR  Raça/cor do paciente       03    Parda         
#>  7 RACA_COR  Raça/cor do paciente       04    Amarela       
#>  8 RACA_COR  Raça/cor do paciente       05    Indígena      
#>  9 RACA_COR  Raça/cor do paciente       99    Sem informação
#> 10 COD_IDADE Unidade de medida da idade 2     Dias          
#> # ℹ 30 more rows
sih_dictionary("SEXO")
#> # A tibble: 3 × 4
#>   variable description      code  label    
#>   <chr>    <chr>            <chr> <chr>    
#> 1 SEXO     Sexo do paciente 0     Ignorado 
#> 2 SEXO     Sexo do paciente 1     Masculino
#> 3 SEXO     Sexo do paciente 3     Feminino 
sih_dictionary("CAR_INT")
#> # A tibble: 6 × 4
#>   variable description           code  label                        
#>   <chr>    <chr>                 <chr> <chr>                        
#> 1 CAR_INT  Caráter da internação 1     Eletiva                      
#> 2 CAR_INT  Caráter da internação 2     Urgência                     
#> 3 CAR_INT  Caráter da internação 3     Acidente no local de trabalho
#> 4 CAR_INT  Caráter da internação 4     Acidente no trajeto          
#> 5 CAR_INT  Caráter da internação 5     Outros acidentes de trânsito 
#> 6 CAR_INT  Caráter da internação 6     Outros tipos de lesões       
```
