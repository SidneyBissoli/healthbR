# Introduction to healthbR

## Overview

healthbR provides easy access to Brazilian public health data directly
from R. The package downloads, caches, and processes data from official
sources (Ministry of Health, IBGE, DATASUS), returning clean,
analysis-ready tibbles following tidyverse conventions.

The package currently supports **13 data sources** organized in two
groups:

**Surveys (IBGE / Ministry of Health)**

| Module        | Source                                             | Years      |
|---------------|----------------------------------------------------|------------|
| VIGITEL       | Telephone survey on chronic disease risk factors   | 2006–2024  |
| PNS           | National Health Survey (microdata + SIDRA API)     | 2013, 2019 |
| PNAD Continua | Continuous household survey (health supplements)   | 2012–2024  |
| POF           | Household budget survey (food security, nutrition) | 2002–2018  |
| Censo         | Population denominators via SIDRA API              | 1970–2022  |

**DATASUS (Ministry of Health FTP)**

| Module | Source                                       | Granularity     | Years        |
|--------|----------------------------------------------|-----------------|--------------|
| SIM    | Mortality (death certificates)               | Annual/UF       | 1996–2024    |
| SINASC | Live births                                  | Annual/UF       | 1996–2024    |
| SIH    | Hospital admissions (AIH)                    | Monthly/UF      | 2008–2024    |
| SIA    | Outpatient procedures (13 file types)        | Monthly/UF      | 2008–2024    |
| SINAN  | Notifiable diseases (31 diseases)            | Annual/National | 2007–2024    |
| CNES   | Health facility registry (13 file types)     | Monthly/UF      | 2005–2024    |
| SI-PNI | Vaccination (aggregated FTP + microdata API) | Annual/UF       | 1994–2025    |
| SISAB  | Primary care coverage indicators (REST API)  | Monthly         | 2007–present |

## Getting started

``` r
library(healthbR)
library(dplyr)
```

To see all available data sources at a glance:

``` r
list_sources()
#> # A tibble: 13 x 5
#>    source  name                         description                    years       status
#>    <chr>   <chr>                        <chr>                          <chr>       <chr>
#>  1 vigitel VIGITEL                      Telephone survey on chronic... 2006-2024   available
#>  2 pns     PNS - Pesquisa Nacional ...  National health survey (IBGE) 2013, 2019  available
#>  ...
```

All modules follow a consistent API pattern:

- `*_years()` / `*_info()` – metadata and available years
- `*_variables()` / `*_dictionary()` – variable names and category
  labels
- `*_data()` – download and load data
- `*_cache_status()` / `*_clear_cache()` – cache management

## VIGITEL – Chronic disease risk factors

VIGITEL is a telephone survey conducted annually in all 27 state
capitals, monitoring risk and protective factors for chronic
non-communicable diseases.

``` r
# check available years
vigitel_years()

# download data for a single year
df <- vigitel_data(year = 2024)

# explore the data dictionary
dict <- vigitel_dictionary()

# list variables
vigitel_variables()
```

Key variables include `pesorake` (survey weight), `diab` (diabetes),
`hart` (hypertension), `fumante` (smoker), and `imc` (BMI).

``` r
# weighted prevalence of diabetes by city using srvyr
library(srvyr)

df |>
  as_survey_design(weights = pesorake) |>
  group_by(cidade) |>
  summarize(
    prevalence = survey_mean(diab == 1, na.rm = TRUE),
    n = unweighted(n())
  )
```

## PNS – National Health Survey

The PNS provides comprehensive data on health conditions, lifestyle, and
healthcare access from ~100,000 households.

``` r
# microdata
pns <- pns_data(year = 2019)

# explore modules and variables
pns_modules(year = 2019)
pns_dictionary(year = 2019)

# tabulated indicators from SIDRA API (no download needed)
pns_sidra_search("diabetes")
pns_sidra_data(table = 4487, territorial_level = "state", year = 2019)
```

## PNAD Continua – Household survey supplements

PNAD Continua includes health-related supplementary modules on
disability, housing conditions, primary health care (APS), and household
characteristics.

``` r
# list available modules
pnadc_modules()

# download disability supplement
defic <- pnadc_data(module = "deficiencia", year = 2019, quarter = 1)

# explore variables
pnadc_variables(module = "deficiencia")
```

