# Show ANVISA Cache Status

Shows information about cached ANVISA data files.

## Usage

``` r
anvisa_cache_status(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Character. Cache directory path. Default:
  `tools::R_user_dir("healthbR", "cache")`.

## Value

A tibble with cache file information (invisibly).

## See also

Other anvisa:
[`anvisa_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_clear_cache.md),
[`anvisa_data()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_data.md),
[`anvisa_info()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_info.md),
[`anvisa_types()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_types.md),
[`anvisa_variables()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_variables.md)

## Examples

``` r
anvisa_cache_status()
#> No cached ANVISA files found.
```
