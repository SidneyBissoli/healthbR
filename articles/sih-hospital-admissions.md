# Hospital Admissions from SIH with healthbR

## Overview

The **SIH (Sistema de Informacoes Hospitalares)** records all hospital
admissions financed by the Brazilian public health system (SUS) through
the *Autorizacao de Internacao Hospitalar* (AIH). It is managed by the
Ministry of Health through DATASUS.

| Feature     | Details                              |
|-------------|--------------------------------------|
| Coverage    | Per state (UF), all 27 states        |
| Years       | 2008–2024                            |
| Granularity | Monthly (one file per UF/month)      |
| Unit        | One row per hospital admission (AIH) |
| Format      | .dbc files from DATASUS FTP          |

## Getting started

``` r
library(healthbR)
library(dplyr)
```

### Check available years

``` r
sih_years()
sih_years(status = "all")
```

### Module information

``` r
sih_info()
```

## Downloading data

### Basic download

``` r
# All months of 2022 for Acre
admissions <- sih_data(year = 2022, uf = "AC")
```

### Specific months

``` r
# First semester only
admissions <- sih_data(year = 2022, uf = "SP", month = 1:6)

# Single month
admissions <- sih_data(year = 2022, uf = "SP", month = 3)
```

### Filter by diagnosis

Use CID-10 code prefixes to filter the principal diagnosis:

``` r
# Acute myocardial infarction (I21)
mi <- sih_data(year = 2022, uf = "SP", diagnosis = "I21")

# All respiratory diseases (Chapter X)
respiratory <- sih_data(year = 2022, uf = "SP", diagnosis = "J")

# Dengue (A90-A91)
dengue_hosp <- sih_data(year = 2022, uf = "SP", diagnosis = "A9")
```

### Select variables

``` r
admissions <- sih_data(
  year = 2022,
  uf = "SP",
  month = 1,
  vars = c("DIAG_PRINC", "DT_INTER", "DT_SAIDA", "SEXO",
           "MORTE", "MUNIC_RES", "VAL_TOT")
)
```

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

``` r
sih_dictionary()
sih_dictionary("SEXO")
sih_dictionary("MORTE")
```

### Explore variables

``` r
sih_variables()
sih_variables(search = "diag")
sih_variables(search = "valor")
```

## Example: Hospital mortality by diagnosis chapter

``` r
admissions <- sih_data(year = 2022, uf = "SP", month = 1:6)

mortality <- admissions |>
  mutate(chapter = substr(DIAG_PRINC, 1, 1)) |>
  group_by(chapter) |>
  summarise(
    total = n(),
    deaths = sum(MORTE == "1", na.rm = TRUE),
    mortality_rate = deaths / total * 100
  ) |>
  arrange(desc(mortality_rate))
```

## Example: Hospitalization costs

``` r
admissions <- sih_data(year = 2022, uf = "SP", month = 1)

costs <- admissions |>
  mutate(
    chapter = substr(DIAG_PRINC, 1, 1),
    cost = as.numeric(VAL_TOT)
  ) |>
  group_by(chapter) |>
  summarise(
    admissions = n(),
    total_cost = sum(cost, na.rm = TRUE),
    mean_cost = mean(cost, na.rm = TRUE)
  ) |>
  arrange(desc(total_cost))
```

## Example: Seasonal patterns

``` r
# respiratory admissions across all months
resp <- sih_data(year = 2022, uf = "SP", diagnosis = "J")

seasonal <- resp |>
  count(month, name = "admissions") |>
  arrange(month)
```

## Smart type parsing

``` r
# parsed types (default)
admissions <- sih_data(year = 2022, uf = "AC", month = 1)
class(admissions$DT_INTER)  # Date
class(admissions$VAL_TOT)   # double

# all character
admissions_raw <- sih_data(year = 2022, uf = "AC", month = 1, parse = FALSE)
```

## Cache and lazy evaluation

``` r
sih_cache_status()
sih_clear_cache()

# lazy query
lazy <- sih_data(year = 2022, uf = "SP", lazy = TRUE)
lazy |>
  filter(MORTE == "1") |>
  select(DIAG_PRINC, DT_INTER, SEXO, MUNIC_RES) |>
  collect()
```

## Further reading

- [SIH on
  DATASUS](https://datasus.saude.gov.br/transferencia-de-arquivos/)
- [SIGTAP procedure table](http://sigtap.datasus.gov.br/)
- [SIA
  vignette](https://sidneybissoli.github.io/healthbR/articles/sia-outpatient.md)
  for outpatient data
