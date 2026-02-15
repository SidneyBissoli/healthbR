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

``` r
library(healthbR)
library(dplyr)
```

### Check available years

``` r
sim_years()

# include preliminary data
sim_years(status = "all")
```

### Module information

``` r
sim_info()
```

## Downloading data

### Basic download (one state, one year)

``` r
deaths_ac <- sim_data(year = 2022, uf = "AC")
```

### Multiple states and years

``` r
deaths_se <- sim_data(year = 2020:2022, uf = c("SP", "RJ", "MG"))
```

### All states (default)

``` r
# downloads all 27 states -- may take several minutes
deaths_all <- sim_data(year = 2022)
```

### Filter by cause of death

Use CID-10 code prefixes to filter by cause:

``` r
# Acute myocardial infarction (I21)
mi <- sim_data(year = 2022, uf = "SP", cause = "I21")

# All cardiovascular diseases (Chapter IX)
cardio <- sim_data(year = 2022, uf = "SP", cause = "I")

# All neoplasms (Chapter II)
cancer <- sim_data(year = 2022, uf = "SP", cause = "C")
```

### Select variables

``` r
deaths <- sim_data(
  year = 2022,
  uf = "SP",
  vars = c("CAUSABAS", "DTOBITO", "SEXO", "IDADE", "RACACOR", "CODMUNRES")
)
```

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

``` r
deaths <- sim_data(year = 2022, uf = "AC")
deaths$age_years  # numeric age in years

# disable decoding
deaths_raw <- sim_data(year = 2022, uf = "AC", decode_age = FALSE)
```

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

``` r
sim_dictionary()
sim_dictionary("SEXO")
sim_dictionary("RACACOR")
```

### Explore variables

``` r
sim_variables()
sim_variables(search = "causa")
```

## Example: Mortality by cause chapter

``` r
deaths <- sim_data(year = 2022, uf = "SP")

deaths |>
  mutate(chapter = substr(CAUSABAS, 1, 1)) |>
  count(chapter, sort = TRUE)
```

## Example: Age-specific mortality rate

Combine SIM data with Census population denominators:

``` r
# deaths by age group
deaths <- sim_data(year = 2022, uf = "SP") |>
  filter(!is.na(age_years)) |>
  mutate(age_group = cut(age_years,
    breaks = c(0, 1, 5, 15, 30, 45, 60, 80, Inf),
    right = FALSE
  )) |>
  count(age_group, name = "deaths")

# population from Census 2022
pop <- censo_populacao(year = 2022, territorial_level = "state", geo_code = "35")

# join and calculate rates per 100,000
```

## Smart type parsing

``` r
# parsed types (default)
deaths <- sim_data(year = 2022, uf = "AC")
class(deaths$DTOBITO)  # Date

# all character (backward-compatible)
deaths_raw <- sim_data(year = 2022, uf = "AC", parse = FALSE)
```

## Cache and lazy evaluation

``` r
sim_cache_status()
sim_clear_cache()

# lazy query (requires arrow)
lazy <- sim_data(year = 2022, uf = "SP", lazy = TRUE)
lazy |>
  filter(CAUSABAS >= "I20", CAUSABAS < "I26") |>
  collect()
```

## Further reading

- SIM on DATASUS (`datasus.saude.gov.br`)
- [SINASC
  vignette](https://sidneybissoli.github.io/healthbR/articles/sinan-notifiable-diseases.md)
  for live birth data
- [Census
  vignette](https://sidneybissoli.github.io/healthbR/articles/censo-denominadores.md)
  for population denominators
