# healthbR Maintenance Guide

This document captures operational knowledge for maintaining the
healthbR package: data source details, monitoring, triage procedures,
and how to add new modules.

## Module Registry

| Module       | Data Source | Source Type | Base URL                                                                                              | File Format | Year Coverage | Last Verified |
|--------------|-------------|-------------|-------------------------------------------------------------------------------------------------------|-------------|---------------|---------------|
| SIM          | DATASUS     | FTP         | `ftp://ftp.datasus.gov.br/dissemin/publicos/SIM/CID10/DORES/`                                         | .dbc        | 1996-2024     | 2026-02       |
| SINASC       | DATASUS     | FTP         | `ftp://ftp.datasus.gov.br/dissemin/publicos/SINASC/1996_/Dados/DNRES/`                                | .dbc        | 1996-2024     | 2026-02       |
| SIH          | DATASUS     | FTP         | `ftp://ftp.datasus.gov.br/dissemin/publicos/SIHSUS/200801_/Dados/`                                    | .dbc        | 2008-2024     | 2026-02       |
| SIA          | DATASUS     | FTP         | `ftp://ftp.datasus.gov.br/dissemin/publicos/SIASUS/200801_/Dados/`                                    | .dbc        | 2008-2024     | 2026-02       |
| SINAN        | DATASUS     | FTP         | `ftp://ftp.datasus.gov.br/dissemin/publicos/SINAN/DADOS/`                                             | .dbc        | 2007-2024     | 2026-02       |
| CNES         | DATASUS     | FTP         | `ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/`                                      | .dbc        | 2005-2024     | 2026-02       |
| SI-PNI (FTP) | DATASUS     | FTP         | `ftp://ftp.datasus.gov.br/dissemin/publicos/PNI/DADOS/`                                               | .dbf        | 1994-2019     | 2026-02       |
| SI-PNI (CSV) | OpenDataSUS | HTTPS       | `https://arquivosdadosabertos.saude.gov.br/dados/dbbni/`                                              | .csv.zip    | 2020-2025     | 2026-02       |
| SISAB        | Min. Saude  | REST API    | `https://relatorioaps-prd.saude.gov.br`                                                               | JSON        | 2019-2025     | 2026-02       |
| PNS          | IBGE        | HTTPS       | `https://ftp.ibge.gov.br/PNS/`                                                                        | .zip        | 2013, 2019    | 2026-02       |
| PNADC        | IBGE        | HTTPS       | `https://ftp.ibge.gov.br/Trabalho_e_Rendimento/Pesquisa_Nacional_por_Amostra_de_Domicilios_continua/` | .zip        | 2012-2024     | 2026-02       |
| POF          | IBGE        | HTTPS       | `https://ftp.ibge.gov.br/Orcamentos_Familiares/`                                                      | .zip        | 2008, 2017    | 2026-02       |
| Censo        | IBGE SIDRA  | REST API    | `https://apisidra.ibge.gov.br/values`                                                                 | JSON        | 1970-2022     | 2026-02       |
| VIGITEL      | SVS/MS      | HTTPS       | `https://svs.aids.gov.br/daent/cgdnt/vigitel/`                                                        | .xls/.xlsx  | 2006-2023     | 2026-02       |

## Known Quirks

- **DATASUS FTP** can be very slow on weekdays 9-17 BRT; weekend/night
  downloads are 5-10x faster.
- **DATASUS FTP** occasionally drops connections mid-transfer; the
  package retries with exponential backoff.
- **DATASUS FTP** requires `ftp_use_epsv=FALSE` in curl; EPSV mode fails
  silently.
- **SI-PNI CSV** files are ~1.4 GB ZIP / ~6 GB CSV each; downloading
  requires patience and disk space.
- **SI-PNI CSV** uses semicolon delimiter and latin1 encoding (not
  UTF-8).
- **SI-PNI CPNI** (coverage) uses comma as decimal separator in the
  `COBERT` field.
- **SISAB** portal (sisab.saude.gov.br) is frequently “Em manutencao”;
  the package uses the relatorioaps-prd backend directly.
- **VIGITEL** page uses JavaScript rendering; the package scrapes direct
  download links from the HTML.
- **SIDRA API** has a rate limit; batch requests with short pauses
  between calls.
