# healthbR ![](reference/figures/logo.png)

## Overview

healthbR provides easy access to Brazilian public health data directly
from R: the DATASUS microdata systems (SIM mortality, SINASC live
births, SIH hospital admissions, SIA outpatient production, SINAN
notifiable diseases, CNES facilities, SI-PNI vaccination), the IBGE and
Ministry of Health surveys (VIGITEL, PNS, PNAD Continua, POF, Censo) and
the regulatory agencies (ANS, ANVISA). The package downloads, caches,
and processes data from official sources, returning clean,
analysis-ready tibbles following tidyverse conventions.

If you already use
[microdatasus](https://CRAN.R-project.org/package=microdatasus) or
[read.dbc](https://github.com/danicat/read.dbc) (or PySUS in Python) for
DATASUS, see [healthbR, microdatasus and
read.dbc](https://sidneybissoli.github.io/healthbR/articles/healthbr-vs-microdatasus.html)
– a measured comparison of the three on the same files: what each
returns, how fast, the same tasks side by side, and the Parquet mirror
read with no package at all.

### Surveys (IBGE / Ministry of Health)

| Module | Description | Years |
|----|----|----|
| **VIGITEL** | Surveillance of Risk Factors for Chronic Diseases by Telephone Survey | 2006–2024 |
| **PNS** | National Health Survey (microdata + SIDRA API) | 2013, 2019 |
| **PNAD Continua** | Continuous National Household Sample Survey | 2012–2024 |
| **POF** | Household Budget Survey (food security, consumption, anthropometry) | 2002–2018 |
| **Censo** | Population denominators via SIDRA API | 1970–2022 |

### DATASUS (Ministry of Health FTP)

| Module | Description | Granularity | Years |
|----|----|----|----|
| **SIM** | Mortality Information System (deaths) | Annual/UF | 1996–2024 |
| **SINASC** | Live Birth Information System | Annual/UF | 1996–2024 |
| **SIH** | Hospital Information System (admissions) | Monthly/UF | 1992–2026 |
| **SIA** | Outpatient Information System (13 file types) | Monthly/UF | 2008–2026 |
| **SINAN** | Notifiable Diseases Surveillance (31 diseases) | Annual/UF | 2007–2026 |
| **CNES** | National Health Facility Registry (13 file types) | Monthly/UF | 2005–2026 |
| **SI-PNI** | National Immunization Program (aggregates 1994–2019, microdata 2020+; served from the healthbr-data R2 mirror with automatic DATASUS fallback) | Annual or Monthly/UF | 1994–2026 |

DATASUS modules download `.dbc` files (compressed DBF) and decompress
them internally using vendored C code – no external dependencies
required. SIH and SI-PNI read by default from the
[healthbr-data](https://github.com/SidneyBissoli/healthbr-data) Parquet
mirror (byte-identical to the Ministry’s files, with per-file
provenance: source URL, MD5, timestamp) and fall back to the FTP.

### Primary Care & Regulatory Agencies

| Module | Source | Description | Years |
|----|----|----|----|
| **SISAB** | Ministry of Health REST API | Primary Care coverage indicators (APS, oral health, community agents, PNS) | 2007–present |
| **ANS** | ANS Open Data Portal | Supplementary health beneficiaries, consumer complaints, financial statements | 2007–present |
| **ANVISA** | ANVISA Open Data Portal | Product registrations, pharmacovigilance, hemovigilance, technovigilance, SNGPC | snapshot + 2014–present |

## healthbR, microdatasus and read.dbc

Three R routes read DATASUS microdata, at different layers: read.dbc
reads a `.dbc` file you downloaded, microdatasus downloads and labels,
healthbR downloads, caches and types. Measured on 2026-10-14 (healthbR
0.4.0.9000, microdatasus 3.0.0, read.dbc 1.2.0) and detailed in the
vignette [healthbR, microdatasus and
read.dbc](https://sidneybissoli.github.io/healthbR/articles/healthbr-vs-microdatasus.html):

|  | healthbR | microdatasus | read.dbc |
|----|----|----|----|
| DATASUS systems | SIM, SINASC, SIH, SIA, SINAN (31 diseases), CNES, SI-PNI | SIM, SINASC, SIH, SIA, SINAN (8 diseases), CNES | any `.dbc` you download |
| Beyond DATASUS | VIGITEL, PNS, PNAD Continua, POF, Censo, SISAB, ANS, ANVISA | SIGTAP, CADGER and municipality tables | – |
| `.dbc` reader | vendored C (blast) | the same code, adapted from healthbR in 3.0.0 | its own C; also writes `.dbc` |
| Codes | kept as codes; typed (`Date`, integer, double); labels via `*_dictionary()` | replaced by labels by `process_*()`; all columns character | as the DBF declares them |
| Source | healthbr-data Parquet mirror with provenance (SIH, SI-PNI), FTP otherwise | DATASUS FTP | – |
| Lazy / cache | `lazy = TRUE` (arrow or duckdb), local Parquet cache | none | none |
| On CRAN | yes | yes | archived 2025-12-14 |
| SIH-SP 2023-01, from nothing | 7.7 s (mirror) | 18.0 s | 9.7 s (with the download) |

Same rows and records in all three on every file compared. Each fits a
different workflow; the vignette says which.

## Installation

From CRAN (0.2.0):

\
[`install.packages`](https://rdrr.io/r/utils/install.packages.html)`(``"healthbR"``)`

The development version, with the SIH mirror and the newest year
coverage, from GitHub:

\
`# install.packages("pak")`\
`pak``::`[`pak`](https://pak.r-lib.org/reference/pak.html)`(``"SidneyBissoli/healthbR"``)`

## Quick start

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`healthbR`](https://github.com/SidneyBissoli/healthbR)`)`\
\
`# see all available data sources`\
[`list_sources`](https://sidneybissoli.github.io/healthbR/reference/list_sources.md)`(``)`

### DATASUS modules

All DATASUS modules follow a consistent API: `*_years()`, `*_info()`,
`*_variables()`, `*_dictionary()`, `*_data()`, `*_cache_status()`,
`*_clear_cache()`.

\
`# mortality data -- deaths in Acre, 2022`\
`obitos`` ``<-`` `[`sim_data`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"AC"``)`\
\
`# filter by cause of death (CID-10 prefix)`\
`obitos_cardio`` ``<-`` `[`sim_data`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"AC"``, cause ``=`` ``"I"``)`\
\
`# live births in Acre, 2022`\
`nascimentos`` ``<-`` `[`sinasc_data`](https://sidneybissoli.github.io/healthbR/reference/sinasc_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"AC"``)`\
\
`# hospital admissions in Acre, January 2022`\
`internacoes`` ``<-`` `[`sih_data`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md)`(``year ``=`` ``2022``, month ``=`` ``1``, uf ``=`` ``"AC"``)`\
\
`# filter by diagnosis (CID-10 prefix)`\
`intern_resp`` ``<-`` `[`sih_data`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md)`(``year ``=`` ``2022``, month ``=`` ``1``, uf ``=`` ``"AC"``, diagnosis ``=`` ``"J"``)`\
\
`# outpatient production in Acre, January 2022`\
`ambulatorial`` ``<-`` `[`sia_data`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md)`(``year ``=`` ``2022``, month ``=`` ``1``, uf ``=`` ``"AC"``)`\
\
`# different file type (e.g., high-cost medications)`\
`medicamentos`` ``<-`` `[`sia_data`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md)`(``year ``=`` ``2022``, month ``=`` ``1``, uf ``=`` ``"AC"``, type ``=`` ``"AM"``)`

### Additional DATASUS modules

\
`# disease notifications -- dengue, 2022`\
`dengue`` ``<-`` `[`sinan_data`](https://sidneybissoli.github.io/healthbR/reference/sinan_data.md)`(``year ``=`` ``2022``, disease ``=`` ``"DENG"``)`\
\
`# health facilities in Acre, January 2023`\
`cnes`` ``<-`` `[`cnes_data`](https://sidneybissoli.github.io/healthbR/reference/cnes_data.md)`(``year ``=`` ``2023``, month ``=`` ``1``, uf ``=`` ``"AC"``)`\
\
`# vaccination data -- Acre (R2 mirror by default, DATASUS fallback)`\
`vacinas`` ``<-`` `[`sipni_data`](https://sidneybissoli.github.io/healthbR/reference/sipni_data.md)`(``year ``=`` ``2019``, uf ``=`` ``"AC"``)`\
`micro`` ``<-`` `[`sipni_data`](https://sidneybissoli.github.io/healthbR/reference/sipni_data.md)`(``year ``=`` ``2024``, uf ``=`` ``"AC"``, month ``=`` ``1``)`

### Survey modules

\
`# VIGITEL telephone survey`\
`vigitel`` ``<-`` `[`vigitel_data`](https://sidneybissoli.github.io/healthbR/reference/vigitel_data.md)`(``year ``=`` ``2024``)`\
\
`# PNS national health survey`\
`pns`` ``<-`` `[`pns_data`](https://sidneybissoli.github.io/healthbR/reference/pns_data.md)`(``year ``=`` ``2019``)`\
\
`# PNAD Continua`\
`pnadc`` ``<-`` `[`pnadc_data`](https://sidneybissoli.github.io/healthbR/reference/pnadc_data.md)`(``year ``=`` ``2023``, quarter ``=`` ``1``)`\
\
`# POF household budget survey`\
`pof`` ``<-`` `[`pof_data`](https://sidneybissoli.github.io/healthbR/reference/pof_data.md)`(``year ``=`` ``2018``, register ``=`` ``"morador"``)`\
\
`# Census population`\
`pop`` ``<-`` `[`censo_populacao`](https://sidneybissoli.github.io/healthbR/reference/censo_populacao.md)`(``year ``=`` ``2022``, territorial_level ``=`` ``"state"``)`

### Primary care & regulatory agencies

\
`# SISAB -- primary care coverage by state, January 2024`\
`sisab`` ``<-`` `[`sisab_data`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md)`(``year ``=`` ``2024``, month ``=`` ``1``)`\
\
`# ANS -- health plan beneficiaries in Acre, December 2023`\
`ans`` ``<-`` `[`ans_data`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md)`(``year ``=`` ``2023``, month ``=`` ``12``, uf ``=`` ``"AC"``)`\
\
`# ANVISA -- registered medicines`\
`med`` ``<-`` `[`anvisa_data`](https://sidneybissoli.github.io/healthbR/reference/anvisa_data.md)`(``type ``=`` ``"medicines"``)`

### Explore variables and dictionaries

\
`# list variables for any module`\
[`sim_variables`](https://sidneybissoli.github.io/healthbR/reference/sim_variables.md)`(``)`\
[`sia_variables`](https://sidneybissoli.github.io/healthbR/reference/sia_variables.md)`(``search ``=`` ``"sexo"``)`\
[`sinan_diseases`](https://sidneybissoli.github.io/healthbR/reference/sinan_diseases.md)`(``search ``=`` ``"dengue"``)`\
\
`# data dictionary with category labels`\
[`sim_dictionary`](https://sidneybissoli.github.io/healthbR/reference/sim_dictionary.md)`(``"SEXO"``)`\
[`sia_dictionary`](https://sidneybissoli.github.io/healthbR/reference/sia_dictionary.md)`(``"PA_RACACOR"``)`

## Parallel downloads

When downloading multiple files (e.g., several years, months, or
states), you can speed up downloads by enabling parallel processing.
Install `furrr` and `future`, then set a parallel plan before calling
any `*_data()` function:

\
[`install.packages`](https://rdrr.io/r/utils/install.packages.html)`(`[`c`](https://rdrr.io/r/base/c.html)`(``"furrr"``, ``"future"``)``)`\
\
[`library`](https://rdrr.io/r/base/library.html)`(`[`future`](https://future.futureverse.org)`)`\
[`plan`](https://future.futureverse.org/reference/plan.html)`(``multisession``, workers ``=`` ``4``)`\
\
`# downloads 4 states in parallel`\
`df`` ``<-`` `[`sih_data`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md)`(``year ``=`` ``2022``, month ``=`` ``1``:``6``, uf ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"SP"``, ``"RJ"``, ``"MG"``, ``"BA"``)``)`\
\
`# reset to sequential when done`\
[`plan`](https://future.futureverse.org/reference/plan.html)`(``sequential``)`

All 12 download-based modules support parallel downloads: SIM, SINASC,
SIH, SIA, SINAN, CNES, SI-PNI, SISAB, ANS, ANVISA, PNS, and PNADC.

## Caching

All modules cache downloaded data automatically. Install `arrow` for
optimized Parquet caching:

\
[`install.packages`](https://rdrr.io/r/utils/install.packages.html)`(``"arrow"``)`

Each module provides cache management functions:

\
`# check what is cached`\
[`sim_cache_status`](https://sidneybissoli.github.io/healthbR/reference/sim_cache_status.md)`(``)`\
[`sih_cache_status`](https://sidneybissoli.github.io/healthbR/reference/sih_cache_status.md)`(``)`\
[`sia_cache_status`](https://sidneybissoli.github.io/healthbR/reference/sia_cache_status.md)`(``)`\
\
`# clear cache for a module`\
[`sim_clear_cache`](https://sidneybissoli.github.io/healthbR/reference/sim_clear_cache.md)`(``)`

## Data sources

All data is downloaded from official Brazilian government repositories
(DATASUS, IBGE, ANS, ANVISA):

- **VIGITEL**: Ministry of Health
- **PNS / PNAD Continua / POF / Censo**: IBGE
- **SIM / SINASC / SIA / SINAN / CNES**: DATASUS FTP
- **SIH / SI-PNI**:
  [healthbr-data](https://github.com/SidneyBissoli/healthbr-data) mirror
  on Cloudflare R2 (byte-identical to the Ministry’s files, with
  provenance metadata), falling back to DATASUS FTP / OpenDataSUS
- **SISAB**: Ministry of Health REST API
- **ANS**: ANS Open Data Portal
- **ANVISA**: ANVISA Open Data Portal

## Citation

If you use healthbR in your research, please cite it:

\
[`citation`](https://rdrr.io/r/utils/citation.html)`(``"healthbR"``)`

## Contributing

Please see
[CONTRIBUTING.md](https://github.com/SidneyBissoli/healthbR/blob/main/CONTRIBUTING.md)
for guidelines on how to contribute to this project.

## Code of Conduct

Please note that the healthbR project is released with a [Contributor
Code of
Conduct](https://github.com/SidneyBissoli/healthbR/blob/main/CODE_OF_CONDUCT.md).
By contributing to this project, you agree to abide by its terms.

## License

MIT © Sidney da Silva Pereira Bissoli
