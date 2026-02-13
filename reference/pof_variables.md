# List POF variables

Returns a list of available variables in the POF microdata with their
labels. This is a convenience wrapper around
[`pof_dictionary`](https://sidneybissoli.github.io/healthbR/reference/pof_dictionary.md)
that returns a simplified view.

## Usage

``` r
pof_variables(
  year = "2017-2018",
  register = NULL,
  search = NULL,
  cache_dir = NULL,
  refresh = FALSE
)
```

## Arguments

- year:

  Character. POF edition (e.g., "2017-2018"). Default is "2017-2018".

- register:

  Character. Register name (e.g., "morador", "domicilio"). If NULL,
  returns variables from all registers. Default is NULL.

- search:

  Character. Optional search term to filter variables by name or
  description. Default is NULL.

- cache_dir:

  Character. Directory for caching downloaded files. Default uses
  `tools::R_user_dir("healthbR", "cache")`.

- refresh:

  Logical. If TRUE, re-download even if file exists in cache. Default is
  FALSE.

## Value

A tibble with columns: variable, description, position, length,
register.

## See also

[`pof_dictionary`](https://sidneybissoli.github.io/healthbR/reference/pof_dictionary.md),
[`pof_data`](https://sidneybissoli.github.io/healthbR/reference/pof_data.md)

Other pof:
[`pof_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/pof_cache_status.md),
[`pof_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/pof_clear_cache.md),
[`pof_data()`](https://sidneybissoli.github.io/healthbR/reference/pof_data.md),
[`pof_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/pof_dictionary.md),
[`pof_info()`](https://sidneybissoli.github.io/healthbR/reference/pof_info.md),
[`pof_registers()`](https://sidneybissoli.github.io/healthbR/reference/pof_registers.md),
[`pof_years()`](https://sidneybissoli.github.io/healthbR/reference/pof_years.md)

## Examples

``` r
if (FALSE) { # interactive()
pof_variables("2017-2018", "morador", cache_dir = tempdir())
pof_variables("2017-2018", "domicilio", search = "ebia", cache_dir = tempdir())
}
```
