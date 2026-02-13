# List SINAN Variables

Returns a tibble with available variables in the SINAN microdata,
including descriptions and value types.

## Usage

``` r
sinan_variables(disease = "DENG", search = NULL)
```

## Arguments

- disease:

  Character. Disease code (e.g., "DENG"). Currently not used for
  filtering but reserved for future disease-specific variables. Default:
  "DENG".

- search:

  Character. Optional search term to filter variables by name or
  description. Case-insensitive and accent-insensitive.

## Value

A tibble with columns: variable, description, type, section.

## See also

Other sinan:
[`sinan_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sinan_cache_status.md),
[`sinan_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sinan_clear_cache.md),
[`sinan_data()`](https://sidneybissoli.github.io/healthbR/reference/sinan_data.md),
[`sinan_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sinan_dictionary.md),
[`sinan_diseases()`](https://sidneybissoli.github.io/healthbR/reference/sinan_diseases.md),
[`sinan_info()`](https://sidneybissoli.github.io/healthbR/reference/sinan_info.md),
[`sinan_years()`](https://sidneybissoli.github.io/healthbR/reference/sinan_years.md)

## Examples

``` r
sinan_variables()
#> # A tibble: 32 × 4
#>    variable   description                                          type  section
#>    <chr>      <chr>                                                <chr> <chr>  
#>  1 NU_NOTIFIC Número da notificação                                char… notifi…
#>  2 TP_NOT     Tipo de notificação (1=Negativa, 2=Individual, 3=Su… char… notifi…
#>  3 ID_AGRAVO  Código do agravo notificado (CID-10)                 char… notifi…
#>  4 DT_NOTIFIC Data da notificação (dd/mm/aaaa)                     char… notifi…
#>  5 SEM_NOT    Semana epidemiológica da notificação                 char… notifi…
#>  6 NU_ANO     Ano da notificação                                   char… notifi…
#>  7 DT_SIN_PRI Data dos primeiros sintomas                          char… notifi…
#>  8 SEM_PRI    Semana epidemiológica dos primeiros sintomas         char… notifi…
#>  9 NM_PACIENT Nome do paciente                                     char… pacien…
#> 10 DT_NASC    Data de nascimento                                   char… pacien…
#> # ℹ 22 more rows
sinan_variables(search = "sexo")
#> # A tibble: 1 × 4
#>   variable description                                type      section 
#>   <chr>    <chr>                                      <chr>     <chr>   
#> 1 CS_SEXO  Sexo (M=Masculino, F=Feminino, I=Ignorado) character paciente
sinan_variables(search = "municipio")
#> # A tibble: 2 × 4
#>   variable   description                                      type      section 
#>   <chr>      <chr>                                            <chr>     <chr>   
#> 1 ID_MUNICIP Município de notificação (código IBGE 6 dígitos) character residen…
#> 2 ID_MN_RESI Município de residência (código IBGE 6 dígitos)  character residen…
```
