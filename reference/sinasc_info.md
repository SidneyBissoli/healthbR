# SINASC Module Information

Displays information about the Live Birth Information System (SINASC),
including data sources, available years, and usage guidance.

## Usage

``` r
sinasc_info()
```

## Value

A list with module information (invisibly).

## See also

Other sinasc:
[`sinasc_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_cache_status.md),
[`sinasc_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_clear_cache.md),
[`sinasc_data()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_data.md),
[`sinasc_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_dictionary.md),
[`sinasc_variables()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_variables.md),
[`sinasc_years()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_years.md)

## Examples

``` r
sinasc_info()
#> 
#> ── SINASC — Sistema de Informações sobre Nascidos Vivos ────────────────────────
#> 
#> Fonte: Ministério da Saúde / DATASUS
#> Acesso: FTP DATASUS
#> Documento base: Declaração de Nascido Vivo (DN)
#> 
#> ── Dados disponíveis ──
#> 
#> • `sinasc_data()`: Microdados de nascidos vivos
#>   Anos definitivos: 1996–2022
#>   Anos preliminares: 2023–2024
#> • `sinasc_variables()`: Lista de variáveis disponíveis
#> • `sinasc_dictionary()`: Dicionário completo com categorias
#> 
#> ── Variáveis-chave ──
#> 
#> DTNASC Data de nascimento
#> CODMUNRES Município de residência da mãe (IBGE)
#> SEXO Sexo
#> PESO Peso ao nascer (gramas)
#> IDADEMAE Idade da mãe
#> GESTACAO Semanas de gestação
#> PARTO Tipo de parto
#> CONSULTAS Consultas pré-natal
#> CODANOMAL Anomalia congênita (CID-10)
#> 
#> ℹ Use com `censo_populacao()` para calcular taxas de natalidade.
```
