# Health Data from PNAD Continua with healthbR

## Overview

The **PNAD Continua (Pesquisa Nacional por Amostra de Domicilios
Continua)** is IBGE’s continuous household sample survey. While its core
questionnaire focuses on labor and income, it includes **supplementary
health-related modules** that are applied in specific quarters.

The `healthbR` package provides access to 4 health-related supplementary
modules:

| Module        | Description                                 | Years            |
|---------------|---------------------------------------------|------------------|
| `deficiencia` | Persons with disabilities                   | 2019, 2022, 2024 |
| `habitacao`   | Housing characteristics (sanitation, water) | 2012–2024        |
| `moradores`   | General resident characteristics            | 2012–2024        |
| `aps`         | Primary health care access                  | 2022 (Q2)        |

## Getting started

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`healthbR`](https://github.com/SidneyBissoli/healthbR)`)`\
[`library`](https://rdrr.io/r/base/library.html)`(`[`dplyr`](https://dplyr.tidyverse.org)`)`

### Module information

\
[`pnadc_info`](https://sidneybissoli.github.io/healthbR/reference/pnadc_info.md)`(``)`

### Available modules and years

\
[`pnadc_modules`](https://sidneybissoli.github.io/healthbR/reference/pnadc_modules.md)`(``)`\
`#> # A tibble: 4 x 4`\
`#>   module       name_pt                            name_en                years`\
`#>   <chr>        <chr>                              <chr>                  <list>`\
`#> 1 deficiencia  Pessoas com deficiencia             Persons with disab... <int>`\
`#> 2 habitacao    Caracteristicas dos domicilios      Housing character...  <int>`\
`#> 3 moradores    Caracteristicas gerais dos morad... General character...  <int>`\
`#> 4 aps          Atencao primaria a saude            Primary health care   <int>`\
\
`# Years for a specific module`\
[`pnadc_years`](https://sidneybissoli.github.io/healthbR/reference/pnadc_years.md)`(``"deficiencia"``)`\
`#> [1] 2019 2022 2024`

## Downloading data

### Basic download

\
`# Disability module, 2022`\
`df`` ``<-`` `[`pnadc_data`](https://sidneybissoli.github.io/healthbR/reference/pnadc_data.md)`(``module ``=`` ``"deficiencia"``, year ``=`` ``2022``)`

### Select variables

\
`df`` ``<-`` `[`pnadc_data`](https://sidneybissoli.github.io/healthbR/reference/pnadc_data.md)`(`\
`  module ``=`` ``"deficiencia"``,`\
`  year ``=`` ``2022``,`\
`  vars ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"UF"``, ``"V2007"``, ``"V2009"``, ``"V2010"``, ``"G001"``, ``"G003"``, ``"G006"``)`\
`)`

### Multiple years

\
`# Housing conditions across all available years`\
`df`` ``<-`` `[`pnadc_data`](https://sidneybissoli.github.io/healthbR/reference/pnadc_data.md)`(``module ``=`` ``"habitacao"``)`

## Exploring variables

\
`# List variable names`\
[`pnadc_variables`](https://sidneybissoli.github.io/healthbR/reference/pnadc_variables.md)`(``module ``=`` ``"deficiencia"``, year ``=`` ``2022``)`\
\
`# Full dictionary with positions and widths`\
[`pnadc_dictionaries`](https://sidneybissoli.github.io/healthbR/reference/pnadc_dictionaries.md)`(``module ``=`` ``"deficiencia"``, year ``=`` ``2022``)`

## Survey design

PNAD Continua uses a complex sample design. Survey design variables
(`UPA`, `Estrato`, `V1028`) are always included in the output. Use
`as_survey = TRUE` to create a survey design object:

\
`# Requires srvyr package`\
`svy`` ``<-`` `[`pnadc_data`](https://sidneybissoli.github.io/healthbR/reference/pnadc_data.md)`(`\
`  module ``=`` ``"deficiencia"``,`\
`  year ``=`` ``2022``,`\
`  as_survey ``=`` ``TRUE`\
`)`\
\
`# Use srvyr verbs for proper variance estimation`\
[`library`](https://rdrr.io/r/base/library.html)`(`[`srvyr`](http://gdfe.co/srvyr/)`)`\
`svy`` ``|>`\
`  `[`group_by`](https://dplyr.tidyverse.org/reference/group_by.html)`(``UF``)`` ``|>`\
`  `[`survey_mean`](http://gdfe.co/srvyr/reference/survey_mean.md)`(``G001`` ``==`` ``"1"``, na.rm ``=`` ``TRUE``)``  ``# disability prevalence by state`

## Example: Disability prevalence

\
`df`` ``<-`` `[`pnadc_data`](https://sidneybissoli.github.io/healthbR/reference/pnadc_data.md)`(``module ``=`` ``"deficiencia"``, year ``=`` ``2022``)`\
\
`# G001: "Tem dificuldade permanente de enxergar" (vision difficulty)`\
`# 1 = Sim, nao consegue de modo algum (cannot at all)`\
`# 2 = Sim, muita dificuldade (great difficulty)`\
`# 3 = Sim, alguma dificuldade (some difficulty)`\
`# 4 = Nao, nenhuma dificuldade (no difficulty)`\
`vision`` ``<-`` ``df`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``G001`` `[`%in%`](https://rdrr.io/r/base/match.html)` `[`c`](https://rdrr.io/r/base/c.html)`(``"1"``, ``"2"``, ``"3"``, ``"4"``)``)`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``G001``)`` ``|>`\
`  `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(``pct ``=`` ``n`` ``/`` `[`sum`](https://rdrr.io/r/base/sum.html)`(``n``)`` ``*`` ``100``)`

## Example: Housing sanitation over time

\
`df`` ``<-`` `[`pnadc_data`](https://sidneybissoli.github.io/healthbR/reference/pnadc_data.md)`(``module ``=`` ``"habitacao"``, year ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``2016``, ``2019``, ``2022``)``)`\
\
`# Analyze water supply and sanitation trends`\
`# Variables vary by year -- check pnadc_variables() for each edition`

## Example: Primary health care access

\
`# APS module only available for 2022 Q2`\
`df`` ``<-`` `[`pnadc_data`](https://sidneybissoli.github.io/healthbR/reference/pnadc_data.md)`(``module ``=`` ``"aps"``, year ``=`` ``2022``)`

## Cache and performance

\
`# Check cache`\
[`pnadc_cache_status`](https://sidneybissoli.github.io/healthbR/reference/pnadc_cache_status.md)`(``)`\
\
`# Clear cache`\
[`pnadc_clear_cache`](https://sidneybissoli.github.io/healthbR/reference/pnadc_clear_cache.md)`(``)`\
\
`# Lazy evaluation`\
`lazy_df`` ``<-`` `[`pnadc_data`](https://sidneybissoli.github.io/healthbR/reference/pnadc_data.md)`(`\
`  module ``=`` ``"deficiencia"``,`\
`  year ``=`` ``2022``,`\
`  lazy ``=`` ``TRUE``,`\
`  backend ``=`` ``"arrow"`\
`)`

## Further reading

- PNAD Continua on IBGE
  (`www.ibge.gov.br/estatisticas/sociais/trabalho/17270-pnad-continua`)
- PNAD Continua microdata documentation (`ftp.ibge.gov.br`)
