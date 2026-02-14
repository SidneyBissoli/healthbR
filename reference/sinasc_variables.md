# List SINASC Variables

Returns a tibble with available variables in the SINASC microdata,
including descriptions and value types.

## Usage

``` r
sinasc_variables(year = NULL, search = NULL)
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

Other sinasc:
[`sinasc_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_cache_status.md),
[`sinasc_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_clear_cache.md),
[`sinasc_data()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_data.md),
[`sinasc_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_dictionary.md),
[`sinasc_info()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_info.md),
[`sinasc_years()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_years.md)

## Examples

``` r
sinasc_variables()
#> # A tibble: 44 × 4
#>    variable  description                                           type  section
#>    <chr>     <chr>                                                 <chr> <chr>  
#>  1 DTNASC    Data de nascimento (ddmmaaaa)                         date… recem_…
#>  2 HORANASC  Hora do nascimento                                    char… recem_…
#>  3 SEXO      Sexo (1=Masculino, 2=Feminino, 0/9=Ignorado)          char… recem_…
#>  4 RACACOR   Raça/cor do recém-nascido                             char… recem_…
#>  5 PESO      Peso ao nascer (gramas)                               inte… recem_…
#>  6 APGAR1    Apgar no 1º minuto                                    inte… recem_…
#>  7 APGAR5    Apgar no 5º minuto                                    inte… recem_…
#>  8 IDANOMAL  Anomalia congênita detectada (1=Sim, 2=Não, 9=Ignora… char… recem_…
#>  9 CODANOMAL Código da anomalia congênita (CID-10)                 char… recem_…
#> 10 IDADEMAE  Idade da mãe (anos)                                   inte… materna
#> # ℹ 34 more rows
sinasc_variables(search = "mae")
#> # A tibble: 9 × 4
#>   variable   description                                           type  section
#>   <chr>      <chr>                                                 <chr> <chr>  
#> 1 IDADEMAE   Idade da mãe (anos)                                   inte… materna
#> 2 ESTCIVMAE  Estado civil da mãe                                   char… materna
#> 3 ESCMAE     Escolaridade da mãe (anos de estudo)                  char… materna
#> 4 ESCMAE2010 Escolaridade da mãe (formato 2010+)                   char… materna
#> 5 RACACORMAE Raça/cor da mãe                                       char… materna
#> 6 CODOCUPMAE Ocupação da mãe (CBO-2002)                            char… materna
#> 7 SERIESCMAE Série escolar da mãe                                  char… materna
#> 8 CODMUNRES  Município de residência da mãe (código IBGE 6 dígito… char… locali…
#> 9 CODMUNNATU Município de naturalidade da mãe (código IBGE)        char… locali…
sinasc_variables(search = "parto")
#> # A tibble: 3 × 4
#>   variable   description                                  type      section
#>   <chr>      <chr>                                        <chr>     <chr>  
#> 1 PARTO      Tipo de parto (1=Vaginal, 2=Cesáreo)         character parto  
#> 2 STCESPARTO Cesárea antes do início do trabalho de parto character parto  
#> 3 STTRABPART Trabalho de parto induzido                   character parto  
```
