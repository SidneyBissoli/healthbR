## R CMD check results

0 errors | 0 warnings | 1 note

* Update from 0.1.1 to 0.6.1 (major feature release: 8 new data modules).

## Existing CRAN NOTE (r-oldrel-macos-x86_64)

The NOTE "Package suggested but not available for checking: 'arrow'" on
r-oldrel-macos-x86_64 is expected. `arrow` is in Suggests and all code
checks its availability with `requireNamespace()` before use, falling
back to .rds caching when unavailable.

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
- DATASUS: Departamento de Informatica do SUS
- VIGITEL: Vigilancia de Fatores de Risco e Protecao para Doencas Cronicas
- PNS: Pesquisa Nacional de Saude
- PNADC / PNAD: Pesquisa Nacional por Amostra de Domicilios
- POF: Pesquisa de Orcamentos Familiares
- SINASC: Sistema de Informacoes sobre Nascidos Vivos
- SIM: Sistema de Informacoes sobre Mortalidade
- SIH: Sistema de Informacoes Hospitalares
- SIA: Sistema de Informacoes Ambulatoriais
- SIDRA: Sistema IBGE de Recuperacao Automatica
- IBGE: Instituto Brasileiro de Geografia e Estatistica

All examples that download data are wrapped in `@examplesIf interactive()`
to avoid network access during R CMD check.

FTP URLs (`ftp://ftp.datasus.gov.br/...`) are intentional -- DATASUS
distributes public health microdata exclusively via FTP.
