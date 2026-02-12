# Download SI-PNI Vaccination Data

Downloads and returns vaccination data (doses applied or coverage) from
DATASUS FTP. Data is aggregated (counts per municipality/vaccine/age
group), not individual-level microdata.

## Usage

``` r
sipni_data(
  year,
  type = "DPNI",
  uf = NULL,
  vars = NULL,
  cache = TRUE,
  cache_dir = NULL
)
```

## Arguments

- year:

  Integer. Year(s) of the data. Required.

- type:

  Character. File type to download. Default: `"DPNI"` (doses applied).
  Use `"CPNI"` for vaccination coverage. See
  [`sipni_info()`](https://sidneybissoli.github.io/healthbR/reference/sipni_info.md)
  for details.

- uf:

  Character. Two-letter state abbreviation(s) to download. If NULL
  (default), downloads all 27 states. Example: `"SP"`, `c("SP", "RJ")`.

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

## Details

Data is downloaded from DATASUS FTP as plain .DBF files (one per
type/state/year). Unlike other DATASUS modules, SI-PNI files are not
DBC-compressed.

SI-PNI data is **aggregated** (dose counts and coverage rates per
municipality, vaccine, and age group), not individual-level microdata.

Two file types are available:

- `"DPNI"` (default): Doses applied – monthly data within each annual
  file, with age group and dose type breakdowns.

- `"CPNI"`: Vaccination coverage – annual rates including target
  population and coverage percentage.

Data on DATASUS FTP is available from 1994 to 2019. Post-2019 data
requires the SI-PNI web API (not yet supported).

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
# doses applied in Acre, 2019
ac_doses <- sipni_data(year = 2019, uf = "AC")

# vaccination coverage in Acre, 2019
ac_cob <- sipni_data(year = 2019, type = "CPNI", uf = "AC")

# only key variables
sipni_data(year = 2019, uf = "AC",
           vars = c("IMUNO", "QT_DOSE", "DOSE", "FX_ETARIA"))
}
```
