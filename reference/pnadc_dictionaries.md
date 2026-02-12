# Download PNADC variable dictionary

Downloads and returns the variable dictionary for PNADC microdata. The
dictionary is cached locally to avoid repeated downloads.

## Usage

``` r
pnadc_dictionaries(module, year = NULL, cache_dir = NULL, refresh = FALSE)
```

## Arguments

- module:

  Character. The module identifier (e.g., "deficiencia", "habitacao").

- year:

  Numeric. Year to get dictionary for. Uses most recent year if NULL.

- cache_dir:

  Character. Directory for caching downloaded files. Default uses
  `tools::R_user_dir("healthbR", "cache")`.

- refresh:

  Logical. If TRUE, re-download even if file exists in cache. Default is
  FALSE.

## Value

A tibble with variable definitions.

## Details

The dictionary includes variable names, positions, and widths from the
IBGE input specification file. This is useful for understanding the
structure of the data returned by
[`pnadc_data`](https://sidneybissoli.github.io/healthbR/reference/pnadc_data.md).

## Data source

Dictionaries are downloaded from the IBGE FTP server.

## Examples

``` r
# \donttest{
# get dictionary for deficiencia module
dict <- pnadc_dictionaries(module = "deficiencia", cache_dir = tempdir())
#> Using year 2024 for dictionary (only one year at a time).
#> ℹ Using cached file: input_PNADC_trimestre3_20251017.txt
#> ✔ Dictionary cached: pnadc_dict_deficiencia_2024.rds
# }
```
