# List Available SIA Years

Returns an integer vector with years for which outpatient production
microdata are available from DATASUS FTP.

## Usage

``` r
sia_years(status = "final")
```

## Arguments

- status:

  Character. Filter by data status. One of:

  - `"final"`: Definitive data only (default).

  - `"preliminary"`: Preliminary data only.

  - `"all"`: All available data (definitive + preliminary).

## Value

An integer vector of available years.

## See also

Other sia:
[`sia_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sia_cache_status.md),
[`sia_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sia_clear_cache.md),
[`sia_data()`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md),
[`sia_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sia_dictionary.md),
[`sia_info()`](https://sidneybissoli.github.io/healthbR/reference/sia_info.md),
[`sia_variables()`](https://sidneybissoli.github.io/healthbR/reference/sia_variables.md)

## Examples

``` r
sia_years()
#>  [1] 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022
#> [16] 2023
sia_years(status = "all")
#>  [1] 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022
#> [16] 2023 2024
```
