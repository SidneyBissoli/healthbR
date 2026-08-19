# Download SI-PNI Vaccination Data

Downloads and returns vaccination data from SI-PNI. For years 1994–2019
the data are aggregated (doses applied / coverage); for years 2020+ they
are individual-level microdata (one row per vaccination dose).

## Usage

``` r
sipni_data(
  year,
  type = "DPNI",
  uf = NULL,
  month = NULL,
  vars = NULL,
  parse = TRUE,
  col_types = NULL,
  cache = TRUE,
  cache_dir = NULL,
  lazy = FALSE,
  backend = c("arrow", "duckdb"),
  source = c("r2", "datasus"),
  r2_credentials = NULL
)
```

## Arguments

- year:

  Integer. Year(s) of the data. Required.

- type:

  Character. File type for FTP data (1994–2019). Default: `"DPNI"`
  (doses applied). Use `"CPNI"` for vaccination coverage. Ignored for
  years \>= 2020 (API data is always microdata).

- uf:

  Character. Two-letter state abbreviation(s) to download. If NULL
  (default), downloads all 27 states. Example: `"SP"`, `c("SP", "RJ")`.

- month:

  Integer. Month(s) to download (1–12). For years \>= 2020 (CSV),
  selects which monthly CSV files to download. For years \<= 2019 (FTP),
  this parameter is ignored (FTP files are annual). If NULL (default),
  downloads all 12 months.

