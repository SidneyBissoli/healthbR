# Download ANVISA Data

Downloads and returns data from the ANVISA (Agencia Nacional de
Vigilancia Sanitaria) open data portal. Supports 14 data types across 4
categories: product registrations, reference tables, post-market
surveillance, and controlled substance sales (SNGPC).

## Usage

``` r
anvisa_data(
  type = "medicines",
  year = NULL,
  month = NULL,
  vars = NULL,
  cache = TRUE,
  cache_dir = NULL,
  lazy = FALSE,
  backend = c("arrow", "duckdb")
)
```

## Arguments

- type:

  Character. Type of data to download. Default: `"medicines"`. Use
  [`anvisa_types()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_types.md)
  to see all 14 available types.

  **Snapshot types** (no year/month needed): `"medicines"`,
  `"medical_devices"`, `"food"`, `"cosmetics"`, `"sanitizers"`,
  `"tobacco"`, `"pesticides"`, `"hemovigilance"`, `"technovigilance"`,
  `"vigimed_notifications"`, `"vigimed_medicines"`,
  `"vigimed_reactions"`.

  **Time-series types** (year required): `"sngpc"`,
  `"sngpc_compounded"`.

- year:

  Integer. Year(s) of the data. Only used for SNGPC types (2014-2026).
  Ignored with a warning for snapshot types.

- month:

  Integer. Month(s) 1-12. Only used for SNGPC types. If NULL (default),
  downloads all 12 months. Ignored with a warning for snapshot types.

- vars:

  Character vector. Variables to keep. If NULL (default), returns all
  available variables. Use
  [`anvisa_variables()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_variables.md)
  to see available variables per type.

- cache:

  Logical. If TRUE (default), caches downloaded data for faster future
  access.

- cache_dir:

  Character. Directory for caching. Default:
  `tools::R_user_dir("healthbR", "cache")`.

- lazy:

  Logical. If TRUE, returns a lazy query object instead of a tibble.
  Only available for SNGPC types (partitioned cache). Requires the arrow
  package. Default: FALSE.

- backend:

  Character. Backend for lazy evaluation: `"arrow"` (default) or
  `"duckdb"`. Only used when `lazy = TRUE`.

## Value

A tibble with ANVISA data. SNGPC types include `year` and `month`
partition columns.

## Details

Data is downloaded from the ANVISA open data portal at
`https://dados.anvisa.gov.br/dados/`.

**Snapshot types**: Download a single CSV file representing the current
state of the registry/database. No time dimension. Cached as flat files.

**SNGPC types**: Monthly CSV files with controlled substance sales data.
Data available from January 2014 to October 2021, with new data from
January 2026. Cached as Hive-style partitioned parquet datasets.

The three VigiMed types share the `IDENTIFICACAO_NOTIFICACAO` key for
linking notifications, medicines, and reactions.

## See also

[`anvisa_types()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_types.md)
for available types,
[`anvisa_variables()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_variables.md)
for variable descriptions.

Other anvisa:
[`anvisa_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_cache_status.md),
[`anvisa_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_clear_cache.md),
[`anvisa_info()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_info.md),
[`anvisa_types()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_types.md),
[`anvisa_variables()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_variables.md)

## Examples

``` r
if (FALSE) { # interactive()
# registered medicines
med <- anvisa_data(type = "medicines")

# hemovigilance notifications
hemo <- anvisa_data(type = "hemovigilance")

# SNGPC controlled substance sales, Jan 2020
sngpc <- anvisa_data(type = "sngpc", year = 2020, month = 1)
}
```
