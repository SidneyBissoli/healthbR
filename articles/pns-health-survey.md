# National Health Survey (PNS) with healthbR

## Overview

The **PNS (Pesquisa Nacional de Saude)** is Brazil’s most comprehensive
household health survey, conducted by IBGE in partnership with the
Ministry of Health. It provides nationally representative data on health
conditions, lifestyle, access to health services, and preventive care.

Two editions are available: **2013** and **2019**, each with
approximately 100,000+ respondents.

The `healthbR` package provides two complementary access paths:

| Access path      | Function                                                                                   | Description                           |
|------------------|--------------------------------------------------------------------------------------------|---------------------------------------|
| **Microdata**    | [`pns_data()`](https://sidneybissoli.github.io/healthbR/reference/pns_data.md)             | Individual-level records via IBGE FTP |
| **SIDRA tables** | [`pns_sidra_data()`](https://sidneybissoli.github.io/healthbR/reference/pns_sidra_data.md) | Pre-tabulated indicators via IBGE API |

## Getting started

``` r
library(healthbR)
library(dplyr)
```

### Check available years

``` r
pns_years()
#> [1] "2013" "2019"
```

### Survey information

``` r
pns_info(2019)
```

### Thematic modules

PNS organizes questions into thematic modules (A through Z). Use
[`pns_modules()`](https://sidneybissoli.github.io/healthbR/reference/pns_modules.md)
to see what’s available:

``` r
pns_modules(year = 2019)
#> # A tibble: 20 x 3
#>    code  name_pt                          name_en
#>    <chr> <chr>                            <chr>
#>  1 A     Informacoes do domicilio         Household information
#>  2 C     Caracteristicas dos moradores    Resident characteristics
#>  3 ...
```

## Microdata access

### Download microdata

``` r
# All modules for 2019
df <- pns_data(year = 2019)

# Select specific variables
df <- pns_data(year = 2019, vars = c("C006", "C008", "C009", "Q002", "Q00201"))
```

### Explore variables

``` r
# List all variables
pns_variables(year = 2019)

# Filter by module
pns_variables(year = 2019, module = "Q")

# Data dictionary
pns_dictionary(year = 2019)
```

## SIDRA tabulated data

For pre-calculated indicators with confidence intervals, use the SIDRA
API path. This is ideal for quick analyses without downloading full
microdata.

### Discover available tables

PNS has 69 SIDRA tables organized by 14 health themes:

``` r
# Browse all tables
pns_sidra_tables()

# Filter by theme
pns_sidra_tables(theme = "Chronic diseases")

# Search by keyword
pns_sidra_search("diabetes")
pns_sidra_search("tabagismo")
```

### Query a SIDRA table

``` r
# Table 7666: Self-reported diabetes prevalence
diabetes <- pns_sidra_data(
  table = 7666,
  territorial_level = "state",
  year = 2019
)
```

### Geographic levels

``` r
# National level
pns_sidra_data(table = 7666, territorial_level = "brazil")

# By state
pns_sidra_data(table = 7666, territorial_level = "state")

# By capital city
pns_sidra_data(table = 7666, territorial_level = "capital")

# Specific state (e.g., Sao Paulo = 35)
pns_sidra_data(table = 7666, territorial_level = "state", geo_code = "35")
```

## Example: Chronic disease prevalence by state

Using SIDRA for quick tabulated results:

``` r
# Self-reported hypertension by state
hypertension <- pns_sidra_data(
  table = 7659,
  territorial_level = "state",
  year = 2019
)
```

## Example: Health service access from microdata

``` r
df <- pns_data(
  year = 2019,
  vars = c("C006", "C008", "C009", "J001", "J007", "J009", "V0024", "UPA_PNS")
)

# J001: Had a medical visit in the last 12 months?
# C006: Sex, C008: Age, C009: Race
access <- df |>
  filter(J001 %in% c("1", "2")) |>
  group_by(C006) |>
  summarise(
    visited = sum(J001 == "1"),
    total = n(),
    pct = visited / total * 100
  )
```

## Cache and performance

``` r
# Check cache
pns_cache_status()

# Clear cache
pns_clear_cache()

# Lazy evaluation for large datasets
lazy_df <- pns_data(year = 2019, lazy = TRUE, backend = "arrow")
```

## Further reading

- PNS on IBGE
  (`www.ibge.gov.br/estatisticas/sociais/saude/9160-pesquisa-nacional-de-saude`)
- PNS SIDRA tables (`sidra.ibge.gov.br/pesquisa/pns`)
