# Get PNS tabulated data from SIDRA API

Queries the IBGE SIDRA API to retrieve tabulated PNS indicators. Returns
pre-aggregated data (prevalences, means, proportions) with confidence
intervals and coefficients of variation.

## Usage

``` r
pns_sidra_data(
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
  [`pns_sidra_tables()`](https://sidneybissoli.github.io/healthbR/reference/pns_sidra_tables.md)
  or
  [`pns_sidra_search()`](https://sidneybissoli.github.io/healthbR/reference/pns_sidra_search.md)
  to find codes.

- territorial_level:

  Character. Geographic level: "brazil" (N1), "region" (N2), "state"
  (N3), "municipality" (N6). Default "brazil".

- geo_code:

  Character. IBGE code(s) for specific localities. "all" returns all
  localities at the chosen level. Default "all".

- year:

  Numeric. Year(s) to query. NULL returns all available periods.

- variable:

  Numeric or character. SIDRA variable ID(s). NULL returns all variables
  excluding metadata. Default NULL.

- classifications:

  Named list. SIDRA classification filters. Example: list("2" = "6794")
  for sex = total. NULL returns default aggregation. Default NULL.

- raw:

  Logical. If TRUE, returns raw API output without cleaning. Default
  FALSE.

## Value

A tibble with queried indicators.

## Examples

``` r
if (FALSE) { # interactive()
# self-rated health by state, 2019
pns_sidra_data(
  table = 4751,
  territorial_level = "state",
  year = 2019
)

# same table, Brazil-level, both years
pns_sidra_data(
  table = 4751,
  territorial_level = "brazil",
  year = c(2013, 2019)
)

# hypertension data
pns_sidra_data(
  table = 4416,
  territorial_level = "brazil"
)
}
```
