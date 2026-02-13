# healthbR ![](reference/figures/logo.png)

## Overview

healthbR provides easy access to Brazilian public health data directly
from R. The package downloads, caches, and processes data from official
sources, returning clean, analysis-ready tibbles following tidyverse
conventions.

### Surveys (IBGE / Ministry of Health)

| Module            | Description                                                           | Years      |
|-------------------|-----------------------------------------------------------------------|------------|
| **VIGITEL**       | Surveillance of Risk Factors for Chronic Diseases by Telephone Survey | 2006–2024  |
| **PNS**           | National Health Survey (microdata + SIDRA API)                        | 2013, 2019 |
| **PNAD Continua** | Continuous National Household Sample Survey                           | 2012–2024  |
| **POF**           | Household Budget Survey (food security, consumption, anthropometry)   | 2002–2018  |
| **Censo**         | Population denominators via SIDRA API                                 | 1970–2022  |

### DATASUS (Ministry of Health FTP)

| Module     | Description                                   | Granularity     | Years     |
|------------|-----------------------------------------------|-----------------|-----------|
| **SIM**    | Mortality Information System (deaths)         | Annual/UF       | 1996–2024 |
| **SINASC** | Live Birth Information System                 | Annual/UF       | 1996–2024 |
| **SIH**    | Hospital Information System (admissions)      | Monthly/UF      | 2008–2024 |
| **SIA**    | Outpatient Information System (13 file types) | Monthly/type/UF | 2008–2024 |

DATASUS modules download `.dbc` files (compressed DBF) and decompress
them internally using vendored C code – no external dependencies
required.

## Installation

You can install the development version of healthbR from GitHub:

``` r
# install.packages("pak")
pak::pak("SidneyBissoli/healthbR")
```

## Quick start

``` r
library(healthbR)

# see all available data sources
list_sources()
```

### DATASUS modules

All DATASUS modules follow a consistent API: `*_years()`, `*_info()`,
`*_variables()`, `*_dictionary()`, `*_data()`, `*_cache_status()`,
`*_clear_cache()`.

``` r
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

### Survey modules

``` r
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

### Explore variables and dictionaries

``` r
# list variables for any module
sim_variables()
sia_variables(search = "sexo")

# data dictionary with category labels
sim_dictionary("SEXO")
sia_dictionary("PA_RACACOR")
```

## Caching

All modules cache downloaded data automatically. Install `arrow` for
optimized Parquet caching:

``` r
install.packages("arrow")
```

Each module provides cache management functions:

``` r
# check what is cached
sim_cache_status()
sih_cache_status()
sia_cache_status()

# clear cache for a module
sim_clear_cache()
```

## Data sources

All data is downloaded from official Brazilian government repositories:

- **VIGITEL**: <https://svs.aids.gov.br/daent/cgdnt/vigitel/>
- **PNS / PNAD Continua / POF**: <https://www.ibge.gov.br/>
- **Censo**: SIDRA API (<https://apisidra.ibge.gov.br/>)
- **SIM / SINASC / SIH / SIA**: DATASUS FTP
  (`ftp://ftp.datasus.gov.br/dissemin/publicos/`)

## Citation

If you use healthbR in your research, please cite it:

``` r
citation("healthbR")
```

## Contributing

Contributions are welcome! Please open an issue to discuss proposed
changes or submit a pull request.

## Code of Conduct

Please note that the healthbR project is released with a [Contributor
Code of
Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.

## License

MIT © Sidney da Silva Pereira Bissoli
