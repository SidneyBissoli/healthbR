# List SIM Variables

Returns a tibble with available variables in the SIM microdata,
including descriptions and value types.

## Usage

``` r
sim_variables(year = NULL, search = NULL)
```

## Arguments

- year:

  Integer. If provided, returns variables available for that specific
  year (reserved for future use). Default: NULL.

- search:

  Character. Optional search term to filter variables by name or
  description. Case-insensitive.

## Value

A tibble with columns: variable, description, type, section.

## See also

Other sim:
[`sim_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sim_cache_status.md),
[`sim_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sim_clear_cache.md),
[`sim_data()`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md),
[`sim_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sim_dictionary.md),
[`sim_info()`](https://sidneybissoli.github.io/healthbR/reference/sim_info.md),
[`sim_years()`](https://sidneybissoli.github.io/healthbR/reference/sim_years.md)

## Examples

``` r
sim_variables()
#> # A tibble: 39 × 4
#>    variable   description                                          type  section
#>    <chr>      <chr>                                                <chr> <chr>  
#>  1 TIPOBITO   Tipo do óbito (1=fetal, 2=não fetal)                 char… identi…
#>  2 DTOBITO    Data do óbito (ddmmaaaa)                             date… identi…
#>  3 HORAOBITO  Hora do óbito                                        char… identi…
#>  4 NATURAL    Naturalidade (código IBGE)                           char… identi…
#>  5 DTNASC     Data de nascimento (ddmmaaaa)                        date… identi…
#>  6 CODMUNRES  Município de residência (código IBGE 6 dígitos)      char… locali…
#>  7 CODMUNOCOR Município de ocorrência do óbito (código IBGE)       char… locali…
#>  8 LOCOCOR    Local de ocorrência (1=Hospital, 2=Outro estab., 3=… char… locali…
#>  9 SEXO       Sexo (M=Masculino, F=Feminino, I=Ignorado)           char… demogr…
#> 10 IDADE      Idade codificada (ver sim_dictionary('IDADE'))       char… demogr…
#> # ℹ 29 more rows
sim_variables(search = "causa")
#> # A tibble: 3 × 4
#>   variable   description                                    type      section
#>   <chr>      <chr>                                          <chr>     <chr>  
#> 1 CAUSABAS   Causa básica do óbito (CID-10)                 character causa  
#> 2 CAUSABAS_O Causa básica original (antes de recodificação) character causa  
#> 3 CIRCOBITO  Circunstância do óbito (causas externas)       character causa  
sim_variables(search = "mae")
#> # A tibble: 2 × 4
#>   variable description         type      section
#>   <chr>    <chr>               <chr>     <chr>  
#> 1 IDADEMAE Idade da mãe        integer   materna
#> 2 ESCMAE   Escolaridade da mãe character materna
```
