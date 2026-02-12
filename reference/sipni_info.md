# SI-PNI Module Information

Displays information about the National Immunization Program Information
System (SI-PNI), including data sources, available years, file types,
and usage guidance.

## Usage

``` r
sipni_info()
```

## Value

A list with module information (invisibly).

## See also

Other sipni:
[`sipni_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sipni_cache_status.md),
[`sipni_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sipni_clear_cache.md),
[`sipni_data()`](https://sidneybissoli.github.io/healthbR/reference/sipni_data.md),
[`sipni_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sipni_dictionary.md),
[`sipni_variables()`](https://sidneybissoli.github.io/healthbR/reference/sipni_variables.md),
[`sipni_years()`](https://sidneybissoli.github.io/healthbR/reference/sipni_years.md)

## Examples

``` r
sipni_info()
#> 
#> ── SI-PNI — Sistema de Informação do Programa Nacional de Imunizações ──────────
#> 
#> Fonte: Ministério da Saúde / DATASUS
#> Acesso: FTP DATASUS
#> Dados: Doses aplicadas e cobertura vacinal (dados agregados)
#> Granularidade: Anual (um arquivo por tipo/UF/ano)
#> 
#> ── Dados disponíveis ──
#> 
#> • `sipni_data()`: Dados de vacinação (doses ou cobertura)
#>   Anos: 1994–2019
#> • `sipni_variables()`: Lista de variáveis disponíveis
#> • `sipni_dictionary()`: Dicionário com categorias
#> 
#> ── Tipos de arquivo ──
#> 
#> DPNI Doses Aplicadas — Doses de vacinas aplicadas por município, faixa etária,
#> imuno e dose
#> CPNI Cobertura Vacinal — Cobertura vacinal por município e imunobiológico
#> 
#> ── Variáveis-chave (DPNI) ──
#> 
#> IMUNO Código do imunobiológico
#> QT_DOSE Quantidade de doses aplicadas
#> DOSE Tipo de dose (1ª, 2ª, Reforço, etc.)
#> FX_ETARIA Faixa etária
#> MUNIC Município (IBGE 6 dígitos)
#> 
#> ℹ Dados agregados (contagens por município/vacina/faixa), não microdados.
#> ℹ Use `type` em `sipni_data()`: DPNI (doses) ou CPNI (cobertura).
#> ℹ Dados no FTP disponíveis até 2019. Pós-2019 requer API web (futuro).
```
