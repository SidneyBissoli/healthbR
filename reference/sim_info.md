# SIM Module Information

Displays information about the Mortality Information System (SIM),
including data sources, available years, and usage guidance.

## Usage

``` r
sim_info()
```

## Value

A list with module information (invisibly).

## See also

Other sim:
[`sim_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sim_cache_status.md),
[`sim_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sim_clear_cache.md),
[`sim_data()`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md),
[`sim_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sim_dictionary.md),
[`sim_variables()`](https://sidneybissoli.github.io/healthbR/reference/sim_variables.md),
[`sim_years()`](https://sidneybissoli.github.io/healthbR/reference/sim_years.md)

## Examples

``` r
sim_info()
#> 
#> ── SIM — Sistema de Informações sobre Mortalidade ──────────────────────────────
#> 
#> Fonte: Ministério da Saúde / DATASUS
#> Acesso: FTP DATASUS
#> Documento base: Declaração de Óbito (DO)
#> 
#> ── Dados disponíveis ──
#> 
#> • `sim_data()`: Microdados de mortalidade
#>   Anos definitivos: 1996–2022
#>   Anos preliminares: 2023–2024
#> • `sim_variables()`: Lista de variáveis disponíveis
#> • `sim_dictionary()`: Dicionário completo com categorias
#> 
#> ── Variáveis-chave ──
#> 
#> CAUSABAS Causa básica do óbito (CID-10)
#> DTOBITO Data do óbito
#> CODMUNRES Município de residência (IBGE)
#> SEXO Sexo
#> IDADE Idade (codificada)
#> RACACOR Raça/cor
#> 
#> ℹ Use com `censo_populacao()` para calcular taxas de mortalidade.
```
