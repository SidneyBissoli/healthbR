# Download PNS variable dictionary

Downloads and returns the variable dictionary for PNS microdata. The
dictionary is cached locally to avoid repeated downloads.

## Usage

``` r
pns_dictionary(year = 2019, cache_dir = NULL, refresh = FALSE)
```

## Arguments

- year:

  Numeric. Year to get dictionary for (2013 or 2019). Default is 2019.

- cache_dir:

  Character. Directory for caching downloaded files. Default uses
  `tools::R_user_dir("healthbR", "cache")`.

- refresh:

  Logical. If TRUE, re-download even if file exists in cache. Default is
  FALSE.

## Value

A tibble with variable definitions.

## Details

The dictionary includes variable names, labels, and response categories
for the PNS microdata. This is useful for understanding the structure of
the data returned by
[`pns_data`](https://sidneybissoli.github.io/healthbR/reference/pns_data.md).

## Data source

Dictionaries are downloaded from the IBGE FTP server:
<https://ftp.ibge.gov.br/PNS/>

## Examples

``` r
if (FALSE) { # interactive()
# get dictionary for 2019
dict <- pns_dictionary(year = 2019, cache_dir = tempdir())

# get dictionary for 2013
dict_2013 <- pns_dictionary(year = 2013, cache_dir = tempdir())
}
```
