# Get intercensitary population estimates

Retrieves population estimates for intercensitary years (2001-2021) from
SIDRA table 6579. These estimates provide population denominators for
years between censuses.

## Usage

``` r
censo_estimativa(
  year,
  territorial_level = "state",
  geo_code = "all",
  raw = FALSE
)
```

## Arguments

- year:

  Numeric or vector. Year(s) between 2001 and 2021.

- territorial_level:

  Character. Geographic level: `"brazil"`, `"region"`, `"state"`, or
  `"municipality"`. Default is `"state"`.

- geo_code:

  Character. IBGE code(s) for specific localities. `"all"` returns all
  localities at the chosen level. Default is `"all"`.

- raw:

  Logical. If TRUE, returns raw API output without cleaning. Default is
  FALSE.

## Value

A tibble with population estimates.

## Details

Table 6579 provides total population estimates (no sex/age breakdown).
These estimates are published annually by IBGE and are widely used as
denominators for health indicator calculations.

For census years with full demographic breakdowns, use
[`censo_populacao`](https://sidneybissoli.github.io/healthbR/reference/censo_populacao.md)
instead.

## Data source

Data is retrieved from IBGE SIDRA API, table 6579:
`https://sidra.ibge.gov.br/tabela/6579`

## Examples

``` r
if (FALSE) { # interactive()
# estimates for 2020 by state
censo_estimativa(year = 2020)

# estimates for multiple years, Brazil level
censo_estimativa(year = 2015:2020, territorial_level = "brazil")

# estimates by municipality
censo_estimativa(year = 2021, territorial_level = "municipality")
}
```
