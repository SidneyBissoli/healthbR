# Vaccination Data with SI-PNI

## Overview

The **SI-PNI (Sistema de Informacao do Programa Nacional de
Imunizacoes)** is Brazil’s national immunization information system,
managed by the Ministry of Health. It tracks vaccination doses applied
and coverage rates across the country.

The `healthbR` package provides access to SI-PNI data from **two
sources**:

| Source              | Years     | Data type                  | Granularity      | Format             |
|---------------------|-----------|----------------------------|------------------|--------------------|
| **FTP DATASUS**     | 1994–2019 | Aggregated counts          | Annual per UF    | .DBF files         |
| **OpenDataSUS CSV** | 2020–2025 | Individual-level microdata | Monthly national | CSV bulk downloads |

[`sipni_data()`](https://sidneybissoli.github.io/healthbR/reference/sipni_data.md)
automatically routes to the correct source based on the requested year.

## Data sources comparison

| Feature     | FTP (1994–2019)                                       | CSV (2020–2025)                           |
|-------------|-------------------------------------------------------|-------------------------------------------|
| Record type | Aggregated (dose counts per municipality/vaccine/age) | Individual (one row per vaccination dose) |
| File types  | DPNI (doses) or CPNI (coverage)                       | Single type (microdata)                   |
| Variables   | 7–12 per type                                         | ~47 per record                            |
| File size   | Small (~100 KB per UF/year)                           | Large (~1.4 GB ZIP per month, national)   |
| Naming      | UPPERCASE column names                                | snake_case column names                   |

## Getting started

``` r
library(healthbR)
library(dplyr)
```

### Check available years

``` r
sipni_years()
#> [1] 1994 1995 ... 2024 2025
```

### Module information

``` r
sipni_info()
```

## FTP path: doses applied (DPNI)

The default type downloads aggregated dose counts (1994–2019):

``` r
# doses applied in Acre, 2019
ac_doses <- sipni_data(year = 2019, uf = "AC")
ac_doses
```

### Key variables (DPNI)

| Variable  | Description                         |
|-----------|-------------------------------------|
| ANO       | Reference year                      |
| UF        | UF code (IBGE 2 digits)             |
| MUNIC     | Municipality code (IBGE 6 digits)   |
| IMUNO     | Immunobiological code               |
| DOSE      | Dose type (1st, 2nd, booster, etc.) |
| QT_DOSE   | Number of doses applied             |
| FX_ETARIA | Age group (coded)                   |

### Using the dictionary

``` r
# vaccine codes
sipni_dictionary("IMUNO")

# dose types
sipni_dictionary("DOSE")

# age groups
sipni_dictionary("FX_ETARIA")
```

## FTP path: vaccination coverage (CPNI)

The CPNI type provides coverage rates per municipality:

``` r
# vaccination coverage in Acre, 2019
ac_coverage <- sipni_data(year = 2019, type = "CPNI", uf = "AC")
ac_coverage
```

### Key variables (CPNI)

| Variable | Description                       |
|----------|-----------------------------------|
| ANO      | Reference year                    |
| UF       | UF code (IBGE 2 digits)           |
| MUNIC    | Municipality code (IBGE 6 digits) |
| IMUNO    | Immunobiological code             |
| QT_DOSE  | Number of doses applied           |
| POP      | Target population                 |
| COBERT   | Vaccination coverage (%)          |

## CSV path: individual-level microdata (2020+)

For years 2020 and later, SI-PNI provides individual-level microdata
(one row per vaccination dose). The `type` parameter is ignored for
these years:

``` r
# microdata for Acre, January 2024
ac_micro <- sipni_data(year = 2024, uf = "AC", month = 1)
ac_micro
```

### Key variables (CSV microdata)

| Variable                         | Description               |
|----------------------------------|---------------------------|
| sigla_uf_estabelecimento         | UF of the health facility |
| codigo_municipio_estabelecimento | Municipality (IBGE)       |
| tipo_sexo_paciente               | Sex (M/F)                 |
| numero_idade_paciente            | Patient age               |
| nome_raca_cor_paciente           | Race/color (descriptive)  |
| descricao_vacina                 | Vaccine name              |
| descricao_dose_vacina            | Dose description          |
| data_vacina                      | Vaccination date          |

### Exploring variables

``` r
# DPNI variables (FTP)
sipni_variables()

# CPNI variables (FTP)
sipni_variables(type = "CPNI")

# API/CSV variables (2020+)
sipni_variables(type = "API")

# search
sipni_variables(search = "dose")
```

## Month parameter for CSV data

For years \>= 2020, each month is a separate ~1.4 GB national CSV file.
Use `month` to select specific months:

``` r
# single month
jan <- sipni_data(year = 2024, uf = "AC", month = 1)

# first quarter
q1 <- sipni_data(year = 2024, uf = "AC", month = 1:3)

# all 12 months (default, downloads ~17 GB total)
full_year <- sipni_data(year = 2024, uf = "AC")
```

For FTP data (1994–2019), the `month` parameter is ignored because FTP
files are annual.

## Example: vaccine doses by immunobiological (FTP)

``` r
ac_2019 <- sipni_data(year = 2019, uf = "AC")

# decode immunobiological names
imuno_labels <- sipni_dictionary("IMUNO") |>
  select(code, label)

doses_by_vaccine <- ac_2019 |>
  group_by(IMUNO) |>
  summarize(total_doses = sum(as.integer(QT_DOSE), na.rm = TRUE),
            .groups = "drop") |>
  left_join(imuno_labels, by = c("IMUNO" = "code")) |>
  arrange(desc(total_doses))

doses_by_vaccine
```

## Example: coverage trends over time

``` r
# coverage data for Sao Paulo, 2015-2019
sp_cov <- sipni_data(
  year = 2015:2019,
  type = "CPNI",
  uf = "SP"
)

# average coverage by year
sp_cov |>
  group_by(year) |>
  summarize(
    mean_coverage = mean(as.numeric(COBERT), na.rm = TRUE),
    .groups = "drop"
  )
```

## Example: individual-level analysis (2020+)

``` r
# COVID-19 vaccinations in Acre, January 2024
ac_jan <- sipni_data(year = 2024, uf = "AC", month = 1)

# vaccines administered
ac_jan |>
  count(descricao_vacina, sort = TRUE)

# doses by sex
ac_jan |>
  count(tipo_sexo_paciente)

# age distribution
ac_jan |>
  mutate(age = as.integer(numero_idade_paciente)) |>
  filter(!is.na(age)) |>
  mutate(age_group = cut(age,
                         breaks = c(0, 5, 12, 18, 30, 60, Inf),
                         right = FALSE)) |>
  count(age_group)
```

## Mixed year requests

When requesting years that span both sources (e.g., 2019 and 2024),
[`sipni_data()`](https://sidneybissoli.github.io/healthbR/reference/sipni_data.md)
fetches from FTP and CSV respectively and combines the results. Note
that column names and structure differ between sources:

``` r
# this downloads FTP (2019) + CSV (2024)
mixed <- sipni_data(year = c(2019, 2024), uf = "AC", month = 1)

# columns from FTP (UPPERCASE) and CSV (snake_case) are combined
# with NAs where columns don't overlap
names(mixed)
```

## Download tips

- **FTP files** (1994–2019) are small (~100 KB each) and download
  quickly.
- **CSV files** (2020+) are large (~1.4 GB per month, national). Start
  with a single month and UF.
- The first download of a CSV month caches **all 27 UFs**. A second
  request for a different UF from the same month is instant from cache.
- Multiple months are downloaded concurrently when possible.

## Smart type parsing

``` r
# parsed types (default)
ac <- sipni_data(year = 2019, uf = "AC")
class(ac$QT_DOSE)  # integer

# raw character columns
ac_raw <- sipni_data(year = 2019, uf = "AC", parse = FALSE)
```

## Cache management

Downloaded data is cached locally for faster future access:

``` r
# check cache status
sipni_cache_status()

# clear cache if needed
sipni_clear_cache()
```

If the `arrow` package is installed, data is cached in Parquet format.
You can also use lazy evaluation:

``` r
# lazy query for FTP data (requires arrow)
sipni_lazy <- sipni_data(year = 2019, uf = "AC", lazy = TRUE)
sipni_lazy |>
  filter(QT_DOSE > 0) |>
  select(IMUNO, DOSE, QT_DOSE) |>
  collect()
```

## Additional resources

- OpenDataSUS (`dadosabertos.saude.gov.br`)
- [Census
  vignette](https://sidneybissoli.github.io/healthbR/articles/censo-denominadores.md)
  for population denominators
