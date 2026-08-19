# SI-PNI Data Availability on the R2 Mirror

Reads the `manifest.json` provenance files of the healthbr-data R2
mirror and returns, for each published partition, when it was processed,
from which Ministry source file, and how many records it holds. Use it
to see which years/months are actually available before calling
[`sipni_data()`](https://sidneybissoli.github.io/healthbR/reference/sipni_data.md),
and to audit the provenance of the mirror.

## Usage

``` r
sipni_status(dataset = c("microdados", "doses", "cobertura"), cache_dir = NULL)
```

## Arguments

- dataset:

  Character. Which dataset(s) to report: `"microdados"`
  (individual-level 2020+, monthly partitions), `"doses"` (DPNI
  aggregates 1994–2019, year x UF partitions), `"cobertura"` (CPNI
  aggregates 1994–2019). Default: all three.

- cache_dir:

  Character. Cache directory (manifests are cached locally and
  revalidated by ETag). Default:
  `tools::R_user_dir("healthbR", "cache")`.

## Value

A tibble with columns: `dataset`, `year`, `month` (NA for aggregates),
`uf` (NA for microdata 2014 partitions are monthly and national),
`records`, `processing_timestamp` (as recorded by the pipeline, no
timezone), `source_url` (the Ministry file the partition was derived
from).

## Details

The manifests are the mirror's source of truth: they record the source
file's URL, size and hash, the processing timestamp, and the SHA-256 of
every published Parquet. Data on the mirror are byte-identical to the
Ministry's files; see the healthbr-data reproducibility policy for the
full audit recipe.

## See also

Other sipni:
[`sipni_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sipni_cache_status.md),
[`sipni_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sipni_clear_cache.md),
[`sipni_data()`](https://sidneybissoli.github.io/healthbR/reference/sipni_data.md),
[`sipni_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sipni_dictionary.md),
[`sipni_info()`](https://sidneybissoli.github.io/healthbR/reference/sipni_info.md),
[`sipni_variables()`](https://sidneybissoli.github.io/healthbR/reference/sipni_variables.md),
[`sipni_years()`](https://sidneybissoli.github.io/healthbR/reference/sipni_years.md)

## Examples

``` r
if (FALSE) { # interactive()
# everything the mirror currently holds
sipni_status()

# which 2026 microdata months are published?
dplyr::filter(sipni_status("microdados"), year == 2026)
}
```
