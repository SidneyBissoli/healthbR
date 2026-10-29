# Mortality Data from SIM with healthbR

## Overview

The **SIM (Sistema de Informacoes sobre Mortalidade)** is Brazil’s
national mortality information system, managed by the Ministry of Health
through DATASUS. It records individual death certificates (*Declaracao
de Obito*) with cause of death coded by ICD-10.

| Feature  | Details                       |
|----------|-------------------------------|
| Coverage | Per state (UF), all 27 states |
| Years    | 1996–2024 (CID-10 era)        |
| Unit     | One row per death certificate |
| Format   | .dbc files from DATASUS FTP   |

## Getting started

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`healthbR`](https://github.com/SidneyBissoli/healthbR)`)`\
[`library`](https://rdrr.io/r/base/library.html)`(`[`dplyr`](https://dplyr.tidyverse.org)`)`

### Check available years

\
[`sim_years`](https://sidneybissoli.github.io/healthbR/reference/sim_years.md)`(``)`\
\
`# include preliminary data`\
[`sim_years`](https://sidneybissoli.github.io/healthbR/reference/sim_years.md)`(``status ``=`` ``"all"``)`

### Module information

\
[`sim_info`](https://sidneybissoli.github.io/healthbR/reference/sim_info.md)`(``)`

## Downloading data

### Basic download (one state, one year)

\
`deaths_ac`` ``<-`` `[`sim_data`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"AC"``)`

### Multiple states and years

\
`deaths_se`` ``<-`` `[`sim_data`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md)`(``year ``=`` ``2020``:``2022``, uf ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"SP"``, ``"RJ"``, ``"MG"``)``)`

### All states (default)

\
`# downloads all 27 states -- may take several minutes`\
`deaths_all`` ``<-`` `[`sim_data`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md)`(``year ``=`` ``2022``)`

### Filter by cause of death

Use CID-10 code prefixes to filter by cause:

\
`# Acute myocardial infarction (I21)`\
`mi`` ``<-`` `[`sim_data`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, cause ``=`` ``"I21"``)`\
\
`# All cardiovascular diseases (Chapter IX)`\
`cardio`` ``<-`` `[`sim_data`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, cause ``=`` ``"I"``)`\
\
`# All neoplasms (Chapter II)`\
`cancer`` ``<-`` `[`sim_data`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, cause ``=`` ``"C"``)`

### Select variables

\
`deaths`` ``<-`` `[`sim_data`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md)`(`\
`  year ``=`` ``2022``,`\
`  uf ``=`` ``"SP"``,`\
`  vars ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"CAUSABAS"``, ``"DTOBITO"``, ``"SEXO"``, ``"IDADE"``, ``"RACACOR"``, ``"CODMUNRES"``)`\
`)`

## Age decoding

The `IDADE` variable uses a 3-digit encoding where the first digit
indicates the unit and the remaining two indicate the value:

| First digit | Unit       | Example           |
|-------------|------------|-------------------|
| 0           | Minutes    | `005` = 5 minutes |
| 1           | Hours      | `112` = 12 hours  |
| 2           | Days       | `215` = 15 days   |
| 3           | Months     | `306` = 6 months  |
| 4           | Years      | `445` = 45 years  |
| 5           | 100+ years | `502` = 102 years |

By default, `decode_age = TRUE` adds an `age_years` column:

\
`deaths`` ``<-`` `[`sim_data`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"AC"``)`\
`deaths``$``age_years``  ``# numeric age in years`\
\
`# disable decoding`\
`deaths_raw`` ``<-`` `[`sim_data`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"AC"``, decode_age ``=`` ``FALSE``)`

## Key variables

| Variable  | Description                                                    |
|-----------|----------------------------------------------------------------|
| CAUSABAS  | Underlying cause of death (CID-10)                             |
| DTOBITO   | Date of death                                                  |
| SEXO      | Sex (1=Male, 2=Female, 0=Unknown)                              |
| IDADE     | Age (3-digit encoded)                                          |
| RACACOR   | Race/color (1=White, 2=Black, 3=Yellow, 4=Brown, 5=Indigenous) |
| CODMUNRES | Municipality of residence (IBGE 6 digits)                      |
| LINHAA-D  | Cause of death lines A-D from the certificate                  |
| ESCMAE    | Mother’s education level                                       |
| ESTCIV    | Marital status                                                 |

### Data dictionary

\
[`sim_dictionary`](https://sidneybissoli.github.io/healthbR/reference/sim_dictionary.md)`(``)`\
[`sim_dictionary`](https://sidneybissoli.github.io/healthbR/reference/sim_dictionary.md)`(``"SEXO"``)`\
[`sim_dictionary`](https://sidneybissoli.github.io/healthbR/reference/sim_dictionary.md)`(``"RACACOR"``)`

### Explore variables

\
[`sim_variables`](https://sidneybissoli.github.io/healthbR/reference/sim_variables.md)`(``)`\
[`sim_variables`](https://sidneybissoli.github.io/healthbR/reference/sim_variables.md)`(``search ``=`` ``"causa"``)`

## Example: Mortality by cause chapter

\
`deaths`` ``<-`` `[`sim_data`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``)`\
\
`deaths`` ``|>`\
`  `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(``chapter ``=`` `[`substr`](https://rdrr.io/r/base/substr.html)`(``CAUSABAS``, ``1``, ``1``)``)`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``chapter``, sort ``=`` ``TRUE``)`

## Example: Age-specific mortality rate

Combine SIM data with Census population denominators:

\
`# deaths by age group`\
`deaths`` ``<-`` `[`sim_data`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``)`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``!`[`is.na`](https://rdrr.io/r/base/NA.html)`(``age_years``)``)`` ``|>`\
`  `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(``age_group ``=`` `[`cut`](https://rdrr.io/r/base/cut.html)`(``age_years``,`\
`    breaks ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``0``, ``1``, ``5``, ``15``, ``30``, ``45``, ``60``, ``80``, ``Inf``)``,`\
`    right ``=`` ``FALSE`\
`  ``)``)`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``age_group``, name ``=`` ``"deaths"``)`\
\
`# population from Census 2022`\
`pop`` ``<-`` `[`censo_populacao`](https://sidneybissoli.github.io/healthbR/reference/censo_populacao.md)`(``year ``=`` ``2022``, territorial_level ``=`` ``"state"``, geo_code ``=`` ``"35"``)`\
\
`# join and calculate rates per 100,000`

## Smart type parsing

\
`# parsed types (default)`\
`deaths`` ``<-`` `[`sim_data`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"AC"``)`\
[`class`](https://rdrr.io/r/base/class.html)`(``deaths``$``DTOBITO``)``  ``# Date`\
\
`# all character (backward-compatible)`\
`deaths_raw`` ``<-`` `[`sim_data`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"AC"``, parse ``=`` ``FALSE``)`

## Cache and lazy evaluation

\
[`sim_cache_status`](https://sidneybissoli.github.io/healthbR/reference/sim_cache_status.md)`(``)`\
[`sim_clear_cache`](https://sidneybissoli.github.io/healthbR/reference/sim_clear_cache.md)`(``)`\
\
`# lazy query (requires arrow)`\
`lazy`` ``<-`` `[`sim_data`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, lazy ``=`` ``TRUE``)`\
`lazy`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``CAUSABAS`` ``>=`` ``"I20"``, ``CAUSABAS`` ``<`` ``"I26"``)`` ``|>`\
`  `[`collect`](https://dplyr.tidyverse.org/reference/compute.html)`(``)`

## Further reading

- SIM on DATASUS (`datasus.saude.gov.br`)
- [SINASC
  vignette](https://sidneybissoli.github.io/healthbR/articles/sinan-notifiable-diseases.md)
  for live birth data
- [Census
  vignette](https://sidneybissoli.github.io/healthbR/articles/censo-denominadores.md)
  for population denominators
