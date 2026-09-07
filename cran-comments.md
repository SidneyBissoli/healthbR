## Resubmission

This is a resubmission. In the previous submission (2026-09-06) CRAN found
two (possibly) invalid file URIs in README.md: relative links to
CONTRIBUTING.md and CODE_OF_CONDUCT.md, which are not shipped in the
tarball (.Rbuildignore). Both links now point to the absolute GitHub URLs
of those files. No other change.

## R CMD check results

0 errors | 0 warnings | 0 notes

## Changes since last CRAN release (0.2.0)

This release carries 0.3.0 and 0.3.1 (GitHub-only) plus 0.4.0. Summary:

* SI-PNI (0.3.0) and SIH (0.4.0) modules gain a `source` argument: the
  default reads from the healthbr-data Parquet mirror (Cloudflare R2,
  public read-only credentials bundled) and falls back to the DATASUS FTP
  when the mirror yields nothing; new `sipni_status()` / `sih_status()`
  expose per-partition provenance from the mirror's manifest. Results carry
  provenance attributes. `lazy = TRUE` over the mirror returns a remote
  arrow dataset.
* SI-PNI dictionary and label maps corrected against the official
  dictionary; `sipni_dictionary(lookup = TRUE)` (0.3.1).
* `*_clear_cache()` now removes partitioned datasets too; SIH manifest
  summary memoised (warm calls 5.5 s -> 0.8 s).
* DATASUS year coverage updated (SINAN 2023-2025 final; SIH/SIA/CNES
  through 2026), fixing a broken download.
* New vignette comparing healthbR with microdatasus (all chunks
  `eval = FALSE`; outputs pasted from a measured session).

## Network use in checks

All tests and vignettes that reach the network are skipped on CRAN
(`skip_if_no_integration()` gate, `eval = FALSE` chunks); the remaining
tests are offline. Brazilian government hosts are cited as plain text or
in `\url{}` only where they answered a URL check on 2026-09-06
(`urlchecker::url_check()`: all URLs correct).

## Test environments

* Local: Windows 11 Pro, R 4.6.1 (`R CMD check --as-cran`)
* GitHub Actions (R-CMD-check.yaml):
  - Ubuntu latest, R release / devel / oldrel-1
  - Windows latest, R release
  - macOS latest (ARM64), R release
