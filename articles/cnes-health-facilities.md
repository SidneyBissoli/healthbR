# Health Facility Registry with CNES

## Overview

The **CNES (Cadastro Nacional de Estabelecimentos de Saude)** is
Brazil’s national health facility registry, maintained by the Ministry
of Health through DATASUS. It contains monthly snapshots of all
registered health establishments, professionals, beds, equipment, and
more.

The `healthbR` package provides access to CNES data from the DATASUS
FTP:

| Feature    | Details                                        |
|------------|------------------------------------------------|
| File types | 13 (establishments, beds, professionals, etc.) |
| Frequency  | Monthly (one file per type/UF/month)           |
| Years      | 2005–2024 (final + preliminary)                |
| Coverage   | Per state (27 UFs)                             |
| Format     | .dbc files, decompressed internally            |

## File types

CNES data is organized into 13 file types:

| Code   | Name                  | Description                        |
|--------|-----------------------|------------------------------------|
| **ST** | Estabelecimentos      | Health facility registry (default) |
| **LT** | Leitos                | Hospital beds                      |
| **PF** | Profissional          | Health professionals               |
| **DC** | Dados Complementares  | Supplementary facility data        |
| **EQ** | Equipamentos          | Health equipment                   |
| **SR** | Servico Especializado | Specialized services               |
| **HB** | Habilitacao           | Facility accreditations            |
| **EP** | Equipes               | Health teams                       |
| **RC** | Regra Contratual      | Contractual rules                  |
| **IN** | Incentivos            | Financial incentives               |
| **EE** | Estab. de Ensino      | Teaching facilities                |
| **EF** | Estab. Filantropico   | Philanthropic facilities           |
| **GM** | Gestao e Metas        | Management and targets             |

## Getting started

``` r
library(healthbR)
library(dplyr)
```

### Check available years

``` r
cnes_years()
#> [1] 2005 2006 ... 2023

cnes_years(status = "all")
#> [1] 2005 2006 ... 2023 2024
```

### Module information

``` r
cnes_info()
```

## Downloading data

### Basic download (establishments)

``` r
# all establishments in Acre, January 2023
ac_jan <- cnes_data(year = 2023, month = 1, uf = "AC")
ac_jan
```

### Hospital beds

``` r
leitos <- cnes_data(year = 2023, month = 1, uf = "AC", type = "LT")
leitos
```

### Health professionals

``` r
prof <- cnes_data(year = 2023, month = 1, uf = "AC", type = "PF")
prof
```

## Month parameter

The `month` parameter controls which monthly snapshots to download:

``` r
# single month
jan <- cnes_data(year = 2023, month = 1, uf = "AC")

# first semester
sem1 <- cnes_data(year = 2023, month = 1:6, uf = "AC")

# specific months
q1_q3 <- cnes_data(year = 2023, month = c(3, 6, 9), uf = "AC")

# all 12 months (default when month = NULL)
full_year <- cnes_data(year = 2023, uf = "AC")
```

### Selecting variables

``` r
# only key variables (faster)
cnes_data(
  year = 2023, month = 1, uf = "AC",
  vars = c("CNES", "CODUFMUN", "TP_UNID", "VINC_SUS")
)
```

## Key variables (ST type)

| Variable  | Description                                                        |
|-----------|--------------------------------------------------------------------|
| CNES      | Facility CNES code                                                 |
| CODUFMUN  | Municipality (UF + IBGE 6 digits)                                  |
| TP_UNID   | Facility type (22 categories)                                      |
| VINC_SUS  | SUS-linked (0=No, 1=Yes)                                           |
| TP_GESTAO | Management type (M=Municipal, E=State, D=Dual)                     |
| ESFERA_A  | Administrative sphere (1=Federal, 2=State, 3=Municipal, 4=Private) |
| TURNO_AT  | Operating hours                                                    |
| NIV_HIER  | Hierarchy level                                                    |
| ATV_AMBUL | Outpatient care (0/1)                                              |
| ATV_HOSP  | Hospital care (0/1)                                                |
| ATV_URG   | Emergency care (0/1)                                               |
| COMPETEN  | Reference period (YYYYMM)                                          |

