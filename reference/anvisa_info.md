# ANVISA Module Information

Displays information about the ANVISA (Agencia Nacional de Vigilancia
Sanitaria) module, including data sources, available types, and usage
guidance.

## Usage

``` r
anvisa_info()
```

## Value

A list with module information (invisibly).

## See also

Other anvisa:
[`anvisa_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_cache_status.md),
[`anvisa_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_clear_cache.md),
[`anvisa_data()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_data.md),
[`anvisa_types()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_types.md),
[`anvisa_variables()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_variables.md)

## Examples

``` r
anvisa_info()
#> 
#> ── ANVISA — Agência Nacional de Vigilância Sanitária ───────────────────────────
#> 
#> Fonte: Agência Nacional de Vigilância Sanitária (ANVISA)
#> Acesso: Portal de Dados Abertos (HTTPS)
#> Conteúdo: Registros de produtos, vigilância pós-mercado, SNGPC
#> 
#> ── Funções disponíveis ──
#> 
#> • `anvisa_data()`: Dados de registros, vigilância e SNGPC
#> • `anvisa_types()`: Tipos de dados disponíveis
#> • `anvisa_variables()`: Lista de variáveis por tipo
#> 
#> ── Categorias de dados ──
#> 
#> Registros de produtos (snapshot):
#> medicines — Medicamentos
#> medical_devices — Produtos para Saúde
#> food — Alimentos
#> cosmetics — Cosméticos
#> sanitizers — Saneantes
#> tobacco — Produtos Fumígenos
#> 
#> Referência (snapshot):
#> pesticides — Agrotóxicos
#> 
#> Vigilância pós-mercado (snapshot):
#> hemovigilance — Hemovigilância
#> technovigilance — Tecnovigilância
#> vigimed_notifications — VigiMed - Notificações
#> vigimed_medicines — VigiMed - Medicamentos
#> vigimed_reactions — VigiMed - Reações
#> 
#> SNGPC - Substâncias controladas (série temporal):
#> sngpc — SNGPC - Industrializados
#> sngpc_compounded — SNGPC - Manipulados
#> 
#> ── Períodos disponíveis ──
#> 
#> Registros/Vigilância: Instantâneo (snapshot atual)
#> SNGPC: 2014–2026 (mensal)
#> 
```
