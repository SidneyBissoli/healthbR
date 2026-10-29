# Chronic Disease Risk Factors from VIGITEL with healthbR

## Overview

**VIGITEL (Vigilancia de Fatores de Risco e Protecao para Doencas
Cronicas por Inquerito Telefonico)** is an annual telephone survey
conducted by the Brazilian Ministry of Health since 2006. It monitors
risk and protective factors for chronic non-communicable diseases among
adults (18+) in all 26 state capitals and the Federal District.

| Topic                 | Examples                                      |
|-----------------------|-----------------------------------------------|
| **Tobacco**           | Smoking prevalence, cessation                 |
| **Alcohol**           | Consumption patterns, binge drinking          |
| **Diet**              | Fruit/vegetable intake, ultra-processed foods |
| **Physical activity** | Leisure, commuting, sedentary behavior        |
| **Chronic diseases**  | Diabetes, hypertension, obesity self-report   |
| **Preventive exams**  | Mammography, Pap smear, colonoscopy           |

Each annual edition interviews approximately 54,000 adults via landline
telephone, with post-stratification weighting (`pesorake`) to match the
adult population of each city.

## Getting started

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`healthbR`](https://github.com/SidneyBissoli/healthbR)`)`\
[`library`](https://rdrr.io/r/base/library.html)`(`[`dplyr`](https://dplyr.tidyverse.org)`)`

### Check available years

\
[`vigitel_years`](https://sidneybissoli.github.io/healthbR/reference/vigitel_years.md)`(``)`\
`#> [1] 2006 2007 2008 ... 2023 2024`

### Survey information

\
[`vigitel_info`](https://sidneybissoli.github.io/healthbR/reference/vigitel_info.md)`(``)`

## Downloading data

### All years at once

VIGITEL is distributed as a single consolidated file covering 2006–2024.
By default, all years are downloaded:

\
`df`` ``<-`` `[`vigitel_data`](https://sidneybissoli.github.io/healthbR/reference/vigitel_data.md)`(``)`

### Specific years

\
`df`` ``<-`` `[`vigitel_data`](https://sidneybissoli.github.io/healthbR/reference/vigitel_data.md)`(``year ``=`` ``2020``:``2024``)`

### Select variables

\
`df`` ``<-`` `[`vigitel_data`](https://sidneybissoli.github.io/healthbR/reference/vigitel_data.md)`(``year ``=`` ``2024``, vars ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"cidade"``, ``"sexo"``, ``"idade"``, ``"pesorake"``,`\
`                                          ``"q6"``, ``"q7"``, ``"q9"``)``)`

### Data format

Two formats are available: Stata (`.dta`, default) and CSV. The Stata
format preserves variable labels:

\
`df_dta`` ``<-`` `[`vigitel_data`](https://sidneybissoli.github.io/healthbR/reference/vigitel_data.md)`(``format ``=`` ``"dta"``)``  ``# default, with labels`\
`df_csv`` ``<-`` `[`vigitel_data`](https://sidneybissoli.github.io/healthbR/reference/vigitel_data.md)`(``format ``=`` ``"csv"``)``  ``# alternative`

## Exploring variables

### Data dictionary

\
[`vigitel_dictionary`](https://sidneybissoli.github.io/healthbR/reference/vigitel_dictionary.md)`(``)`

### Search variables

\
[`vigitel_variables`](https://sidneybissoli.github.io/healthbR/reference/vigitel_variables.md)`(``)`

## Example: Smoking prevalence over time

\
`# Download smoking-related variables`\
`df`` ``<-`` `[`vigitel_data`](https://sidneybissoli.github.io/healthbR/reference/vigitel_data.md)`(`\
`  year ``=`` ``2006``:``2024``,`\
`  vars ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"ano"``, ``"cidade"``, ``"sexo"``, ``"pesorake"``, ``"q6"``)`\
`)`\
\
`# q6: "Atualmente, o(a) sr(a) fuma?" (1 = sim, 2 = nao)`\
`smoking`` ``<-`` ``df`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``q6`` `[`%in%`](https://rdrr.io/r/base/match.html)` `[`c`](https://rdrr.io/r/base/c.html)`(``"1"``, ``"2"``)``)`` ``|>`\
`  `[`group_by`](https://dplyr.tidyverse.org/reference/group_by.html)`(``ano``)`` ``|>`\
`  `[`summarise`](https://dplyr.tidyverse.org/reference/summarise.html)`(`\
`    smokers ``=`` `[`sum`](https://rdrr.io/r/base/sum.html)`(``pesorake``[``q6`` ``==`` ``"1"``]``, na.rm ``=`` ``TRUE``)``,`\
`    total ``=`` `[`sum`](https://rdrr.io/r/base/sum.html)`(``pesorake``, na.rm ``=`` ``TRUE``)``,`\
`    prevalence ``=`` ``smokers`` ``/`` ``total`` ``*`` ``100`\
`  ``)`

## Example: Obesity by capital city

\
`df`` ``<-`` `[`vigitel_data`](https://sidneybissoli.github.io/healthbR/reference/vigitel_data.md)`(`\
`  year ``=`` ``2024``,`\
`  vars ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"cidade"``, ``"sexo"``, ``"pesorake"``, ``"q8"``, ``"q9"``)`\
`)`\
\
`# q8 = weight (kg), q9 = height (cm)`\
`# BMI >= 30 = obesity`\
`obesity`` ``<-`` ``df`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``!`[`is.na`](https://rdrr.io/r/base/NA.html)`(``q8``)``, ``!`[`is.na`](https://rdrr.io/r/base/NA.html)`(``q9``)``, ``q9`` ``>`` ``0``)`` ``|>`\
`  `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(`\
`    bmi ``=`` `[`as.numeric`](https://rdrr.io/r/base/numeric.html)`(``q8``)`` ``/`` ``(`[`as.numeric`](https://rdrr.io/r/base/numeric.html)`(``q9``)`` ``/`` ``100``)``^``2``,`\
`    obese ``=`` ``bmi`` ``>=`` ``30`\
`  ``)`` ``|>`\
`  `[`group_by`](https://dplyr.tidyverse.org/reference/group_by.html)`(``cidade``)`` ``|>`\
`  `[`summarise`](https://dplyr.tidyverse.org/reference/summarise.html)`(`\
`    prevalence ``=`` `[`weighted.mean`](https://rdrr.io/r/stats/weighted.mean.html)`(``obese``, `[`as.numeric`](https://rdrr.io/r/base/numeric.html)`(``pesorake``)``, na.rm ``=`` ``TRUE``)`` ``*`` ``100`\
`  ``)`` ``|>`\
`  `[`arrange`](https://dplyr.tidyverse.org/reference/arrange.html)`(`[`desc`](https://dplyr.tidyverse.org/reference/desc.html)`(``prevalence``)``)`

## Cache and performance

Data is automatically cached in partitioned parquet format (when `arrow`
is installed). Subsequent calls load instantly from cache:

\
`# First call downloads (~30 seconds)`\
`df`` ``<-`` `[`vigitel_data`](https://sidneybissoli.github.io/healthbR/reference/vigitel_data.md)`(``year ``=`` ``2024``)`\
\
`# Second call loads from cache (instant)`\
`df`` ``<-`` `[`vigitel_data`](https://sidneybissoli.github.io/healthbR/reference/vigitel_data.md)`(``year ``=`` ``2024``)`\
\
`# Check cache status`\
[`vigitel_cache_status`](https://sidneybissoli.github.io/healthbR/reference/vigitel_cache_status.md)`(``)`\
\
`# Clear cache if needed`\
[`vigitel_clear_cache`](https://sidneybissoli.github.io/healthbR/reference/vigitel_clear_cache.md)`(``)`

### Lazy evaluation

For large analyses, use lazy evaluation to query without loading all
data into memory:

\
`lazy_df`` ``<-`` `[`vigitel_data`](https://sidneybissoli.github.io/healthbR/reference/vigitel_data.md)`(``lazy ``=`` ``TRUE``, backend ``=`` ``"arrow"``)`

## Further reading

- VIGITEL official page (`svs.aids.gov.br/daent/cgdnt/vigitel`)
