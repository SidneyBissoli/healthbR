# SIH Module Information

Displays information about the Hospital Information System (SIH),
including data sources, available years, and usage guidance.

## Usage

``` r
sih_info()
```

## Value

A list with module information (invisibly).

## See also

Other sih:
[`sih_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sih_cache_status.md),
[`sih_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sih_clear_cache.md),
[`sih_data()`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md),
[`sih_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sih_dictionary.md),
[`sih_status()`](https://sidneybissoli.github.io/healthbR/reference/sih_status.md),
[`sih_variables()`](https://sidneybissoli.github.io/healthbR/reference/sih_variables.md),
[`sih_years()`](https://sidneybissoli.github.io/healthbR/reference/sih_years.md)

## Examples

``` r
sih_info()
#> 
#> ── SIH — Sistema de Informações Hospitalares ───────────────────────────────────
#> 
#> Fonte: Ministério da Saúde / DATASUS
#> Acesso: Espelho R2 healthbr-data (padrão) com fallback FTP DATASUS
#> Documento base: Autorização de Internação Hospitalar (AIH)
#> Granularidade: Mensal (um arquivo por UF/mês)
#> 
#> ── Dados disponíveis ──
#> 
#> • `sih_data()`: Microdados de internações hospitalares
#>   Anos definitivos: 2008–2024
#>   Anos preliminares: 2025 and 2026
#> • `sih_variables()`: Lista de variáveis disponíveis
#> • `sih_dictionary()`: Dicionário completo com categorias
#> 
#> ── Variáveis-chave ──
#> 
#> DIAG_PRINC Diagnóstico principal (CID-10)
#> DT_INTER Data de internação
#> MUNIC_RES Município de residência (IBGE)
#> SEXO Sexo (0=Ign, 1=Masc, 3=Fem)
#> MORTE Óbito hospitalar (0=Não, 1=Sim)
#> VAL_TOT Valor total da AIH
#> 
#> ── Fontes de dados ──
#> 
#> • R2 healthbr-data (padrão): Parquet idêntico ao .dbc do FTP, 1992–presente,
#>   com proveniência (URL, MD5 e data de download do arquivo de origem)
#> • FTP DATASUS (fallback): arquivos RD{UF}{aa}{mm}.dbc, 2008–presente
#>   Use `source` em `sih_data()` para fixar uma fonte.
#> 
#> ℹ Dados mensais: use `month` em `sih_data()` para selecionar meses.
#> ℹ `sih_status()` lista as competências publicadas no espelho, com hash e data de cada arquivo.
```
