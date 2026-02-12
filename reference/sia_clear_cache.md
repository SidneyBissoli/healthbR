# Clear SIA Cache

Deletes cached SIA data files.

## Usage

``` r
sia_clear_cache(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Character. Cache directory path. Default:
  `tools::R_user_dir("healthbR", "cache")`.

## Value

Invisible NULL.

## See also

Other sia:
[`sia_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sia_cache_status.md),
[`sia_data()`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md),
[`sia_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sia_dictionary.md),
[`sia_info()`](https://sidneybissoli.github.io/healthbR/reference/sia_info.md),
[`sia_variables()`](https://sidneybissoli.github.io/healthbR/reference/sia_variables.md),
[`sia_years()`](https://sidneybissoli.github.io/healthbR/reference/sia_years.md)

## Examples

``` r
# \donttest{
sia_clear_cache()
#> No cached SIA files to clear.
# }
```
