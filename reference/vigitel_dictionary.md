# Get VIGITEL variable dictionary

Downloads and returns the VIGITEL data dictionary containing variable
descriptions, codes, and categories.

## Usage

``` r
vigitel_dictionary(cache_dir = NULL, force = FALSE)
```

## Arguments

- cache_dir:

  Character. Directory for caching downloaded files. Default uses
  `tools::R_user_dir("healthbR", "cache")`.

- force:

  Logical. If TRUE, re-download even if file exists in cache. Default is
  FALSE.

## Value

A tibble with variable dictionary.

## Examples

``` r
if (FALSE) { # interactive()
dict <- vigitel_dictionary(cache_dir = tempdir())
head(dict)
}
```
