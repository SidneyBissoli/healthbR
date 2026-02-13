# Show SISAB Cache Status

Shows information about cached SISAB data files.

## Usage

``` r
sisab_cache_status(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Character. Cache directory path. Default:
  `tools::R_user_dir("healthbR", "cache")`.

## Value

A tibble with cache file information (invisibly).

## See also

Other sisab:
[`sisab_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sisab_clear_cache.md),
[`sisab_data()`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md),
[`sisab_info()`](https://sidneybissoli.github.io/healthbR/reference/sisab_info.md),
[`sisab_variables()`](https://sidneybissoli.github.io/healthbR/reference/sisab_variables.md),
[`sisab_years()`](https://sidneybissoli.github.io/healthbR/reference/sisab_years.md)

## Examples

``` r
sisab_cache_status()
#> No cached SISAB files found.
```
