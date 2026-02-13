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
#> Acesso: FTP DATASUS (1994-2019) + OpenDataSUS CSV (2020+)
#> Dados: Agregados (FTP) e microdados individuais (CSV)
#> Granularidade: Anual/UF (FTP), Mensal/UF (CSV)
#> 
#> ── Fontes de dados ──
#> 
#> • FTP DATASUS (1994–2019): Dados agregados (DPNI/CPNI) em .DBF
#> • OpenDataSUS CSV (2020–2025): Microdados individuais (1 linha por dose)
#> 
#> ── Dados disponíveis ──
#> 
#> • `sipni_data()`: Dados de vacinação (doses, cobertura ou microdados)
#>   Anos: 1994–2025
#> • `sipni_variables()`: Lista de variáveis disponíveis
#> • `sipni_dictionary()`: Dicionário com categorias (FTP)
#> 
#> ── Tipos de arquivo ──
#> 
#> DPNI Doses Aplicadas — Doses de vacinas aplicadas por município, faixa etária,
#> imuno e dose (FTP, 1994-2019)
#> CPNI Cobertura Vacinal — Cobertura vacinal por município e imunobiológico (FTP,
#> 1994-2019)
#> API Microdados CSV — Microdados individuais de vacinação via OpenDataSUS CSV
#> (2020+)
#> 
#> ── Variáveis-chave (DPNI) ──
#> 
#> IMUNO Código do imunobiológico
#> QT_DOSE Quantidade de doses aplicadas
#> DOSE Tipo de dose (1ª, 2ª, Reforço, etc.)
#> FX_ETARIA Faixa etária
#> MUNIC Município (IBGE 6 dígitos)
#> 
#> ── Variáveis-chave (API 2020+) ──
#> 
#> descricao_vacina Nome da vacina
#> descricao_dose_vacina Descrição da dose
#> tipo_sexo_paciente Sexo do paciente (M/F)
#> numero_idade_paciente Idade do paciente
#> data_vacina Data da vacinação
#> 
#> ℹ 1994-2019: Dados agregados (contagens por município/vacina/faixa).
#> ℹ 2020+: Microdados individuais (1 linha por dose aplicada) via CSV.
#> ℹ Use `month` em `sipni_data()` para filtrar meses (CSV 2020+).
```
