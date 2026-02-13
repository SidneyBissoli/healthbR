# Clear VIGITEL cache

Removes all cached VIGITEL data files.

## Usage

``` r
vigitel_clear_cache(keep_parquet = FALSE, cache_dir = NULL)
```

## Arguments

- keep_parquet:

  Logical. If TRUE, keep parquet cache and only remove source files
  (ZIP, DTA, CSV). Default is FALSE (remove all).

- cache_dir:

  Character. Optional custom cache directory. If NULL (default), uses
  the standard user cache directory.

## Value

NULL (invisibly)

## Examples

``` r
# remove all cached files from default cache
vigitel_clear_cache()
#> ℹ Cache is already empty
```
