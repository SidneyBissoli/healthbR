# List Available SINAN Years

Returns an integer vector with years for which notifiable diseases
microdata are available from DATASUS FTP.

## Usage

``` r
sinan_years(status = "final")
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

Other sinan:
[`sinan_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sinan_cache_status.md),
[`sinan_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sinan_clear_cache.md),
[`sinan_data()`](https://sidneybissoli.github.io/healthbR/reference/sinan_data.md),
[`sinan_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sinan_dictionary.md),
[`sinan_diseases()`](https://sidneybissoli.github.io/healthbR/reference/sinan_diseases.md),
[`sinan_info()`](https://sidneybissoli.github.io/healthbR/reference/sinan_info.md),
[`sinan_variables()`](https://sidneybissoli.github.io/healthbR/reference/sinan_variables.md)

## Examples

``` r
sinan_years()
#>  [1] 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021
#> [16] 2022
sinan_years(status = "all")
#>  [1] 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021
#> [16] 2022 2023 2024
```
