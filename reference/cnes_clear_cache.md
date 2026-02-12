# Clear CNES Cache

Deletes cached CNES data files.

## Usage

``` r
cnes_clear_cache(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Character. Cache directory path. Default:
  `tools::R_user_dir("healthbR", "cache")`.

## Value

Invisible NULL.

## See also

Other cnes:
[`cnes_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/cnes_cache_status.md),
[`cnes_data()`](https://sidneybissoli.github.io/healthbR/reference/cnes_data.md),
[`cnes_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/cnes_dictionary.md),
[`cnes_info()`](https://sidneybissoli.github.io/healthbR/reference/cnes_info.md),
[`cnes_variables()`](https://sidneybissoli.github.io/healthbR/reference/cnes_variables.md),
[`cnes_years()`](https://sidneybissoli.github.io/healthbR/reference/cnes_years.md)

## Examples

``` r
if (FALSE) { # interactive()
cnes_clear_cache()
}
```
