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

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`healthbR`](https://github.com/SidneyBissoli/healthbR)`)`\
[`library`](https://rdrr.io/r/base/library.html)`(`[`dplyr`](https://dplyr.tidyverse.org)`)`

### Check available years

\
[`sisab_years`](https://sidneybissoli.github.io/healthbR/reference/sisab_years.md)`(``)`

### Module information

\
[`sisab_info`](https://sidneybissoli.github.io/healthbR/reference/sisab_info.md)`(``)`

## Basic download

### APS coverage by state (default)

\
`# APS coverage by state, January 2024`\
`aps_jan`` ``<-`` `[`sisab_data`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md)`(``year ``=`` ``2024``, month ``=`` ``1``)`\
`aps_jan`

### Full year

\
`# APS coverage, all months of 2023`\
`aps_2023`` ``<-`` `[`sisab_data`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md)`(``year ``=`` ``2023``)`\
`aps_2023`

## Other report types

### Oral health coverage

\
`sb`` ``<-`` `[`sisab_data`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md)`(``year ``=`` ``2024``, type ``=`` ``"sb"``, month ``=`` ``6``)`\
`sb`

### Community health agents

\
`acs`` ``<-`` `[`sisab_data`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md)`(``year ``=`` ``2023``, type ``=`` ``"acs"``)`\
`acs`

### PNS coverage

\
`pns`` ``<-`` `[`sisab_data`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md)`(``year ``=`` ``2022``, type ``=`` ``"pns"``)`\
`pns`

## Geographic levels

### National total

\
`national`` ``<-`` `[`sisab_data`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md)`(``year ``=`` ``2024``, level ``=`` ``"brazil"``, month ``=`` ``1``)`\
`national`

### By region

\
`regions`` ``<-`` `[`sisab_data`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md)`(``year ``=`` ``2024``, level ``=`` ``"region"``, month ``=`` ``1``)`\
`regions`

### By state (default)

\
`states`` ``<-`` `[`sisab_data`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md)`(``year ``=`` ``2024``, level ``=`` ``"uf"``, month ``=`` ``1``)`\
`states`

### By municipality

\
`# filter by UF to avoid large downloads`\
`sp_munic`` ``<-`` `[`sisab_data`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md)`(`\
`  year ``=`` ``2024``,`\
`  level ``=`` ``"municipality"``,`\
`  uf ``=`` ``"SP"``,`\
`  month ``=`` ``1`\
`)`\
`sp_munic`

## Filtering by state and month

\
`# single state, single month`\
`sp_jan`` ``<-`` `[`sisab_data`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md)`(``year ``=`` ``2024``, uf ``=`` ``"SP"``, month ``=`` ``1``)`\
\
`# specific months`\
`sp_q1`` ``<-`` `[`sisab_data`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md)`(``year ``=`` ``2024``, uf ``=`` ``"SP"``, month ``=`` ``1``:``3``)`\
\
`# multiple years`\
`sp_multi`` ``<-`` `[`sisab_data`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md)`(``year ``=`` ``2022``:``2024``, uf ``=`` ``"SP"``, month ``=`` ``6``)`

## Exploring variables

\
`# APS variables (default)`\
[`sisab_variables`](https://sidneybissoli.github.io/healthbR/reference/sisab_variables.md)`(``)`\
\
`# oral health variables`\
[`sisab_variables`](https://sidneybissoli.github.io/healthbR/reference/sisab_variables.md)`(``type ``=`` ``"sb"``)`\
\
`# community agents`\
[`sisab_variables`](https://sidneybissoli.github.io/healthbR/reference/sisab_variables.md)`(``type ``=`` ``"acs"``)`\
\
`# PNS variables`\
[`sisab_variables`](https://sidneybissoli.github.io/healthbR/reference/sisab_variables.md)`(``type ``=`` ``"pns"``)`\
\
`# search`\
[`sisab_variables`](https://sidneybissoli.github.io/healthbR/reference/sisab_variables.md)`(``search ``=`` ``"cobertura"``)`\
[`sisab_variables`](https://sidneybissoli.github.io/healthbR/reference/sisab_variables.md)`(``search ``=`` ``"equipe"``)`

## Example: APS coverage by state

\
`aps`` ``<-`` `[`sisab_data`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md)`(``year ``=`` ``2024``, level ``=`` ``"uf"``, month ``=`` ``6``)`\
\
`# coverage by state`\
`aps`` ``|>`\
`  `[`select`](https://dplyr.tidyverse.org/reference/select.html)`(``sgUf``, ``qtPopulacao``, ``qtCobertura``)`` ``|>`\
`  `[`arrange`](https://dplyr.tidyverse.org/reference/arrange.html)`(`[`desc`](https://dplyr.tidyverse.org/reference/desc.html)`(``qtCobertura``)``)`

## Example: coverage trends over time

\
`# monthly APS coverage, national level, 2020-2024`\
`trend`` ``<-`` `[`sisab_data`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md)`(`\
`  year ``=`` ``2020``:``2024``,`\
`  level ``=`` ``"brazil"`\
`)`\
\
`trend`` ``|>`\
`  `[`select`](https://dplyr.tidyverse.org/reference/select.html)`(``year``, ``nuComp``, ``qtCobertura``)`` ``|>`\
`  `[`arrange`](https://dplyr.tidyverse.org/reference/arrange.html)`(``year``, ``nuComp``)`

## Example: municipal-level analysis

\
`# municipality-level APS coverage in Minas Gerais`\
`mg_munic`` ``<-`` `[`sisab_data`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md)`(`\
`  year ``=`` ``2024``,`\
`  level ``=`` ``"municipality"``,`\
`  uf ``=`` ``"MG"``,`\
`  month ``=`` ``6`\
`)`\
\
`# distribution of coverage`\
`mg_munic`` ``|>`\
`  `[`summarize`](https://dplyr.tidyverse.org/reference/summarise.html)`(`\
`    n_municipalities ``=`` `[`n`](https://dplyr.tidyverse.org/reference/context.html)`(``)``,`\
`    mean_coverage ``=`` `[`mean`](https://rdrr.io/r/base/mean.html)`(``qtCobertura``, na.rm ``=`` ``TRUE``)``,`\
`    median_coverage ``=`` `[`median`](https://rdrr.io/r/stats/median.html)`(``qtCobertura``, na.rm ``=`` ``TRUE``)``,`\
`    min_coverage ``=`` `[`min`](https://rdrr.io/r/base/Extremes.html)`(``qtCobertura``, na.rm ``=`` ``TRUE``)``,`\
`    max_coverage ``=`` `[`max`](https://rdrr.io/r/base/Extremes.html)`(``qtCobertura``, na.rm ``=`` ``TRUE``)`\
`  ``)`

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

\
`# check cache status`\
[`sisab_cache_status`](https://sidneybissoli.github.io/healthbR/reference/sisab_cache_status.md)`(``)`\
\
`# clear cache if needed`\
[`sisab_clear_cache`](https://sidneybissoli.github.io/healthbR/reference/sisab_clear_cache.md)`(``)`

## Additional resources

- SISAB reporting portal (`sisab.saude.gov.br`)
- relatorioaps portal (`relatorioaps.saude.gov.br`)
- Primary care policy (SAPS) (`www.gov.br/saude/pt-br/composicao/saps`)
- [Census
  vignette](https://sidneybissoli.github.io/healthbR/articles/censo-denominadores.md)
  for population denominators
