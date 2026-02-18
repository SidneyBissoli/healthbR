# healthbR <img src="man/figures/logo.png" align="right" height="139" alt="" />
<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN status](https://www.r-pkg.org/badges/version/healthbR)](https://CRAN.R-project.org/package=healthbR)
[![R-CMD-check](https://github.com/SidneyBissoli/healthbR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/SidneyBissoli/healthbR/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/SidneyBissoli/healthbR/graph/badge.svg)](https://app.codecov.io/gh/SidneyBissoli/healthbR)
<!-- badges: end -->

## Overview

healthbR provides easy access to Brazilian public health data directly from R. The package downloads, caches, and processes data from official sources, returning clean, analysis-ready tibbles following tidyverse conventions.

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
| **SIH** | Hospital Information System (admissions) | Monthly/UF | 2008--2024 |
| **SIA** | Outpatient Information System (13 file types) | Monthly/UF | 2008--2024 |
| **SINAN** | Notifiable Diseases Surveillance (31 diseases) | Annual/UF | 2007--2024 |
| **CNES** | National Health Facility Registry (13 file types) | Monthly/UF | 2005--2024 |
| **SI-PNI** | National Immunization Program (FTP 1994--2019, CSV 2020+) | Annual or Monthly/UF | 1994--2025 |

DATASUS modules download `.dbc` files (compressed DBF) and decompress them internally using vendored C code -- no external dependencies required.

### Primary Care & Regulatory Agencies

| Module | Source | Description | Years |
|--------|--------|-------------|-------|
| **SISAB** | Ministry of Health REST API | Primary Care coverage indicators (APS, oral health, community agents, PNS) | 2007--present |
| **ANS** | ANS Open Data Portal | Supplementary health beneficiaries, consumer complaints, financial statements | 2007--present |
| **ANVISA** | ANVISA Open Data Portal | Product registrations, pharmacovigilance, hemovigilance, technovigilance, SNGPC | snapshot + 2014--present |

## Installation

You can install the development version of healthbR from GitHub:

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

# vaccination data -- Acre, 2019 (FTP) or 2024 (CSV)
vacinas <- sipni_data(year = 2019, uf = "AC")
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

All data is downloaded from official Brazilian government repositories:

- **VIGITEL**: Ministry of Health
- **PNS / PNAD Continua / POF / Censo**: IBGE
- **SIM / SINASC / SIH / SIA / SINAN / CNES / SI-PNI**: DATASUS FTP
- **SISAB**: Ministry of Health REST API
- **ANS**: ANS Open Data Portal
- **ANVISA**: ANVISA Open Data Portal

## Citation

If you use healthbR in your research, please cite it:

```r
citation("healthbR")
```

## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute to this project.

## Code of Conduct

Please note that the healthbR project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By contributing to this project, you agree to abide by its terms.

## License

MIT © Sidney da Silva Pereira Bissoli
