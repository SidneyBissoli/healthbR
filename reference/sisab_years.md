# List Available SISAB Years

Returns an integer vector with years for which SISAB coverage data are
potentially available from the relatorioaps API. Actual availability
depends on the report type.

## Usage

``` r
sisab_years()
```

## Value

An integer vector of available years.

## Details

Availability by report type:

- `aps`: APS coverage (2019–present)

- `sb`: Oral health coverage (2024–present)

- `acs`: Community health agents (2007–present)

- `pns`: PNS coverage (2020–2023)

## See also

Other sisab:
[`sisab_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sisab_cache_status.md),
[`sisab_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sisab_clear_cache.md),
[`sisab_data()`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md),
[`sisab_info()`](https://sidneybissoli.github.io/healthbR/reference/sisab_info.md),
[`sisab_variables()`](https://sidneybissoli.github.io/healthbR/reference/sisab_variables.md)

## Examples

``` r
sisab_years()
#>  [1] 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021
#> [16] 2022 2023 2024 2025 2026
```