### Using the dictionary

``` r
# all coded variables
cnes_dictionary()

# facility types (22 categories)
cnes_dictionary("TP_UNID")

# administrative sphere
cnes_dictionary("ESFERA_A")
```

### Joining dictionary labels

``` r
# get facility type labels
tp_unid_labels <- cnes_dictionary("TP_UNID") |>
  select(code, label)

# join to data
ac_facilities <- cnes_data(year = 2023, month = 1, uf = "AC") |>
  left_join(tp_unid_labels, by = c("TP_UNID" = "code")) |>
  rename(facility_type = label)

ac_facilities |>
  count(facility_type, sort = TRUE)
```

## Example: SUS-linked facilities by type

``` r
ac <- cnes_data(year = 2023, month = 1, uf = "AC")

sus_by_type <- ac |>
  filter(VINC_SUS == "1") |>
  count(TP_UNID, sort = TRUE)

# add labels
tp_labels <- cnes_dictionary("TP_UNID") |>
  select(code, label)

sus_by_type |>
  left_join(tp_labels, by = c("TP_UNID" = "code"))
```

## Example: hospital beds per capita

Combine CNES bed data with Census population:

``` r
# step 1: count beds by UF (December snapshot)
beds <- cnes_data(year = 2023, month = 12, type = "LT") |>
  group_by(uf_source) |>
  summarize(total_beds = n(), .groups = "drop")

# step 2: population from Census 2022
pop <- censo_populacao(year = 2022, territorial_level = "state")

# step 3: calculate beds per 1,000 inhabitants
# beds_rate <- beds |>
#   left_join(pop, by = ...) |>
#   mutate(beds_per_1000 = (total_beds / population) * 1000) |>
#   arrange(desc(beds_per_1000))
```

## Example: tracking facility counts over time

``` r
# quarterly snapshots for Sao Paulo
sp_quarterly <- cnes_data(
  year = 2020:2023,
  month = c(3, 6, 9, 12),
  uf = "SP"
)

facility_trend <- sp_quarterly |>
  group_by(year, month) |>
  summarize(
    total = n(),
    sus_linked = sum(VINC_SUS == "1", na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(year, month)

facility_trend
```

## Download tips

CNES data is monthly and per-state, so full downloads can involve many
files:

- **1 UF, 1 month, 1 type** = 1 file
- **1 UF, 12 months** = 12 files
- **27 UFs, 12 months** = 324 files per type

Use `uf` and `month` to limit downloads. Start with a single UF and
month to explore the data before scaling up.

## Smart type parsing

``` r
# parsed types (default)
ac <- cnes_data(year = 2023, month = 1, uf = "AC")
class(ac$COMPETEN)  # Date

# raw character columns
ac_raw <- cnes_data(year = 2023, month = 1, uf = "AC", parse = FALSE)
```

## Cache management

Downloaded data is cached locally for faster future access:

``` r
# check cache status
cnes_cache_status()

# clear cache if needed
cnes_clear_cache()
```

If the `arrow` package is installed, data is cached in Parquet format.
You can also use lazy evaluation:

``` r
# lazy query (requires arrow)
cnes_lazy <- cnes_data(year = 2023, uf = "AC", lazy = TRUE)
cnes_lazy |>
  filter(VINC_SUS == "1", month == 1L) |>
  select(CNES, CODUFMUN, TP_UNID) |>
  collect()
```

## Additional resources

- [CNES official page (DATASUS)](https://cnes.datasus.gov.br/)
- [CNES open
  data](https://dados.gov.br/dados/conjuntos-dados/cnes---cadastro-nacional-de-estabelecimentos-de-saude)
- [Census
  vignette](https://sidneybissoli.github.io/healthbR/articles/censo-denominadores.md)
  for population denominators
