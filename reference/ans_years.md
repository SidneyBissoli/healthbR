# List Available ANS Years

Returns an integer vector with years for which ANS data are available.

## Usage

``` r
ans_years(type = "beneficiaries")
```

## Arguments

- type:

  Character. Type of data. One of:

  - `"beneficiaries"`: Consolidated beneficiary counts (default).

  - `"complaints"`: Consumer complaints (NIP).

  - `"financial"`: Financial statements.

## Value

An integer vector of available years.

## See also

Other ans:
[`ans_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/ans_cache_status.md),
[`ans_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/ans_clear_cache.md),
[`ans_data()`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md),
[`ans_info()`](https://sidneybissoli.github.io/healthbR/reference/ans_info.md),
[`ans_operators()`](https://sidneybissoli.github.io/healthbR/reference/ans_operators.md),
[`ans_variables()`](https://sidneybissoli.github.io/healthbR/reference/ans_variables.md)

## Examples

``` r
ans_years()
#> [1] 2019 2020 2021 2022 2023 2024 2025
ans_years(type = "complaints")
#>  [1] 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025
#> [16] 2026
ans_years(type = "financial")
#>  [1] 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021
#> [16] 2022 2023 2024 2025
```
