# List Available SIM Years

Returns an integer vector with years for which mortality microdata are
available from DATASUS FTP.

## Usage

``` r
sim_years(status = "final")
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

Other sim:
[`sim_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sim_cache_status.md),
[`sim_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sim_clear_cache.md),
[`sim_data()`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md),
[`sim_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sim_dictionary.md),
[`sim_info()`](https://sidneybissoli.github.io/healthbR/reference/sim_info.md),
[`sim_variables()`](https://sidneybissoli.github.io/healthbR/reference/sim_variables.md)

## Examples

``` r
sim_years()
#>  [1] 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010
#> [16] 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022
sim_years(status = "all")
#>  [1] 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010
#> [16] 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024
```
