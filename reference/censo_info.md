# Census information

Displays information about the Brazilian Census and returns metadata.

## Usage

``` r
censo_info(year = NULL)
```

## Arguments

- year:

  Numeric. Year to get specific information about. NULL shows general
  info.

## Value

Invisibly returns a list with Census metadata.

## Examples

``` r
censo_info()
#> 
#> ── Censo Demográfico ───────────────────────────────────────────────────────────
#> 
#> O Censo Demográfico é a principal pesquisa do IBGE, realizada a cada 10 anos,
#> que recenseou a população brasileira. Fornece denominadores populacionais
#> essenciais para o cálculo de taxas de mortalidade, incidência e outros
#> indicadores epidemiológicos.
#> 
#> ℹ Institution: IBGE - Instituto Brasileiro de Geografia e Estatística
#> ℹ Available years: 1970, 1980, 1991, 2000, 2010, 2022
#> 
#> 
#> ── Data access ──
#> 
#> → Population by sex/age/race: `censo_populacao()`
#> → Intercensitary estimates: `censo_estimativa()`
#> → Any SIDRA table: `censo_sidra_data()`
#> 
#> URL:
#> <https://www.ibge.gov.br/estatisticas/sociais/populacao/22827-censo-demografico-2022.html>
#> SIDRA: <https://sidra.ibge.gov.br/pesquisa/censo-demografico>
censo_info(2022)
#> 
#> ── Censo Demográfico ───────────────────────────────────────────────────────────
#> 
#> O Censo Demográfico é a principal pesquisa do IBGE, realizada a cada 10 anos,
#> que recenseou a população brasileira. Fornece denominadores populacionais
#> essenciais para o cálculo de taxas de mortalidade, incidência e outros
#> indicadores epidemiológicos.
#> 
#> ℹ Institution: IBGE - Instituto Brasileiro de Geografia e Estatística
#> ℹ Available years: 1970, 1980, 1991, 2000, 2010, 2022
#> 
#> 
#> ── Data access ──
#> 
#> → Population by sex/age/race: `censo_populacao()`
#> → Intercensitary estimates: `censo_estimativa()`
#> → Any SIDRA table: `censo_sidra_data()`
#> 
#> URL:
#> <https://www.ibge.gov.br/estatisticas/sociais/populacao/22827-censo-demografico-2022.html>
#> SIDRA: <https://sidra.ibge.gov.br/pesquisa/censo-demografico>
#> 
#> 
#> ── Censo 2022 ──
#> 
#> ℹ Population: 203,080,756
#> ℹ Notes: Primeiro com dados quilombolas, realizado após adiamento pela pandemia
```
