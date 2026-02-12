# Population Denominators from the Census with healthbR

## Overview

The **Censo Demografico** (Demographic Census) is the main source of
population denominators in Brazil, essential for calculating mortality
rates, disease incidence, and other epidemiological indicators.

The `healthbR` package provides direct access to Census population data
via the IBGE SIDRA API, covering:

| Function                                                                                       | Description                             | Years         |
|------------------------------------------------------------------------------------------------|-----------------------------------------|---------------|
| [`censo_populacao()`](https://sidneybissoli.github.io/healthbR/reference/censo_populacao.md)   | Population by sex, age, race, situation | 1970-2022     |
| [`censo_estimativa()`](https://sidneybissoli.github.io/healthbR/reference/censo_estimativa.md) | Intercensitary population estimates     | 2001-2021     |
| [`censo_sidra_data()`](https://sidneybissoli.github.io/healthbR/reference/censo_sidra_data.md) | Any Census SIDRA table                  | All available |

## Getting started

``` r
library(healthbR)
library(dplyr)
```

### Check available years

``` r
censo_years()
#> [1] "1970" "1980" "1991" "2000" "2010" "2022"
```

### Survey information

``` r
censo_info(2022)
```

## Population by state

The most common use case: getting population by state as a denominator
for health indicators.

``` r
# total population by state, Census 2022
pop_state <- censo_populacao(year = 2022, territorial_level = "state")
pop_state
```

## Population by sex

``` r
# population by sex, Brazil level
pop_sex <- censo_populacao(
  year = 2022,
  variables = "sex",
  territorial_level = "brazil"
)
pop_sex
```

## Age pyramids

``` r
# population by age and sex
pop_age_sex <- censo_populacao(
  year = 2022,
  variables = "age_sex",
  territorial_level = "brazil"
)
pop_age_sex
```

## Population by race/color

``` r
# population by race, 2022
pop_race <- censo_populacao(
  year = 2022,
  variables = "race",
  territorial_level = "state"
)
pop_race
```

## Intercensitary estimates

For years between censuses, IBGE publishes annual population estimates
that serve as denominators:

``` r
# population estimates 2015-2021
estimates <- censo_estimativa(
  year = 2015:2021,
  territorial_level = "state"
)
estimates
```

## Example: calculating a mortality rate

A typical epidemiological workflow combines mortality data (SIM) with
Census denominators:

``` r
# step 1: get population denominator
pop_2010 <- censo_populacao(
  year = 2010,
  variables = "total",
  territorial_level = "state"
)

# step 2: suppose you have mortality data (from SIM or other source)
# deaths_by_state <- sim_data(year = 2010) |> count(state)

# step 3: calculate crude mortality rate
# mortality_rate <- deaths_by_state |>
#   left_join(pop_2010, by = "state") |>
#   mutate(rate_per_100k = (n / population) * 100000)
```

## Exploring Census tables

The Census module includes a catalog of SIDRA tables organized by theme:

``` r
# list all available tables
censo_sidra_tables()

# filter by theme
censo_sidra_tables(theme = "disability")
censo_sidra_tables(theme = "indigenous")

# search by keyword
censo_sidra_search("quilombola")
censo_sidra_search("saneamento")
```

## Custom SIDRA queries

For full flexibility, use
[`censo_sidra_data()`](https://sidneybissoli.github.io/healthbR/reference/censo_sidra_data.md)
to query any Census table:

``` r
# population by race from table 9605
pop_race_raw <- censo_sidra_data(
  table = 9605,
  territorial_level = "state",
  year = 2022,
  variable = 93,
  classifications = list("86" = "allxt")
)
pop_race_raw
```

## Historical comparisons

``` r
# compare population across census years
pop_2010 <- censo_populacao(year = 2010, territorial_level = "brazil")
pop_2022 <- censo_populacao(year = 2022, territorial_level = "brazil")

# or use estimates for intercensitary years
pop_series <- censo_estimativa(
  year = 2001:2021,
  territorial_level = "brazil"
)
pop_series
```
