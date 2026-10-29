# Introduction to healthbR

## Overview

healthbR provides easy access to Brazilian public health data directly
from R. The package downloads, caches, and processes data from official
sources (Ministry of Health, IBGE, DATASUS), returning clean,
analysis-ready tibbles following tidyverse conventions.

The package currently supports **16 data sources** organized in three
groups:

**Surveys (IBGE / Ministry of Health)**

| Module | Source | Years |
|----|----|----|
| VIGITEL | Telephone survey on chronic disease risk factors | 2006–2024 |
| PNS | National Health Survey (microdata + SIDRA API) | 2013, 2019 |
| PNAD Continua | Continuous household survey (health supplements) | 2012–2024 |
| POF | Household budget survey (food security, nutrition) | 2002–2018 |
| Censo | Population denominators via SIDRA API | 1970–2022 |

**DATASUS (Ministry of Health FTP)**

| Module | Source | Granularity | Years |
|----|----|----|----|
| SIM | Mortality (death certificates) | Annual/UF | 1996–2024 |
| SINASC | Live births | Annual/UF | 1996–2024 |
| SIH | Hospital admissions (AIH) | Monthly/UF | 1992–2024 |
| SIA | Outpatient procedures (13 file types) | Monthly/UF | 2008–2024 |
| SINAN | Notifiable diseases (31 diseases) | Annual/National | 2007–2024 |
| CNES | Health facility registry (13 file types) | Monthly/UF | 2005–2024 |
| SI-PNI | Vaccination (aggregated FTP + microdata API) | Annual/UF | 1994–2025 |
| SISAB | Primary care coverage indicators (REST API) | Monthly | 2007–present |

**Regulatory agencies**

| Module | Source | Granularity | Years |
|----|----|----|----|
| ANS | Supplementary health (beneficiaries, complaints, financial) | Monthly/UF | 2007–present |
| ANVISA | Medicines, devices, pharmacovigilance, SNGPC | National | 2014–present |

