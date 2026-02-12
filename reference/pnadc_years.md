# List available years for a PNADC module

Returns a vector of years for which data is available for the specified
module.

## Usage

``` r
pnadc_years(module)
```

## Arguments

- module:

  Character. The module identifier. Use
  [`pnadc_modules`](https://sidneybissoli.github.io/healthbR/reference/pnadc_modules.md)
  to see available modules.

## Value

An integer vector of available years.

## Examples

``` r
pnadc_years("deficiencia")
#> [1] 2019 2022 2024
pnadc_years("habitacao")
#>  [1] 2012 2013 2014 2015 2016 2017 2018 2019 2022 2023 2024
```
