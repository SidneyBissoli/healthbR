# Outpatient Production Data from SIA with healthbR

## Overview

The **SIA (Sistema de Informacoes Ambulatoriais)** records all
outpatient procedures performed in the Brazilian public health system
(SUS), including consultations, exams, and high-complexity procedures.
It is managed by the Ministry of Health through DATASUS.

| Feature     | Details                                 |
|-------------|-----------------------------------------|
| Coverage    | Per state (UF), all 27 states           |
| Years       | 2008–2024                               |
| Granularity | Monthly (one file per type/UF/month)    |
| Unit        | One row per outpatient procedure record |
| Format      | .dbc files from DATASUS FTP             |

## Getting started

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`healthbR`](https://github.com/SidneyBissoli/healthbR)`)`\
[`library`](https://rdrr.io/r/base/library.html)`(`[`dplyr`](https://dplyr.tidyverse.org)`)`

### Check available years

\
[`sia_years`](https://sidneybissoli.github.io/healthbR/reference/sia_years.md)`(``)`\
[`sia_years`](https://sidneybissoli.github.io/healthbR/reference/sia_years.md)`(``status ``=`` ``"all"``)`

### Module information

\
[`sia_info`](https://sidneybissoli.github.io/healthbR/reference/sia_info.md)`(``)`

## File types

SIA organizes data into 13 file types. The default is PA (outpatient
production):

| Type | Description                           |
|------|---------------------------------------|
| PA   | Outpatient production (BPA, default)  |
| BI   | Individualized BPA                    |
| AD   | APAC - Dialysis                       |
| AM   | APAC - Chemotherapy/Radiotherapy      |
| AN   | APAC - Nephrology                     |
| AQ   | APAC - Other procedures               |
| AR   | APAC - Orthopedic Surgery             |
| AB   | APAC - Bariatric Surgery              |
| ACF  | APAC - Cleft Lip/Palate               |
| ATD  | APAC - TFD (Treatment Away from Home) |
| AMP  | APAC - Specialized Medicines          |
| SAD  | RAAS - Home Care                      |
| PS   | RAAS - Psychosocial Care              |

## Downloading data

### Basic download (PA type)

\
`outpatient`` ``<-`` `[`sia_data`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"AC"``)`

### Specific type

\
`# chemotherapy/radiotherapy APAC records`\
`chemo`` ``<-`` `[`sia_data`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, type ``=`` ``"AM"``)`

### Specific months

\
`outpatient`` ``<-`` `[`sia_data`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, month ``=`` ``1``:``3``)`

### Filter by procedure

Use SIGTAP procedure code prefixes:

\
`# Medical consultations (group 03.01)`\
`consults`` ``<-`` `[`sia_data`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, month ``=`` ``1``, procedure ``=`` ``"0301"``)`\
\
`# Imaging exams (group 02.04)`\
`imaging`` ``<-`` `[`sia_data`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, month ``=`` ``1``, procedure ``=`` ``"0204"``)`

### Filter by diagnosis

\
`# Diabetes-related outpatient care (E10-E14)`\
`diabetes`` ``<-`` `[`sia_data`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, month ``=`` ``1``, diagnosis ``=`` ``"E1"``)`

### Select variables

\
`outpatient`` ``<-`` `[`sia_data`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md)`(`\
`  year ``=`` ``2022``,`\
`  uf ``=`` ``"SP"``,`\
`  month ``=`` ``1``,`\
`  vars ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"PA_PROC_ID"``, ``"PA_CIDPRI"``, ``"PA_SEXO"``, ``"PA_IDADE"``,`\
`           ``"PA_MUNPCN"``, ``"PA_VALAPR"``)`\
`)`

## Key variables (PA type)

| Variable   | Description                         |
|------------|-------------------------------------|
| PA_PROC_ID | Procedure code (SIGTAP)             |
| PA_CIDPRI  | Principal diagnosis (CID-10)        |
| PA_SEXO    | Sex (1=Male, 2=Female)              |
| PA_IDADE   | Patient age                         |
| PA_MUNPCN  | Municipality of patient’s residence |
| PA_VALAPR  | Approved value (R\$)                |
| PA_QTDAPR  | Approved quantity                   |
| PA_CODUNI  | Health facility (CNES code)         |
| PA_GESTAO  | Management level                    |
| PA_CONDIC  | Processing condition                |

### Data dictionary

\
[`sia_dictionary`](https://sidneybissoli.github.io/healthbR/reference/sia_dictionary.md)`(``)`\
[`sia_dictionary`](https://sidneybissoli.github.io/healthbR/reference/sia_dictionary.md)`(``"PA_SEXO"``)`

### Explore variables

\
[`sia_variables`](https://sidneybissoli.github.io/healthbR/reference/sia_variables.md)`(``)`\
[`sia_variables`](https://sidneybissoli.github.io/healthbR/reference/sia_variables.md)`(``search ``=`` ``"valor"``)`\
\
`# variables for a specific type`\
[`sia_variables`](https://sidneybissoli.github.io/healthbR/reference/sia_variables.md)`(``type ``=`` ``"AM"``)`

## Example: Top procedures by volume

\
`outpatient`` ``<-`` `[`sia_data`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, month ``=`` ``1``)`\
\
`top_procedures`` ``<-`` ``outpatient`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``PA_PROC_ID``, sort ``=`` ``TRUE``)`` ``|>`\
`  `[`head`](https://rdrr.io/r/utils/head.html)`(``20``)`

## Example: Outpatient spending by diagnosis

\
`outpatient`` ``<-`` `[`sia_data`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, month ``=`` ``1``)`\
\
`spending`` ``<-`` ``outpatient`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``!`[`is.na`](https://rdrr.io/r/base/NA.html)`(``PA_CIDPRI``)``, ``PA_CIDPRI`` ``!=`` ``""``)`` ``|>`\
`  `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(`\
`    chapter ``=`` `[`substr`](https://rdrr.io/r/base/substr.html)`(``PA_CIDPRI``, ``1``, ``1``)``,`\
`    value ``=`` `[`as.numeric`](https://rdrr.io/r/base/numeric.html)`(``PA_VALAPR``)`\
`  ``)`` ``|>`\
`  `[`group_by`](https://dplyr.tidyverse.org/reference/group_by.html)`(``chapter``)`` ``|>`\
`  `[`summarise`](https://dplyr.tidyverse.org/reference/summarise.html)`(`\
`    records ``=`` `[`n`](https://dplyr.tidyverse.org/reference/context.html)`(``)``,`\
`    total_value ``=`` `[`sum`](https://rdrr.io/r/base/sum.html)`(``value``, na.rm ``=`` ``TRUE``)`\
`  ``)`` ``|>`\
`  `[`arrange`](https://dplyr.tidyverse.org/reference/arrange.html)`(`[`desc`](https://dplyr.tidyverse.org/reference/desc.html)`(``total_value``)``)`

## Example: Chemotherapy APAC records

\
`chemo`` ``<-`` `[`sia_data`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, type ``=`` ``"AM"``, month ``=`` ``1``:``6``)`\
\
`chemo`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``month``, name ``=`` ``"records"``)`` ``|>`\
`  `[`arrange`](https://dplyr.tidyverse.org/reference/arrange.html)`(``month``)`

## Smart type parsing

\
`# parsed types (default)`\
`outpatient`` ``<-`` `[`sia_data`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"AC"``, month ``=`` ``1``)`\
[`class`](https://rdrr.io/r/base/class.html)`(``outpatient``$``PA_VALAPR``)``  ``# double`\
\
`# all character`\
`outpatient_raw`` ``<-`` `[`sia_data`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"AC"``, month ``=`` ``1``, parse ``=`` ``FALSE``)`

## Cache and lazy evaluation

\
[`sia_cache_status`](https://sidneybissoli.github.io/healthbR/reference/sia_cache_status.md)`(``)`\
[`sia_clear_cache`](https://sidneybissoli.github.io/healthbR/reference/sia_clear_cache.md)`(``)`\
\
`# lazy query`\
`lazy`` ``<-`` `[`sia_data`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, lazy ``=`` ``TRUE``)`\
`lazy`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``PA_CIDPRI`` ``>=`` ``"E10"``, ``PA_CIDPRI`` ``<=`` ``"E14"``)`` ``|>`\
`  `[`collect`](https://dplyr.tidyverse.org/reference/compute.html)`(``)`

## Further reading

- SIA on DATASUS (`datasus.saude.gov.br`)
- SIGTAP procedure table (`wiki.saude.gov.br/sigtap`)
- [SIH
  vignette](https://sidneybissoli.github.io/healthbR/articles/sih-hospital-admissions.md)
  for hospital admission data
