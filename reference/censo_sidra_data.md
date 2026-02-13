# Get Census data from SIDRA API

Queries the IBGE SIDRA API to retrieve any Census table. This is the
most flexible function, allowing full control over SIDRA query
parameters.

## Usage

``` r
censo_sidra_data(
  table,
  territorial_level = "brazil",
  geo_code = "all",
  year = NULL,
  variable = NULL,
  classifications = NULL,
  raw = FALSE
)
```

## Arguments

- table:

  Numeric or character. SIDRA table code. Use
  [`censo_sidra_tables`](https://sidneybissoli.github.io/healthbR/reference/censo_sidra_tables.md)
  or
  [`censo_sidra_search`](https://sidneybissoli.github.io/healthbR/reference/censo_sidra_search.md)
  to find codes.

- territorial_level:

  Character. Geographic level: `"brazil"` (N1), `"region"` (N2),
  `"state"` (N3), `"municipality"` (N6). Default `"brazil"`.

- geo_code:

  Character. IBGE code(s) for specific localities. `"all"` returns all
  localities at the chosen level. Default `"all"`.

- year:

  Numeric or character. Year(s) to query. NULL returns all available
  periods.

- variable:

  Numeric or character. SIDRA variable ID(s). NULL returns all variables
  excluding metadata. Default NULL.

- classifications:

  Named list. SIDRA classification filters. Example:
  `list("2" = "allxt")` for sex breakdown. NULL returns default
  aggregation. Default NULL.

- raw:

  Logical. If TRUE, returns raw API output without cleaning. Default
  FALSE.

## Value

A tibble with queried data.

## Examples

``` r
if (FALSE) { # interactive()
# population by state from 2022 Census
censo_sidra_data(
  table = 9514,
  territorial_level = "state",
  year = 2022,
  variable = 93
)

# population by race, Brazil level
censo_sidra_data(
  table = 9605,
  territorial_level = "brazil",
  year = 2022,
  variable = 93,
  classifications = list("86" = "allxt")
)
}
```
