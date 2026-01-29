# healthbR <img src="man/figures/logo.png" align="right" height="139" alt="" />
<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN status](https://www.r-pkg.org/badges/version/healthbR)](https://CRAN.R-project.org/package=healthbR)
[![R-CMD-check](https://github.com/SidneyBissoli/healthbR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/SidneyBissoli/healthbR/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

## Overview
healthbR provides easy access to Brazilian public health survey data directly from R. The package downloads, caches, and processes data from official sources, returning clean, analysis-ready tibbles following tidyverse conventions.
 
Currently supported data sources:

- **VIGITEL** - Surveillance of Risk Factors for Chronic Diseases by Telephone Survey (Vigilância de Fatores de Risco e Proteção para Doenças Crônicas por Inquérito Telefônico)

Planned for future releases:

- PNS (National Health Survey)
- PNAD (National Household Sample Survey)
- SIM (Mortality Information System)
- SINASC (Live Birth Information System)
- SIH (Hospital Information System)

## Installation

You can install the development version of healthbR from GitHub:

```r
# install.packages("pak")
pak::pak("SidneyBissoli/healthbR")
```

## Usage

### Check available years

```r
library(healthbR)

# list available VIGITEL survey years
vigitel_years()
#> [1] 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020
#> [16] 2021 2022 2023
```

### Download and load data

```r
# load data for a single year
df <- vigitel_data(2023)

# load data for multiple years
df <- vigitel_data(2021:2023)
```

### Explore variables

```r
# list variables available in a specific year
vigitel_variables(2023)

# get the data dictionary with variable descriptions
dict <- vigitel_dictionary()

# search for specific variables
dict |>
  dplyr::filter(stringr::str_detect(variable_name, "peso"))
```

### Survey analysis with srvyr

VIGITEL uses complex survey sampling. Use the `pesorake` weight variable for proper inference:
 
```r
library(dplyr)
library(srvyr)

# create survey design
vigitel_svy <- df |>
  as_survey_design(weights = pesorake)

# calculate weighted prevalence
vigitel_svy |>
  group_by(cidade) |>
  summarize(
    prevalence = survey_mean(diab == 1, na.rm = TRUE),
    n = unweighted(n())
  )
```

## Performance optimization

healthbR offers three strategies for handling large datasets efficiently:

### 1. Parquet conversion (recommended for repeated use)

Convert Excel files to Parquet format for 10-20x faster loading:

```r
# convert downloaded files to parquet (one-time operation
vigitel_convert_to_parquet(2020:2023)

# subsequent loads are much faster
df <- vigitel_data(2020:2023)
```

### 2. Parallel downloads

Download multiple years simultaneously (requires optional packages):

```r
# install optional packages for parallel processing
install.packages(c("furrr", "future"))

# uses furrr for parallel processing (2-4 workers)
df <- vigitel_data(2015:2023)
```

### 3. Lazy evaluation with Arrow

For very large datasets, use lazy evaluation to process data without loading everything into memory:

```r
# returns an Arrow Dataset (not loaded into RAM)
df_lazy <- vigitel_data(2020:2023, lazy = TRUE)

# filter and select before collecting
result <- df_lazy |>
  dplyr::filter(cidade == 1) |>
  dplyr::select(q6, q8_anos, pesorake, diab, hart) |>
  dplyr::collect()
```

## Data sources

All data is downloaded from official Brazilian Ministry of Health repositories:

- VIGITEL: https://svs.aids.gov.br/download/Vigitel/

## Citation

If you use healthbR in your research, please cite it:

```r
citation("healthbR")
```

## Contributing

Contributions are welcome! Please open an issue to discuss proposed changes or submit a pull request.

## Code of Conduct

Please note
 that the healthbR project is released with a [Contributor Code of Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html). By contributing to this project, you agree to abide by its terms.

## License

MIT © Sidney da Silva Pereira Bissoli
