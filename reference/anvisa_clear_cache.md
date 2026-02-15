# Clear ANVISA Cache

Deletes cached ANVISA data files.

## Usage

``` r
anvisa_clear_cache(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Character. Cache directory path. Default:
  `tools::R_user_dir("healthbR", "cache")`.

## Value

Invisible NULL.

## See also

Other anvisa:
[`anvisa_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_cache_status.md),
[`anvisa_data()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_data.md),
[`anvisa_info()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_info.md),
[`anvisa_types()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_types.md),
[`anvisa_variables()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_variables.md)

## Examples

``` r
if (FALSE) { # interactive()
anvisa_clear_cache()
}
```
