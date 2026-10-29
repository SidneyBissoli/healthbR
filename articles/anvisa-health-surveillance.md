# Health Surveillance Data with ANVISA

## Overview

**ANVISA (Agencia Nacional de Vigilancia Sanitaria)** is Brazil’s health
surveillance agency responsible for regulating medicines, health
products, food, cosmetics, sanitizers, tobacco, and pesticides. Its open
data portal provides CSV files on product registrations, post-market
surveillance (pharmacovigilance, hemovigilance, technovigilance), and
controlled substance sales (SNGPC).

| Feature        | Details                                        |
|----------------|------------------------------------------------|
| Source         | HTTPS CSV (dados.anvisa.gov.br)                |
| Data types     | 14 (12 snapshot + 2 time-series)               |
| Snapshot types | Current registry/database state                |
| SNGPC types    | Monthly controlled substance sales (2014–2026) |

## Data types

Use
[`anvisa_types()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_types.md)
to see all available types:

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`healthbR`](https://github.com/SidneyBissoli/healthbR)`)`\
[`library`](https://rdrr.io/r/base/library.html)`(`[`dplyr`](https://dplyr.tidyverse.org)`)`\
\
[`anvisa_types`](https://sidneybissoli.github.io/healthbR/reference/anvisa_types.md)`(``)`

### Snapshot types (12)

These download the current snapshot of the registry or database. No
`year` or `month` parameter is needed.

| Code                      | Name                 | Category             |
|---------------------------|----------------------|----------------------|
| **medicines**             | Medicamentos         | Product Registration |
| **medical_devices**       | Produtos para Saude  | Product Registration |
| **food**                  | Alimentos            | Product Registration |
| **cosmetics**             | Cosmeticos           | Product Registration |
| **sanitizers**            | Saneantes            | Product Registration |
| **tobacco**               | Produtos Fumigenos   | Product Registration |
| **pesticides**            | Agrotoxicos          | Reference            |
| **hemovigilance**         | Hemovigilancia       | Surveillance         |
| **technovigilance**       | Tecnovigilancia      | Surveillance         |
| **vigimed_notifications** | VigiMed Notificacoes | Surveillance         |
| **vigimed_medicines**     | VigiMed Medicamentos | Surveillance         |
| **vigimed_reactions**     | VigiMed Reacoes      | Surveillance         |

### Time-series types (2)

These require a `year` parameter and optionally a `month` parameter.

| Code                 | Name                   | Availability                   |
|----------------------|------------------------|--------------------------------|
| **sngpc**            | SNGPC Industrializados | Jan 2014 – Oct 2021, Jan 2026+ |
| **sngpc_compounded** | SNGPC Manipulados      | Jan 2014 – Oct 2021, Jan 2026+ |

## Product registrations

### Medicines

Download the complete registry of medicines approved by ANVISA:

\
`medicines`` ``<-`` `[`anvisa_data`](https://sidneybissoli.github.io/healthbR/reference/anvisa_data.md)`(``type ``=`` ``"medicines"``)`\
\
`# explore the data`\
[`nrow`](https://rdrr.io/r/base/nrow.html)`(``medicines``)`\
[`names`](https://rdrr.io/r/base/names.html)`(``medicines``)`\
\
`# filter active medicines`\
`active`` ``<-`` ``medicines`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``SITUACAO_REGISTRO`` ``==`` ``"ATIVO"``)`\
\
`# count by therapeutic class`\
`active`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``CLASSE_TERAPEUTICA``, sort ``=`` ``TRUE``)`

### Medical devices

\
`devices`` ``<-`` `[`anvisa_data`](https://sidneybissoli.github.io/healthbR/reference/anvisa_data.md)`(``type ``=`` ``"medical_devices"``)`\
\
`# count by risk class`\
`devices`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``CLASSE_RISCO``, sort ``=`` ``TRUE``)`

### Food and cosmetics

\
`food`` ``<-`` `[`anvisa_data`](https://sidneybissoli.github.io/healthbR/reference/anvisa_data.md)`(``type ``=`` ``"food"``)`\
`cosmetics`` ``<-`` `[`anvisa_data`](https://sidneybissoli.github.io/healthbR/reference/anvisa_data.md)`(``type ``=`` ``"cosmetics"``)`

### Select specific variables

\
`# only keep product name and active ingredient`\
`med_slim`` ``<-`` `[`anvisa_data`](https://sidneybissoli.github.io/healthbR/reference/anvisa_data.md)`(`\
`  type ``=`` ``"medicines"``,`\
`  vars ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"NOME_PRODUTO"``, ``"PRINCIPIO_ATIVO"``, ``"SITUACAO_REGISTRO"``)`\
`)`

## Pesticides

Pesticide monographs list authorized active ingredients and their
maximum residue limits (LMR):

\
`pesticides`` ``<-`` `[`anvisa_data`](https://sidneybissoli.github.io/healthbR/reference/anvisa_data.md)`(``type ``=`` ``"pesticides"``)`\
\
`# search for a specific substance`\
[`anvisa_variables`](https://sidneybissoli.github.io/healthbR/reference/anvisa_variables.md)`(``type ``=`` ``"pesticides"``, search ``=`` ``"substancia"``)`\
\
`# substances authorized for coffee`\
`coffee`` ``<-`` ``pesticides`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``NO_CULTURA`` ``==`` ``"Cafe"``)`

## Post-market surveillance

### Hemovigilance

Adverse events related to blood transfusions:

\
`hemo`` ``<-`` `[`anvisa_data`](https://sidneybissoli.github.io/healthbR/reference/anvisa_data.md)`(``type ``=`` ``"hemovigilance"``)`\
\
`# count by reaction type`\
`hemo`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``TIPO_REACAO_TRANSFUSIONAL``, sort ``=`` ``TRUE``)`\
\
`# count by state`\
`hemo`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``UF_NOTIFICACAO``, sort ``=`` ``TRUE``)`

### Technovigilance

Adverse events related to medical devices:

\
`techno`` ``<-`` `[`anvisa_data`](https://sidneybissoli.github.io/healthbR/reference/anvisa_data.md)`(``type ``=`` ``"technovigilance"``)`\
\
`# count by notification type`\
`techno`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``TIPO_NOTIFICACAO``, sort ``=`` ``TRUE``)`

### Pharmacovigilance (VigiMed)

Drug/vaccine adverse event reports are split into three linked datasets
sharing the `IDENTIFICACAO_NOTIFICACAO` key:

\
`# notifications (patient info + event summary)`\
`notif`` ``<-`` `[`anvisa_data`](https://sidneybissoli.github.io/healthbR/reference/anvisa_data.md)`(``type ``=`` ``"vigimed_notifications"``)`\
\
`# medicines involved`\
`meds`` ``<-`` `[`anvisa_data`](https://sidneybissoli.github.io/healthbR/reference/anvisa_data.md)`(``type ``=`` ``"vigimed_medicines"``)`\
\
`# adverse reactions (MedDRA coded)`\
`reactions`` ``<-`` `[`anvisa_data`](https://sidneybissoli.github.io/healthbR/reference/anvisa_data.md)`(``type ``=`` ``"vigimed_reactions"``)`\
\
`# link notifications to reactions`\
`linked`` ``<-`` ``notif`` ``|>`\
`  `[`select`](https://dplyr.tidyverse.org/reference/select.html)`(``IDENTIFICACAO_NOTIFICACAO``, ``SEXO``, ``IDADE_MOMENTO_REACAO``, ``GRAVE``)`` ``|>`\
`  `[`inner_join`](https://dplyr.tidyverse.org/reference/mutate-joins.html)`(``reactions``, by ``=`` ``"IDENTIFICACAO_NOTIFICACAO"``)`\
\
`# most common reactions`\
`linked`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``PT``, sort ``=`` ``TRUE``)`` ``|>`\
`  `[`head`](https://rdrr.io/r/utils/head.html)`(``20``)`

## SNGPC – Controlled substance sales

The SNGPC (Sistema Nacional de Gerenciamento de Produtos Controlados)
tracks sales of controlled substances (psychotropics, narcotics) by
pharmacies across Brazil.

### Industrialized medicines

\
`# download January 2020 data`\
`sngpc_jan`` ``<-`` `[`anvisa_data`](https://sidneybissoli.github.io/healthbR/reference/anvisa_data.md)`(``type ``=`` ``"sngpc"``, year ``=`` ``2020``, month ``=`` ``1``)`\
\
`# top prescribed controlled substances`\
`sngpc_jan`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``DS_PRINCIPIO_ATIVO``, sort ``=`` ``TRUE``)`` ``|>`\
`  `[`head`](https://rdrr.io/r/utils/head.html)`(``10``)`\
\
`# sales by state`\
`sngpc_jan`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``SG_UF_VENDA``, sort ``=`` ``TRUE``)`

### Multiple months

\
`# download Q1 2020 (Jan-Mar)`\
`sngpc_q1`` ``<-`` `[`anvisa_data`](https://sidneybissoli.github.io/healthbR/reference/anvisa_data.md)`(``type ``=`` ``"sngpc"``, year ``=`` ``2020``, month ``=`` ``1``:``3``)`\
\
`# monthly trend`\
`sngpc_q1`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``month``, name ``=`` ``"sales"``)`

### Compounded medicines

\
`# compounded (manipulated) controlled substances`\
`manip`` ``<-`` `[`anvisa_data`](https://sidneybissoli.github.io/healthbR/reference/anvisa_data.md)`(``type ``=`` ``"sngpc_compounded"``, year ``=`` ``2020``, month ``=`` ``1``)`\
\
`# most common active ingredients`\
`manip`` ``|>`\
`  `[`count`](https://dplyr.tidyverse.org/reference/count.html)`(``NO_PRINCIPIO_ATIVO``, sort ``=`` ``TRUE``)`` ``|>`\
`  `[`head`](https://rdrr.io/r/utils/head.html)`(``10``)`

### Lazy evaluation for large queries

For large SNGPC queries spanning many months, use lazy evaluation to
defer computation:

\
`# lazy query (requires arrow package)`\
`lazy_sngpc`` ``<-`` `[`anvisa_data`](https://sidneybissoli.github.io/healthbR/reference/anvisa_data.md)`(`\
`  type ``=`` ``"sngpc"``, year ``=`` ``2020``, month ``=`` ``1``:``12``,`\
`  lazy ``=`` ``TRUE`\
`)`\
\
`# filter and collect only what you need`\
`result`` ``<-`` ``lazy_sngpc`` ``|>`\
`  `[`filter`](https://dplyr.tidyverse.org/reference/filter.html)`(``SG_UF_VENDA`` ``==`` ``"SP"``)`` ``|>`\
`  `[`collect`](https://dplyr.tidyverse.org/reference/compute.html)`(``)`

## Exploring variables

Use
[`anvisa_variables()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_variables.md)
to see available variables for any type:

\
`# all medicines variables`\
[`anvisa_variables`](https://sidneybissoli.github.io/healthbR/reference/anvisa_variables.md)`(``type ``=`` ``"medicines"``)`\
\
`# search across descriptions`\
[`anvisa_variables`](https://sidneybissoli.github.io/healthbR/reference/anvisa_variables.md)`(``type ``=`` ``"hemovigilance"``, search ``=`` ``"paciente"``)`\
\
`# SNGPC variables`\
[`anvisa_variables`](https://sidneybissoli.github.io/healthbR/reference/anvisa_variables.md)`(``type ``=`` ``"sngpc"``)`

## Caching

Downloaded data is cached locally for faster subsequent access:

\
`# check cache status`\
[`anvisa_cache_status`](https://sidneybissoli.github.io/healthbR/reference/anvisa_cache_status.md)`(``)`\
\
`# clear all cached ANVISA data`\
[`anvisa_clear_cache`](https://sidneybissoli.github.io/healthbR/reference/anvisa_clear_cache.md)`(``)`

## Module information

\
`# full module overview`\
[`anvisa_info`](https://sidneybissoli.github.io/healthbR/reference/anvisa_info.md)`(``)`
