# Show ANS Cache Status

Shows information about cached ANS data files.

## Usage

``` r
ans_cache_status(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Character. Cache directory path. Default:
  `tools::R_user_dir("healthbR", "cache")`.

## Value

A tibble with cache file information (invisibly).

## See also

Other ans:
[`ans_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/ans_clear_cache.md),
[`ans_data()`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md),
[`ans_info()`](https://sidneybissoli.github.io/healthbR/reference/ans_info.md),
[`ans_operators()`](https://sidneybissoli.github.io/healthbR/reference/ans_operators.md),
[`ans_variables()`](https://sidneybissoli.github.io/healthbR/reference/ans_variables.md),
[`ans_years()`](https://sidneybissoli.github.io/healthbR/reference/ans_years.md)

## Examples

``` r
ans_cache_status()
#> No cached ANS files found.
```
