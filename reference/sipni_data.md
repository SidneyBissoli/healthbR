# Download SI-PNI Vaccination Data

Downloads and returns vaccination data from SI-PNI. For years 1994–2019,
data is downloaded from DATASUS FTP (aggregated doses/coverage). For
years 2020+, data is downloaded from OpenDataSUS as monthly CSV bulk
files (individual-level microdata with one row per vaccination dose).

## Usage

``` r
sipni_data(
  year,
  type = "DPNI",
  uf = NULL,
  month = NULL,
  vars = NULL,
  cache = TRUE,
  cache_dir = NULL
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

- cache:

  Logical. If TRUE (default), caches downloaded data for faster future
  access.

- cache_dir:

  Character. Directory for caching. Default:
  `tools::R_user_dir("healthbR", "cache")`.

## Value

A tibble with vaccination data. Includes columns `year` and `uf_source`
to identify the source when multiple years/states are combined.

**Output differs by year range:**

- **1994–2019 (FTP)**: Aggregated data with DPNI (12 vars) or CPNI (7
  vars) columns, all character.

- **2020+ (CSV)**: Individual-level microdata with ~47 columns
  (snake_case Portuguese), all character. Use
  `sipni_variables(type = "API")` to see the full list.

## Details

**FTP data (1994–2019):** Downloaded as plain .DBF files. SI-PNI FTP
data is **aggregated** (dose counts and coverage rates per municipality,
vaccine, and age group). Two file types: DPNI (doses) and CPNI
(coverage).

**CSV data (2020+):** Downloaded from OpenDataSUS as monthly CSV bulk
files (national, semicolon-delimited, latin1 encoding). Each monthly ZIP
is ~1.4 GB. This is **individual-level microdata** (one row per
vaccination dose, ~47 fields per record). The `type` parameter is
ignored for CSV years. Data is filtered by UF during chunked reading to
avoid loading the full national file into memory.

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
