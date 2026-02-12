# Show CNES Cache Status

Shows information about cached CNES data files.

## Usage

``` r
cnes_cache_status(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Character. Cache directory path. Default:
  `tools::R_user_dir("healthbR", "cache")`.

## Value

A tibble with cache file information (invisibly).

## See also

Other cnes:
[`cnes_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/cnes_clear_cache.md),
[`cnes_data()`](https://sidneybissoli.github.io/healthbR/reference/cnes_data.md),
[`cnes_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/cnes_dictionary.md),
[`cnes_info()`](https://sidneybissoli.github.io/healthbR/reference/cnes_info.md),
[`cnes_variables()`](https://sidneybissoli.github.io/healthbR/reference/cnes_variables.md),
[`cnes_years()`](https://sidneybissoli.github.io/healthbR/reference/cnes_years.md)

## Examples

``` r
cnes_cache_status()
#> No cached CNES files found.
```
