# Download CNES Health Facility Registry Data

Downloads and returns health facility registry data from DATASUS FTP.
Each row represents one health facility record (for the ST type). Data
is organized monthly – one .dbc file per type, state (UF), and month.

## Usage

``` r
cnes_data(
  year,
  type = "ST",
  month = NULL,
  vars = NULL,
  uf = NULL,
  cache = TRUE,
  cache_dir = NULL
)
```

## Arguments

- year:

  Integer. Year(s) of the data. Required.

- type:

  Character. File type to download. Default: `"ST"` (establishments).
  See
  [`cnes_info()`](https://sidneybissoli.github.io/healthbR/reference/cnes_info.md)
  for all 13 types.

- month:

  Integer. Month(s) of the data (1-12). If NULL (default), downloads all
  12 months. Example: `1` (January), `1:6` (first semester).

- vars:

  Character vector. Variables to keep. If NULL (default), returns all
  available variables. Use
  [`cnes_variables()`](https://sidneybissoli.github.io/healthbR/reference/cnes_variables.md)
  to see available variables.

- uf:

  Character. Two-letter state abbreviation(s) to download. If NULL
  (default), downloads all 27 states. Example: `"SP"`, `c("SP", "RJ")`.

- cache:

  Logical. If TRUE (default), caches downloaded data for faster future
  access.

- cache_dir:

  Character. Directory for caching. Default:
  `tools::R_user_dir("healthbR", "cache")`.

## Value

A tibble with health facility data. Includes columns `year`, `month`,
and `uf_source` to identify the source when multiple years/months/states
are combined.

## Details

Data is downloaded from DATASUS FTP as .dbc files (one per
type/state/month). The .dbc format is decompressed internally using
vendored C code from the blast library. No external dependencies are
required.

CNES data is monthly, so downloading an entire year for all states
requires 324 files (27 UFs x 12 months) per type. Use `uf` and `month`
to limit downloads.

The CNES has 13 file types. The default `"ST"` (establishments) is the
most commonly used. Use
[`cnes_info()`](https://sidneybissoli.github.io/healthbR/reference/cnes_info.md)
to see all types.

## See also

[`cnes_info()`](https://sidneybissoli.github.io/healthbR/reference/cnes_info.md)
for file type descriptions,
[`censo_populacao()`](https://sidneybissoli.github.io/healthbR/reference/censo_populacao.md)
for population denominators.

Other cnes:
[`cnes_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/cnes_cache_status.md),
[`cnes_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/cnes_clear_cache.md),
[`cnes_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/cnes_dictionary.md),
[`cnes_info()`](https://sidneybissoli.github.io/healthbR/reference/cnes_info.md),
[`cnes_variables()`](https://sidneybissoli.github.io/healthbR/reference/cnes_variables.md),
[`cnes_years()`](https://sidneybissoli.github.io/healthbR/reference/cnes_years.md)

## Examples

``` r
if (FALSE) { # interactive()
# all establishments in Acre, January 2023
ac_jan <- cnes_data(year = 2023, month = 1, uf = "AC")

# only key variables
cnes_data(year = 2023, month = 1, uf = "AC",
          vars = c("CNES", "CODUFMUN", "TP_UNID", "VINC_SUS"))

# hospital beds
leitos <- cnes_data(year = 2023, month = 1, uf = "AC", type = "LT")

# health professionals
prof <- cnes_data(year = 2023, month = 1, uf = "AC", type = "PF")
}
```
