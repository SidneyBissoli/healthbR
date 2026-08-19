# List Available SI-PNI Years

Returns an integer vector with years for which vaccination data are
available.

## Usage

``` r
sipni_years()
```

## Value

An integer vector of available years (1994 onwards).

## Details

SI-PNI data come in two eras:

- **1994–2019**: Aggregated data (doses applied and coverage).

- **2020+**: Individual-level microdata (one row per vaccination dose),
  published monthly.

The returned vector is a static range extended with the microdata years
actually published on the healthbr-data R2 mirror once its manifest has
been read in the session (e.g. after calling
[`sipni_status()`](https://sidneybissoli.github.io/healthbR/reference/sipni_status.md));
this function itself never touches the network. Use
[`sipni_status()`](https://sidneybissoli.github.io/healthbR/reference/sipni_status.md)
for month-level availability.

## See also

Other sipni:
[`sipni_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sipni_cache_status.md),
[`sipni_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sipni_clear_cache.md),
[`sipni_data()`](https://sidneybissoli.github.io/healthbR/reference/sipni_data.md),
[`sipni_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sipni_dictionary.md),
[`sipni_info()`](https://sidneybissoli.github.io/healthbR/reference/sipni_info.md),
[`sipni_status()`](https://sidneybissoli.github.io/healthbR/reference/sipni_status.md),
[`sipni_variables()`](https://sidneybissoli.github.io/healthbR/reference/sipni_variables.md)

## Examples

``` r
sipni_years()
#>  [1] 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008
#> [16] 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023
#> [31] 2024 2025 2026
```
