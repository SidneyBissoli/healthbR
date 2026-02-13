# List Available CNES Years

Returns an integer vector with years for which health facility registry
data are available from DATASUS FTP.

## Usage

``` r
cnes_years(status = "final")
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

Other cnes:
[`cnes_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/cnes_cache_status.md),
[`cnes_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/cnes_clear_cache.md),
[`cnes_data()`](https://sidneybissoli.github.io/healthbR/reference/cnes_data.md),
[`cnes_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/cnes_dictionary.md),
[`cnes_info()`](https://sidneybissoli.github.io/healthbR/reference/cnes_info.md),
[`cnes_variables()`](https://sidneybissoli.github.io/healthbR/reference/cnes_variables.md)

## Examples

``` r
cnes_years()
#>  [1] 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019
#> [16] 2020 2021 2022 2023
cnes_years(status = "all")
#>  [1] 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019
#> [16] 2020 2021 2022 2023 2024
```
