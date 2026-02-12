# Clear SIM Cache

Deletes cached SIM data files.

## Usage

``` r
sim_clear_cache(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Character. Cache directory path. Default:
  `tools::R_user_dir("healthbR", "cache")`.

## Value

Invisible NULL.

## See also

Other sim:
[`sim_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sim_cache_status.md),
[`sim_data()`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md),
[`sim_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sim_dictionary.md),
[`sim_info()`](https://sidneybissoli.github.io/healthbR/reference/sim_info.md),
[`sim_variables()`](https://sidneybissoli.github.io/healthbR/reference/sim_variables.md),
[`sim_years()`](https://sidneybissoli.github.io/healthbR/reference/sim_years.md)

## Examples

``` r
# \donttest{
sim_clear_cache()
#> No cached SIM files to clear.
# }
```
