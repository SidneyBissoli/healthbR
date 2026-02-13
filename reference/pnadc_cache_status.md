# Get PNADC cache status

Shows cache status including downloaded files and their sizes.

## Usage

``` r
pnadc_cache_status(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Character. Optional custom cache directory. If NULL (default), uses
  the standard user cache directory.

## Value

A tibble with cache information

## Examples

``` r
pnadc_cache_status()
#> ℹ Cache is empty
#> # A tibble: 0 × 5
#> # ℹ 5 variables: file <chr>, module <chr>, year <int>, size_mb <dbl>,
#> #   modified <dttm>
```
