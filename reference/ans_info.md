# ANS Module Information

Displays information about the ANS (Agencia Nacional de Saude
Suplementar) module, including data sources, available years, and usage
guidance.

## Usage

``` r
ans_info()
```

## Value

A list with module information (invisibly).

## See also

Other ans:
[`ans_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/ans_cache_status.md),
[`ans_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/ans_clear_cache.md),
[`ans_data()`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md),
[`ans_operators()`](https://sidneybissoli.github.io/healthbR/reference/ans_operators.md),
[`ans_variables()`](https://sidneybissoli.github.io/healthbR/reference/ans_variables.md),
[`ans_years()`](https://sidneybissoli.github.io/healthbR/reference/ans_years.md)

## Examples

``` r
ans_info()
#> 
#> ── ANS — Agência Nacional de Saúde Suplementar ─────────────────────────────────
#> 
#> Fonte: Agência Nacional de Saúde Suplementar (ANS)
#> Acesso: Dados Abertos ANS (HTTP)
#> Conteúdo: Dados do setor de saúde suplementar (planos de saúde)
#> 
#> ── Dados disponíveis ──
#> 
#> • `ans_data()`: Dados de beneficiários, demandas e demonstrações contábeis
#> • `ans_operators()`: Cadastro de operadoras (ativas/canceladas)
#> • `ans_variables()`: Lista de variáveis disponíveis
#> 
#> ── Tipos de dados ──
#> 
#> beneficiaries Beneficiários — Informações consolidadas de beneficiários por
#> operadora, UF, sexo, faixa etária
#> complaints Demandas dos consumidores (NIP) — Demandas e reclamações de
#> consumidores via NIP
#> financial Demonstrações contábeis — Demonstrações contábeis trimestrais das
#> operadoras
#> 
#> ── Parâmetros por tipo ──
#> 
#> beneficiaries: year, month, uf
#> complaints: year
#> financial: year, quarter
#> 
#> ── Períodos disponíveis ──
#> 
#> Beneficiários: Abr/2019–2025 (mensal, por UF)
#> Demandas NIP: 2011–2026 (anual, nacional)
#> Demonstrações: 2007–2025 (trimestral)
#> Operadoras: Instantaneo (cadastro atual)
#> 
```
