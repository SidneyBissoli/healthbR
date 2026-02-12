# List SI-PNI Variables

Returns a tibble with available variables in the SI-PNI data, including
descriptions and value types.

## Usage

``` r
sipni_variables(type = "DPNI", search = NULL)
```

## Arguments

- type:

  Character. File type to show variables for. `"DPNI"` (default) for
  doses applied, `"CPNI"` for coverage.

- search:

  Character. Optional search term to filter variables by name or
  description. Case-insensitive and accent-insensitive.

## Value

A tibble with columns: variable, description, type, section.

## See also

Other sipni:
[`sipni_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sipni_cache_status.md),
[`sipni_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sipni_clear_cache.md),
[`sipni_data()`](https://sidneybissoli.github.io/healthbR/reference/sipni_data.md),
[`sipni_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sipni_dictionary.md),
[`sipni_info()`](https://sidneybissoli.github.io/healthbR/reference/sipni_info.md),
[`sipni_years()`](https://sidneybissoli.github.io/healthbR/reference/sipni_years.md)

## Examples

``` r
sipni_variables()
#> # A tibble: 12 × 4
#>    variable  description                       type      section    
#>    <chr>     <chr>                             <chr>     <chr>      
#>  1 ANO       Ano de referência                 character temporal   
#>  2 ANOMES    Ano e mês (AAAAMM)                character temporal   
#>  3 MES       Mês (01-12)                       character temporal   
#>  4 UF        Código UF (IBGE 2 dígitos)        character localizacao
#>  5 MUNIC     Código município (IBGE 6 dígitos) character localizacao
#>  6 FX_ETARIA Faixa etária (codificada)         character paciente   
#>  7 IMUNO     Código do imunobiológico          character vacinacao  
#>  8 DOSE      Tipo de dose                      character vacinacao  
#>  9 QT_DOSE   Quantidade de doses aplicadas     character vacinacao  
#> 10 DOSE1     (Reservado)                       character vacinacao  
#> 11 DOSEN     (Reservado)                       character vacinacao  
#> 12 DIFER     (Reservado)                       character vacinacao  
sipni_variables(type = "CPNI")
#> # A tibble: 7 × 4
#>   variable description                       type      section    
#>   <chr>    <chr>                             <chr>     <chr>      
#> 1 ANO      Ano de referência                 character temporal   
#> 2 UF       Código UF (IBGE 2 dígitos)        character localizacao
#> 3 MUNIC    Código município (IBGE 6 dígitos) character localizacao
#> 4 IMUNO    Código do imunobiológico          character vacinacao  
#> 5 QT_DOSE  Quantidade de doses aplicadas     character vacinacao  
#> 6 POP      População alvo                    character vacinacao  
#> 7 COBERT   Cobertura vacinal (%)             character vacinacao  
sipni_variables(search = "dose")
#> # A tibble: 4 × 4
#>   variable description                   type      section  
#>   <chr>    <chr>                         <chr>     <chr>    
#> 1 DOSE     Tipo de dose                  character vacinacao
#> 2 QT_DOSE  Quantidade de doses aplicadas character vacinacao
#> 3 DOSE1    (Reservado)                   character vacinacao
#> 4 DOSEN    (Reservado)                   character vacinacao
```
