# List PNADC variables

Returns a list of available variables in the PNADC microdata for a given
module. This is a convenience wrapper around
[`pnadc_dictionaries`](https://sidneybissoli.github.io/healthbR/reference/pnadc_dictionaries.md).

## Usage

``` r
pnadc_variables(module, year = NULL, cache_dir = NULL, refresh = FALSE)
```

## Arguments

- module:

  Character. The module identifier (e.g., "deficiencia", "habitacao").

- year:

  Numeric. Year to get variables for. Uses most recent year if NULL.

- cache_dir:

  Character. Directory for caching downloaded files. Default uses
  `tools::R_user_dir("healthbR", "cache")`.

- refresh:

  Logical. If TRUE, re-download even if file exists in cache. Default is
  FALSE.

## Value

A character vector of variable names.

## Examples

``` r
if (FALSE) { # interactive()
# list variables for deficiencia module
pnadc_variables(module = "deficiencia", cache_dir = tempdir())
}
```
