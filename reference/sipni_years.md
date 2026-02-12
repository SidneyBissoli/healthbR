# List Available SI-PNI Years

Returns an integer vector with years for which vaccination data are
available from DATASUS FTP.

## Usage

``` r
sipni_years()
```

## Value

An integer vector of available years (1994–2019).

## Details

SI-PNI data on the DATASUS FTP is available from 1994 to 2019. All data
is definitive (no preliminary/final distinction). Post-2019 data
requires the SI-PNI web API (not yet supported).

## See also

Other sipni:
[`sipni_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sipni_cache_status.md),
[`sipni_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sipni_clear_cache.md),
[`sipni_data()`](https://sidneybissoli.github.io/healthbR/reference/sipni_data.md),
[`sipni_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sipni_dictionary.md),
[`sipni_info()`](https://sidneybissoli.github.io/healthbR/reference/sipni_info.md),
[`sipni_variables()`](https://sidneybissoli.github.io/healthbR/reference/sipni_variables.md)

## Examples

``` r
sipni_years()
#>  [1] 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008
#> [16] 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019
```
