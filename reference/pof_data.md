# Download and import POF microdata

Downloads POF microdata from IBGE FTP and returns as a tibble. Data is
cached locally to avoid repeated downloads.

## Usage

``` r
pof_data(
  year = "2017-2018",
  register = "morador",
  vars = NULL,
  cache_dir = NULL,
  as_survey = FALSE,
  refresh = FALSE
)
```

## Arguments

- year:

  Character. POF edition (e.g., "2017-2018"). Default is "2017-2018".

- register:

  Character. Which register to download. Use
  [`pof_registers()`](https://sidneybissoli.github.io/healthbR/reference/pof_registers.md)
  to see available options. Default is "morador".

- vars:

  Character vector. Optional: specific variables to select. If NULL,
  returns all variables from the register. Default is NULL.

- cache_dir:

  Character. Directory for caching downloaded files. Default uses
  `tools::R_user_dir("healthbR", "cache")`.

- as_survey:

  Logical. If TRUE, returns survey design object. Requires srvyr
  package. Default is FALSE.

- refresh:

  Logical. If TRUE, re-download even if file exists in cache. Default is
  FALSE.

## Value

A tibble with microdata, or tbl_svy if as_survey = TRUE.

## Details

The POF (Pesquisa de Orcamentos Familiares) is a household survey
conducted by IBGE that investigates household budgets, living
conditions, and nutritional profiles of the Brazilian population.

### Health-related data

The POF contains several health-related modules:

- **EBIA** (Food Security Scale): Available in 2017-2018, variable V6199
  in the domicilio register

- **Food Consumption**: Detailed food consumption data in the
  consumo_alimentar register (2008-2009, 2017-2018)

- **Health Expenses**: Expenses with medications, health insurance,
  consultations in the despesa_individual register

- **Anthropometry**: Weight, height, BMI in morador register (2008-2009
  only)

### Survey design

For proper statistical analysis with complex survey design, use
`as_survey = TRUE` which creates a survey design object with:

- Weight variable: PESO_FINAL

- Stratum variable: ESTRATO_POF

- PSU variable: COD_UPA

## Data source

Data is downloaded from the IBGE FTP server:
<https://ftp.ibge.gov.br/Orcamentos_Familiares/>

## See also

[`pof_years`](https://sidneybissoli.github.io/healthbR/reference/pof_years.md),
[`pof_info`](https://sidneybissoli.github.io/healthbR/reference/pof_info.md),
[`pof_registers`](https://sidneybissoli.github.io/healthbR/reference/pof_registers.md),
[`pof_variables`](https://sidneybissoli.github.io/healthbR/reference/pof_variables.md)

Other pof:
[`pof_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/pof_cache_status.md),
[`pof_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/pof_clear_cache.md),
[`pof_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/pof_dictionary.md),
[`pof_info()`](https://sidneybissoli.github.io/healthbR/reference/pof_info.md),
[`pof_registers()`](https://sidneybissoli.github.io/healthbR/reference/pof_registers.md),
[`pof_variables()`](https://sidneybissoli.github.io/healthbR/reference/pof_variables.md),
[`pof_years()`](https://sidneybissoli.github.io/healthbR/reference/pof_years.md)

## Examples

``` r
if (FALSE) { # interactive()
# basic usage - download morador register
morador <- pof_data("2017-2018", "morador", cache_dir = tempdir())

# download domicilio register (includes EBIA)
domicilio <- pof_data("2017-2018", "domicilio", cache_dir = tempdir())

# select specific variables
df <- pof_data(
  "2017-2018", "morador",
  vars = c("COD_UPA", "ESTRATO_POF", "PESO_FINAL", "V0403"),
  cache_dir = tempdir()
)

# with survey design (requires srvyr package)
morador_svy <- pof_data("2017-2018", "morador", as_survey = TRUE,
                         cache_dir = tempdir())
}
```