- vars:

  Character vector. Variables to keep. If NULL (default), returns all
  available variables. Use
  [`sipni_variables()`](https://sidneybissoli.github.io/healthbR/reference/sipni_variables.md)
  to see available variables.

- parse:

  Logical. If TRUE (default), converts columns to appropriate types
  (integer, double, Date) based on the variable metadata. Use
  [`sipni_variables()`](https://sidneybissoli.github.io/healthbR/reference/sipni_variables.md)
  to see the target type for each variable. Set to FALSE for
  backward-compatible all-character output.

- col_types:

  Named list. Override the default type for specific columns. Names are
  column names, values are type strings: `"character"`, `"integer"`,
  `"double"`, `"date_dmy"`, `"date_ymd"`, `"date_ym"`, `"date"`.
  Example: `list(QT_DOSE = "character")` to keep QT_DOSE as character.

- cache:

  Logical. If TRUE (default), caches downloaded data for faster future
  access.

- cache_dir:

  Character. Directory for caching. Default:
  `tools::R_user_dir("healthbR", "cache")`.

- lazy:

  Logical. If TRUE, returns a lazy query object instead of a tibble.
  Requires the arrow package. The lazy object supports dplyr verbs
  (filter, select, mutate, etc.) which are pushed down to the query
  engine before collecting into memory. Call
  [`dplyr::collect()`](https://dplyr.tidyverse.org/reference/compute.html)
  to materialize the result. Default: FALSE.

- backend:

  Character. Backend for lazy evaluation: `"arrow"` (default) or
  `"duckdb"`. Only used when `lazy = TRUE`. DuckDB backend requires the
  duckdb package.

- source:

  Character vector. Data source(s) in priority order: `"r2"`
  (healthbr-data mirror on Cloudflare R2, Parquet) and/or `"datasus"`
  (DATASUS FTP for 1994–2019, OpenDataSUS CSV for 2020+). The default
  `c("r2", "datasus")` tries the mirror first and falls back to the
  official source automatically; pass a single value to disable the
  fallback. Note: as of 2026 the Ministry removed the 2020–2025
  microdata files from OpenDataSUS, so those years are only served by
  `"r2"`. The R2 backend requires the arrow package.

- r2_credentials:

  List or NULL. Credentials for the R2 backend. If NULL (default), uses
  the public read-only token of the healthbr-data bucket. To point at
  another S3-compatible bucket, pass
  `list(access_key_id =, secret_access_key =, endpoint =, bucket =)`.

## Value

A tibble with vaccination data. Includes columns `year`, `uf_source`
(and `month` for 2020+) to identify the source partition when multiple
years/states are combined. Attributes: `healthbr_source` (which source
served each era) and, for R2 reads, `healthbr_provenance` (per-partition
processing timestamp and Ministry source URL from the mirror manifests).

**Output differs by year range 2014 and, for 2020+, by source:**

- **1994–2019 (aggregated)**: DPNI (12 vars) or CPNI (7 vars) columns.
  Identical for both sources.

- **2020+ via R2 (default)**: 56 fields from the Ministry's JSON exports
  (`dt_vacina`, `ds_vacina`, `sg_uf_paciente`, ...). Use
  `sipni_variables(type = "API", source = "r2")` to see the list.

- **2020+ via DATASUS CSV**: ~47 fields with different names
  (`data_vacina`, `descricao_vacina`, ...). Use
  `sipni_variables(type = "API", source = "datasus")`.

Each source returns its columns exactly as published by the Ministry;
healthbR does not rename or remap them.

## Details

By default data are read from the **healthbr-data R2 mirror** (Parquet
on Cloudflare R2, values byte-identical to the Ministry's files,
complete 2020+ series), falling back automatically to the official
DATASUS/ OpenDataSUS sources if the mirror is unreachable 2014 see
`source`. The result carries a `healthbr_source` attribute recording
which source actually served each era, and (for R2 reads) a
`healthbr_provenance` attribute with the processing timestamp and
Ministry source URL of each partition, taken from the mirror's
manifests.

**Aggregated data (1994–2019):** SI-PNI aggregated data (dose counts and
coverage rates per municipality, vaccine, and age group). Two file
types: DPNI (doses) and CPNI (coverage). Served from the R2 mirror as
Parquet, or from DATASUS FTP as plain .DBF files.

**Microdata (2020+):** Individual-level microdata (one row per
vaccination dose). The `type` parameter is ignored for these years. Via
R2 the data come from the Ministry's JSON exports (no CSV serialization
artifacts) and only the requested UF/month partitions are transferred.
Via DATASUS the national monthly CSV ZIP (~1.4 GB) is downloaded and
filtered by UF during chunked reading.

**Availability note (2026):** the Ministry decommissioned the old
OpenDataSUS host and removed the 2020–2025 files from the new one. The
R2 mirror holds the complete series; use
[`sipni_status()`](https://sidneybissoli.github.io/healthbR/reference/sipni_status.md)
to see exactly which months are published and when they were processed.

**Lazy evaluation with R2:** with `lazy = TRUE` and the default source,
the function returns the remote arrow dataset itself 2014 dplyr verbs
are pushed down and only the touched partitions are transferred. In this
mode the partition columns keep the bucket layout names (`ano`, `mes`,
`uf`, as strings) instead of `year`/`month`/`uf_source`.

### Parallel downloads

When downloading multiple files (e.g., several years or states), install
furrr and future and set a parallel plan to speed up downloads:
`future::plan(future::multisession, workers = 4)`. See
[`vignette("healthbR")`](https://sidneybissoli.github.io/healthbR/articles/healthbR.md)
for details.

## See also

[`sipni_info()`](https://sidneybissoli.github.io/healthbR/reference/sipni_info.md)
for type descriptions,
[`censo_populacao()`](https://sidneybissoli.github.io/healthbR/reference/censo_populacao.md)
for population denominators.

Other sipni:
[`sipni_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sipni_cache_status.md),
[`sipni_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sipni_clear_cache.md),
[`sipni_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sipni_dictionary.md),
[`sipni_info()`](https://sidneybissoli.github.io/healthbR/reference/sipni_info.md),
[`sipni_status()`](https://sidneybissoli.github.io/healthbR/reference/sipni_status.md),
[`sipni_variables()`](https://sidneybissoli.github.io/healthbR/reference/sipni_variables.md),
[`sipni_years()`](https://sidneybissoli.github.io/healthbR/reference/sipni_years.md)

## Examples

``` r
if (FALSE) { # interactive()
# FTP: doses applied in Acre, 2019
ac_doses <- sipni_data(year = 2019, uf = "AC")

# FTP: vaccination coverage in Acre, 2019
ac_cob <- sipni_data(year = 2019, type = "CPNI", uf = "AC")

# API: microdata for Acre, January 2024
ac_api <- sipni_data(year = 2024, uf = "AC", month = 1)

# API: select specific variables
sipni_data(year = 2024, uf = "AC", month = 1,
           vars = c("descricao_vacina", "tipo_sexo_paciente",
                    "data_vacina"))
}
```
