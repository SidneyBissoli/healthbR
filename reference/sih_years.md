# List Available SIH Years

Returns an integer vector with years for which hospital admission
microdata are available. Since 0.4.0.9000 the range starts in 1992:
years before 2008 exist only on the healthbr-data R2 mirror (the DATASUS
FTP fallback starts in 2008) and have no `RACA_COR` column (race/colour
was added to the AIH layout in 2008).

## Usage

``` r
sih_years(status = "final")
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

Other sih:
[`sih_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sih_cache_status.md),
[`sih_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sih_clear_cache.md),
[`sih_data()`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md),
[`sih_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sih_dictionary.md),
[`sih_info()`](https://sidneybissoli.github.io/healthbR/reference/sih_info.md),
[`sih_status()`](https://sidneybissoli.github.io/healthbR/reference/sih_status.md),
[`sih_variables()`](https://sidneybissoli.github.io/healthbR/reference/sih_variables.md)

## Examples

``` r
sih_years()
#>  [1] 1992 1993 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006
#> [16] 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021
#> [31] 2022 2023 2024
sih_years(status = "all")
#>  [1] 1992 1993 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006
#> [16] 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021
#> [31] 2022 2023 2024 2025 2026
```
