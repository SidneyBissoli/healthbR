# healthbR <img src="man/figures/logo.png" align="right" height="139" alt="" />
<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN status](https://www.r-pkg.org/badges/version/healthbR)](https://CRAN.R-project.org/package=healthbR)
[![R-CMD-check](https://github.com/SidneyBissoli/healthbR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/SidneyBissoli/healthbR/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/SidneyBissoli/healthbR/graph/badge.svg)](https://app.codecov.io/gh/SidneyBissoli/healthbR)
<!-- badges: end -->

## Overview

healthbR provides easy access to Brazilian public health data directly from R: the DATASUS microdata systems (SIM mortality, SINASC live births, SIH hospital admissions, SIA outpatient production, SINAN notifiable diseases, CNES facilities, SI-PNI vaccination), the IBGE and Ministry of Health surveys (VIGITEL, PNS, PNAD Continua, POF, Censo) and the regulatory agencies (ANS, ANVISA). The package downloads, caches, and processes data from official sources, returning clean, analysis-ready tibbles following tidyverse conventions.

If you already use [microdatasus](https://CRAN.R-project.org/package=microdatasus) (or PySUS in Python) for DATASUS, see [healthbR vs microdatasus](https://sidneybissoli.github.io/healthbR/articles/healthbr-vs-microdatasus.html) -- a measured comparison of the two packages on the systems both read.

### Surveys (IBGE / Ministry of Health)

| Module | Description | Years |
|--------|-------------|-------|
| **VIGITEL** | Surveillance of Risk Factors for Chronic Diseases by Telephone Survey | 2006--2024 |
| **PNS** | National Health Survey (microdata + SIDRA API) | 2013, 2019 |
| **PNAD Continua** | Continuous National Household Sample Survey | 2012--2024 |
| **POF** | Household Budget Survey (food security, consumption, anthropometry) | 2002--2018 |
| **Censo** | Population denominators via SIDRA API | 1970--2022 |

### DATASUS (Ministry of Health FTP)

| Module | Description | Granularity | Years |
|--------|-------------|-------------|-------|
| **SIM** | Mortality Information System (deaths) | Annual/UF | 1996--2024 |
| **SINASC** | Live Birth Information System | Annual/UF | 1996--2024 |
| **SIH** | Hospital Information System (admissions) | Monthly/UF | 2008--2026 |
| **SIA** | Outpatient Information System (13 file types) | Monthly/UF | 2008--2026 |
| **SINAN** | Notifiable Diseases Surveillance (31 diseases) | Annual/UF | 2007--2026 |
| **CNES** | National Health Facility Registry (13 file types) | Monthly/UF | 2005--2026 |
| **SI-PNI** | National Immunization Program (aggregates 1994--2019, microdata 2020+; served from the healthbr-data R2 mirror with automatic DATASUS fallback) | Annual or Monthly/UF | 1994--2026 |

DATASUS modules download `.dbc` files (compressed DBF) and decompress them internally using vendored C code -- no external dependencies required. SIH and SI-PNI read by default from the [healthbr-data](https://github.com/SidneyBissoli/healthbr-data) Parquet mirror (byte-identical to the Ministry's files, with per-file provenance: source URL, MD5, timestamp) and fall back to the FTP.

### Primary Care & Regulatory Agencies

| Module | Source | Description | Years |
|--------|--------|-------------|-------|
| **SISAB** | Ministry of Health REST API | Primary Care coverage indicators (APS, oral health, community agents, PNS) | 2007--present |
| **ANS** | ANS Open Data Portal | Supplementary health beneficiaries, consumer complaints, financial statements | 2007--present |
| **ANVISA** | ANVISA Open Data Portal | Product registrations, pharmacovigilance, hemovigilance, technovigilance, SNGPC | snapshot + 2014--present |

## healthbR and microdatasus

Two R packages read DATASUS microdata; they overlap on six systems and differ in what they do with the bytes. Measured on 2026-09-05 (healthbR 0.3.1 dev, microdatasus 3.0.0) and detailed in the vignette [healthbR vs microdatasus](https://sidneybissoli.github.io/healthbR/articles/healthbr-vs-microdatasus.html):

| | healthbR | microdatasus |
|---|---|---|
| DATASUS systems | SIM, SINASC, SIH, SIA, SINAN (31 diseases), CNES, SI-PNI | SIM, SINASC, SIH, SIA, SINAN (8 diseases), CNES |
| Beyond DATASUS | VIGITEL, PNS, PNAD Continua, POF, Censo, SISAB, ANS, ANVISA | SIGTAP, CADGER and municipality tables |
| `.dbc` reader | vendored C (blast) | the same code, adapted from healthbR in 3.0.0 |
| Codes | kept as codes; typed (`Date`, integer, double); labels via `*_dictionary()` | replaced by labels by `process_*()`; all columns character |
| Source | healthbr-data Parquet mirror with provenance (SIH, SI-PNI), FTP otherwise | DATASUS FTP |
| Lazy / cache | `lazy = TRUE` (arrow or duckdb), local Parquet cache | none |

Same rows, same records, same death counts on the three downloads compared. Each package fits a different workflow; the vignette says which.

## Installation

From CRAN (0.2.0):

```r
install.packages("healthbR")
```

The development version, with the SIH mirror and the newest year coverage, from GitHub:

```r
# install.packages("pak")
pak::pak("SidneyBissoli/healthbR")
```

## Quick start

```r
library(healthbR)

# see all available data sources
list_sources()
```

### DATASUS modules

All DATASUS modules follow a consistent API: `*_years()`, `*_info()`, `*_variables()`, `*_dictionary()`, `*_data()`, `*_cache_status()`, `*_clear_cache()`.

```r
# mortality data -- deaths in Acre, 2022
obitos <- sim_data(year = 2022, uf = "AC")

# filter by cause of death (CID-10 prefix)
obitos_cardio <- sim_data(year = 2022, uf = "AC", cause = "I")

# live births in Acre, 2022
nascimentos <- sinasc_data(year = 2022, uf = "AC")

# hospital admissions in Acre, January 2022
internacoes <- sih_data(year = 2022, month = 1, uf = "AC")

# filter by diagnosis (CID-10 prefix)
intern_resp <- sih_data(year = 2022, month = 1, uf = "AC", diagnosis = "J")

# outpatient production in Acre, January 2022
ambulatorial <- sia_data(year = 2022, month = 1, uf = "AC")

# different file type (e.g., high-cost medications)
medicamentos <- sia_data(year = 2022, month = 1, uf = "AC", type = "AM")
```

### Additional DATASUS modules

```r
# disease notifications -- dengue, 2022
dengue <- sinan_data(year = 2022, disease = "DENG")

# health facilities in Acre, January 2023
cnes <- cnes_data(year = 2023, month = 1, uf = "AC")

# vaccination data -- Acre (R2 mirror by default, DATASUS fallback)
vacinas <- sipni_data(year = 2019, uf = "AC")
micro <- sipni_data(year = 2024, uf = "AC", month = 1)
```

### Survey modules

```r
# VIGITEL telephone survey
vigitel <- vigitel_data(year = 2024)

# PNS national health survey
pns <- pns_data(year = 2019)

# PNAD Continua
pnadc <- pnadc_data(year = 2023, quarter = 1)

# POF household budget survey
pof <- pof_data(year = 2018, register = "morador")

# Census population
pop <- censo_populacao(year = 2022, territorial_level = "state")
```

### Primary care & regulatory agencies

```r
# SISAB -- primary care coverage by state, January 2024
sisab <- sisab_data(year = 2024, month = 1)

# ANS -- health plan beneficiaries in Acre, December 2023
ans <- ans_data(year = 2023, month = 12, uf = "AC")

# ANVISA -- registered medicines
med <- anvisa_data(type = "medicines")
```

### Explore variables and dictionaries

```r
# list variables for any module
sim_variables()
sia_variables(search = "sexo")
sinan_diseases(search = "dengue")

# data dictionary with category labels
sim_dictionary("SEXO")
sia_dictionary("PA_RACACOR")
```

## Parallel downloads

When downloading multiple files (e.g., several years, months, or states), you
can speed up downloads by enabling parallel processing. Install `furrr` and
`future`, then set a parallel plan before calling any `*_data()` function:

```r
install.packages(c("furrr", "future"))

library(future)
plan(multisession, workers = 4)

# downloads 4 states in parallel
df <- sih_data(year = 2022, month = 1:6, uf = c("SP", "RJ", "MG", "BA"))

# reset to sequential when done
plan(sequential)
```

All 12 download-based modules support parallel downloads: SIM, SINASC, SIH, SIA, SINAN, CNES, SI-PNI, SISAB, ANS, ANVISA, PNS, and PNADC.

## Caching

All modules cache downloaded data automatically. Install `arrow` for optimized Parquet caching:

```r
install.packages("arrow")
```

Each module provides cache management functions:

```r
# check what is cached
sim_cache_status()
sih_cache_status()
sia_cache_status()

# clear cache for a module
sim_clear_cache()
```

## Data sources

All data is downloaded from official Brazilian government repositories (DATASUS, IBGE, ANS, ANVISA):

- **VIGITEL**: Ministry of Health
- **PNS / PNAD Continua / POF / Censo**: IBGE
- **SIM / SINASC / SIA / SINAN / CNES**: DATASUS FTP
- **SIH / SI-PNI**: [healthbr-data](https://github.com/SidneyBissoli/healthbr-data)
  mirror on Cloudflare R2 (byte-identical to the Ministry's files, with
  provenance metadata), falling back to DATASUS FTP / OpenDataSUS
- **SISAB**: Ministry of Health REST API
- **ANS**: ANS Open Data Portal
- **ANVISA**: ANVISA Open Data Portal

## Citation

If you use healthbR in your research, please cite it:

```r
citation("healthbR")
```

## Contributing

Please see [CONTRIBUTING.md](https://github.com/SidneyBissoli/healthbR/blob/main/CONTRIBUTING.md) for guidelines on how to contribute to this project.

## Code of Conduct

Please note that the healthbR project is released with a [Contributor Code of Conduct](https://github.com/SidneyBissoli/healthbR/blob/main/CODE_OF_CONDUCT.md). By contributing to this project, you agree to abide by its terms.

## License

MIT © Sidney da Silva Pereira Bissoli
