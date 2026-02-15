# Download ANS Data

Downloads and returns data from the ANS (Agencia Nacional de Saude
Suplementar) open data portal. Supports three data types: beneficiary
counts, consumer complaints (NIP), and financial statements.

## Usage

``` r
ans_data(
  year,
  type = "beneficiaries",
  uf = NULL,
  month = NULL,
  quarter = NULL,
  vars = NULL,
  cache = TRUE,
  cache_dir = NULL,
  lazy = FALSE,
  backend = c("arrow", "duckdb")
)
```

## Arguments

- year:

  Integer. Year(s) of the data. Required.

- type:

  Character. Type of data. One of:

  - `"beneficiaries"`: Consolidated beneficiary counts (default). Uses
    `year`, `month`, `uf` parameters.

  - `"complaints"`: Consumer complaints via NIP. Uses `year` only
    (national data).

  - `"financial"`: Financial statements. Uses `year`, `quarter`
    parameters.

- uf:

  Character. Two-letter state abbreviation(s). Only used for
  `type = "beneficiaries"`. Includes `"XX"` for unidentified
  beneficiaries. If NULL (default), downloads all 27 states.

- month:

  Integer. Month(s) 1-12. Only used for `type = "beneficiaries"`. If
  NULL (default), downloads all months. Note: 2019 starts at month 4
  (April).

- quarter:

  Integer. Quarter(s) 1-4. Only used for `type = "financial"`. If NULL
  (default), downloads all 4 quarters.

- vars:

  Character vector. Variables to keep. If NULL (default), returns all
  available variables. Use
  [`ans_variables()`](https://sidneybissoli.github.io/healthbR/reference/ans_variables.md)
  to see available variables per type.

- cache:

  Logical. If TRUE (default), caches downloaded data for faster future
  access.

- cache_dir:

  Character. Directory for caching. Default:
  `tools::R_user_dir("healthbR", "cache")`.

- lazy:

  Logical. If TRUE, returns a lazy query object instead of a tibble.
  Requires the arrow package. Default: FALSE.

- backend:

  Character. Backend for lazy evaluation: `"arrow"` (default) or
  `"duckdb"`. Only used when `lazy = TRUE`.

## Value

A tibble with ANS data. Includes partition columns: `year` (all types),
`month` and `uf_source` (beneficiaries), `quarter` (financial).

## Details

Data is downloaded from the ANS open data portal at
`https://dadosabertos.ans.gov.br/`.

**Beneficiaries**: Monthly per-state ZIP files containing CSV data with
consolidated beneficiary counts by operator, plan type, sex, age group,
and municipality. Available from April 2019.

**Complaints**: Annual national CSV files with consumer complaints filed
through the NIP (Notificacao de Intermediacao Preliminar). Available
from 2011.

**Financial**: Quarterly ZIP files with financial statements of health
plan operators (balance sheets, income statements). Available from 2007.

## See also

[`ans_operators()`](https://sidneybissoli.github.io/healthbR/reference/ans_operators.md)
for the operator registry,
[`ans_variables()`](https://sidneybissoli.github.io/healthbR/reference/ans_variables.md)
for variable descriptions.

Other ans:
[`ans_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/ans_cache_status.md),
[`ans_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/ans_clear_cache.md),
[`ans_info()`](https://sidneybissoli.github.io/healthbR/reference/ans_info.md),
[`ans_operators()`](https://sidneybissoli.github.io/healthbR/reference/ans_operators.md),
[`ans_variables()`](https://sidneybissoli.github.io/healthbR/reference/ans_variables.md),
[`ans_years()`](https://sidneybissoli.github.io/healthbR/reference/ans_years.md)

## Examples

``` r
if (FALSE) { # interactive()
# beneficiary counts for Acre, December 2023
ac <- ans_data(year = 2023, month = 12, uf = "AC")

# consumer complaints for 2022
nip <- ans_data(year = 2022, type = "complaints")

# financial statements Q1 2023
fin <- ans_data(year = 2023, type = "financial", quarter = 1)
}
```
