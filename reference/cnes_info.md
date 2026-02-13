# CNES Module Information

Displays information about the National Health Facility Registry (CNES),
including data sources, available years, file types, and usage guidance.

## Usage

``` r
cnes_info()
```

## Value

A list with module information (invisibly).

## See also

Other cnes:
[`cnes_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/cnes_cache_status.md),
[`cnes_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/cnes_clear_cache.md),
[`cnes_data()`](https://sidneybissoli.github.io/healthbR/reference/cnes_data.md),
[`cnes_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/cnes_dictionary.md),
[`cnes_variables()`](https://sidneybissoli.github.io/healthbR/reference/cnes_variables.md),
[`cnes_years()`](https://sidneybissoli.github.io/healthbR/reference/cnes_years.md)

## Examples

``` r
cnes_info()
#> 
#> ── CNES — Cadastro Nacional de Estabelecimentos de Saúde ───────────────────────
#> 
#> Fonte: Ministério da Saúde / DATASUS
#> Acesso: FTP DATASUS
#> Documento base: Cadastro Nacional de Estabelecimentos de Saúde
#> Granularidade: Mensal (um arquivo por tipo/UF/mês)
#> 
#> ── Dados disponíveis ──
#> 
#> • `cnes_data()`: Dados cadastrais de estabelecimentos de saúde
#>   Anos definitivos: 2005–2023
#>   Anos preliminares: 2024
#> • `cnes_variables()`: Lista de variáveis disponíveis
#> • `cnes_dictionary()`: Dicionário completo com categorias
#> 
#> ── Tipos de arquivo ──
#> 
#> ST Estabelecimentos — Cadastro de estabelecimentos de saúde
#> LT Leitos — Leitos hospitalares
#> PF Profissional — Profissionais de saúde
#> DC Dados Complementares — Dados complementares do estabelecimento
#> EQ Equipamentos — Equipamentos de saúde
#> SR Serviço Especializado — Serviços especializados
#> HB Habilitação — Habilitações
#> EP Equipes — Equipes de saúde
#> RC Regra Contratual — Regras contratuais
#> IN Incentivos — Incentivos financeiros
#> EE Estab. de Ensino — Estabelecimentos de ensino em saúde
#> EF Estab. Filantrópico — Estabelecimentos filantrópicos
#> GM Gestão e Metas — Gestão e metas
#> 
#> ── Variáveis-chave (ST) ──
#> 
#> CNES Código CNES do estabelecimento
#> CODUFMUN Município (UF + IBGE 6 dígitos)
#> TP_UNID Tipo de unidade
#> VINC_SUS Vínculo SUS (0=Não, 1=Sim)
#> TP_GESTAO Tipo de gestão (M/E/D/S)
#> 
#> ℹ Dados mensais: use `month` em `cnes_data()` para selecionar meses.
#> ℹ Use `type` em `cnes_data()` para selecionar o tipo (padrão: ST).
```
