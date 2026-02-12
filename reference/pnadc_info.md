# PNADC survey information

Displays information about PNAD Continua and returns metadata.

## Usage

``` r
pnadc_info()
```

## Value

Invisibly returns a list with survey metadata.

## Examples

``` r
pnadc_info()
#> 
#> ── PNAD Contínua ───────────────────────────────────────────────────────────────
#> 
#> A PNAD Contínua é uma pesquisa domiciliar que investiga características gerais
#> da população, educação, trabalho e rendimento. Além dos temas permanentes, a
#> pesquisa inclui suplementos temáticos sobre saúde, deficiência, habitação e
#> outros temas.
#> 
#> ℹ Institution: IBGE - Instituto Brasileiro de Geografia e Estatística
#> 
#> 
#> ── Available Modules ──
#> 
#> → "deficiencia": Pessoas com Deficiência (2019-2024)
#> → "habitacao": Características da Habitação (2012-2024)
#> → "moradores": Características Gerais dos Moradores (2012-2024)
#> → "aps": Atenção Primária à Saúde (2022)
#> 
#> 
#> ── Data access ──
#> 
#> → Microdata: `pnadc_data()`
#> → Dictionary: `pnadc_dictionaries()`
#> → Variables: `pnadc_variables()`
#> 
#> URL:
#> <https://www.ibge.gov.br/estatisticas/sociais/trabalho/9171-pesquisa-nacional-por-amostra-de-domicilios-continua-mensal.html>
#> FTP:
#> <https://ftp.ibge.gov.br/Trabalho_e_Rendimento/Pesquisa_Nacional_por_Amostra_de_Domicilios_continua/>
```
