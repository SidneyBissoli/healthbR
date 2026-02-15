# Clear ANS Cache

Deletes cached ANS data files.

## Usage

``` r
ans_clear_cache(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Character. Cache directory path. Default:
  `tools::R_user_dir("healthbR", "cache")`.

## Value

Invisible NULL.

## See also

Other ans:
[`ans_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/ans_cache_status.md),
[`ans_data()`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md),
[`ans_info()`](https://sidneybissoli.github.io/healthbR/reference/ans_info.md),
[`ans_operators()`](https://sidneybissoli.github.io/healthbR/reference/ans_operators.md),
[`ans_variables()`](https://sidneybissoli.github.io/healthbR/reference/ans_variables.md),
[`ans_years()`](https://sidneybissoli.github.io/healthbR/reference/ans_years.md)

## Examples

``` r
if (FALSE) { # interactive()
ans_clear_cache()
}
```
