# Clear SINAN Cache

Deletes cached SINAN data files.

## Usage

``` r
sinan_clear_cache(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Character. Cache directory path. Default:
  `tools::R_user_dir("healthbR", "cache")`.

## Value

Invisible NULL.

## See also

Other sinan:
[`sinan_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sinan_cache_status.md),
[`sinan_data()`](https://sidneybissoli.github.io/healthbR/reference/sinan_data.md),
[`sinan_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sinan_dictionary.md),
[`sinan_diseases()`](https://sidneybissoli.github.io/healthbR/reference/sinan_diseases.md),
[`sinan_info()`](https://sidneybissoli.github.io/healthbR/reference/sinan_info.md),
[`sinan_variables()`](https://sidneybissoli.github.io/healthbR/reference/sinan_variables.md),
[`sinan_years()`](https://sidneybissoli.github.io/healthbR/reference/sinan_years.md)

## Examples

``` r
if (FALSE) { # interactive()
sinan_clear_cache()
}
```
