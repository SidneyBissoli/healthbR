# Download ANS Operators Registry

Downloads and returns the current registry of health plan operators from
the ANS open data portal. This is a snapshot of the current operator
status (not time-series data).

## Usage

``` r
ans_operators(status = "active", vars = NULL, cache = TRUE, cache_dir = NULL)
```

## Arguments

- status:

  Character. Filter by operator status:

  - `"active"`: Active operators only (default).

  - `"cancelled"`: Cancelled operators only.

  - `"all"`: Both active and cancelled.

- vars:

  Character vector. Variables to keep. If NULL (default), returns all 20
  variables. Use `ans_variables(type = "operators")` to see available
  variables.

- cache:

  Logical. If TRUE (default), caches downloaded data.

- cache_dir:

  Character. Directory for caching.

## Value

A tibble with operator data. When `status = "all"`, includes a `status`
column indicating "active" or "cancelled".

## See also

Other ans:
[`ans_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/ans_cache_status.md),
[`ans_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/ans_clear_cache.md),
[`ans_data()`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md),
[`ans_info()`](https://sidneybissoli.github.io/healthbR/reference/ans_info.md),
[`ans_variables()`](https://sidneybissoli.github.io/healthbR/reference/ans_variables.md),
[`ans_years()`](https://sidneybissoli.github.io/healthbR/reference/ans_years.md)

## Examples

``` r
if (FALSE) { # interactive()
# active operators
ops <- ans_operators()

# all operators (active + cancelled)
all_ops <- ans_operators(status = "all")
}
```
