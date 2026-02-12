# Show SI-PNI Cache Status

Shows information about cached SI-PNI data files.

## Usage

``` r
sipni_cache_status(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Character. Cache directory path. Default:
  `tools::R_user_dir("healthbR", "cache")`.

## Value

A tibble with cache file information (invisibly).

## See also

Other sipni:
[`sipni_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sipni_clear_cache.md),
[`sipni_data()`](https://sidneybissoli.github.io/healthbR/reference/sipni_data.md),
[`sipni_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sipni_dictionary.md),
[`sipni_info()`](https://sidneybissoli.github.io/healthbR/reference/sipni_info.md),
[`sipni_variables()`](https://sidneybissoli.github.io/healthbR/reference/sipni_variables.md),
[`sipni_years()`](https://sidneybissoli.github.io/healthbR/reference/sipni_years.md)

## Examples

``` r
sipni_cache_status()
#> No cached SI-PNI files found.
```
