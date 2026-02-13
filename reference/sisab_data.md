# Download SISAB Coverage Data

Downloads and returns primary care coverage data from the SISAB
relatorioaps API. Data is aggregated (coverage indicators per geographic
unit and period), not individual-level microdata.

## Usage

``` r
sisab_data(
  year,
  type = "aps",
  level = "uf",
  month = NULL,
  uf = NULL,
  vars = NULL,
  cache = TRUE,
  cache_dir = NULL
)
```

## Arguments

- year:

  Integer. Year(s) of the data. Required.

- type:

  Character. Report type to download. Default: `"aps"` (APS coverage).
  See
  [`sisab_info()`](https://sidneybissoli.github.io/healthbR/reference/sisab_info.md)
  for all types.

- level:

  Character. Geographic aggregation level. Default: `"uf"`. One of:
  `"brazil"`, `"region"`, `"uf"`, `"municipality"`.

- month:

  Integer. Month(s) to download (1–12). If NULL (default), downloads all
  12 months.

- uf:

  Character. Two-letter state abbreviation to filter by when `level` is
  `"uf"` or `"municipality"`. If NULL (default), returns all states.
  Example: `"SP"`, `c("SP", "RJ")`.

- vars:

  Character vector. Variables to keep. If NULL (default), returns all
  available variables. Use
  [`sisab_variables()`](https://sidneybissoli.github.io/healthbR/reference/sisab_variables.md)
  to see available variables.

- cache:

  Logical. If TRUE (default), caches downloaded data for faster future
  access.

- cache_dir:

  Character. Directory for caching. Default:
  `tools::R_user_dir("healthbR", "cache")`.

## Value

A tibble with coverage data. Includes columns `year` and `type` to
identify the source when multiple years/types are combined. Column names
are preserved from the API (camelCase).

## Details

Data is fetched from the relatorioaps REST API
(<https://relatorioaps.saude.gov.br>), the public reporting portal for
primary care in Brazil.

Four report types are available:

- `"aps"` (default): APS coverage – number of primary care teams (eSF,
  eAP, eSFR, eCR, eAPP) and estimated coverage percentage. Available
  from 2019.

- `"sb"`: Oral health coverage – dental care teams and coverage.
  Available from 2024.

- `"acs"`: Community health agents – number of active ACS and population
  coverage. Available from 2007.

- `"pns"`: PNS coverage – coverage estimates from the National Health
  Survey. Available 2020–2023.

For municipality-level data, it is recommended to filter by UF using the
`uf` parameter to avoid large downloads.

## See also

[`sisab_info()`](https://sidneybissoli.github.io/healthbR/reference/sisab_info.md)
for report type descriptions,
[`censo_populacao()`](https://sidneybissoli.github.io/healthbR/reference/censo_populacao.md)
for population denominators.

Other sisab:
[`sisab_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sisab_cache_status.md),
[`sisab_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sisab_clear_cache.md),
[`sisab_info()`](https://sidneybissoli.github.io/healthbR/reference/sisab_info.md),
[`sisab_variables()`](https://sidneybissoli.github.io/healthbR/reference/sisab_variables.md),
[`sisab_years()`](https://sidneybissoli.github.io/healthbR/reference/sisab_years.md)

## Examples

``` r
if (FALSE) { # interactive()
# APS coverage by state, January 2024
sisab_data(year = 2024, month = 1)

# National total, full year 2023
sisab_data(year = 2023, level = "brazil")

# Oral health coverage by UF
sisab_data(year = 2024, type = "sb", month = 6)

# Municipality level for Sao Paulo
sisab_data(year = 2024, level = "municipality", uf = "SP", month = 1)
}
```
