# Get POF survey information

Returns metadata about the POF survey edition including available health
modules and sampling design information.

## Usage

``` r
pof_info(year = "2017-2018")
```

## Arguments

- year:

  Character. POF edition (e.g., "2017-2018"). Default is "2017-2018".

## Value

A list with survey metadata (invisibly).

## See also

[`pof_years`](https://sidneybissoli.github.io/healthbR/reference/pof_years.md),
[`pof_data`](https://sidneybissoli.github.io/healthbR/reference/pof_data.md)

Other pof:
[`pof_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/pof_cache_status.md),
[`pof_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/pof_clear_cache.md),
[`pof_data()`](https://sidneybissoli.github.io/healthbR/reference/pof_data.md),
[`pof_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/pof_dictionary.md),
[`pof_registers()`](https://sidneybissoli.github.io/healthbR/reference/pof_registers.md),
[`pof_variables()`](https://sidneybissoli.github.io/healthbR/reference/pof_variables.md),
[`pof_years()`](https://sidneybissoli.github.io/healthbR/reference/pof_years.md)

## Examples

``` r
pof_info()
#> 
#> ── POF 2017-2018 ───────────────────────────────────────────────────────────────
#> Pesquisa sobre orçamentos domésticos, condições de vida e perfil nutricional
#> 
#> Registros disponíveis: "domicilio", "morador", "caderneta_coletiva",
#> "despesa_individual", "consumo_alimentar", "rendimento", "inventario",
#> "despesa_coletiva", "aluguel_estimado", and "outros_rendimentos"
#> 
#> 
#> ── Módulos de saúde ──
#> 
#> ✓ ebia: Escala Brasileira de Insegurança Alimentar
#> ✗ antropometria: Peso, altura e estado nutricional
#> ✓ consumo_alimentar: Consumo alimentar pessoal detalhado (subamostra)
#> ✓ despesas_saude: Gastos com medicamentos, planos de saúde, consultas
#> 
#> 
#> ── Detalhes da edição ──
#> 
#> ℹ Sample size: approximately 58,000 households
#> ℹ Reference period: July 2017 - July 2018
#> ℹ Notes: Latest edition with EBIA and detailed food consumption
#> 
#> URL:
#> <https://www.ibge.gov.br/estatisticas/sociais/saude/24786-pesquisa-de-orcamentos-familiares-2.html>
#> FTP: <https://ftp.ibge.gov.br/Orcamentos_Familiares/>
pof_info("2017-2018")
#> 
#> ── POF 2017-2018 ───────────────────────────────────────────────────────────────
#> Pesquisa sobre orçamentos domésticos, condições de vida e perfil nutricional
#> 
#> Registros disponíveis: "domicilio", "morador", "caderneta_coletiva",
#> "despesa_individual", "consumo_alimentar", "rendimento", "inventario",
#> "despesa_coletiva", "aluguel_estimado", and "outros_rendimentos"
#> 
#> 
#> ── Módulos de saúde ──
#> 
#> ✓ ebia: Escala Brasileira de Insegurança Alimentar
#> ✗ antropometria: Peso, altura e estado nutricional
#> ✓ consumo_alimentar: Consumo alimentar pessoal detalhado (subamostra)
#> ✓ despesas_saude: Gastos com medicamentos, planos de saúde, consultas
#> 
#> 
#> ── Detalhes da edição ──
#> 
#> ℹ Sample size: approximately 58,000 households
#> ℹ Reference period: July 2017 - July 2018
#> ℹ Notes: Latest edition with EBIA and detailed food consumption
#> 
#> URL:
#> <https://www.ibge.gov.br/estatisticas/sociais/saude/24786-pesquisa-de-orcamentos-familiares-2.html>
#> FTP: <https://ftp.ibge.gov.br/Orcamentos_Familiares/>
pof_info("2008-2009")
#> 
#> ── POF 2008-2009 ───────────────────────────────────────────────────────────────
#> Pesquisa sobre orçamentos domésticos, condições de vida e perfil nutricional
#> 
#> Registros disponíveis: "domicilio", "morador", "caderneta_coletiva",
#> "despesa_individual", "consumo_alimentar", "rendimento", "inventario",
#> "despesa_coletiva", "despesa_90dias", and "despesa_12meses"
#> 
#> 
#> ── Módulos de saúde ──
#> 
#> ✗ ebia: Escala Brasileira de Insegurança Alimentar
#> ✓ antropometria: Peso, altura e estado nutricional
#> ✓ consumo_alimentar: Consumo alimentar pessoal detalhado (subamostra)
#> ✓ despesas_saude: Gastos com medicamentos, planos de saúde, consultas
#> 
#> 
#> ── Detalhes da edição ──
#> 
#> ℹ Sample size: approximately 56,000 households
#> ℹ Reference period: May 2008 - May 2009
#> ℹ Notes: Includes anthropometry module
#> 
#> URL:
#> <https://www.ibge.gov.br/estatisticas/sociais/saude/24786-pesquisa-de-orcamentos-familiares-2.html>
#> FTP: <https://ftp.ibge.gov.br/Orcamentos_Familiares/>
```
