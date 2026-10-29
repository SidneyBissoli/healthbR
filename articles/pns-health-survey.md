# National Health Survey (PNS) with healthbR

## Overview

The **PNS (Pesquisa Nacional de Saude)** is Brazil’s most comprehensive
household health survey, conducted by IBGE in partnership with the
Ministry of Health. It provides nationally representative data on health
conditions, lifestyle, access to health services, and preventive care.

Two editions are available: **2013** and **2019**, each with
approximately 100,000+ respondents.

The `healthbR` package provides two complementary access paths:

| Access path | Function | Description |
|----|----|----|
| **Microdata** | [`pns_data()`](https://sidneybissoli.github.io/healthbR/reference/pns_data.md) | Individual-level records via IBGE FTP |
| **SIDRA tables** | [`pns_sidra_data()`](https://sidneybissoli.github.io/healthbR/reference/pns_sidra_data.md) | Pre-tabulated indicators via IBGE API |

## Getting started

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`healthbR`](https://github.com/SidneyBissoli/healthbR)`)`\
[`library`](https://rdrr.io/r/base/library.html)`(`[`dplyr`](https://dplyr.tidyverse.org)`)`

### Check available years

\
[`pns_years`](https://sidneybissoli.github.io/healthbR/reference/pns_years.md)`(``)`\
`#> [1] "2013" "2019"`

### Survey information

\
[`pns_info`](https://sidneybissoli.github.io/healthbR/reference/pns_info.md)`(``2019``)`

### Thematic modules

PNS organizes questions into thematic modules (A through Z). Use
[`pns_modules()`](https://sidneybissoli.github.io/healthbR/reference/pns_modules.md)
to see what’s available:

\
[`pns_modules`](https://sidneybissoli.github.io/healthbR/reference/pns_modules.md)`(``year ``=`` ``2019``)`\
`#> # A tibble: 20 x 3`\
`#>    code  name_pt                          name_en`\
`#>    <chr> <chr>                            <chr>`\
`#>  1 A     Informacoes do domicilio         Household information`\
`#>  2 C     Caracteristicas dos moradores    Resident characteristics`\
`#>  3 ...`

## Microdata access

### Download microdata

\
`# All modules for 2019`\
`df`` ``<-`` `[`pns_data`](https://sidneybissoli.github.io/healthbR/reference/pns_data.md)`(``year ``=`` ``2019``)`\
\
`# Select specific variables`\
`df`` ``<-`` `[`pns_data`](https://sidneybissoli.github.io/healthbR/reference/pns_data.md)`(``year ``=`` ``2019``, vars ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"C006"``, ``"C008"``, ``"C009"``, ``"Q002"``, ``"Q00201"``)``)`

### Explore variables

\
`# List all variables`\
[`pns_variables`](https://sidneybissoli.github.io/healthbR/reference/pns_variables.md)`(``year ``=`` ``2019``)`\
\
`# Filter by module`\
[`pns_variables`](https://sidneybissoli.github.io/healthbR/reference/pns_variables.md)`(``year ``=`` ``2019``, module ``=`` ``"Q"``)`\
\
`# Data dictionary`\
[`pns_dictionary`](https://sidneybissoli.github.io/healthbR/reference/pns_dictionary.md)`(``year ``=`` ``2019``)`

## SIDRA tabulated data

For pre-calculated indicators with confidence intervals, use the SIDRA
API path. This is ideal for quick analyses without downloading full
microdata.

### Discover available tables

PNS has 69 SIDRA tables organized by 14 health themes:

\
`# Browse all tables`\
[`pns_sidra_tables`](https://sidneybissoli.github.io/healthbR/reference/pns_sidra_tables.md)`(``)`\
\
`# Filter by theme`\
[`pns_sidra_tables`](https://sidneybissoli.github.io/healthbR/reference/pns_sidra_tables.md)`(``theme ``=`` ``"Chronic diseases"``)`\
\
`# Search by keyword`\
[`pns_sidra_search`](https://sidneybissoli.github.io/healthbR/reference/pns_sidra_search.md)`(``"diabetes"``)`\
[`pns_sidra_search`](https://sidneybissoli.github.io/healthbR/reference/pns_sidra_search.md)`(``"tabagismo"``)`

### Query a SIDRA table

\
`# Table 7666: Self-reported diabetes prevalence`\
`diabetes`` ``<-`` `[`pns_sidra_data`](https://sidneybissoli.github.io/healthbR/reference/pns_sidra_data.md)`(`\
`  table ``=`` ``7666``,`\
`  territorial_level ``=`` ``"state"``,`\
`  year ``=`` ``2019`\
`)`

### Geographic levels

\
`# National level`\
[`pns_sidra_data`](https://sidneybissoli.github.io/healthbR/reference/pns_sidra_data.md)`(``table ``=`` ``7666``, territorial_level ``=`` ``"brazil"``)`\
\
`# By state`\
[`pns_sidra_data`](https://sidneybissoli.github.io/healthbR/reference/pns_sidra_data.md)`(``table ``=`` ``7666``, territorial_level ``=`` ``"state"``)`\
\
`# By capital city`\
[`pns_sidra_data`](https://sidneybissoli.github.io/healthbR/reference/pns_sidra_data.md)`(``table ``=`` ``7666``, territorial_level ``=`` ``"capital"``)`\
\
`# Specific state (e.g., Sao Paulo = 35)`\
[`pns_sidra_data`](https://sidneybissoli.github.io/healthbR/reference/pns_sidra_data.md)`(``table ``=`` ``7666``, territorial_level ``=`` ``"state"``, geo_code ``=`` ``"35"``)`

## Example: Chronic disease prevalence by state

Using SIDRA for quick tabulated results:

\
`# Self-reported hypertension by state`\
`hypertension`` ``<-`` `[`pns_sidra_data`](https://sidneybissoli.github.io/healthbR/reference/pns_sidra_data.md)`(`\
`  table ``=`` ``7659``,`\
`  territorial_level ``=`` ``"state"``,`\
`  year ``=`` ``2019`\
`)`

## Example: Health service access from microdata

\
`df`` ``<-`` `[`pns_data`](https://sidneybissoli.github.io/healthbR/reference/pns_data.md)`(`\
`  year ``=`` ``2019``,`\
`  vars ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"C006"``, ``"C008"``, ``"C009"``, ``"J001"``, ``"J007"``, ``"J009"``, ``"V0024"``, ``"UPA_PNS"``)`\
`)`\
\
`# J001: Had a medical visit in the last 12 months?`\
`# C006: Sex, C008: Age, C009: Race`\
`access`` ``<-`` ``df`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``J001`` `[`%in%`](https://rdrr.io/r/base/match.html)` `[`c`](https://rdrr.io/r/base/c.html)`(``"1"``, ``"2"``)``)`` ``|>`\
`  `[`group_by`](https://dplyr.tidyverse.org/reference/group_by.html)`(``C006``)`` ``|>`\
`  `[`summarise`](https://dplyr.tidyverse.org/reference/summarise.html)`(`\
`    visited ``=`` `[`sum`](https://rdrr.io/r/base/sum.html)`(``J001`` ``==`` ``"1"``)``,`\
`    total ``=`` `[`n`](https://dplyr.tidyverse.org/reference/context.html)`(``)``,`\
`    pct ``=`` ``visited`` ``/`` ``total`` ``*`` ``100`\
`  ``)`

## Cache and performance

\
`# Check cache`\
[`pns_cache_status`](https://sidneybissoli.github.io/healthbR/reference/pns_cache_status.md)`(``)`\
\
`# Clear cache`\
[`pns_clear_cache`](https://sidneybissoli.github.io/healthbR/reference/pns_clear_cache.md)`(``)`\
\
`# Lazy evaluation for large datasets`\
`lazy_df`` ``<-`` `[`pns_data`](https://sidneybissoli.github.io/healthbR/reference/pns_data.md)`(``year ``=`` ``2019``, lazy ``=`` ``TRUE``, backend ``=`` ``"arrow"``)`

## Further reading

- PNS on IBGE
  (`www.ibge.gov.br/estatisticas/sociais/saude/9160-pesquisa-nacional-de-saude`)
- PNS SIDRA tables (`sidra.ibge.gov.br/pesquisa/pns`)
