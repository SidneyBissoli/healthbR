# healthbR <img src="man/figures/logo.png" align="right" height="139" alt="" />
<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN status](https://www.r-pkg.org/badges/version/healthbR)](https://CRAN.R-project.org/package=healthbR)
[![R-CMD-check](https://github.com/SidneyBissoli/healthbR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/SidneyBissoli/healthbR/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

## Overview
healthbR provides easy access to Brazilian public health survey data directly from R. The package downloads, caches, and processes data from official sources, returning clean, analysis-ready tibbles following tidyverse conventions.

Currently supported data sources:

- **VIGITEL** - Surveillance of Risk Factors for Chronic Diseases by Telephone Survey - Years 2006-2024
- **PNS** - National Health Survey (microdata + SIDRA API) - Years 2013, 2019
- **PNAD Continua** - Continuous National Household Sample Survey - Years 2012-2024
- **POF** - Household Budget Survey (food security, consumption, anthropometry) - Years 2002-2018
- **Censo Demografico** - Population denominators via SIDRA API - Census 1970-2022, estimates 2001-2021

Planned for future releases:

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
#> [16] 2021 2022 2023 2024
```

### Download and load data

```r
# load data for a single year
df <- vigitel_data(year = 2024)

# load data for multiple years
df <- vigitel_data(year = 2020:2024)

# load all available years
df <- vigitel_data()

# choose data format (default is Stata .dta which preserves labels)
df <- vigitel_data(year = 2024, format = "dta")
df <- vigitel_data(year = 2024, format = "csv")

# select specific variables
df <- vigitel_data(
  year = 2024,
  vars = c("cidade", "sexo", "idade", "pesorake")
)
```

### Explore variables

```r
# get the data dictionary with variable descriptions
dict <- vigitel_dictionary()

# list variables (same as dictionary)
vars <- vigitel_variables()

# view the dictionary structure
head(dict)
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

healthbR automatically optimizes data loading using partitioned parquet caching when the `arrow` package is installed.

### Automatic parquet caching (recommended)

Install the `arrow` package for significantly faster subsequent reads:

```r
# install arrow for better performance
install.packages("arrow")

# first load downloads and creates partitioned cache
df <- vigitel_data(year = 2024)

# subsequent loads are extremely fast (reads only requested year)
df <- vigitel_data(year = 2024)  # instant!
```

When `arrow` is installed:
- Data is automatically cached in partitioned parquet format
- Reading a single year loads only that year's partition (~25MB instead of ~500MB)
- Multiple years are combined efficiently

### Cache management

```r
# check cache status
vigitel_cache_status()

# clear cache (all files)
vigitel_clear_cache()

# clear only source files, keep parquet cache
vigitel_clear_cache(keep_parquet = TRUE)
```

## Data sources

All data is downloaded from official Brazilian Ministry of Health repositories:

- VIGITEL: https://svs.aids.gov.br/daent/cgdnt/vigitel/

## Citation

If you use healthbR in your research, please cite it:

```r
citation("healthbR")
```

## Contributing

Contributions are welcome! Please open an issue to discuss proposed changes or submit a pull request.

## Code of Conduct

Please note that the healthbR project is released with a [Contributor Code of Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html). By contributing to this project, you agree to abide by its terms.

## License

MIT © Sidney da Silva Pereira Bissoli
