# Notifiable Disease Surveillance with SINAN

## Overview

The **SINAN (Sistema de Informacao de Agravos de Notificacao)** is
Brazil’s national notifiable disease surveillance system, managed by the
Ministry of Health through DATASUS. It records individual notification
forms for compulsory-notification diseases.

The `healthbR` package provides access to SINAN microdata from the
DATASUS FTP:

| Feature  | Details                                  |
|----------|------------------------------------------|
| Coverage | National (one file per disease per year) |
| Diseases | 31 notifiable disease codes              |
| Years    | 2007–2024 (final + preliminary)          |
| Unit     | One row per notification record          |
| Format   | .dbc files, decompressed internally      |

## Getting started

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`healthbR`](https://github.com/SidneyBissoli/healthbR)`)`\
[`library`](https://rdrr.io/r/base/library.html)`(`[`dplyr`](https://dplyr.tidyverse.org)`)`

### Check available years

\
[`sinan_years`](https://sidneybissoli.github.io/healthbR/reference/sinan_years.md)`(``)`\
`#> [1] 2007 2008 2009 ... 2022`\
\
[`sinan_years`](https://sidneybissoli.github.io/healthbR/reference/sinan_years.md)`(``status ``=`` ``"all"``)`\
`#> [1] 2007 2008 ... 2022 2023 2024`

### Module information

\
[`sinan_info`](https://sidneybissoli.github.io/healthbR/reference/sinan_info.md)`(``)`

## Exploring diseases

SINAN covers 31 notifiable diseases. Use
[`sinan_diseases()`](https://sidneybissoli.github.io/healthbR/reference/sinan_diseases.md)
to browse them:

\
`# all available diseases`\
[`sinan_diseases`](https://sidneybissoli.github.io/healthbR/reference/sinan_diseases.md)`(``)`\
\
`# search by name or code`\
[`sinan_diseases`](https://sidneybissoli.github.io/healthbR/reference/sinan_diseases.md)`(``search ``=`` ``"dengue"``)`\
[`sinan_diseases`](https://sidneybissoli.github.io/healthbR/reference/sinan_diseases.md)`(``search ``=`` ``"sifilis"``)`\
[`sinan_diseases`](https://sidneybissoli.github.io/healthbR/reference/sinan_diseases.md)`(``search ``=`` ``"tuberculose"``)`

Common disease codes:

| Code | Disease           |
|------|-------------------|
| DENG | Dengue            |
| CHIK | Chikungunya       |
| ZIKA | Zika              |
| TUBE | Tuberculose       |
| HANS | Hanseniase        |
| HEPA | Hepatites virais  |
| SIFA | Sifilis adquirida |
| SIFC | Sifilis congenita |
| LEPT | Leptospirose      |
| MENI | Meningite         |

## Downloading data

### Basic download (dengue, single year)

\
`dengue_2022`` ``<-`` `[`sinan_data`](https://sidneybissoli.github.io/healthbR/reference/sinan_data.md)`(``year ``=`` ``2022``)`\
`dengue_2022`

### Multiple years

\
`tb`` ``<-`` `[`sinan_data`](https://sidneybissoli.github.io/healthbR/reference/sinan_data.md)`(``year ``=`` ``2020``:``2022``, disease ``=`` ``"TUBE"``)`\
`tb`

### Selecting variables

\
`# only key variables (faster and less memory)`\
`dengue_key`` ``<-`` `[`sinan_data`](https://sidneybissoli.github.io/healthbR/reference/sinan_data.md)`(`\
`  year ``=`` ``2022``,`\
`  disease ``=`` ``"DENG"``,`\
`  vars ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"DT_NOTIFIC"``, ``"CS_SEXO"``, ``"NU_IDADE_N"``,`\
`           ``"CS_RACA"``, ``"ID_MUNICIP"``, ``"CLASSI_FIN"``)`\
`)`

### Exploring variables

\
[`sinan_variables`](https://sidneybissoli.github.io/healthbR/reference/sinan_variables.md)`(``)`\
[`sinan_variables`](https://sidneybissoli.github.io/healthbR/reference/sinan_variables.md)`(``search ``=`` ``"sexo"``)`\
[`sinan_variables`](https://sidneybissoli.github.io/healthbR/reference/sinan_variables.md)`(``search ``=`` ``"municipio"``)`

## Filtering by state

SINAN files are **national** (not per-state). To filter by geographic
unit, use the `SG_UF_NOT` (UF of notification) or `ID_MUNICIP`
(municipality code) columns after download:

\
`# filter by UF`\
`dengue_sp`` ``<-`` `[`sinan_data`](https://sidneybissoli.github.io/healthbR/reference/sinan_data.md)`(``year ``=`` ``2022``)`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``SG_UF_NOT`` ``==`` ``"35"``)``  ``# 35 = Sao Paulo`\
\
`# filter by municipality`\
`dengue_rj_capital`` ``<-`` `[`sinan_data`](https://sidneybissoli.github.io/healthbR/reference/sinan_data.md)`(``year ``=`` ``2022``)`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``ID_MUNICIP`` ``==`` ``"330455"``)``  ``# Rio de Janeiro capital`

## Key variables

| Variable   | Description                                                    |
|------------|----------------------------------------------------------------|
| DT_NOTIFIC | Notification date                                              |
| ID_AGRAVO  | Disease code (CID-10)                                          |
| SG_UF_NOT  | UF of notification (IBGE code)                                 |
| ID_MUNICIP | Municipality of notification (IBGE 6 digits)                   |
| CS_SEXO    | Sex (M/F/I)                                                    |
| NU_IDADE_N | Age (encoded: 1st digit = unit, digits 2-3 = value)            |
| CS_RACA    | Race/color (1=White, 2=Black, 3=Yellow, 4=Brown, 5=Indigenous) |
| CLASSI_FIN | Final classification (1=Confirmed, 2=Discarded)                |
| EVOLUCAO   | Outcome (1=Cured, 2=Death by disease, 3=Death other causes)    |
| CRITERIO   | Confirmation criteria (1=Lab, 2=Clinical-epi)                  |

### Using the dictionary

\
`# all coded variables`\
[`sinan_dictionary`](https://sidneybissoli.github.io/healthbR/reference/sinan_dictionary.md)`(``)`\
\
`# specific variable`\
[`sinan_dictionary`](https://sidneybissoli.github.io/healthbR/reference/sinan_dictionary.md)`(``"CS_SEXO"``)`\
[`sinan_dictionary`](https://sidneybissoli.github.io/healthbR/reference/sinan_dictionary.md)`(``"EVOLUCAO"``)`\
[`sinan_dictionary`](https://sidneybissoli.github.io/healthbR/reference/sinan_dictionary.md)`(``"CLASSI_FIN"``)`

## Preliminary vs. final data

SINAN publishes both final (definitive) and preliminary data. By
default,
[`sinan_years()`](https://sidneybissoli.github.io/healthbR/reference/sinan_years.md)
returns only final years:

\
`# final data only (default)`\
[`sinan_years`](https://sidneybissoli.github.io/healthbR/reference/sinan_years.md)`(``status ``=`` ``"final"``)`\
\
`# preliminary data`\
[`sinan_years`](https://sidneybissoli.github.io/healthbR/reference/sinan_years.md)`(``status ``=`` ``"preliminary"``)`\
\
`# both`\
[`sinan_years`](https://sidneybissoli.github.io/healthbR/reference/sinan_years.md)`(``status ``=`` ``"all"``)`

Preliminary data (2023–2024) may still be revised by the Ministry of
Health.

## Example: confirmed dengue cases by month

\
`dengue`` ``<-`` `[`sinan_data`](https://sidneybissoli.github.io/healthbR/reference/sinan_data.md)`(``year ``=`` ``2022``, disease ``=`` ``"DENG"``)`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``CLASSI_FIN`` `[`%in%`](https://rdrr.io/r/base/match.html)` `[`c`](https://rdrr.io/r/base/c.html)`(``"1"``, ``"5"``)``)`` ``|>``  ``# confirmed cases`\
\
`  `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(``month ``=`` `[`as.integer`](https://rdrr.io/r/base/integer.html)`(`[`format`](https://rdrr.io/r/base/format.html)`(``DT_NOTIFIC``, ``"%m"``)``)``)`\
\
`cases_by_month`` ``<-`` ``dengue`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``month``)`` ``|>`\
`  `[`arrange`](https://dplyr.tidyverse.org/reference/arrange.html)`(``month``)`\
\
`cases_by_month`

## Example: tuberculosis by sex and age group

\
`tb`` ``<-`` `[`sinan_data`](https://sidneybissoli.github.io/healthbR/reference/sinan_data.md)`(``year ``=`` ``2022``, disease ``=`` ``"TUBE"``)`\
\
`# decode age: 4th digit means years`\
`tb_age`` ``<-`` ``tb`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``CLASSI_FIN`` ``==`` ``"1"``)`` ``|>`\
`  `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(`\
`    age_unit ``=`` `[`substr`](https://rdrr.io/r/base/substr.html)`(``NU_IDADE_N``, ``1``, ``1``)``,`\
`    age_value ``=`` `[`as.integer`](https://rdrr.io/r/base/integer.html)`(`[`substr`](https://rdrr.io/r/base/substr.html)`(``NU_IDADE_N``, ``2``, ``3``)``)``,`\
`    age_years ``=`` `[`ifelse`](https://rdrr.io/r/base/ifelse.html)`(``age_unit`` ``==`` ``"4"``, ``age_value``, ``NA_integer_``)``,`\
`    age_group ``=`` `[`cut`](https://rdrr.io/r/base/cut.html)`(``age_years``,`\
`                    breaks ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``0``, ``15``, ``30``, ``45``, ``60``, ``Inf``)``,`\
`                    labels ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"<15"``, ``"15-29"``, ``"30-44"``, ``"45-59"``, ``"60+"``)``,`\
`                    right ``=`` ``FALSE``)`\
`  ``)`\
\
`tb_age`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``!`[`is.na`](https://rdrr.io/r/base/NA.html)`(``age_group``)``)`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``CS_SEXO``, ``age_group``)`` ``|>`\
`  ``tidyr``::`[`pivot_wider`](https://tidyr.tidyverse.org/reference/pivot_wider.html)`(``names_from ``=`` ``CS_SEXO``, values_from ``=`` ``n``)`

## Example: incidence rate with Census denominators

Combine SINAN data with Census population to calculate incidence rates:

\
`# step 1: confirmed dengue by UF`\
`dengue_uf`` ``<-`` `[`sinan_data`](https://sidneybissoli.github.io/healthbR/reference/sinan_data.md)`(``year ``=`` ``2022``, disease ``=`` ``"DENG"``)`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``CLASSI_FIN`` `[`%in%`](https://rdrr.io/r/base/match.html)` `[`c`](https://rdrr.io/r/base/c.html)`(``"1"``, ``"5"``)``)`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``SG_UF_NOT``, name ``=`` ``"cases"``)`\
\
`# step 2: population from Census 2022`\
`pop`` ``<-`` `[`censo_populacao`](https://sidneybissoli.github.io/healthbR/reference/censo_populacao.md)`(``year ``=`` ``2022``, territorial_level ``=`` ``"state"``)`\
\
`# step 3: calculate incidence rate per 100,000`\
`# incidence <- dengue_uf |>`\
`#   left_join(pop, by = ...) |>`\
`#   mutate(rate_100k = (cases / population) * 100000) |>`\
`#   arrange(desc(rate_100k))`

## Smart type parsing

By default,
[`sinan_data()`](https://sidneybissoli.github.io/healthbR/reference/sinan_data.md)
parses columns to appropriate types (dates, integers):

\
`# parsed types (default)`\
`dengue`` ``<-`` `[`sinan_data`](https://sidneybissoli.github.io/healthbR/reference/sinan_data.md)`(``year ``=`` ``2022``, disease ``=`` ``"DENG"``)`\
[`class`](https://rdrr.io/r/base/class.html)`(``dengue``$``DT_NOTIFIC``)``  ``# Date`\
[`class`](https://rdrr.io/r/base/class.html)`(``dengue``$``NU_ANO``)``      ``# integer`\
\
`# raw character columns (backward-compatible)`\
`dengue_raw`` ``<-`` `[`sinan_data`](https://sidneybissoli.github.io/healthbR/reference/sinan_data.md)`(``year ``=`` ``2022``, disease ``=`` ``"DENG"``, parse ``=`` ``FALSE``)`\
\
`# override specific columns`\
`dengue_custom`` ``<-`` `[`sinan_data`](https://sidneybissoli.github.io/healthbR/reference/sinan_data.md)`(`\
`  year ``=`` ``2022``,`\
`  col_types ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(``DT_NOTIFIC ``=`` ``"character"``)`\
`)`

## Cache management

Downloaded data is cached locally for faster future access:

\
`# check cache status`\
[`sinan_cache_status`](https://sidneybissoli.github.io/healthbR/reference/sinan_cache_status.md)`(``)`\
\
`# clear cache if needed`\
[`sinan_clear_cache`](https://sidneybissoli.github.io/healthbR/reference/sinan_clear_cache.md)`(``)`

If the `arrow` package is installed, data is cached in Parquet format
for faster loading. You can also use lazy evaluation:

\
`# lazy query (requires arrow)`\
`dengue_lazy`` ``<-`` `[`sinan_data`](https://sidneybissoli.github.io/healthbR/reference/sinan_data.md)`(``year ``=`` ``2022``, disease ``=`` ``"DENG"``, lazy ``=`` ``TRUE``)`\
`dengue_lazy`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``CLASSI_FIN`` ``==`` ``"1"``)`` ``|>`\
`  `[`select`](https://dplyr.tidyverse.org/reference/select.html)`(``DT_NOTIFIC``, ``CS_SEXO``, ``NU_IDADE_N``, ``ID_MUNICIP``)`` ``|>`\
`  `[`collect`](https://dplyr.tidyverse.org/reference/compute.html)`(``)`

## Additional resources

- SINAN official page (`portalsinan.saude.gov.br`)
- [SIM
  vignette](https://sidneybissoli.github.io/healthbR/articles/datasus-modules.md)
  for mortality data
- [Census
  vignette](https://sidneybissoli.github.io/healthbR/articles/censo-denominadores.md)
  for population denominators
