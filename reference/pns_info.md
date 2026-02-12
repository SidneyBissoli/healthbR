# PNS survey information

Displays information about the PNS survey and returns metadata.

## Usage

``` r
pns_info(year = NULL)
```

## Arguments

- year:

  Numeric. Year to get specific information about. NULL shows general
  info.

## Value

Invisibly returns a list with survey metadata.

## Examples

``` r
pns_info()
#> 
#> ── Pesquisa Nacional de Saúde (PNS) ────────────────────────────────────────────
#> 
#> A PNS é uma pesquisa domiciliar que investiga as condições de saúde da
#> população brasileira, incluindo estilo de vida, prevalência de doenças
#> crônicas, acesso a serviços de saúde, entre outros temas.
#> 
#> ℹ Institution: IBGE - Instituto Brasileiro de Geografia e Estatística
#> ℹ Partner: Ministério da Saúde
#> ℹ Available years: 2013, 2019
#> ℹ SIDRA tables: 2222
#> 
#> 
#> ── Data access ──
#> 
#> → Microdata (individual records): `pns_data()`
#> → Tabulated indicators (SIDRA API): `pns_sidra_data()`
#> 
#> URL:
#> <https://www.ibge.gov.br/estatisticas/sociais/saude/9160-pesquisa-nacional-de-saude.html>
#> FTP: <https://ftp.ibge.gov.br/PNS/>
#> SIDRA: <https://sidra.ibge.gov.br/pesquisa/pns>
pns_info(2019)
#> 
#> ── Pesquisa Nacional de Saúde (PNS) ────────────────────────────────────────────
#> 
#> A PNS é uma pesquisa domiciliar que investiga as condições de saúde da
#> população brasileira, incluindo estilo de vida, prevalência de doenças
#> crônicas, acesso a serviços de saúde, entre outros temas.
#> 
#> ℹ Institution: IBGE - Instituto Brasileiro de Geografia e Estatística
#> ℹ Partner: Ministério da Saúde
#> ℹ Available years: 2013, 2019
#> ℹ SIDRA tables: 2222
#> 
#> 
#> ── Data access ──
#> 
#> → Microdata (individual records): `pns_data()`
#> → Tabulated indicators (SIDRA API): `pns_sidra_data()`
#> 
#> URL:
#> <https://www.ibge.gov.br/estatisticas/sociais/saude/9160-pesquisa-nacional-de-saude.html>
#> FTP: <https://ftp.ibge.gov.br/PNS/>
#> SIDRA: <https://sidra.ibge.gov.br/pesquisa/pns>
#> 
#> 
#> ── PNS 2019 ──
#> 
#> ℹ Sample size: approximately 100,000 households
#> ℹ Reference period: August 2019 - December 2019
#> ℹ Modules: A, C, E, F, G, J, K, L, M, N, O, P, Q, R, S, U, W, X, Y, Z
#> ℹ Notes: Second edition with expanded sample
```
