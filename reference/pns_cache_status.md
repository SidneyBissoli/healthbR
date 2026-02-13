# Get PNS cache status

Shows cache status including downloaded files and their sizes.

## Usage

``` r
pns_cache_status(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Character. Optional custom cache directory. If NULL (default), uses
  the standard user cache directory.

## Value

A tibble with cache information

## Examples

``` r
pns_cache_status()
#> ℹ Cache is empty
#> # A tibble: 0 × 3
#> # ℹ 3 variables: file <chr>, size_mb <dbl>, modified <dttm>
```