## POF – Food security and nutrition

The POF (Household Budget Survey) contains data on food insecurity
(EBIA), individual food consumption, anthropometry, and health expenses.

``` r
# list available registers
pof_registers(year = 2018)

# food consumption microdata
consumo <- pof_data(year = 2018, register = "consumo_alimentar")

# food insecurity scale (EBIA)
morador <- pof_data(year = 2018, register = "morador")

# variable dictionary for a specific register
pof_dictionary(year = 2018, register = "morador")
```

See
[`vignette("pof-health-data")`](https://sidneybissoli.github.io/healthbR/articles/pof-health-data.md)
for a detailed walkthrough.

## Censo – Population denominators

The Census module queries the IBGE SIDRA API for population
denominators, essential for calculating mortality rates, incidence, and
other epidemiological indicators.

``` r
# population by state, sex, and age group (2022 Census)
pop <- censo_populacao(year = 2022, territorial_level = "state")

# intercensitary population estimates (for years between censuses)
est <- censo_estimativa(year = 2020, territorial_level = "state")

# query any Census SIDRA table directly
censo_sidra_search("populacao")
censo_sidra_data(table = 9514, territorial_level = "brazil", year = 2022)
```

See
[`vignette("censo-denominadores")`](https://sidneybissoli.github.io/healthbR/articles/censo-denominadores.md)
for epidemiological examples.

## SIM – Mortality data

SIM contains individual death records from death certificates (CID-10,
1996+).

``` r
# deaths in Acre, 2022
obitos <- sim_data(year = 2022, uf = "AC")

# filter by cause of death (CID-10 prefix)
obitos_cardio <- sim_data(year = 2022, uf = "AC", cause = "I")

# explore variables and categories
sim_variables()
sim_dictionary("CAUSABAS")
```

## SINASC – Live births

SINASC contains individual birth records including birth weight,
gestational age, prenatal care, and congenital anomalies.

``` r
# births in Acre, 2022
nascimentos <- sinasc_data(year = 2022, uf = "AC")

# filter by congenital anomaly (CID-10 prefix)
anomalias <- sinasc_data(year = 2022, uf = "AC", anomaly = "Q")

sinasc_variables()
sinasc_dictionary("PARTO")
```

## SIH – Hospital admissions

SIH contains hospital admission records (AIH) with diagnosis,
procedures, length of stay, and costs. Data is organized monthly.

``` r
# admissions in Acre, January 2022
internacoes <- sih_data(year = 2022, month = 1, uf = "AC")

# filter by principal diagnosis (CID-10 prefix)
intern_resp <- sih_data(year = 2022, month = 1, uf = "AC", diagnosis = "J")

sih_variables()
sih_dictionary("DIAG_PRINC")
```

## SIA – Outpatient procedures

SIA covers outpatient production data with 13 file types (BPA, APAC,
RAAS).

``` r
# outpatient production in Acre, January 2022 (default type: PA)
ambulatorial <- sia_data(year = 2022, month = 1, uf = "AC")

# high-cost medications (APAC)
medicamentos <- sia_data(year = 2022, month = 1, uf = "AC", type = "AM")

# filter by procedure or diagnosis
sia_data(year = 2022, month = 1, uf = "AC", procedure = "0301")
sia_data(year = 2022, month = 1, uf = "AC", diagnosis = "E11")
```

## SINAN – Notifiable diseases

SINAN contains individual notification records for 31 notifiable
diseases including dengue, tuberculosis, chikungunya, zika, hepatitis,
syphilis, and others. Files are **national** (not per-state), so each
download covers all of Brazil for a given disease and year.

``` r
# list available diseases
sinan_diseases()

# search for a specific disease
sinan_diseases(search = "dengue")

# dengue notifications, 2022
dengue <- sinan_data(year = 2022, disease = "DENG")

# tuberculosis, 2020-2022
tb <- sinan_data(year = 2020:2022, disease = "TUBE")

# explore variables and categories
sinan_variables()
sinan_dictionary("EVOLUCAO")
```

Since SINAN files are national, filter by state after download using
`SG_UF_NOT` (UF of notification) or `ID_MUNICIP` (municipality code):

``` r
dengue |>
  filter(SG_UF_NOT == "35")  # Sao Paulo
```

## CNES – Health facility registry

CNES is the national registry of health facilities, covering hospitals,
clinics, primary care units, and all other health establishments. Data
is organized monthly with 13 file types.

``` r
# see all file types
cnes_info()

# establishments in Acre, January 2023
estab <- cnes_data(year = 2023, month = 1, uf = "AC")

# hospital beds
leitos <- cnes_data(year = 2023, month = 1, uf = "AC", type = "LT")

# health professionals
prof <- cnes_data(year = 2023, month = 1, uf = "AC", type = "PF")

# explore variables and categories
cnes_variables()
cnes_dictionary("TP_UNID")
```

See
[`vignette("datasus-modules")`](https://sidneybissoli.github.io/healthbR/articles/datasus-modules.md)
for cross-module analysis examples.

## SI-PNI – Vaccination data

SI-PNI data comes from two sources: **FTP** (1994–2019) with aggregated
dose counts and coverage rates, and the **OpenDataSUS API** (2020–2025)
with individual-level microdata (one row per vaccination dose).
[`sipni_data()`](https://sidneybissoli.github.io/healthbR/reference/sipni_data.md)
routes transparently based on the requested year.

``` r
# module overview
sipni_info()

# FTP: doses applied in Acre, 2019 (aggregated)
doses <- sipni_data(year = 2019, uf = "AC")

# FTP: vaccination coverage
cobertura <- sipni_data(year = 2019, type = "CPNI", uf = "AC")

# API: microdata for Acre, January 2024
micro <- sipni_data(year = 2024, uf = "AC", month = 1)

# explore variables for each data source
sipni_variables()                  # FTP DPNI variables
sipni_variables(type = "API")      # API microdata variables
sipni_dictionary("IMUNO")          # FTP dictionary
```

## SISAB – Primary care coverage

SISAB provides aggregated coverage indicators for primary care (Atencao
Primaria) via a public REST API. Unlike other DATASUS modules, no FTP
download or .dbc decompression is needed.

``` r
# module overview
sisab_info()

# APS coverage by state, January 2024
cobertura <- sisab_data(year = 2024, month = 1)

# national total, full year 2023
sisab_data(year = 2023, level = "brazil")

# oral health coverage
sisab_data(year = 2024, type = "sb", month = 6)

# municipality level for Sao Paulo
sisab_data(year = 2024, level = "municipality", uf = "SP", month = 1)

# explore variables
sisab_variables()
sisab_variables(type = "sb")
```

## Caching

All modules cache downloaded data automatically to avoid repeated
downloads. Install `arrow` for optimized Parquet caching (recommended):

``` r
install.packages("arrow")
```

Cache management works the same across all modules:

``` r
# check what is cached
sim_cache_status()
vigitel_cache_status()

# clear a module's cache
sim_clear_cache()

# use a custom cache directory (e.g., for temporary use)
sim_data(year = 2022, uf = "AC", cache_dir = tempdir())
```

## Combining modules

healthbR’s real power comes from combining data across modules. For
example, calculating mortality rates requires deaths (SIM) and
population (Censo):

``` r
library(dplyr)

# deaths by state
deaths <- sim_data(year = 2022, uf = "AC") |>
  count(name = "deaths")

# population by state
pop <- censo_populacao(year = 2022, territorial_level = "state") |>
  filter(nivel_territorial_codigo == "12")  # Acre

# crude mortality rate
deaths$deaths / pop$valor * 100000
```

## Additional resources

- [`vignette("pof-health-data")`](https://sidneybissoli.github.io/healthbR/articles/pof-health-data.md)
  – Analyzing food security and nutrition from POF
- [`vignette("censo-denominadores")`](https://sidneybissoli.github.io/healthbR/articles/censo-denominadores.md)
  – Population denominators for epidemiology
- [`vignette("datasus-modules")`](https://sidneybissoli.github.io/healthbR/articles/datasus-modules.md)
  – SIM, SINASC, SIH, SIA, SINAN, and CNES in depth
- [Package website](https://sidneybissoli.github.io/healthbR/)
- [GitHub repository](https://github.com/SidneyBissoli/healthbR)