## Getting started

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`healthbR`](https://github.com/SidneyBissoli/healthbR)`)`\
[`library`](https://rdrr.io/r/base/library.html)`(`[`dplyr`](https://dplyr.tidyverse.org)`)`

To see all available data sources at a glance:

\
[`list_sources`](https://sidneybissoli.github.io/healthbR/reference/list_sources.md)`(``)`\
`#> # A tibble: 16 x 5`\
`#>    source  name                         description                    years       status`\
`#>    <chr>   <chr>                        <chr>                          <chr>       <chr>`\
`#>  1 vigitel VIGITEL                      Telephone survey on chronic... 2006-2024   available`\
`#>  2 pns     PNS - Pesquisa Nacional ...  National health survey (IBGE) 2013, 2019  available`\
`#>  ...`

All modules follow a consistent API pattern:

- `*_years()` / `*_info()` – metadata and available years
- `*_variables()` / `*_dictionary()` – variable names and category
  labels
- `*_data()` – download and load data
- `*_cache_status()` / `*_clear_cache()` – cache management

## VIGITEL – Chronic disease risk factors

VIGITEL is a telephone survey conducted annually in all 27 state
capitals, monitoring risk and protective factors for chronic
non-communicable diseases.

\
`# check available years`\
[`vigitel_years`](https://sidneybissoli.github.io/healthbR/reference/vigitel_years.md)`(``)`\
\
`# download data for a single year`\
`df`` ``<-`` `[`vigitel_data`](https://sidneybissoli.github.io/healthbR/reference/vigitel_data.md)`(``year ``=`` ``2024``)`\
\
`# explore the data dictionary`\
`dict`` ``<-`` `[`vigitel_dictionary`](https://sidneybissoli.github.io/healthbR/reference/vigitel_dictionary.md)`(``)`\
\
`# list variables`\
[`vigitel_variables`](https://sidneybissoli.github.io/healthbR/reference/vigitel_variables.md)`(``)`

Key variables include `pesorake` (survey weight), `diab` (diabetes),
`hart` (hypertension), `fumante` (smoker), and `imc` (BMI).

\
`# weighted prevalence of diabetes by city using srvyr`\
[`library`](https://rdrr.io/r/base/library.html)`(`[`srvyr`](http://gdfe.co/srvyr/)`)`\
\
`df`` ``|>`\
`  `[`as_survey_design`](http://gdfe.co/srvyr/reference/as_survey_design.md)`(``weights ``=`` ``pesorake``)`` ``|>`\
`  `[`group_by`](https://dplyr.tidyverse.org/reference/group_by.html)`(``cidade``)`` ``|>`\
`  `[`summarize`](https://dplyr.tidyverse.org/reference/summarise.html)`(`\
`    prevalence ``=`` `[`survey_mean`](http://gdfe.co/srvyr/reference/survey_mean.md)`(``diab`` ``==`` ``1``, na.rm ``=`` ``TRUE``)``,`\
`    n ``=`` `[`unweighted`](http://gdfe.co/srvyr/reference/unweighted.md)`(`[`n`](https://dplyr.tidyverse.org/reference/context.html)`(``)``)`\
`  ``)`

## PNS – National Health Survey

The PNS provides comprehensive data on health conditions, lifestyle, and
healthcare access from ~100,000 households.

\
`# microdata`\
`pns`` ``<-`` `[`pns_data`](https://sidneybissoli.github.io/healthbR/reference/pns_data.md)`(``year ``=`` ``2019``)`\
\
`# explore modules and variables`\
[`pns_modules`](https://sidneybissoli.github.io/healthbR/reference/pns_modules.md)`(``year ``=`` ``2019``)`\
[`pns_dictionary`](https://sidneybissoli.github.io/healthbR/reference/pns_dictionary.md)`(``year ``=`` ``2019``)`\
\
`# tabulated indicators from SIDRA API (no download needed)`\
[`pns_sidra_search`](https://sidneybissoli.github.io/healthbR/reference/pns_sidra_search.md)`(``"diabetes"``)`\
[`pns_sidra_data`](https://sidneybissoli.github.io/healthbR/reference/pns_sidra_data.md)`(``table ``=`` ``4487``, territorial_level ``=`` ``"state"``, year ``=`` ``2019``)`

## PNAD Continua – Household survey supplements

PNAD Continua includes health-related supplementary modules on
disability, housing conditions, primary health care (APS), and household
characteristics.

\
`# list available modules`\
[`pnadc_modules`](https://sidneybissoli.github.io/healthbR/reference/pnadc_modules.md)`(``)`\
\
`# download disability supplement`\
`defic`` ``<-`` `[`pnadc_data`](https://sidneybissoli.github.io/healthbR/reference/pnadc_data.md)`(``module ``=`` ``"deficiencia"``, year ``=`` ``2019``, quarter ``=`` ``1``)`\
\
`# explore variables`\
[`pnadc_variables`](https://sidneybissoli.github.io/healthbR/reference/pnadc_variables.md)`(``module ``=`` ``"deficiencia"``)`

## POF – Food security and nutrition

The POF (Household Budget Survey) contains data on food insecurity
(EBIA), individual food consumption, anthropometry, and health expenses.

\
`# list available registers`\
[`pof_registers`](https://sidneybissoli.github.io/healthbR/reference/pof_registers.md)`(``year ``=`` ``2018``)`\
\
`# food consumption microdata`\
`consumo`` ``<-`` `[`pof_data`](https://sidneybissoli.github.io/healthbR/reference/pof_data.md)`(``year ``=`` ``2018``, register ``=`` ``"consumo_alimentar"``)`\
\
`# food insecurity scale (EBIA)`\
`morador`` ``<-`` `[`pof_data`](https://sidneybissoli.github.io/healthbR/reference/pof_data.md)`(``year ``=`` ``2018``, register ``=`` ``"morador"``)`\
\
`# variable dictionary for a specific register`\
[`pof_dictionary`](https://sidneybissoli.github.io/healthbR/reference/pof_dictionary.md)`(``year ``=`` ``2018``, register ``=`` ``"morador"``)`

See
[`vignette("pof-health-data")`](https://sidneybissoli.github.io/healthbR/articles/pof-health-data.md)
for a detailed walkthrough.

## Censo – Population denominators

The Census module queries the IBGE SIDRA API for population
denominators, essential for calculating mortality rates, incidence, and
other epidemiological indicators.

\
`# population by state, sex, and age group (2022 Census)`\
`pop`` ``<-`` `[`censo_populacao`](https://sidneybissoli.github.io/healthbR/reference/censo_populacao.md)`(``year ``=`` ``2022``, territorial_level ``=`` ``"state"``)`\
\
`# intercensitary population estimates (for years between censuses)`\
`est`` ``<-`` `[`censo_estimativa`](https://sidneybissoli.github.io/healthbR/reference/censo_estimativa.md)`(``year ``=`` ``2020``, territorial_level ``=`` ``"state"``)`\
\
`# query any Census SIDRA table directly`\
[`censo_sidra_search`](https://sidneybissoli.github.io/healthbR/reference/censo_sidra_search.md)`(``"populacao"``)`\
[`censo_sidra_data`](https://sidneybissoli.github.io/healthbR/reference/censo_sidra_data.md)`(``table ``=`` ``9514``, territorial_level ``=`` ``"brazil"``, year ``=`` ``2022``)`

See
[`vignette("censo-denominadores")`](https://sidneybissoli.github.io/healthbR/articles/censo-denominadores.md)
for epidemiological examples.

## SIM – Mortality data

SIM contains individual death records from death certificates (CID-10,
1996+).

\
`# deaths in Acre, 2022`\
`obitos`` ``<-`` `[`sim_data`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"AC"``)`\
\
`# filter by cause of death (CID-10 prefix)`\
`obitos_cardio`` ``<-`` `[`sim_data`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"AC"``, cause ``=`` ``"I"``)`\
\
`# explore variables and categories`\
[`sim_variables`](https://sidneybissoli.github.io/healthbR/reference/sim_variables.md)`(``)`\
[`sim_dictionary`](https://sidneybissoli.github.io/healthbR/reference/sim_dictionary.md)`(``"CAUSABAS"``)`

## SINASC – Live births

SINASC contains individual birth records including birth weight,
gestational age, prenatal care, and congenital anomalies.

\
`# births in Acre, 2022`\
`nascimentos`` ``<-`` `[`sinasc_data`](https://sidneybissoli.github.io/healthbR/reference/sinasc_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"AC"``)`\
\
`# filter by congenital anomaly (CID-10 prefix)`\
`anomalias`` ``<-`` `[`sinasc_data`](https://sidneybissoli.github.io/healthbR/reference/sinasc_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"AC"``, anomaly ``=`` ``"Q"``)`\
\
[`sinasc_variables`](https://sidneybissoli.github.io/healthbR/reference/sinasc_variables.md)`(``)`\
[`sinasc_dictionary`](https://sidneybissoli.github.io/healthbR/reference/sinasc_dictionary.md)`(``"PARTO"``)`

## SIH – Hospital admissions

SIH contains hospital admission records (AIH) with diagnosis,
procedures, length of stay, and costs. Data is organized monthly.

\
`# admissions in Acre, January 2022`\
`internacoes`` ``<-`` `[`sih_data`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md)`(``year ``=`` ``2022``, month ``=`` ``1``, uf ``=`` ``"AC"``)`\
\
`# filter by principal diagnosis (CID-10 prefix)`\
`intern_resp`` ``<-`` `[`sih_data`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md)`(``year ``=`` ``2022``, month ``=`` ``1``, uf ``=`` ``"AC"``, diagnosis ``=`` ``"J"``)`\
\
[`sih_variables`](https://sidneybissoli.github.io/healthbR/reference/sih_variables.md)`(``)`\
[`sih_dictionary`](https://sidneybissoli.github.io/healthbR/reference/sih_dictionary.md)`(``"DIAG_PRINC"``)`

## SIA – Outpatient procedures

SIA covers outpatient production data with 13 file types (BPA, APAC,
RAAS).

\
`# outpatient production in Acre, January 2022 (default type: PA)`\
`ambulatorial`` ``<-`` `[`sia_data`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md)`(``year ``=`` ``2022``, month ``=`` ``1``, uf ``=`` ``"AC"``)`\
\
`# high-cost medications (APAC)`\
`medicamentos`` ``<-`` `[`sia_data`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md)`(``year ``=`` ``2022``, month ``=`` ``1``, uf ``=`` ``"AC"``, type ``=`` ``"AM"``)`\
\
`# filter by procedure or diagnosis`\
[`sia_data`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md)`(``year ``=`` ``2022``, month ``=`` ``1``, uf ``=`` ``"AC"``, procedure ``=`` ``"0301"``)`\
[`sia_data`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md)`(``year ``=`` ``2022``, month ``=`` ``1``, uf ``=`` ``"AC"``, diagnosis ``=`` ``"E11"``)`

## SINAN – Notifiable diseases

SINAN contains individual notification records for 31 notifiable
diseases including dengue, tuberculosis, chikungunya, zika, hepatitis,
syphilis, and others. Files are **national** (not per-state), so each
download covers all of Brazil for a given disease and year.

\
`# list available diseases`\
[`sinan_diseases`](https://sidneybissoli.github.io/healthbR/reference/sinan_diseases.md)`(``)`\
\
`# search for a specific disease`\
[`sinan_diseases`](https://sidneybissoli.github.io/healthbR/reference/sinan_diseases.md)`(``search ``=`` ``"dengue"``)`\
\
`# dengue notifications, 2022`\
`dengue`` ``<-`` `[`sinan_data`](https://sidneybissoli.github.io/healthbR/reference/sinan_data.md)`(``year ``=`` ``2022``, disease ``=`` ``"DENG"``)`\
\
`# tuberculosis, 2020-2022`\
`tb`` ``<-`` `[`sinan_data`](https://sidneybissoli.github.io/healthbR/reference/sinan_data.md)`(``year ``=`` ``2020``:``2022``, disease ``=`` ``"TUBE"``)`\
\
`# explore variables and categories`\
[`sinan_variables`](https://sidneybissoli.github.io/healthbR/reference/sinan_variables.md)`(``)`\
[`sinan_dictionary`](https://sidneybissoli.github.io/healthbR/reference/sinan_dictionary.md)`(``"EVOLUCAO"``)`

Since SINAN files are national, filter by state after download using
`SG_UF_NOT` (UF of notification) or `ID_MUNICIP` (municipality code):

\
`dengue`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``SG_UF_NOT`` ``==`` ``"35"``)``  ``# Sao Paulo`

## CNES – Health facility registry

CNES is the national registry of health facilities, covering hospitals,
clinics, primary care units, and all other health establishments. Data
is organized monthly with 13 file types.

\
`# see all file types`\
[`cnes_info`](https://sidneybissoli.github.io/healthbR/reference/cnes_info.md)`(``)`\
\
`# establishments in Acre, January 2023`\
`estab`` ``<-`` `[`cnes_data`](https://sidneybissoli.github.io/healthbR/reference/cnes_data.md)`(``year ``=`` ``2023``, month ``=`` ``1``, uf ``=`` ``"AC"``)`\
\
`# hospital beds`\
`leitos`` ``<-`` `[`cnes_data`](https://sidneybissoli.github.io/healthbR/reference/cnes_data.md)`(``year ``=`` ``2023``, month ``=`` ``1``, uf ``=`` ``"AC"``, type ``=`` ``"LT"``)`\
\
`# health professionals`\
`prof`` ``<-`` `[`cnes_data`](https://sidneybissoli.github.io/healthbR/reference/cnes_data.md)`(``year ``=`` ``2023``, month ``=`` ``1``, uf ``=`` ``"AC"``, type ``=`` ``"PF"``)`\
\
`# explore variables and categories`\
[`cnes_variables`](https://sidneybissoli.github.io/healthbR/reference/cnes_variables.md)`(``)`\
[`cnes_dictionary`](https://sidneybissoli.github.io/healthbR/reference/cnes_dictionary.md)`(``"TP_UNID"``)`

See
[`vignette("datasus-modules")`](https://sidneybissoli.github.io/healthbR/articles/datasus-modules.md)
for cross-module analysis examples.

## SI-PNI – Vaccination data

SI-PNI data comes from two sources: **FTP** (1994–2019) with aggregated
dose counts and coverage rates, and the **OpenDataSUS API** (2020–2025)
with individual-level microdata (one row per vaccination dose).
[`sipni_data()`](https://sidneybissoli.github.io/healthbR/reference/sipni_data.md)
routes transparently based on the requested year.

\
`# module overview`\
[`sipni_info`](https://sidneybissoli.github.io/healthbR/reference/sipni_info.md)`(``)`\
\
`# FTP: doses applied in Acre, 2019 (aggregated)`\
`doses`` ``<-`` `[`sipni_data`](https://sidneybissoli.github.io/healthbR/reference/sipni_data.md)`(``year ``=`` ``2019``, uf ``=`` ``"AC"``)`\
\
`# FTP: vaccination coverage`\
`cobertura`` ``<-`` `[`sipni_data`](https://sidneybissoli.github.io/healthbR/reference/sipni_data.md)`(``year ``=`` ``2019``, type ``=`` ``"CPNI"``, uf ``=`` ``"AC"``)`\
\
`# API: microdata for Acre, January 2024`\
`micro`` ``<-`` `[`sipni_data`](https://sidneybissoli.github.io/healthbR/reference/sipni_data.md)`(``year ``=`` ``2024``, uf ``=`` ``"AC"``, month ``=`` ``1``)`\
\
`# explore variables for each data source`\
[`sipni_variables`](https://sidneybissoli.github.io/healthbR/reference/sipni_variables.md)`(``)``                  ``# FTP DPNI variables`\
[`sipni_variables`](https://sidneybissoli.github.io/healthbR/reference/sipni_variables.md)`(``type ``=`` ``"API"``)``      ``# API microdata variables`\
[`sipni_dictionary`](https://sidneybissoli.github.io/healthbR/reference/sipni_dictionary.md)`(``"IMUNO"``)``          ``# FTP dictionary`

## SISAB – Primary care coverage

SISAB provides aggregated coverage indicators for primary care (Atencao
Primaria) via a public REST API. Unlike other DATASUS modules, no FTP
download or .dbc decompression is needed.

\
`# module overview`\
[`sisab_info`](https://sidneybissoli.github.io/healthbR/reference/sisab_info.md)`(``)`\
\
`# APS coverage by state, January 2024`\
`cobertura`` ``<-`` `[`sisab_data`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md)`(``year ``=`` ``2024``, month ``=`` ``1``)`\
\
`# national total, full year 2023`\
[`sisab_data`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md)`(``year ``=`` ``2023``, level ``=`` ``"brazil"``)`\
\
`# oral health coverage`\
[`sisab_data`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md)`(``year ``=`` ``2024``, type ``=`` ``"sb"``, month ``=`` ``6``)`\
\
`# municipality level for Sao Paulo`\
[`sisab_data`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md)`(``year ``=`` ``2024``, level ``=`` ``"municipality"``, uf ``=`` ``"SP"``, month ``=`` ``1``)`\
\
`# explore variables`\
[`sisab_variables`](https://sidneybissoli.github.io/healthbR/reference/sisab_variables.md)`(``)`\
[`sisab_variables`](https://sidneybissoli.github.io/healthbR/reference/sisab_variables.md)`(``type ``=`` ``"sb"``)`

## ANS – Supplementary health

ANS (Agencia Nacional de Saude Suplementar) provides open data on
private health insurance in Brazil, including beneficiary counts,
consumer complaints, and operator financial statements.

\
`# module overview`\
[`ans_info`](https://sidneybissoli.github.io/healthbR/reference/ans_info.md)`(``)`\
\
`# beneficiaries by state, January 2024`\
`benef`` ``<-`` `[`ans_data`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md)`(``type ``=`` ``"beneficiaries"``, year ``=`` ``2024``, month ``=`` ``1``, uf ``=`` ``"SP"``)`\
\
`# consumer complaints, 2023`\
`reclamacoes`` ``<-`` `[`ans_data`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md)`(``type ``=`` ``"complaints"``, year ``=`` ``2023``)`\
\
`# operator financial data, 2024 Q1`\
`financeiro`` ``<-`` `[`ans_data`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md)`(``type ``=`` ``"financial"``, year ``=`` ``2024``, quarter ``=`` ``1``)`\
\
`# health plan operator registry`\
`operadoras`` ``<-`` `[`ans_operators`](https://sidneybissoli.github.io/healthbR/reference/ans_operators.md)`(``)`\
\
`# explore variables`\
[`ans_variables`](https://sidneybissoli.github.io/healthbR/reference/ans_variables.md)`(``type ``=`` ``"beneficiaries"``)`

See
[`vignette("ans-supplementary-health")`](https://sidneybissoli.github.io/healthbR/articles/ans-supplementary-health.md)
for detailed examples.

## ANVISA – Medicines and pharmacovigilance

ANVISA (Agencia Nacional de Vigilancia Sanitaria) publishes open data on
regulated products (medicines, medical devices, food, cosmetics) and
pharmacovigilance reports (VigiMed). The SNGPC module provides
controlled substance dispensing data.

\
`# see all available data types`\
[`anvisa_types`](https://sidneybissoli.github.io/healthbR/reference/anvisa_types.md)`(``)`\
\
`# registered medicines`\
`medicamentos`` ``<-`` `[`anvisa_data`](https://sidneybissoli.github.io/healthbR/reference/anvisa_data.md)`(``type ``=`` ``"medicines"``)`\
\
`# pharmacovigilance notifications (VigiMed)`\
`vigimed`` ``<-`` `[`anvisa_data`](https://sidneybissoli.github.io/healthbR/reference/anvisa_data.md)`(``type ``=`` ``"vigimed_notifications"``)`\
\
`# controlled substance dispensing (SNGPC), monthly time-series`\
`sngpc`` ``<-`` `[`anvisa_data`](https://sidneybissoli.github.io/healthbR/reference/anvisa_data.md)`(``type ``=`` ``"sngpc"``, year ``=`` ``2024``, month ``=`` ``1``:``6``)`\
\
`# explore variables`\
[`anvisa_variables`](https://sidneybissoli.github.io/healthbR/reference/anvisa_variables.md)`(``type ``=`` ``"medicines"``)`

See `vignette("anvisa-regulatory-data")` for detailed examples.

## Caching

All modules cache downloaded data automatically to avoid repeated
downloads. Install `arrow` for optimized Parquet caching (recommended):

\
[`install.packages`](https://rdrr.io/r/utils/install.packages.html)`(``"arrow"``)`

Cache management works the same across all modules:

\
`# check what is cached`\
[`sim_cache_status`](https://sidneybissoli.github.io/healthbR/reference/sim_cache_status.md)`(``)`\
[`vigitel_cache_status`](https://sidneybissoli.github.io/healthbR/reference/vigitel_cache_status.md)`(``)`\
\
`# clear a module's cache`\
[`sim_clear_cache`](https://sidneybissoli.github.io/healthbR/reference/sim_clear_cache.md)`(``)`\
\
`# use a custom cache directory (e.g., for temporary use)`\
[`sim_data`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"AC"``, cache_dir ``=`` `[`tempdir`](https://rdrr.io/r/base/tempfile.html)`(``)``)`

## Parallel downloads

When downloading data for multiple years, months, or states, healthbR
processes each file sequentially by default. You can enable parallel
downloads by installing `furrr` and `future` and setting a parallel plan
before calling any `*_data()` function:

\
[`install.packages`](https://rdrr.io/r/utils/install.packages.html)`(`[`c`](https://rdrr.io/r/base/c.html)`(``"furrr"``, ``"future"``)``)`

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`future`](https://future.futureverse.org)`)`\
\
`# use multiple R sessions (e.g., 4 workers)`\
[`plan`](https://future.futureverse.org/reference/plan.html)`(``multisession``, workers ``=`` ``4``)`\
\
`# downloads now run in parallel across workers`\
`df`` ``<-`` `[`sih_data`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md)`(``year ``=`` ``2020``:``2023``, month ``=`` ``1``:``6``, uf ``=`` ``"SP"``)`\
\
`# return to sequential mode when done`\
[`plan`](https://future.futureverse.org/reference/plan.html)`(``sequential``)`

This works with every module that downloads multiple files, including
SIM, SINASC, SIH, SIA, SINAN, CNES, SI-PNI, SISAB, ANS, ANVISA, PNS, and
PNADC. No code changes are needed beyond setting the plan – healthbR
detects the active `future` plan automatically.

A few practical notes:

- **FTP sources** (DATASUS modules) include a small delay between
  requests to avoid overwhelming the server. Parallel workers respect
  this delay independently, so 4 workers download roughly 4x faster.
- **SI-PNI CSV** (2020+) uses an additional concurrent HTTP strategy
  ([`curl::multi_download()`](https://jeroen.r-universe.dev/curl/reference/multi_download.html))
  that works without `furrr`, downloading multiple months simultaneously
  within a single R session.
- Choose the number of workers based on your connection and the server.
  2–4 workers is usually a good balance between speed and politeness.

## Combining modules

healthbR’s real power comes from combining data across modules. For
example, calculating mortality rates requires deaths (SIM) and
population (Censo):

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`dplyr`](https://dplyr.tidyverse.org)`)`\
\
`# deaths by state`\
`deaths`` ``<-`` `[`sim_data`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md)`(``year ``=`` ``2022``, uf ``=`` ``"AC"``)`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``name ``=`` ``"deaths"``)`\
\
`# population by state`\
`pop`` ``<-`` `[`censo_populacao`](https://sidneybissoli.github.io/healthbR/reference/censo_populacao.md)`(``year ``=`` ``2022``, territorial_level ``=`` ``"state"``)`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``nivel_territorial_codigo`` ``==`` ``"12"``)``  ``# Acre`\
\
`# crude mortality rate`\
`deaths``$``deaths`` ``/`` ``pop``$``valor`` ``*`` ``100000`

## Additional resources

- [`vignette("datasus-modules")`](https://sidneybissoli.github.io/healthbR/articles/datasus-modules.md)
  – SIM, SINASC, SIH, SIA, SINAN, and CNES in depth
- [`vignette("censo-denominadores")`](https://sidneybissoli.github.io/healthbR/articles/censo-denominadores.md)
  – Population denominators for epidemiology
- [`vignette("pof-health-data")`](https://sidneybissoli.github.io/healthbR/articles/pof-health-data.md)
  – Analyzing food security and nutrition from POF
- [`vignette("sipni-vaccination")`](https://sidneybissoli.github.io/healthbR/articles/sipni-vaccination.md)
  – SI-PNI vaccination data (FTP + API)
- [`vignette("sisab-primary-care")`](https://sidneybissoli.github.io/healthbR/articles/sisab-primary-care.md)
  – SISAB primary care coverage indicators
- [`vignette("ans-supplementary-health")`](https://sidneybissoli.github.io/healthbR/articles/ans-supplementary-health.md)
  – ANS supplementary health data
- `vignette("anvisa-regulatory-data")` – ANVISA medicines and
  pharmacovigilance
- [Package website](https://sidneybissoli.github.io/healthbR/)
- [GitHub repository](https://github.com/SidneyBissoli/healthbR)
