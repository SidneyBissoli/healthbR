# List SIH Variables

Returns a tibble with available variables in the SIH microdata,
including descriptions and value types.

## Usage

``` r
sih_variables(year = NULL, search = NULL)
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

Other sih:
[`sih_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sih_cache_status.md),
[`sih_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sih_clear_cache.md),
[`sih_data()`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md),
[`sih_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sih_dictionary.md),
[`sih_info()`](https://sidneybissoli.github.io/healthbR/reference/sih_info.md),
[`sih_years()`](https://sidneybissoli.github.io/healthbR/reference/sih_years.md)

## Examples

``` r
sih_variables()
#> # A tibble: 41 × 4
#>    variable  description                                           type  section
#>    <chr>     <chr>                                                 <chr> <chr>  
#>  1 N_AIH     Número da AIH                                         char… identi…
#>  2 IDENT     Tipo de AIH (1=Normal, 5=Longa permanência)           char… identi…
#>  3 CEP       CEP do paciente                                       char… identi…
#>  4 MUNIC_RES Município de residência (código IBGE 6 dígitos)       char… identi…
#>  5 MUNIC_MOV Município de atendimento (código IBGE 6 dígitos)      char… identi…
#>  6 NASC      Data de nascimento (aaaammdd)                         date… pacien…
#>  7 SEXO      Sexo (0=Ignorado, 1=Masculino, 3=Feminino)            char… pacien…
#>  8 IDADE     Idade (valor numérico conforme COD_IDADE)             inte… pacien…
#>  9 COD_IDADE Código da unidade de idade (2=dias, 3=meses, 4=anos)  char… pacien…
#> 10 RACA_COR  Raça/cor (01=Branca, 02=Preta, 03=Parda, 04=Amarela,… char… pacien…
#> # ℹ 31 more rows
sih_variables(search = "diag")
#> # A tibble: 3 × 4
#>   variable   description                       type      section
#>   <chr>      <chr>                             <chr>     <chr>  
#> 1 DIAG_PRINC Diagnóstico principal (CID-10)    character clinica
#> 2 DIAG_SECUN Diagnóstico secundário (CID-10)   character clinica
#> 3 DIAGSEC1   Diagnóstico secundário 1 (CID-10) character clinica
sih_variables(search = "valor")
#> # A tibble: 6 × 4
#>   variable description                               type    section   
#>   <chr>    <chr>                                     <chr>   <chr>     
#> 1 IDADE    Idade (valor numérico conforme COD_IDADE) integer paciente  
#> 2 VAL_SH   Valor dos serviços hospitalares           double  financeiro
#> 3 VAL_SP   Valor dos serviços profissionais          double  financeiro
#> 4 VAL_TOT  Valor total da AIH                        double  financeiro
#> 5 VAL_UTI  Valor de UTI                              double  financeiro
#> 6 US_TOT   Valor total dos procedimentos (US$)       double  financeiro
```
