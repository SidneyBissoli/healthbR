# healthbR <img src="man/figures/logo.png" align="right" height="139" />
<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/healthbR)](https://CRAN.R-project.org/package=healthbR)
[![R-CMD-check](https://github.com/yourusername/healthbR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/yourusername/healthbR/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

## Overview

**healthbR** provides easy access to Brazilian public health data from multiple sources. All data is returned in tidy format following tidyverse conventions.

## Installation

You can install the development version of healthbR from GitHub:

```r
# install.packages("remotes")
remotes::install_github("yourusername/healthbR")
```

## Available Data Sources

| Source | Name | Status |
|--------|------|--------|
| VIGITEL | Telephone Survey on Chronic Disease Risk Factors | ✅ Available |
| PNS | National Health Survey | 🔜 Planned |
| PNAD | National Household Sample Survey | 🔜 Planned |
| SIM | Mortality Information System | 🔜 Planned |
| SINASC | Live Birth Information System | 🔜 Planned |
| SIH | Hospital Information System | 🔜 Planned |
| SINAN | Notifiable Diseases Information System | 🔜 Planned |

Use `list_sources()` to see all available data sources.

## Usage

### VIGITEL

```r
library(healthbR)
library(dplyr)

# See available years
vigitel_years()
#> [1] 2006 2007 2008 ... 2023

# See available variables
vigitel_variables(year = 2023)

# Check dictionary
vigitel_dictionary(year = 2023)
vigitel_dictionary(year = 2023, variable = "q006")

# Download data
df <- vigitel_data(years = 2023)

# Download multiple years with specific variables
df <- vigitel_data(
  years = 2020:2023,
  variables = c("sexo", "idade", "peso", "altura")
)

# Pipe-friendly workflow
vigitel_data(years = 2023) |>
  filter(uf == "SP") |>
  group_by(sexo) |>
  summarise(
    n = n(),
    media_imc = mean(imc, na.rm = TRUE)
  )
```

## Function Naming Convention

Each data source follows the same pattern:

- `[source]_years()` — List available years
- `[source]_variables()` — List available variables
- `[source]_dictionary()` — Get data dictionary
- `[source]_data()` — Download data

For example:
- `vigitel_years()`, `vigitel_data()`
- `sim_years()`, `sim_data()` (future)
- `pns_years()`, `pns_data()` (future)

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## License

MIT © Sidney Silva

## Citation

If you use healthbR in your research, please cite:

```
@software{healthbR,
  author = {Silva, Sidney},
  title = {healthbR: Access Brazilian Public Health Data},
  url = {https://github.com/yourusername/healthbR},
  year = {2026}
}
```

## Acknowledgments

This package was inspired by [nhanesA](https://cran.r-project.org/package=nhanesA), [fingertipsR](https://cran.r-project.org/package=fingertipsR), and [rdhs](https://cran.r-project.org/package=rdhs).

Data sources are provided by the Brazilian Ministry of Health (DATASUS, SVS) and IBGE.
