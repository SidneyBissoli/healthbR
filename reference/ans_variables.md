# List ANS Variables

Returns a tibble with available variables in the ANS data, including
descriptions and value types.

## Usage

``` r
ans_variables(type = "beneficiaries", search = NULL)
```

## Arguments

- type:

  Character. Type of data. One of `"beneficiaries"` (default),
  `"complaints"`, `"financial"`, or `"operators"`.

- search:

  Character. Optional search term to filter variables by name or
  description. Case-insensitive and accent-insensitive.

## Value

A tibble with columns: variable, description, type, section.

## See also

Other ans:
[`ans_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/ans_cache_status.md),
[`ans_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/ans_clear_cache.md),
[`ans_data()`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md),
[`ans_info()`](https://sidneybissoli.github.io/healthbR/reference/ans_info.md),
[`ans_operators()`](https://sidneybissoli.github.io/healthbR/reference/ans_operators.md),
[`ans_years()`](https://sidneybissoli.github.io/healthbR/reference/ans_years.md)

## Examples

``` r
ans_variables()
#> # A tibble: 22 × 4
#>    variable             description                                type  section
#>    <chr>                <chr>                                      <chr> <chr>  
#>  1 ID_CMPT_MOVEL        Competência (AAAA-MM)                      char… operad…
#>  2 CD_OPERADORA         Código da operadora na ANS                 char… operad…
#>  3 NM_RAZAO_SOCIAL      Razão social da operadora                  char… operad…
#>  4 NR_CNPJ              CNPJ da operadora                          char… operad…
#>  5 MODALIDADE_OPERADORA Modalidade da operadora (Medicina de Grup… char… operad…
#>  6 SG_UF                Sigla da UF                                char… locali…
#>  7 CD_MUNICIPIO         Código do município (IBGE)                 char… locali…
#>  8 NM_MUNICIPIO         Nome do município                          char… locali…
#>  9 TP_SEXO              Sexo do beneficiário (M/F)                 char… benefi…
#> 10 DE_FAIXA_ETARIA      Faixa etária                               char… benefi…
#> # ℹ 12 more rows
ans_variables(type = "complaints")
#> # A tibble: 27 × 4
#>    variable                   description                          type  section
#>    <chr>                      <chr>                                <chr> <chr>  
#>  1 NUMERO_DA_DEMANDA          Número da demanda                    char… demanda
#>  2 ABERTURA_DA_DEMANDA        Data de abertura da demanda          date  demanda
#>  3 ANO_DE_REFERENCIA          Ano de referência                    inte… demanda
#>  4 MES_DE_REFERENCIA          Mês de referência                    inte… demanda
#>  5 SITUACAO_DA_DEMANDA        Situação da demanda (Finalizado, Em… char… demanda
#>  6 FORMA_DE_CONTATO_COM_A_ANS Forma de contato (Telefone, Interne… char… demanda
#>  7 ASSUNTO                    Assunto da demanda                   char… assunto
#>  8 REGISTRO_OPERADORA         Registro da operadora na ANS         char… operad…
#>  9 NOME_OPERADORA             Nome da operadora                    char… operad…
#> 10 MODALIDADE_DA_OPERADORA    Modalidade da operadora              char… operad…
#> # ℹ 17 more rows
ans_variables(search = "operadora")
#> # A tibble: 4 × 4
#>   variable             description                                 type  section
#>   <chr>                <chr>                                       <chr> <chr>  
#> 1 CD_OPERADORA         Código da operadora na ANS                  char… operad…
#> 2 NM_RAZAO_SOCIAL      Razão social da operadora                   char… operad…
#> 3 NR_CNPJ              CNPJ da operadora                           char… operad…
#> 4 MODALIDADE_OPERADORA Modalidade da operadora (Medicina de Grupo… char… operad…
```
