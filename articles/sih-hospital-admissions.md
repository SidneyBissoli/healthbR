# Hospital Admissions from SIH with healthbR

## Overview

The **SIH (Sistema de Informacoes Hospitalares)** records all hospital
admissions financed by the Brazilian public health system (SUS) through
the *Autorizacao de Internacao Hospitalar* (AIH). It is managed by the
Ministry of Health through DATASUS.

| Feature | Details |
|----|----|
| Coverage | Per state (UF), all 27 states |
| Years | 1992–2024 (1992–2007 only on the R2 mirror; `RACA_COR` only from 2008) |
| Granularity | Monthly (one file per UF/month) |
| Unit | One row per hospital admission (AIH) |
| Format | Parquet on the healthbr-data R2 mirror (default), .dbc files from DATASUS FTP (fallback) |

## Getting started

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`healthbR`](https://github.com/SidneyBissoli/healthbR)`)`\
[`library`](https://rdrr.io/r/base/library.html)`(`[`dplyr`](https://dplyr.tidyverse.org)`)`

### Check available years

\
[`sih_years`](https://sidneybissoli.github.io/healthbR/reference/sih_years.md)`(``)`\
[`sih_years`](https://sidneybissoli.github.io/healthbR/reference/sih_years.md)`(``status ``=`` ``"all"``)`

### Module information

\
[`sih_info`](https://sidneybissoli.github.io/healthbR/reference/sih_info.md)`(``)`

## Downloading data

### Basic download

\
`# All months of 2022 for Acre`\
`admissions`` ``<-`` `[`sih_data`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"AC"``)`

### Specific months

\
`# First semester only`\
`admissions`` ``<-`` `[`sih_data`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, month ``=`` ``1``:``6``)`\
\
`# Single month`\
`admissions`` ``<-`` `[`sih_data`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, month ``=`` ``3``)`

### Filter by diagnosis

Use CID-10 code prefixes to filter the principal diagnosis:

\
`# Acute myocardial infarction (I21)`\
`mi`` ``<-`` `[`sih_data`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, diagnosis ``=`` ``"I21"``)`\
\
`# All respiratory diseases (Chapter X)`\
`respiratory`` ``<-`` `[`sih_data`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, diagnosis ``=`` ``"J"``)`\
\
`# Dengue (A90-A91)`\
`dengue_hosp`` ``<-`` `[`sih_data`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, diagnosis ``=`` ``"A9"``)`

### Select variables

\
`admissions`` ``<-`` `[`sih_data`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md)`(`\
`  year ``=`` ``2022``,`\
`  uf ``=`` ``"SP"``,`\
`  month ``=`` ``1``,`\
`  vars ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"DIAG_PRINC"``, ``"DT_INTER"``, ``"DT_SAIDA"``, ``"SEXO"``,`\
`           ``"MORTE"``, ``"MUNIC_RES"``, ``"VAL_TOT"``)`\
`)`

## Key variables

| Variable   | Description                           |
|------------|---------------------------------------|
| DIAG_PRINC | Principal diagnosis (CID-10)          |
| DT_INTER   | Admission date                        |
| DT_SAIDA   | Discharge date                        |
| SEXO       | Sex (0=Unknown, 1=Male, 3=Female)     |
| NASC       | Date of birth                         |
| MORTE      | Hospital death (0=No, 1=Yes)          |
| MUNIC_RES  | Municipality of residence (IBGE code) |
| MUNIC_MOV  | Municipality of hospitalization       |
| VAL_TOT    | Total AIH value (R\$)                 |
| DIAS_PERM  | Length of stay (days)                 |
| PROC_REA   | Procedure performed (SIGTAP code)     |
| UTI_MES_TO | ICU days                              |

Note: Sex codes in SIH differ from SIM/SINASC (0=Unknown, 1=Male,
**3**=Female).

### Data dictionary

\
[`sih_dictionary`](https://sidneybissoli.github.io/healthbR/reference/sih_dictionary.md)`(``)`\
[`sih_dictionary`](https://sidneybissoli.github.io/healthbR/reference/sih_dictionary.md)`(``"SEXO"``)`\
[`sih_dictionary`](https://sidneybissoli.github.io/healthbR/reference/sih_dictionary.md)`(``"MORTE"``)`

### Explore variables

\
[`sih_variables`](https://sidneybissoli.github.io/healthbR/reference/sih_variables.md)`(``)`\
[`sih_variables`](https://sidneybissoli.github.io/healthbR/reference/sih_variables.md)`(``search ``=`` ``"diag"``)`\
[`sih_variables`](https://sidneybissoli.github.io/healthbR/reference/sih_variables.md)`(``search ``=`` ``"valor"``)`

## Example: Hospital mortality by diagnosis chapter

\
`admissions`` ``<-`` `[`sih_data`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, month ``=`` ``1``:``6``)`\
\
`mortality`` ``<-`` ``admissions`` ``|>`\
`  `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(``chapter ``=`` `[`substr`](https://rdrr.io/r/base/substr.html)`(``DIAG_PRINC``, ``1``, ``1``)``)`` ``|>`\
`  `[`group_by`](https://dplyr.tidyverse.org/reference/group_by.html)`(``chapter``)`` ``|>`\
`  `[`summarise`](https://dplyr.tidyverse.org/reference/summarise.html)`(`\
`    total ``=`` `[`n`](https://dplyr.tidyverse.org/reference/context.html)`(``)``,`\
`    deaths ``=`` `[`sum`](https://rdrr.io/r/base/sum.html)`(``MORTE`` ``==`` ``"1"``, na.rm ``=`` ``TRUE``)``,`\
`    mortality_rate ``=`` ``deaths`` ``/`` ``total`` ``*`` ``100`\
`  ``)`` ``|>`\
`  `[`arrange`](https://dplyr.tidyverse.org/reference/arrange.html)`(`[`desc`](https://dplyr.tidyverse.org/reference/desc.html)`(``mortality_rate``)``)`

## Example: Hospitalization costs

\
`admissions`` ``<-`` `[`sih_data`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, month ``=`` ``1``)`\
\
`costs`` ``<-`` ``admissions`` ``|>`\
`  `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(`\
`    chapter ``=`` `[`substr`](https://rdrr.io/r/base/substr.html)`(``DIAG_PRINC``, ``1``, ``1``)``,`\
`    cost ``=`` `[`as.numeric`](https://rdrr.io/r/base/numeric.html)`(``VAL_TOT``)`\
`  ``)`` ``|>`\
`  `[`group_by`](https://dplyr.tidyverse.org/reference/group_by.html)`(``chapter``)`` ``|>`\
`  `[`summarise`](https://dplyr.tidyverse.org/reference/summarise.html)`(`\
`    admissions ``=`` `[`n`](https://dplyr.tidyverse.org/reference/context.html)`(``)``,`\
`    total_cost ``=`` `[`sum`](https://rdrr.io/r/base/sum.html)`(``cost``, na.rm ``=`` ``TRUE``)``,`\
`    mean_cost ``=`` `[`mean`](https://rdrr.io/r/base/mean.html)`(``cost``, na.rm ``=`` ``TRUE``)`\
`  ``)`` ``|>`\
`  `[`arrange`](https://dplyr.tidyverse.org/reference/arrange.html)`(`[`desc`](https://dplyr.tidyverse.org/reference/desc.html)`(``total_cost``)``)`

## Example: Seasonal patterns

\
`# respiratory admissions across all months`\
`resp`` ``<-`` `[`sih_data`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, diagnosis ``=`` ``"J"``)`\
\
`seasonal`` ``<-`` ``resp`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``month``, name ``=`` ``"admissions"``)`` ``|>`\
`  `[`arrange`](https://dplyr.tidyverse.org/reference/arrange.html)`(``month``)`

## Smart type parsing

\
`# parsed types (default)`\
`admissions`` ``<-`` `[`sih_data`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"AC"``, month ``=`` ``1``)`\
[`class`](https://rdrr.io/r/base/class.html)`(``admissions``$``DT_INTER``)``  ``# Date`\
[`class`](https://rdrr.io/r/base/class.html)`(``admissions``$``VAL_TOT``)``   ``# double`\
\
`# all character`\
`admissions_raw`` ``<-`` `[`sih_data`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"AC"``, month ``=`` ``1``, parse ``=`` ``FALSE``)`

## Cache and lazy evaluation

\
[`sih_cache_status`](https://sidneybissoli.github.io/healthbR/reference/sih_cache_status.md)`(``)`\
[`sih_clear_cache`](https://sidneybissoli.github.io/healthbR/reference/sih_clear_cache.md)`(``)`\
\
`# lazy query`\
`lazy`` ``<-`` `[`sih_data`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, lazy ``=`` ``TRUE``)`\
`lazy`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``MORTE`` ``==`` ``"1"``)`` ``|>`\
`  `[`select`](https://dplyr.tidyverse.org/reference/select.html)`(``DIAG_PRINC``, ``DT_INTER``, ``SEXO``, ``MUNIC_RES``)`` ``|>`\
`  `[`collect`](https://dplyr.tidyverse.org/reference/compute.html)`(``)`

## Further reading

- SIH on DATASUS (`datasus.saude.gov.br`)
- SIGTAP procedure table (`wiki.saude.gov.br/sigtap`)
- [SIA
  vignette](https://sidneybissoli.github.io/healthbR/articles/sia-outpatient.md)
  for outpatient data
