# Clear PNS cache

Removes all cached PNS data files.

## Usage

``` r
pns_clear_cache(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Character. Optional custom cache directory. If NULL (default), uses
  the standard user cache directory.

## Value

NULL (invisibly)

## Examples

``` r
pns_clear_cache()
#> ℹ Cache is already empty
```
