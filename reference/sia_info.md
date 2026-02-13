# SIA Module Information

Displays information about the Outpatient Information System (SIA),
including data sources, available years, file types, and usage guidance.

## Usage

``` r
sia_info()
```

## Value

A list with module information (invisibly).

## See also

Other sia:
[`sia_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sia_cache_status.md),
[`sia_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sia_clear_cache.md),
[`sia_data()`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md),
[`sia_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sia_dictionary.md),
[`sia_variables()`](https://sidneybissoli.github.io/healthbR/reference/sia_variables.md),
[`sia_years()`](https://sidneybissoli.github.io/healthbR/reference/sia_years.md)

## Examples

``` r
sia_info()
#> 
#> ── SIA — Sistema de Informações Ambulatoriais ──────────────────────────────────
#> 
#> Fonte: Ministério da Saúde / DATASUS
#> Acesso: FTP DATASUS
#> Documento base: Boletim de Produção Ambulatorial (BPA) / APAC
#> Granularidade: Mensal (um arquivo por tipo/UF/mês)
#> 
#> ── Dados disponíveis ──
#> 
#> • `sia_data()`: Microdados de produção ambulatorial
#>   Anos definitivos: 2008–2023
#>   Anos preliminares: 2024
#> • `sia_variables()`: Lista de variáveis disponíveis
#> • `sia_dictionary()`: Dicionário completo com categorias
#> 
#> ── Tipos de arquivo ──
#> 
#> PA Produção Ambulatorial — BPA consolidado
#> BI Boletim Individualizado — BPA individualizado
#> AD APAC Laudos Diversos — Autorização de alta complexidade
#> AM APAC Medicamentos — Medicamentos de alto custo
#> AN APAC Nefrologia — Procedimentos nefrológicos
#> AQ APAC Quimioterapia — Quimioterapia oncológica
#> AR APAC Radioterapia — Radioterapia oncológica
#> AB APAC Cirurgia Bariátrica — Cirurgia bariátrica
#> ACF APAC Confecção de Fístula — Confecção de fístula arteriovenosa
#> ATD APAC Tratamento Dialítico — Diálise
#> AMP APAC Acompanhamento Multiprofissional — Acompanhamento multiprofissional
#> SAD RAAS Atenção Domiciliar — Serviços de atenção domiciliar
#> PS RAAS Psicossocial — CAPS e serviços psicossociais
#> 
#> ── Variáveis-chave (PA) ──
#> 
#> PA_PROC_ID Procedimento (código SIGTAP)
#> PA_CIDPRI Diagnóstico principal (CID-10)
#> PA_SEXO Sexo (1=Masc, 2=Fem)
#> PA_IDADE Idade do paciente
#> PA_VALAPR Valor aprovado (R$)
#> 
#> ℹ Dados mensais: use `month` em `sia_data()` para selecionar meses.
#> ℹ Use `type` em `sia_data()` para selecionar o tipo (padrão: PA).
```
