# Get Census population data

Retrieves population data from the Brazilian Demographic Census via
SIDRA API. Automatically selects the correct SIDRA table based on year
and requested variables.

## Usage

``` r
censo_populacao(
  year,
  variables = "total",
  territorial_level = "state",
  geo_code = "all",
  raw = FALSE
)
```

## Arguments

- year:

  Numeric. Census year (1970, 1980, 1991, 2000, 2010, or 2022).

- variables:

  Character. Type of breakdown:

  - `"total"`: Total population only

  - `"sex"`: By sex (male/female)

  - `"age"`: By age groups

  - `"age_sex"`: By age groups and sex

  - `"race"`: By race/color (only 2000, 2010, 2022)

  - `"situation"`: By urban/rural situation

  Default is `"total"`.

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

A tibble with population data.

## Details

This function provides an easy interface for the most common Census
queries. It automatically resolves the correct SIDRA table:

- Table 200: Historical population 1970-2010 (by sex, age, situation)

- Table 9514: Census 2022 population by sex and age

- Table 136: Population by race 2000-2010

- Table 9605: Population by race 2022

- Table 9515: Population by urban/rural 2022

For more flexibility, use
[`censo_sidra_data`](https://sidneybissoli.github.io/healthbR/reference/censo_sidra_data.md)
to query any table with custom parameters.

## Data source

Data is retrieved from IBGE SIDRA API: `https://sidra.ibge.gov.br/`

## Examples

``` r
if (FALSE) { # interactive()
# total population by state, 2022
censo_populacao(year = 2022)

# population by sex, Brazil level
censo_populacao(year = 2022, variables = "sex", territorial_level = "brazil")

# population by age and sex, 2010
censo_populacao(year = 2010, variables = "age_sex")

# population by race, 2022
censo_populacao(year = 2022, variables = "race")
}
```
