# Clear SISAB Cache

Deletes cached SISAB data files.

## Usage

``` r
sisab_clear_cache(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Character. Cache directory path. Default:
  `tools::R_user_dir("healthbR", "cache")`.

## Value

Invisible NULL.

## See also

Other sisab:
[`sisab_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sisab_cache_status.md),
[`sisab_data()`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md),
[`sisab_info()`](https://sidneybissoli.github.io/healthbR/reference/sisab_info.md),
[`sisab_variables()`](https://sidneybissoli.github.io/healthbR/reference/sisab_variables.md),
[`sisab_years()`](https://sidneybissoli.github.io/healthbR/reference/sisab_years.md)

## Examples

``` r
if (FALSE) { # interactive()
sisab_clear_cache()
}
```
