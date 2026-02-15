## R CMD check results

0 errors | 0 warnings | 0 notes

* Update from 0.6.1 to 0.14.0 (major feature release: 7 new data modules,
  performance infrastructure, code quality improvements).

## Changes since last CRAN release (0.6.1)

* Added 7 new data modules: CNES (health facilities), SINAN (notifiable
  diseases), SI-PNI (vaccination), SISAB (primary care coverage), ANS
  (supplementary health), ANVISA (health surveillance), and extended SI-PNI
  with post-2019 OpenDataSUS CSV support. Total: 16 modules.
* Added Hive-style partitioned parquet caching, lazy evaluation (Arrow/DuckDB),
  parallel downloads, smart type parsing for DATASUS modules.
* Extracted shared helpers for validation, search, cache, and return logic.
* Removed deprecated flat cache migration infrastructure.

## Test environments

* Local: Windows 11 Pro, R 4.5.2
* GitHub Actions:
  - Ubuntu Linux 22.04, R release
  - Ubuntu Linux 22.04, R devel
  - Ubuntu Linux 22.04, R oldrel-1
  - Windows Server 2022, R release
  - macOS (ARM64), R release

## Notes

The package includes compiled C code (`src/blast.c`, `src/dbc2dbf.c`) for
decompressing DATASUS .dbc files (PKWare DCL compressed DBF). The vendored
`blast.c`/`blast.h` are from Mark Adler (zlib license); `dbc2dbf.c` is
original code (MIT license). Both are documented in `inst/COPYRIGHTS`.

The NOTE about "possibly misspelled words" refers to Brazilian health system
acronyms used in the DESCRIPTION:
- ANVISA: Agencia Nacional de Vigilancia Sanitaria
- ANS: Agencia Nacional de Saude Suplementar
- CNES: Cadastro Nacional de Estabelecimentos de Saude
- DATASUS: Departamento de Informatica do SUS
- IBGE: Instituto Brasileiro de Geografia e Estatistica
- PNADC / PNAD: Pesquisa Nacional por Amostra de Domicilios
- PNS: Pesquisa Nacional de Saude
- POF: Pesquisa de Orcamentos Familiares
- SI-PNI / PNI: Sistema de Informacao do Programa Nacional de Imunizacoes
- SIA: Sistema de Informacoes Ambulatoriais
- SIDRA: Sistema IBGE de Recuperacao Automatica
- SIH: Sistema de Informacoes Hospitalares
- SIM: Sistema de Informacoes sobre Mortalidade
- SINAN: Sistema de Informacao de Agravos de Notificacao
- SINASC: Sistema de Informacoes sobre Nascidos Vivos
- SISAB: Sistema de Informacao em Saude para a Atencao Basica
- SNGPC: Sistema Nacional de Gerenciamento de Produtos Controlados
- VIGITEL: Vigilancia de Fatores de Risco e Protecao para Doencas Cronicas

All examples that download data are wrapped in `@examplesIf interactive()`
to avoid network access during R CMD check.

FTP URLs (`ftp://ftp.datasus.gov.br/...`) are intentional -- DATASUS
distributes public health microdata exclusively via FTP.

## Existing CRAN NOTE (r-oldrel-macos-x86_64)

The NOTE "Package suggested but not available for checking: 'arrow'" on
r-oldrel-macos-x86_64 is expected. `arrow` is in Suggests and all code
checks its availability with `requireNamespace()` before use, falling
back to .rds caching when unavailable.
