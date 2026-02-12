# List PNS variables

Returns a list of available variables in the PNS microdata with their
labels. This is a convenience wrapper around
[`pns_dictionary`](https://sidneybissoli.github.io/healthbR/reference/pns_dictionary.md)
that returns only unique variable names and labels.

## Usage

``` r
pns_variables(year = 2019, module = NULL, cache_dir = NULL, refresh = FALSE)
```

## Arguments

- year:

  Numeric. Year to get variables for (2013 or 2019). Default is 2019.

- module:

  Character. Filter by module code (e.g., "J", "K", "L"). NULL returns
  all modules. Default is NULL.

- cache_dir:

  Character. Directory for caching downloaded files. Default uses
  `tools::R_user_dir("healthbR", "cache")`.

- refresh:

  Logical. If TRUE, re-download even if file exists in cache. Default is
  FALSE.

## Value

A tibble with variable names and labels.

## Examples

``` r
if (FALSE) { # interactive()
# list all variables for 2019
pns_variables(year = 2019, cache_dir = tempdir())

# list variables for a specific module
pns_variables(year = 2019, module = "J", cache_dir = tempdir())
}
```
