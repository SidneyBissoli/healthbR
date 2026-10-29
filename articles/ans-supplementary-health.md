# Supplementary Health Data with ANS

## Overview

The **ANS (Agencia Nacional de Saude Suplementar)** is Brazil’s
regulatory agency for private/supplementary health insurance (planos de
saude). Its open data portal provides data on beneficiaries, consumer
complaints, and operator financial statements.

| Feature       | Details                                  |
|---------------|------------------------------------------|
| Source        | HTTP CSV/ZIP (dadosabertos.ans.gov.br)   |
| Data types    | 3 (beneficiaries, complaints, financial) |
| Beneficiaries | Monthly, per-UF (Apr 2019–present)       |
| Complaints    | Annual, national (2011–present)          |
| Financial     | Quarterly (2007–present)                 |
| Operators     | Snapshot registry (separate function)    |

## Data types

| Code              | Name                    | Granularity      | Availability  |
|-------------------|-------------------------|------------------|---------------|
| **beneficiaries** | Beneficiarios           | Monthly, per-UF  | Apr 2019–2025 |
| **complaints**    | Demandas NIP            | Annual, national | 2011–2026     |
| **financial**     | Demonstracoes contabeis | Quarterly        | 2007–2025     |

## Getting started

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`healthbR`](https://github.com/SidneyBissoli/healthbR)`)`\
[`library`](https://rdrr.io/r/base/library.html)`(`[`dplyr`](https://dplyr.tidyverse.org)`)`

### Check available years

\
`# beneficiaries (default)`\
[`ans_years`](https://sidneybissoli.github.io/healthbR/reference/ans_years.md)`(``)`\
\
`# complaints`\
[`ans_years`](https://sidneybissoli.github.io/healthbR/reference/ans_years.md)`(``type ``=`` ``"complaints"``)`\
\
`# financial statements`\
[`ans_years`](https://sidneybissoli.github.io/healthbR/reference/ans_years.md)`(``type ``=`` ``"financial"``)`

### Module information

\
[`ans_info`](https://sidneybissoli.github.io/healthbR/reference/ans_info.md)`(``)`

## Beneficiaries

Beneficiary data provides consolidated counts of health plan enrollees
broken down by operator, municipality, sex, age group, plan type, and
more. Each file covers one state (UF) and one month.

### Basic download

\
`# Acre, December 2023`\
`ac`` ``<-`` `[`ans_data`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md)`(``year ``=`` ``2023``, month ``=`` ``12``, uf ``=`` ``"AC"``)`\
`ac`

### Multiple months and states

\
`# first quarter 2024, two states`\
`ne`` ``<-`` `[`ans_data`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md)`(``year ``=`` ``2024``, month ``=`` ``1``:``3``, uf ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"CE"``, ``"PE"``)``)`\
\
`# full year (month = NULL downloads all 12 months)`\
`ac_2023`` ``<-`` `[`ans_data`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md)`(``year ``=`` ``2023``, uf ``=`` ``"AC"``)`

### Selecting variables

\
[`ans_data`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md)`(`\
`  year ``=`` ``2023``, month ``=`` ``12``, uf ``=`` ``"AC"``,`\
`  vars ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"CD_OPERADORA"``, ``"SG_UF"``, ``"TP_SEXO"``,`\
`           ``"DE_FAIXA_ETARIA"``, ``"QT_BENEFICIARIO_ATIVO"``)`\
`)`

### Key variables

| Variable | Description |
|----|----|
| ID_CMPT_MOVEL | Reference period (YYYY-MM) |
| CD_OPERADORA | Operator code at ANS |
| NM_RAZAO_SOCIAL | Operator name |
| SG_UF | State abbreviation |
| CD_MUNICIPIO | Municipality (IBGE code) |
| TP_SEXO | Sex (M/F) |
| DE_FAIXA_ETARIA | Age group |
| DE_CONTRATACAO_PLANO | Contract type (Individual, Coletivo Empresarial, etc.) |
| DE_SEGMENTACAO_PLANO | Plan segment (Ambulatorial, Hospitalar, etc.) |
| COBERTURA_ASSIST_PLAN | Coverage type (Medico-hospitalar, Odontologica) |
| TIPO_VINCULO | Beneficiary link (Titular, Dependente) |
| QT_BENEFICIARIO_ATIVO | Active beneficiary count |

## Consumer complaints (NIP)

Consumer complaints data covers demands filed through ANS’s NIP
(Notificacao de Intermediacao Preliminar) system. Files are national
(not per-UF) and annual.

\
`# complaints filed in 2022`\
`nip`` ``<-`` `[`ans_data`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md)`(``year ``=`` ``2022``, type ``=`` ``"complaints"``)`\
`nip`\
\
`# multiple years`\
`nip_multi`` ``<-`` `[`ans_data`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md)`(``year ``=`` ``2020``:``2023``, type ``=`` ``"complaints"``)`

### Key variables

| Variable                 | Description           |
|--------------------------|-----------------------|
| NUMERO_DA_DEMANDA        | Complaint number      |
| ABERTURA_DA_DEMANDA      | Filing date           |
| ASSUNTO                  | Subject               |
| REGISTRO_OPERADORA       | Operator registration |
| NOME_OPERADORA           | Operator name         |
| TIPO_DE_PLANO_CONTRATADO | Contract type         |
| SEXO                     | Sex (M/F)             |
| ESTADO_DO_BENEFICIARIO   | Beneficiary state     |
| CLASSIFICACAO_DA_NIP     | NIP classification    |
| NATUREZA_DA_NIP          | NIP nature            |
| SITUACAO_DA_NIP          | NIP status            |

## Financial statements

Quarterly financial statements (demonstracoes contabeis) for all health
plan operators.

\
`# Q1 2023`\
`fin_q1`` ``<-`` `[`ans_data`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md)`(``year ``=`` ``2023``, type ``=`` ``"financial"``, quarter ``=`` ``1``)`\
\
`# all 4 quarters of 2023`\
`fin_2023`` ``<-`` `[`ans_data`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md)`(``year ``=`` ``2023``, type ``=`` ``"financial"``)`\
\
`# specific quarters`\
`fin_q12`` ``<-`` `[`ans_data`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md)`(``year ``=`` ``2023``, type ``=`` ``"financial"``, quarter ``=`` ``1``:``2``)`

### Key variables

| Variable          | Description                              |
|-------------------|------------------------------------------|
| DATA              | Reference date                           |
| REG_ANS           | Operator registration                    |
| CD_CONTA_CONTABIL | Accounting code                          |
| DESCRICAO         | Account description                      |
| VL_SALDO_INICIAL  | Opening balance (R$`) |                  
                     | VL_SALDO_FINAL | Closing balance (R`$)  |

## Operator registry

The operator registry is a separate snapshot (not time-series), so it
uses its own function:

\
`# active operators`\
`active`` ``<-`` `[`ans_operators`](https://sidneybissoli.github.io/healthbR/reference/ans_operators.md)`(``)`\
\
`# cancelled operators`\
`cancelled`` ``<-`` `[`ans_operators`](https://sidneybissoli.github.io/healthbR/reference/ans_operators.md)`(``status ``=`` ``"cancelled"``)`\
\
`# both combined`\
`all_ops`` ``<-`` `[`ans_operators`](https://sidneybissoli.github.io/healthbR/reference/ans_operators.md)`(``status ``=`` ``"all"``)`

### Key variables

| Variable           | Description                                     |
|--------------------|-------------------------------------------------|
| REGISTRO_OPERADORA | ANS registration number                         |
| CNPJ               | Tax ID                                          |
| Razao_Social       | Legal name                                      |
| Nome_Fantasia      | Trade name                                      |
| Modalidade         | Modality (Medicina de Grupo, Cooperativa, etc.) |
| UF                 | State                                           |
| Data_Registro_ANS  | ANS registration date                           |

## Exploring variables

\
`# beneficiaries variables (default)`\
[`ans_variables`](https://sidneybissoli.github.io/healthbR/reference/ans_variables.md)`(``)`\
\
`# complaints variables`\
[`ans_variables`](https://sidneybissoli.github.io/healthbR/reference/ans_variables.md)`(``type ``=`` ``"complaints"``)`\
\
`# financial variables`\
[`ans_variables`](https://sidneybissoli.github.io/healthbR/reference/ans_variables.md)`(``type ``=`` ``"financial"``)`\
\
`# search across variables`\
[`ans_variables`](https://sidneybissoli.github.io/healthbR/reference/ans_variables.md)`(``search ``=`` ``"operadora"``)`\
[`ans_variables`](https://sidneybissoli.github.io/healthbR/reference/ans_variables.md)`(``search ``=`` ``"beneficiario"``)`

## Example: beneficiaries by state and plan type

\
`# December 2023, all states`\
`ben`` ``<-`` `[`ans_data`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md)`(``year ``=`` ``2023``, month ``=`` ``12``)`\
\
`# active beneficiaries by state and coverage type`\
`ben`` ``|>`\
`  `[`group_by`](https://dplyr.tidyverse.org/reference/group_by.html)`(``SG_UF``, ``COBERTURA_ASSIST_PLAN``)`` ``|>`\
`  `[`summarize`](https://dplyr.tidyverse.org/reference/summarise.html)`(`\
`    total ``=`` `[`sum`](https://rdrr.io/r/base/sum.html)`(`[`as.integer`](https://rdrr.io/r/base/integer.html)`(``QT_BENEFICIARIO_ATIVO``)``, na.rm ``=`` ``TRUE``)``,`\
`    .groups ``=`` ``"drop"`\
`  ``)`` ``|>`\
`  `[`arrange`](https://dplyr.tidyverse.org/reference/arrange.html)`(`[`desc`](https://dplyr.tidyverse.org/reference/desc.html)`(``total``)``)`

## Example: complaints by subject and operator

\
`nip`` ``<-`` `[`ans_data`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md)`(``year ``=`` ``2023``, type ``=`` ``"complaints"``)`\
\
`# top complaint subjects`\
`nip`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``ASSUNTO``, sort ``=`` ``TRUE``)`` ``|>`\
`  `[`head`](https://rdrr.io/r/utils/head.html)`(``10``)`\
\
`# operators with most complaints`\
`nip`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``NOME_OPERADORA``, sort ``=`` ``TRUE``)`` ``|>`\
`  `[`head`](https://rdrr.io/r/utils/head.html)`(``10``)`

## Example: operator financial health

\
`# Q4 2023 financial data`\
`fin`` ``<-`` `[`ans_data`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md)`(``year ``=`` ``2023``, type ``=`` ``"financial"``, quarter ``=`` ``4``)`\
\
`# join with operator registry for names`\
`ops`` ``<-`` `[`ans_operators`](https://sidneybissoli.github.io/healthbR/reference/ans_operators.md)`(``)`\
\
`fin`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(`[`grepl`](https://rdrr.io/r/base/grep.html)`(``"^41"``, ``CD_CONTA_CONTABIL``)``)`` ``|>``  ``# revenue accounts`\
`  `[`group_by`](https://dplyr.tidyverse.org/reference/group_by.html)`(``REG_ANS``)`` ``|>`\
`  `[`summarize`](https://dplyr.tidyverse.org/reference/summarise.html)`(`\
`    revenue ``=`` `[`sum`](https://rdrr.io/r/base/sum.html)`(`[`as.numeric`](https://rdrr.io/r/base/numeric.html)`(``VL_SALDO_FINAL``)``, na.rm ``=`` ``TRUE``)``,`\
`    .groups ``=`` ``"drop"`\
`  ``)`` ``|>`\
`  `[`left_join`](https://dplyr.tidyverse.org/reference/mutate-joins.html)`(`\
`    ``ops`` ``|>`` `[`select`](https://dplyr.tidyverse.org/reference/select.html)`(``REGISTRO_OPERADORA``, ``Razao_Social``)``,`\
`    by ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"REG_ANS"`` ``=`` ``"REGISTRO_OPERADORA"``)`\
`  ``)`` ``|>`\
`  `[`arrange`](https://dplyr.tidyverse.org/reference/arrange.html)`(`[`desc`](https://dplyr.tidyverse.org/reference/desc.html)`(``revenue``)``)`` ``|>`\
`  `[`head`](https://rdrr.io/r/utils/head.html)`(``10``)`

## Example: combining ANS with SUS data

ANS beneficiary counts complement SUS data by showing private coverage:

\
`# private coverage (ANS)`\
`ben`` ``<-`` `[`ans_data`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md)`(``year ``=`` ``2023``, month ``=`` ``12``,`\
`                vars ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"SG_UF"``, ``"QT_BENEFICIARIO_ATIVO"``)``)`\
\
`private_by_uf`` ``<-`` ``ben`` ``|>`\
`  `[`group_by`](https://dplyr.tidyverse.org/reference/group_by.html)`(``SG_UF``)`` ``|>`\
`  `[`summarize`](https://dplyr.tidyverse.org/reference/summarise.html)`(`\
`    private_beneficiaries ``=`` `[`sum`](https://rdrr.io/r/base/sum.html)`(`[`as.integer`](https://rdrr.io/r/base/integer.html)`(``QT_BENEFICIARIO_ATIVO``)``, na.rm ``=`` ``TRUE``)``,`\
`    .groups ``=`` ``"drop"`\
`  ``)`\
\
`# total population (Census 2022)`\
`pop`` ``<-`` `[`censo_populacao`](https://sidneybissoli.github.io/healthbR/reference/censo_populacao.md)`(``year ``=`` ``2022``, territorial_level ``=`` ``"state"``)`\
\
`# private coverage rate`\
`# private_by_uf |>`\
`#   left_join(pop, by = ...) |>`\
`#   mutate(coverage_pct = (private_beneficiaries / population) * 100) |>`\
`#   arrange(desc(coverage_pct))`

## Parameter routing

[`ans_data()`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md)
routes parameters based on the `type`:

| Parameter |     beneficiaries      | complaints |   financial    |
|-----------|:----------------------:|:----------:|:--------------:|
| `year`    |        required        |  required  |    required    |
| `month`   |    optional (1–12)     |  ignored   |    ignored     |
| `uf`      | optional (27 UFs + XX) |  ignored   |    ignored     |
| `quarter` |        ignored         |  ignored   | optional (1–4) |
| `vars`    |        optional        |  optional  |    optional    |

Unused parameters emit a warning but do not cause errors.

## Lazy evaluation

With the `arrow` package installed, data is cached in Parquet format and
can be queried lazily:

\
`# lazy query (requires arrow)`\
`lazy_ben`` ``<-`` `[`ans_data`](https://sidneybissoli.github.io/healthbR/reference/ans_data.md)`(``year ``=`` ``2023``, uf ``=`` ``"AC"``, lazy ``=`` ``TRUE``)`\
`lazy_ben`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``month`` ``==`` ``12L``, ``TP_SEXO`` ``==`` ``"F"``)`` ``|>`\
`  `[`select`](https://dplyr.tidyverse.org/reference/select.html)`(``CD_OPERADORA``, ``DE_FAIXA_ETARIA``, ``QT_BENEFICIARIO_ATIVO``)`` ``|>`\
`  `[`collect`](https://dplyr.tidyverse.org/reference/compute.html)`(``)`

## Cache management

Downloaded data is cached locally for faster future access:

\
`# check cache status`\
[`ans_cache_status`](https://sidneybissoli.github.io/healthbR/reference/ans_cache_status.md)`(``)`\
\
`# clear cache if needed`\
[`ans_clear_cache`](https://sidneybissoli.github.io/healthbR/reference/ans_clear_cache.md)`(``)`

## Differences from DATASUS modules

| Feature | ANS | DATASUS modules |
|----|----|----|
| Data source | HTTP CSV/ZIP | FTP .dbc/.DBF files |
| Column names | MixedCase (from CSV) | UPPERCASE |
| `parse` parameter | Not available | Available |
| `dictionary()` | Not available | Available |
| `quarter` parameter | Financial data | Not used |
| Operator registry | [`ans_operators()`](https://sidneybissoli.github.io/healthbR/reference/ans_operators.md) | Not applicable |

## Additional resources

- ANS open data portal (`dadosabertos.ans.gov.br`)
- ANS official website (`www.gov.br/ans/pt-br`)
- ANS Tabnet (`www.ans.gov.br/anstabnet`)
- [Census
  vignette](https://sidneybissoli.github.io/healthbR/articles/censo-denominadores.md)
  for population denominators
