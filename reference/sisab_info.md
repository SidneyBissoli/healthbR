# SISAB Module Information

Displays information about the Primary Care Health Information System
(SISAB), including data sources, available report types, and usage
guidance.

## Usage

``` r
sisab_info()
```

## Value

A list with module information (invisibly).

## See also

Other sisab:
[`sisab_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sisab_cache_status.md),
[`sisab_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sisab_clear_cache.md),
[`sisab_data()`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md),
[`sisab_variables()`](https://sidneybissoli.github.io/healthbR/reference/sisab_variables.md),
[`sisab_years()`](https://sidneybissoli.github.io/healthbR/reference/sisab_years.md)

## Examples

``` r
sisab_info()
#> 
#> ── SISAB — Sistema de Informação em Saúde para a Atenção Básica ────────────────
#> 
#> Fonte: Ministério da Saúde / SAPS
#> Acesso: API REST (relatorioaps.saude.gov.br)
#> Dados: Cobertura da Atenção Primária (dados agregados)
#> Granularidade: Mensal (por competência CNES)
#> 
#> ── Dados disponíveis ──
#> 
#> • `sisab_data()`: Cobertura da atenção primária
#>   4 tipos de relatório, 4 níveis geográficos
#> • `sisab_variables()`: Lista de variáveis disponíveis
#> 
#> ── Tipos de relatório ──
#> 
#> aps Cobertura da Atenção Primária
#> Cobertura potencial da APS por equipes eSF, eAP, eSFR, eCR, eAPP (2019-atual)
#> sb Cobertura de Saúde Bucal
#> Cobertura de saúde bucal por equipes eSB e outras (2024-atual)
#> acs Cobertura de Agentes Comunitários de Saúde
#> Cobertura de agentes comunitários de saúde (2007-atual)
#> pns Cobertura PNS (Pesquisa Nacional de Saúde)
#> Cobertura da Atenção Primária via PNS (2020-2023)
#> 
#> ── Níveis geográficos ──
#> 
#> brazil Total nacional
#> region 5 macrorregiões
#> uf 27 estados
#> municipality ~5.570 municípios
#> 
#> ℹ Dados agregados (cobertura por município/equipe/período), não microdados.
#> ℹ Dados via API REST pública (não requer autenticação).
#> ℹ O relatório de produção (atendimentos) do portal SISAB está em manutenção.
```
