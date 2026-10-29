# Live Birth Data from SINASC with healthbR

## Overview

The **SINASC (Sistema de Informacoes sobre Nascidos Vivos)** is Brazil’s
national live birth information system, managed by the Ministry of
Health through DATASUS. It records individual birth certificates
(*Declaracao de Nascido Vivo*) with maternal, delivery, and newborn
characteristics.

| Feature  | Details                            |
|----------|------------------------------------|
| Coverage | Per state (UF), all 27 states      |
| Years    | 1996–2024                          |
| Unit     | One row per live birth certificate |
| Format   | .dbc files from DATASUS FTP        |

## Getting started

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`healthbR`](https://github.com/SidneyBissoli/healthbR)`)`\
[`library`](https://rdrr.io/r/base/library.html)`(`[`dplyr`](https://dplyr.tidyverse.org)`)`

### Check available years

\
[`sinasc_years`](https://sidneybissoli.github.io/healthbR/reference/sinasc_years.md)`(``)`\
\
`# include preliminary data`\
[`sinasc_years`](https://sidneybissoli.github.io/healthbR/reference/sinasc_years.md)`(``status ``=`` ``"all"``)`

### Module information

\
[`sinasc_info`](https://sidneybissoli.github.io/healthbR/reference/sinasc_info.md)`(``)`

## Downloading data

### Basic download

\
`births`` ``<-`` `[`sinasc_data`](https://sidneybissoli.github.io/healthbR/reference/sinasc_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"AC"``)`

### Multiple states and years

\
`births`` ``<-`` `[`sinasc_data`](https://sidneybissoli.github.io/healthbR/reference/sinasc_data.md)`(``year ``=`` ``2020``:``2022``, uf ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"SP"``, ``"RJ"``)``)`

### Filter by congenital anomaly

Use CID-10 code prefixes to filter births with congenital anomalies:

\
`# Down syndrome (Q90)`\
`down`` ``<-`` `[`sinasc_data`](https://sidneybissoli.github.io/healthbR/reference/sinasc_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, anomaly ``=`` ``"Q90"``)`\
\
`# All congenital anomalies (Chapter XVII)`\
`anomalies`` ``<-`` `[`sinasc_data`](https://sidneybissoli.github.io/healthbR/reference/sinasc_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, anomaly ``=`` ``"Q"``)`

### Select variables

\
`births`` ``<-`` `[`sinasc_data`](https://sidneybissoli.github.io/healthbR/reference/sinasc_data.md)`(`\
`  year ``=`` ``2022``,`\
`  uf ``=`` ``"SP"``,`\
`  vars ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"DTNASC"``, ``"SEXO"``, ``"PESO"``, ``"IDADEMAE"``, ``"GESTACAO"``,`\
`           ``"PARTO"``, ``"CONSULTAS"``, ``"CODMUNRES"``)`\
`)`

## Key variables

| Variable       | Description                                        |
|----------------|----------------------------------------------------|
| DTNASC         | Birth date                                         |
| SEXO           | Sex (1=Male, 2=Female, 0=Unknown)                  |
| PESO           | Birth weight (grams)                               |
| IDADEMAE       | Mother’s age (years)                               |
| GESTACAO       | Gestational age (weeks, categorized)               |
| PARTO          | Delivery type (1=Vaginal, 2=Cesarean)              |
| CONSULTAS      | Prenatal consultations (categorized)               |
| CODANOMAL      | Congenital anomaly (CID-10 code)                   |
| CODMUNRES      | Municipality of mother’s residence (IBGE 6 digits) |
| ESCMAE         | Mother’s education level                           |
| RACACOR        | Newborn’s race/color                               |
| APGAR1, APGAR5 | Apgar score at 1 and 5 minutes                     |

### Data dictionary

\
[`sinasc_dictionary`](https://sidneybissoli.github.io/healthbR/reference/sinasc_dictionary.md)`(``)`\
[`sinasc_dictionary`](https://sidneybissoli.github.io/healthbR/reference/sinasc_dictionary.md)`(``"PARTO"``)`\
[`sinasc_dictionary`](https://sidneybissoli.github.io/healthbR/reference/sinasc_dictionary.md)`(``"GESTACAO"``)`

### Explore variables

\
[`sinasc_variables`](https://sidneybissoli.github.io/healthbR/reference/sinasc_variables.md)`(``)`\
[`sinasc_variables`](https://sidneybissoli.github.io/healthbR/reference/sinasc_variables.md)`(``search ``=`` ``"mae"``)`\
[`sinasc_variables`](https://sidneybissoli.github.io/healthbR/reference/sinasc_variables.md)`(``search ``=`` ``"peso"``)`

## Example: Low birth weight by state

\
`births`` ``<-`` `[`sinasc_data`](https://sidneybissoli.github.io/healthbR/reference/sinasc_data.md)`(``year ``=`` ``2022``, uf ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"SP"``, ``"RJ"``, ``"MG"``, ``"BA"``, ``"RS"``)``)`\
\
`lbw`` ``<-`` ``births`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``!`[`is.na`](https://rdrr.io/r/base/NA.html)`(``PESO``)``, ``PESO`` ``!=`` ``"0"``)`` ``|>`\
`  `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(`\
`    weight ``=`` `[`as.numeric`](https://rdrr.io/r/base/numeric.html)`(``PESO``)``,`\
`    low_weight ``=`` ``weight`` ``<`` ``2500`\
`  ``)`` ``|>`\
`  `[`group_by`](https://dplyr.tidyverse.org/reference/group_by.html)`(``uf_source``)`` ``|>`\
`  `[`summarise`](https://dplyr.tidyverse.org/reference/summarise.html)`(`\
`    total ``=`` `[`n`](https://dplyr.tidyverse.org/reference/context.html)`(``)``,`\
`    low_weight_n ``=`` `[`sum`](https://rdrr.io/r/base/sum.html)`(``low_weight``)``,`\
`    low_weight_pct ``=`` ``low_weight_n`` ``/`` ``total`` ``*`` ``100`\
`  ``)`

## Example: Cesarean rates over time

\
`births`` ``<-`` `[`sinasc_data`](https://sidneybissoli.github.io/healthbR/reference/sinasc_data.md)`(``year ``=`` ``2018``:``2022``, uf ``=`` ``"SP"``,`\
`                      vars ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"PARTO"``, ``"CODMUNRES"``)``)`\
\
`cesarean`` ``<-`` ``births`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``PARTO`` `[`%in%`](https://rdrr.io/r/base/match.html)` `[`c`](https://rdrr.io/r/base/c.html)`(``"1"``, ``"2"``)``)`` ``|>`\
`  `[`group_by`](https://dplyr.tidyverse.org/reference/group_by.html)`(``year``)`` ``|>`\
`  `[`summarise`](https://dplyr.tidyverse.org/reference/summarise.html)`(`\
`    vaginal ``=`` `[`sum`](https://rdrr.io/r/base/sum.html)`(``PARTO`` ``==`` ``"1"``)``,`\
`    cesarean ``=`` `[`sum`](https://rdrr.io/r/base/sum.html)`(``PARTO`` ``==`` ``"2"``)``,`\
`    cesarean_rate ``=`` ``cesarean`` ``/`` ``(``vaginal`` ``+`` ``cesarean``)`` ``*`` ``100`\
`  ``)`

## Example: Teen pregnancy

\
`births`` ``<-`` `[`sinasc_data`](https://sidneybissoli.github.io/healthbR/reference/sinasc_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``)`\
\
`teen`` ``<-`` ``births`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``!`[`is.na`](https://rdrr.io/r/base/NA.html)`(``IDADEMAE``)``)`` ``|>`\
`  `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(`\
`    mother_age ``=`` `[`as.integer`](https://rdrr.io/r/base/integer.html)`(``IDADEMAE``)``,`\
`    teen_mother ``=`` ``mother_age`` ``<`` ``20`\
`  ``)`` ``|>`\
`  `[`summarise`](https://dplyr.tidyverse.org/reference/summarise.html)`(`\
`    total ``=`` `[`n`](https://dplyr.tidyverse.org/reference/context.html)`(``)``,`\
`    teen_n ``=`` `[`sum`](https://rdrr.io/r/base/sum.html)`(``teen_mother``, na.rm ``=`` ``TRUE``)``,`\
`    teen_pct ``=`` ``teen_n`` ``/`` ``total`` ``*`` ``100`\
`  ``)`

## Smart type parsing

\
`# parsed types (default)`\
`births`` ``<-`` `[`sinasc_data`](https://sidneybissoli.github.io/healthbR/reference/sinasc_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"AC"``)`\
[`class`](https://rdrr.io/r/base/class.html)`(``births``$``DTNASC``)``  ``# Date`\
[`class`](https://rdrr.io/r/base/class.html)`(``births``$``PESO``)``    ``# integer`\
\
`# all character`\
`births_raw`` ``<-`` `[`sinasc_data`](https://sidneybissoli.github.io/healthbR/reference/sinasc_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"AC"``, parse ``=`` ``FALSE``)`

## Cache and lazy evaluation

\
[`sinasc_cache_status`](https://sidneybissoli.github.io/healthbR/reference/sinasc_cache_status.md)`(``)`\
[`sinasc_clear_cache`](https://sidneybissoli.github.io/healthbR/reference/sinasc_clear_cache.md)`(``)`\
\
`# lazy query`\
`lazy`` ``<-`` `[`sinasc_data`](https://sidneybissoli.github.io/healthbR/reference/sinasc_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"SP"``, lazy ``=`` ``TRUE``)`\
`lazy`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``PARTO`` ``==`` ``"2"``)`` ``|>`\
`  `[`collect`](https://dplyr.tidyverse.org/reference/compute.html)`(``)`

## Further reading

- SINASC on DATASUS (`datasus.saude.gov.br`)
- [SIM
  vignette](https://sidneybissoli.github.io/healthbR/articles/sim-mortality.md)
  for mortality data
- [Census
  vignette](https://sidneybissoli.github.io/healthbR/articles/censo-denominadores.md)
  for population denominators
