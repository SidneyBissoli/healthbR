# Primary Care Coverage with SISAB

## Overview

The **SISAB (Sistema de Informacao em Saude para a Atencao Basica)**
provides primary care coverage indicators for Brazil, maintained by the
Ministry of Health (SAPS). Unlike other DATASUS modules that use FTP,
SISAB data is fetched from a public REST API.

| Feature           | Details                                     |
|-------------------|---------------------------------------------|
| Source            | REST API (relatorioaps.saude.gov.br)        |
| Data type         | Aggregated coverage indicators              |
| Report types      | 4 (APS, oral health, community agents, PNS) |
| Geographic levels | 4 (Brazil, region, UF, municipality)        |
| Frequency         | Monthly (by CNES competencia)               |

## Report types

| Code    | Name                                  | Availability |
|---------|---------------------------------------|--------------|
| **aps** | APS coverage (primary care teams)     | 2019–present |
| **sb**  | Oral health coverage (dental teams)   | 2024–present |
| **acs** | Community health agents (ACS)         | 2007–present |
| **pns** | PNS coverage (National Health Survey) | 2020–2023    |

## Geographic levels

| Level            | Description           |
|------------------|-----------------------|
| `"brazil"`       | National total        |
| `"region"`       | 5 macro-regions       |
| `"uf"`           | 27 states (default)   |
| `"municipality"` | ~5,570 municipalities |

## Getting started

``` r
library(healthbR)
library(dplyr)
```

### Check available years

``` r
sisab_years()
```

### Module information

``` r
sisab_info()
```

## Basic download

### APS coverage by state (default)

``` r
# APS coverage by state, January 2024
aps_jan <- sisab_data(year = 2024, month = 1)
aps_jan
```

### Full year

``` r
# APS coverage, all months of 2023
aps_2023 <- sisab_data(year = 2023)
aps_2023
```

## Other report types

### Oral health coverage

``` r
sb <- sisab_data(year = 2024, type = "sb", month = 6)
sb
```

### Community health agents

``` r
acs <- sisab_data(year = 2023, type = "acs")
acs
```

### PNS coverage

``` r
pns <- sisab_data(year = 2022, type = "pns")
pns
```

## Geographic levels

### National total

``` r
national <- sisab_data(year = 2024, level = "brazil", month = 1)
national
```

### By region

``` r
regions <- sisab_data(year = 2024, level = "region", month = 1)
regions
```

### By state (default)

``` r
states <- sisab_data(year = 2024, level = "uf", month = 1)
states
```

### By municipality

``` r
# filter by UF to avoid large downloads
sp_munic <- sisab_data(
  year = 2024,
  level = "municipality",
  uf = "SP",
  month = 1
)
sp_munic
```

## Filtering by state and month

``` r
# single state, single month
sp_jan <- sisab_data(year = 2024, uf = "SP", month = 1)

# specific months
sp_q1 <- sisab_data(year = 2024, uf = "SP", month = 1:3)

# multiple years
sp_multi <- sisab_data(year = 2022:2024, uf = "SP", month = 6)
```

## Exploring variables

``` r
# APS variables (default)
sisab_variables()

# oral health variables
sisab_variables(type = "sb")

# community agents
sisab_variables(type = "acs")

# PNS variables
sisab_variables(type = "pns")

# search
sisab_variables(search = "cobertura")
sisab_variables(search = "equipe")
```

## Example: APS coverage by state

``` r
aps <- sisab_data(year = 2024, level = "uf", month = 6)

# coverage by state
aps |>
  select(sgUf, qtPopulacao, qtCobertura) |>
  arrange(desc(qtCobertura))
```

## Example: coverage trends over time

``` r
# monthly APS coverage, national level, 2020-2024
trend <- sisab_data(
  year = 2020:2024,
  level = "brazil"
)

trend |>
  select(year, nuComp, qtCobertura) |>
  arrange(year, nuComp)
```

## Example: municipal-level analysis

``` r
# municipality-level APS coverage in Minas Gerais
mg_munic <- sisab_data(
  year = 2024,
  level = "municipality",
  uf = "MG",
  month = 6
)

# distribution of coverage
mg_munic |>
  summarize(
    n_municipalities = n(),
    mean_coverage = mean(qtCobertura, na.rm = TRUE),
    median_coverage = median(qtCobertura, na.rm = TRUE),
    min_coverage = min(qtCobertura, na.rm = TRUE),
    max_coverage = max(qtCobertura, na.rm = TRUE)
  )
```

## Differences from other modules

SISAB has a few differences from DATASUS FTP modules (SIM, SIH, CNES,
etc.):

| Feature           | SISAB                | DATASUS modules                |
|-------------------|----------------------|--------------------------------|
| Data source       | REST API             | FTP .dbc/.DBF files            |
| Column names      | camelCase (from API) | UPPERCASE                      |
| `lazy` parameter  | Not available        | Available (arrow/DuckDB)       |
| `parse` parameter | Not available        | Available                      |
| `dictionary()`    | Not available        | Available                      |
| Data type         | Aggregated coverage  | Microdata (individual records) |

Column names are preserved as returned by the API (e.g., `qtCobertura`,
`sgUf`, `noMunicipioIbge`). Use
[`sisab_variables()`](https://sidneybissoli.github.io/healthbR/reference/sisab_variables.md)
to explore them.

## Cache management

Downloaded data is cached locally for faster future access:

``` r
# check cache status
sisab_cache_status()

# clear cache if needed
sisab_clear_cache()
```

## Additional resources

- [SISAB reporting portal](https://sisab.saude.gov.br/)
- [relatorioaps portal](https://relatorioaps.saude.gov.br/)
- [Primary care policy
  (SAPS)](https://www.gov.br/saude/pt-br/composicao/saps)
- [Census
  vignette](https://sidneybissoli.github.io/healthbR/articles/censo-denominadores.md)
  for population denominators
