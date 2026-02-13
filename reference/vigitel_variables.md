# List VIGITEL variables

Returns a tibble with information about available variables in the
VIGITEL dataset.

## Usage

``` r
vigitel_variables(cache_dir = NULL, force = FALSE)
```

## Arguments

- cache_dir:

  Character. Directory for caching downloaded files. Default uses
  `tools::R_user_dir("healthbR", "cache")`.

- force:

  Logical. If TRUE, re-download even if file exists in cache. Default is
  FALSE.

## Value

A tibble with variable information from the dictionary.

## Examples

``` r
if (FALSE) { # interactive()
vars <- vigitel_variables(cache_dir = tempdir())
head(vars)
}
```
