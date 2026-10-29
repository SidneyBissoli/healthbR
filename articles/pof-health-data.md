# Analyzing Health Data from POF with healthbR

## Overview

The **POF (Pesquisa de Orçamentos Familiares)** is a household budget
survey conducted by IBGE that investigates household expenditures,
living conditions, and nutritional profiles of the Brazilian population.
It is conducted in partnership with the Ministry of Health.

The `healthbR` package provides access to POF microdata with a focus on
**health-related data**:

| Module | Description | Available editions |
|----|----|----|
| **Food Security (EBIA)** | Brazilian Food Insecurity Scale | 2017-2018 |
| **Food Consumption** | Detailed personal food intake | 2008-2009, 2017-2018 |
| **Anthropometry** | Weight, height, BMI | 2008-2009 |
| **Health Expenses** | Medications, insurance, consultations | All editions |

## Getting started

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`healthbR`](https://github.com/SidneyBissoli/healthbR)`)`\
[`library`](https://rdrr.io/r/base/library.html)`(`[`dplyr`](https://dplyr.tidyverse.org)`)`

### Check available editions

\
[`pof_years`](https://sidneybissoli.github.io/healthbR/reference/pof_years.md)`(``)`\
`#> [1] "2002-2003" "2008-2009" "2017-2018"`

### Survey information

Use
[`pof_info()`](https://sidneybissoli.github.io/healthbR/reference/pof_info.md)
to see which health modules are available for each edition:

\
[`pof_info`](https://sidneybissoli.github.io/healthbR/reference/pof_info.md)`(``"2017-2018"``)`

### List available registers

Each POF edition contains multiple data registers. Use
[`pof_registers()`](https://sidneybissoli.github.io/healthbR/reference/pof_registers.md)
to see them:

\
`# all registers`\
[`pof_registers`](https://sidneybissoli.github.io/healthbR/reference/pof_registers.md)`(``"2017-2018"``)`\
\
`# only health-related registers`\
[`pof_registers`](https://sidneybissoli.github.io/healthbR/reference/pof_registers.md)`(``"2017-2018"``, health_only ``=`` ``TRUE``)`

### Explore variables

Before downloading data, you can browse available variables:

\
`# list all variables in the domicilio register`\
[`pof_variables`](https://sidneybissoli.github.io/healthbR/reference/pof_variables.md)`(``"2017-2018"``, ``"domicilio"``)`\
\
`# search for food security variables`\
[`pof_variables`](https://sidneybissoli.github.io/healthbR/reference/pof_variables.md)`(``"2017-2018"``, search ``=`` ``"ebia"``)`\
\
`# search for weight-related variables`\
[`pof_variables`](https://sidneybissoli.github.io/healthbR/reference/pof_variables.md)`(``"2017-2018"``, ``"morador"``, search ``=`` ``"peso"``)`

## Food Security Analysis (EBIA)

The **EBIA (Escala Brasileira de Insegurança Alimentar)** is available
in the 2017-2018 edition through the `domicilio` register. The variable
`V6199` contains the food security classification.

### Download domicilio data

\
`domicilio`` ``<-`` `[`pof_data`](https://sidneybissoli.github.io/healthbR/reference/pof_data.md)`(``"2017-2018"``, ``"domicilio"``)`

### EBIA classification

The EBIA classifies households into four levels:

| Code | Classification           |
|------|--------------------------|
| 1    | Food security            |
| 2    | Mild food insecurity     |
| 3    | Moderate food insecurity |
| 4    | Severe food insecurity   |

### Create EBIA categories

\
`domicilio`` ``<-`` ``domicilio`` ``|>`\
`  `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(`\
`    ebia ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(`\
`      ``V6199``,`\
`      levels ``=`` ``1``:``4``,`\
`      labels ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(`\
`        ``"Food security"``,`\
`        ``"Mild insecurity"``,`\
`        ``"Moderate insecurity"``,`\
`        ``"Severe insecurity"`\
`      ``)`\
`    ``)`\
`  ``)`\
\
`# frequency table`\
`domicilio`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``ebia``)`` ``|>`\
`  `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(``pct ``=`` ``n`` ``/`` `[`sum`](https://rdrr.io/r/base/sum.html)`(``n``)`` ``*`` ``100``)`

### Weighted estimates with survey design

For proper population estimates, use the survey design:

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`srvyr`](http://gdfe.co/srvyr/)`)`\
\
`domicilio_svy`` ``<-`` `[`pof_data`](https://sidneybissoli.github.io/healthbR/reference/pof_data.md)`(``"2017-2018"``, ``"domicilio"``, as_survey ``=`` ``TRUE``)`\
\
`# add EBIA categories`\
`domicilio_svy`` ``<-`` ``domicilio_svy`` ``|>`\
`  `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(`\
`    ebia ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(`\
`      ``V6199``,`\
`      levels ``=`` ``1``:``4``,`\
`      labels ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(`\
`        ``"Food security"``,`\
`        ``"Mild insecurity"``,`\
`        ``"Moderate insecurity"``,`\
`        ``"Severe insecurity"`\
`      ``)`\
`    ``)`\
`  ``)`\
\
`# weighted prevalence`\
`domicilio_svy`` ``|>`\
`  `[`group_by`](https://dplyr.tidyverse.org/reference/group_by.html)`(``ebia``)`` ``|>`\
`  `[`summarize`](https://dplyr.tidyverse.org/reference/summarise.html)`(`\
`    prevalence ``=`` `[`survey_mean`](http://gdfe.co/srvyr/reference/survey_mean.md)`(``na.rm ``=`` ``TRUE``, vartype ``=`` ``"ci"``)``,`\
`    n ``=`` `[`unweighted`](http://gdfe.co/srvyr/reference/unweighted.md)`(`[`n`](https://dplyr.tidyverse.org/reference/context.html)`(``)``)`\
`  ``)`

### EBIA by region (UF)

\
`# food insecurity by state`\
`domicilio_svy`` ``|>`\
`  `[`group_by`](https://dplyr.tidyverse.org/reference/group_by.html)`(``UF``, ``ebia``)`` ``|>`\
`  `[`summarize`](https://dplyr.tidyverse.org/reference/summarise.html)`(`\
`    prevalence ``=`` `[`survey_mean`](http://gdfe.co/srvyr/reference/survey_mean.md)`(``na.rm ``=`` ``TRUE``, vartype ``=`` ``"ci"``)``,`\
`    n ``=`` `[`unweighted`](http://gdfe.co/srvyr/reference/unweighted.md)`(`[`n`](https://dplyr.tidyverse.org/reference/context.html)`(``)``)`\
`  ``)`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``ebia`` ``==`` ``"Severe insecurity"``)`` ``|>`\
`  `[`arrange`](https://dplyr.tidyverse.org/reference/arrange.html)`(`[`desc`](https://dplyr.tidyverse.org/reference/desc.html)`(``prevalence``)``)`

## Food Consumption Analysis

The `consumo_alimentar` register contains detailed personal food intake
data from a subsample. This data is available for the 2008-2009 and
2017-2018 editions.

### Download food consumption data

\
`consumo`` ``<-`` `[`pof_data`](https://sidneybissoli.github.io/healthbR/reference/pof_data.md)`(``"2017-2018"``, ``"consumo_alimentar"``)`

### Key variables

| Variable       | Description      |
|----------------|------------------|
| `V9001`        | Food item code   |
| `V9005`        | Amount consumed  |
| `V9007`        | Unit of measure  |
| `ENERGIA_KCAL` | Energy (kcal)    |
| `PROTEINA`     | Protein (g)      |
| `CARBOIDRATO`  | Carbohydrate (g) |
| `LIPIDIO`      | Total lipids (g) |

### Average caloric intake

\
`# total daily caloric intake per person`\
`consumo`` ``|>`\
`  `[`group_by`](https://dplyr.tidyverse.org/reference/group_by.html)`(``COD_UPA``, ``NUM_DOM``, ``NUM_UC``, ``COD_INFORMANTE``)`` ``|>`\
`  `[`summarize`](https://dplyr.tidyverse.org/reference/summarise.html)`(`\
`    total_kcal ``=`` `[`sum`](https://rdrr.io/r/base/sum.html)`(``ENERGIA_KCAL``, na.rm ``=`` ``TRUE``)``,`\
`    total_protein ``=`` `[`sum`](https://rdrr.io/r/base/sum.html)`(``PROTEINA``, na.rm ``=`` ``TRUE``)``,`\
`    total_carb ``=`` `[`sum`](https://rdrr.io/r/base/sum.html)`(``CARBOIDRATO``, na.rm ``=`` ``TRUE``)``,`\
`    total_fat ``=`` `[`sum`](https://rdrr.io/r/base/sum.html)`(``LIPIDIO``, na.rm ``=`` ``TRUE``)``,`\
`    .groups ``=`` ``"drop"`\
`  ``)`` ``|>`\
`  `[`summarize`](https://dplyr.tidyverse.org/reference/summarise.html)`(`\
`    mean_kcal ``=`` `[`mean`](https://rdrr.io/r/base/mean.html)`(``total_kcal``, na.rm ``=`` ``TRUE``)``,`\
`    mean_protein ``=`` `[`mean`](https://rdrr.io/r/base/mean.html)`(``total_protein``, na.rm ``=`` ``TRUE``)``,`\
`    mean_carb ``=`` `[`mean`](https://rdrr.io/r/base/mean.html)`(``total_carb``, na.rm ``=`` ``TRUE``)``,`\
`    mean_fat ``=`` `[`mean`](https://rdrr.io/r/base/mean.html)`(``total_fat``, na.rm ``=`` ``TRUE``)`\
`  ``)`

## Health Expenses

The `despesa_individual` register contains individual expenses,
including health-related spending such as medications, health insurance,
and medical consultations.

### Download expense data

\
`despesas`` ``<-`` `[`pof_data`](https://sidneybissoli.github.io/healthbR/reference/pof_data.md)`(``"2017-2018"``, ``"despesa_individual"``)`

### Filter health expenses

Health-related expenses can be identified by product group codes:

\
`# explore expense categories`\
`despesas`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``QUADRO``)`` ``|>`\
`  `[`arrange`](https://dplyr.tidyverse.org/reference/arrange.html)`(`[`desc`](https://dplyr.tidyverse.org/reference/desc.html)`(``n``)``)`

## Combining registers

For many analyses you need to combine data from multiple registers. Use
the household identifier variables (`COD_UPA`, `NUM_DOM`, `NUM_UC`) to
merge:

\
`# download morador (demographic data) and domicilio (household data)`\
`morador`` ``<-`` `[`pof_data`](https://sidneybissoli.github.io/healthbR/reference/pof_data.md)`(``"2017-2018"``, ``"morador"``)`\
`domicilio`` ``<-`` `[`pof_data`](https://sidneybissoli.github.io/healthbR/reference/pof_data.md)`(``"2017-2018"``, ``"domicilio"``)`\
\
`# merge: add household-level EBIA to individual-level data`\
`morador_ebia`` ``<-`` ``morador`` ``|>`\
`  `[`left_join`](https://dplyr.tidyverse.org/reference/mutate-joins.html)`(`\
`    ``domicilio`` ``|>`` `[`select`](https://dplyr.tidyverse.org/reference/select.html)`(``COD_UPA``, ``NUM_DOM``, ``NUM_UC``, ``V6199``)``,`\
`    by ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"COD_UPA"``, ``"NUM_DOM"``, ``"NUM_UC"``)`\
`  ``)`` ``|>`\
`  `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(`\
`    ebia ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(`\
`      ``V6199``,`\
`      levels ``=`` ``1``:``4``,`\
`      labels ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(`\
`        ``"Food security"``,`\
`        ``"Mild insecurity"``,`\
`        ``"Moderate insecurity"``,`\
`        ``"Severe insecurity"`\
`      ``)`\
`    ``)`\
`  ``)`\
\
`# food insecurity by age group`\
`morador_ebia`` ``|>`\
`  `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(``age_group ``=`` `[`cut`](https://rdrr.io/r/base/cut.html)`(``V0403``, breaks ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``0``, ``5``, ``12``, ``18``, ``30``, ``60``, ``Inf``)``)``)`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``age_group``, ``ebia``)`` ``|>`\
`  `[`group_by`](https://dplyr.tidyverse.org/reference/group_by.html)`(``age_group``)`` ``|>`\
`  `[`mutate`](https://dplyr.tidyverse.org/reference/mutate.html)`(``pct ``=`` ``n`` ``/`` `[`sum`](https://rdrr.io/r/base/sum.html)`(``n``)`` ``*`` ``100``)`

## Comparing editions

The POF has been conducted in different years, and data structure may
vary. Use
[`pof_info()`](https://sidneybissoli.github.io/healthbR/reference/pof_info.md)
to check what is available in each edition:

\
`# check health modules by edition`\
[`pof_info`](https://sidneybissoli.github.io/healthbR/reference/pof_info.md)`(``"2017-2018"``)``  ``# EBIA + food consumption`\
[`pof_info`](https://sidneybissoli.github.io/healthbR/reference/pof_info.md)`(``"2008-2009"``)``  ``# anthropometry + food consumption`\
[`pof_info`](https://sidneybissoli.github.io/healthbR/reference/pof_info.md)`(``"2002-2003"``)``  ``# expenses only`

## Cache management

POF data files are large. healthbR caches downloaded files locally so
you only download once:

\
`# check cached files`\
[`pof_cache_status`](https://sidneybissoli.github.io/healthbR/reference/pof_cache_status.md)`(``)`\
\
`# clear cache if needed`\
[`pof_clear_cache`](https://sidneybissoli.github.io/healthbR/reference/pof_clear_cache.md)`(``)`

If the `arrow` package is installed, data is cached in Parquet format
for faster loading:

\
`# install arrow for optimized caching (recommended)`\
[`install.packages`](https://rdrr.io/r/utils/install.packages.html)`(``"arrow"``)`

## Additional resources

- POF official page
  (`www.ibge.gov.br/estatisticas/sociais/saude/24786-pesquisa-de-orcamentos-familiares-2`)
- POF 2017-2018 Food Security publication (`biblioteca.ibge.gov.br`)
- POF 2017-2018 Food Consumption publication (`biblioteca.ibge.gov.br`)
- [srvyr package
  documentation](https://cran.r-project.org/package=srvyr)
