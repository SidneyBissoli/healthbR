# Download VIGITEL microdata

Downloads and returns VIGITEL survey microdata from the Ministry of
Health. Data is cached locally to avoid repeated downloads. When the
`arrow` package is installed, data is cached in partitioned parquet
format for faster subsequent reads.

## Usage

``` r
vigitel_data(
  year = NULL,
  format = c("dta", "csv"),
  vars = NULL,
  cache_dir = NULL,
  force = FALSE
)
```

## Arguments

- year:

  Integer or vector of integers. Years to return (2006-2024). Use NULL
  to return all years. Default is NULL.

- format:

  Character. File format to download: "dta" (Stata, default) or "csv".
  Stata format preserves variable labels.

- vars:

  Character vector. Variables to select. Use NULL for all variables.
  Default is NULL.

- cache_dir:

  Character. Directory for caching downloaded files. Default uses
  `tools::R_user_dir("healthbR", "cache")`.

- force:

  Logical. If TRUE, re-download even if file exists in cache. Default is
  FALSE.

## Value

A tibble with VIGITEL microdata.

## Details

The VIGITEL survey (Vigilância de Fatores de Risco e Proteção para
Doenças Crônicas por Inquérito Telefônico) is conducted annually by the
Brazilian Ministry of Health in all state capitals and the Federal
District.

Data includes information on:

- Demographics (age, sex, education, race)

- Health behaviors (smoking, alcohol, diet, physical activity)

- Health conditions (hypertension, diabetes, obesity)

- Healthcare utilization

The survey uses post-stratification weights (variable `pesorake`) to
produce population estimates. Always use these weights for statistical
inference.

### Performance

When the `arrow` package is installed, data is cached in partitioned
parquet format. This allows the function to read only the requested
years without loading the entire dataset into memory. If you frequently
work with VIGITEL data, installing `arrow` is highly recommended:

    install.packages("arrow")

## Data source

Data is downloaded from the Ministry of Health website:
<https://svs.aids.gov.br/daent/cgdnt/vigitel/>

## Examples

``` r
# \donttest{
# download all years (uses tempdir to avoid leaving files)
df <- vigitel_data(cache_dir = tempdir())
#> Downloading VIGITEL data (dta format)...
#> URL:
#> <https://svs.aids.gov.br/daent/cgdnt/vigitel/vigitel-2006-2024-peso-rake-dta.zip>
#> This may take a few minutes...
#> ✔ Download complete: /tmp/RtmpJ1hFKo/vigitel/vigitel-2006-2024-peso-rake-dta.zip
#> Extracting ZIP file...
#> ✔ Extracted: /tmp/RtmpJ1hFKo/vigitel/vigitel-2006-2024-peso-rake.dta
#> Reading dta file (this may take a moment)...
#> Creating partitioned parquet cache for faster future reads...
#> ✔ Partitioned cache created at /tmp/RtmpJ1hFKo/vigitel/vigitel_data
#> ✔ Loaded 833217 observations from 18 years: 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2023, and 2024

# download specific year
df_2024 <- vigitel_data(year = 2024, cache_dir = tempdir())
#> Reading from partitioned cache...
#> ✔ Loaded 27048 observations from 1 year: 2024

# download multiple years
df_recent <- vigitel_data(year = 2020:2024, cache_dir = tempdir())
#> Reading from partitioned cache...
#> ✔ Loaded 102908 observations from 4 years: 2020, 2021, 2023, and 2024

# select specific variables
df_subset <- vigitel_data(
  year = 2024,
  vars = c("ano", "cidade", "sexo", "idade", "pesorake"),
  cache_dir = tempdir()
)
#> Reading from partitioned cache...
#> Warning: Variables not found: "sexo", "idade", and "pesorake"
#> ✔ Loaded 27048 observations from 1 year: 2024
# }
```
