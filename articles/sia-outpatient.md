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

``` r
library(healthbR)
library(dplyr)
```

### Check available years

``` r
sia_years()
sia_years(status = "all")
```

### Module information

``` r
sia_info()
```

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

``` r
outpatient <- sia_data(year = 2022, uf = "AC")
```

### Specific type

``` r
# chemotherapy/radiotherapy APAC records
chemo <- sia_data(year = 2022, uf = "SP", type = "AM")
```

### Specific months

``` r
outpatient <- sia_data(year = 2022, uf = "SP", month = 1:3)
```

### Filter by procedure

Use SIGTAP procedure code prefixes:

``` r
# Medical consultations (group 03.01)
consults <- sia_data(year = 2022, uf = "SP", month = 1, procedure = "0301")

# Imaging exams (group 02.04)
imaging <- sia_data(year = 2022, uf = "SP", month = 1, procedure = "0204")
```

### Filter by diagnosis

``` r
# Diabetes-related outpatient care (E10-E14)
diabetes <- sia_data(year = 2022, uf = "SP", month = 1, diagnosis = "E1")
```

### Select variables

``` r
outpatient <- sia_data(
  year = 2022,
  uf = "SP",
  month = 1,
  vars = c("PA_PROC_ID", "PA_CIDPRI", "PA_SEXO", "PA_IDADE",
           "PA_MUNPCN", "PA_VALAPR")
)
```

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

``` r
sia_dictionary()
sia_dictionary("PA_SEXO")
```

### Explore variables

``` r
sia_variables()
sia_variables(search = "valor")

# variables for a specific type
sia_variables(type = "AM")
```

## Example: Top procedures by volume

``` r
outpatient <- sia_data(year = 2022, uf = "SP", month = 1)

top_procedures <- outpatient |>
  count(PA_PROC_ID, sort = TRUE) |>
  head(20)
```

## Example: Outpatient spending by diagnosis

``` r
outpatient <- sia_data(year = 2022, uf = "SP", month = 1)

spending <- outpatient |>
  filter(!is.na(PA_CIDPRI), PA_CIDPRI != "") |>
  mutate(
    chapter = substr(PA_CIDPRI, 1, 1),
    value = as.numeric(PA_VALAPR)
  ) |>
  group_by(chapter) |>
  summarise(
    records = n(),
    total_value = sum(value, na.rm = TRUE)
  ) |>
  arrange(desc(total_value))
```

## Example: Chemotherapy APAC records

``` r
chemo <- sia_data(year = 2022, uf = "SP", type = "AM", month = 1:6)

chemo |>
  count(month, name = "records") |>
  arrange(month)
```

## Smart type parsing

``` r
# parsed types (default)
outpatient <- sia_data(year = 2022, uf = "AC", month = 1)
class(outpatient$PA_VALAPR)  # double

# all character
outpatient_raw <- sia_data(year = 2022, uf = "AC", month = 1, parse = FALSE)
```

## Cache and lazy evaluation

``` r
sia_cache_status()
sia_clear_cache()

# lazy query
lazy <- sia_data(year = 2022, uf = "SP", lazy = TRUE)
lazy |>
  filter(PA_CIDPRI >= "E10", PA_CIDPRI <= "E14") |>
  collect()
```

## Further reading

- [SIA on
  DATASUS](https://datasus.saude.gov.br/transferencia-de-arquivos/)
- [SIGTAP procedure
  table](https://wiki.saude.gov.br/sigtap/index.php/P%C3%A1gina_principal)
- [SIH
  vignette](https://sidneybissoli.github.io/healthbR/articles/sih-hospital-admissions.md)
  for hospital admission data
