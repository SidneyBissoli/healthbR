# Show SINASC Cache Status

Shows information about cached SINASC data files.

## Usage

``` r
sinasc_cache_status(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Character. Cache directory path. Default:
  `tools::R_user_dir("healthbR", "cache")`.

## Value

A tibble with cache file information (invisibly).

## See also

Other sinasc:
[`sinasc_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_clear_cache.md),
[`sinasc_data()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_data.md),
[`sinasc_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_dictionary.md),
[`sinasc_info()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_info.md),
[`sinasc_variables()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_variables.md),
[`sinasc_years()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_years.md)

## Examples

``` r
sinasc_cache_status()
#> No cached SINASC files found.
```
