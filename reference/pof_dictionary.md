# Get POF variable dictionary

Downloads and returns the variable dictionary for POF microdata. The
dictionary is cached locally to avoid repeated downloads.

## Usage

``` r
pof_dictionary(
  year = "2017-2018",
  register = NULL,
  cache_dir = NULL,
  refresh = FALSE
)
```

## Arguments

- year:

  Character. POF edition (e.g., "2017-2018"). Default is "2017-2018".

- register:

  Character. Register name. If NULL, returns all registers. Default is
  NULL.

- cache_dir:

  Character. Directory for caching downloaded files. Default uses
  `tools::R_user_dir("healthbR", "cache")`.

- refresh:

  Logical. If TRUE, re-download even if file exists in cache. Default is
  FALSE.

## Value

A tibble with variable definitions including: variable, description,
position, length, decimals, register.

## See also

[`pof_variables`](https://sidneybissoli.github.io/healthbR/reference/pof_variables.md),
[`pof_data`](https://sidneybissoli.github.io/healthbR/reference/pof_data.md)

Other pof:
[`pof_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/pof_cache_status.md),
[`pof_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/pof_clear_cache.md),
[`pof_data()`](https://sidneybissoli.github.io/healthbR/reference/pof_data.md),
[`pof_info()`](https://sidneybissoli.github.io/healthbR/reference/pof_info.md),
[`pof_registers()`](https://sidneybissoli.github.io/healthbR/reference/pof_registers.md),
[`pof_variables()`](https://sidneybissoli.github.io/healthbR/reference/pof_variables.md),
[`pof_years()`](https://sidneybissoli.github.io/healthbR/reference/pof_years.md)

## Examples

``` r
if (FALSE) { # interactive()
pof_dictionary("2017-2018", "morador", cache_dir = tempdir())
}
```