- **SIH/SIA** SEXO codes differ from SIM: SIH uses 0/1/3
  (Ignorado/Masculino/Feminino), SIM uses M/F/I.
- **DBC files** are DBF compressed with PKWare DCL implode; the package
  includes C code for decompression.
- **`iconv(x, to = "ASCII//TRANSLIT")`** segfaults on Windows R; the
  package uses [`chartr()`](https://rdrr.io/r/base/chartr.html) for
  accent removal.
- **[`utils::unzip()`](https://rdrr.io/r/utils/unzip.html)** fails with
  Portuguese characters in ZIP filenames on Windows; PowerShell
  `Expand-Archive` is used as fallback.

## Automated Monitoring

The `check-endpoints.yaml` GitHub Actions workflow runs on the 1st of
each month (and on manual trigger). It probes all 14 endpoints and fails
if any are unreachable, triggering GitHub email notification.

To run manually:

``` bash
gh workflow run check-endpoints.yaml
```

## When Monitoring Fails

Follow this triage checklist:

1.  **Is it temporary?** Re-run the workflow. DATASUS FTP has
    intermittent outages lasting minutes to hours.
2.  **Is the server completely down?** Check if other DATASUS/IBGE
    services are also affected. Government servers sometimes have
    planned maintenance windows (especially weekends).
3.  **Did the URL move?** Browse the parent FTP directory to see if the
    path structure changed. DATASUS has historically reorganized
    directories (e.g., the `200801_` prefix in SIH).
4.  **Did the schema change?** Download a sample file and check column
    names against the dictionary. DATASUS occasionally adds/removes
    columns between years.
5.  **Is it a new year rollover?** Around March-April each year, DATASUS
    publishes prior-year data. Preliminary directories may appear before
    final data is available.
6.  **Open an issue** with the label `data-source` describing which
    endpoint failed, when it was last working, and any error details
    from the workflow log.

## CRAN Update Cadence

- Target ~2 releases per year.
- Time releases around DATASUS annual data publications (typically
  March/April for prior-year data).
- Always run `devtools::check(cran = TRUE)` before submission; target 0
  errors, 0 warnings, 0 notes.
- Test on R-devel, R-release, and R-oldrel (the R-CMD-check workflow
  covers this).

## Adding a New Module

### Checklist

1.  **Identify the data source**: URL, file format, update frequency,
    geographic/temporal coverage.
2.  **Create `R/{module}.R`** with these exported functions:
    - `{module}_data()` — main data retrieval function.
    - `{module}_dictionary()` — variable dictionary (if the data has
      coded categories).
    - `{module}_variables()` or `{module}_{type}s()` — list available
      file types or categories.
3.  **Follow existing parameter conventions**:
    - `uf` — 2-letter state abbreviation (when data is per-UF).
    - `year` — 4-digit year(s).
    - `month` — 1-12 (when data is monthly).
    - `cache` — logical, default TRUE.
    - `parse` — logical, default TRUE (smart type parsing).
    - `col_types` — named list of type overrides, default NULL.
    - `lazy` — logical, default FALSE (lazy evaluation).
    - `backend` — `c("arrow", "duckdb")` for lazy queries.
4.  **Use shared infrastructure**:
    - `utils-cache.R` — `.cache_parquet()`, `.cache_read()`,
      `.try_lazy_cache()`, `.data_return()`.
    - `utils-download.R` — `.ftp_download()`,
      `.http_download_resumable()`, `.multi_download()`.
    - `utils-parallel.R` — `.map_parallel()`.
    - `utils-parse.R` — `.parse_columns()`, `.build_type_spec()`.
5.  **Write tests** in `tests/testthat/test-{module}.R`:
    - Unit tests that mock downloads (should run without network).
    - Integration tests guarded with `skip_if_no_integration()`.
    - Aim for 50+ unit tests covering validation, caching, parsing,
      error handling.
6.  **Add a vignette** in `vignettes/{module}.Rmd`.
7.  **Add a probe** to `.github/workflows/check-endpoints.yaml`.
8.  **Update `MAINTENANCE.md`** — add the module to the registry table
    and note any quirks.
9.  **Update `DESCRIPTION`** — bump version, add any new dependencies to
    Imports/Suggests.
10. **Run `devtools::check(cran = TRUE)`** — must pass with 0/0/0.
