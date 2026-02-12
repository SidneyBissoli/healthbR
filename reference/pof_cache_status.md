# Get POF cache status

Shows cache status including downloaded files and their sizes.

## Usage

``` r
pof_cache_status(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Character. Optional custom cache directory. If NULL (default), uses
  the standard user cache directory.

## Value

A tibble with cache information

## See also

Other pof:
[`pof_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/pof_clear_cache.md),
[`pof_data()`](https://sidneybissoli.github.io/healthbR/reference/pof_data.md),
[`pof_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/pof_dictionary.md),
[`pof_info()`](https://sidneybissoli.github.io/healthbR/reference/pof_info.md),
[`pof_registers()`](https://sidneybissoli.github.io/healthbR/reference/pof_registers.md),
[`pof_variables()`](https://sidneybissoli.github.io/healthbR/reference/pof_variables.md),
[`pof_years()`](https://sidneybissoli.github.io/healthbR/reference/pof_years.md)

## Examples

``` r
pof_cache_status()
#> ℹ Cache is empty
#> # A tibble: 0 × 3
#> # ℹ 3 variables: file <chr>, size_mb <dbl>, modified <dttm>
```
