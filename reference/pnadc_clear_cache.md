# Clear PNADC cache

Removes all cached PNADC data files.

## Usage

``` r
pnadc_clear_cache(module = NULL, cache_dir = NULL)
```

## Arguments

- module:

  Character. Optional module to clear cache for. If NULL (default),
  clears cache for all modules.

- cache_dir:

  Character. Optional custom cache directory. If NULL (default), uses
  the standard user cache directory.

## Value

NULL (invisibly)

## Examples

``` r
pnadc_clear_cache()
#> ℹ Cache is already empty
```
