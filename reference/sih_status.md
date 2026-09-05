# Status of the SIH-RD dataset on the healthbr-data R2 mirror

Reads the mirror's `manifest.json` (revalidated by ETag, cached locally)
and returns one row per published partition (billing competence x state
of the hospital): the DATASUS source file it came from (URL, MD5, size),
the Parquet it became (path in the bucket, SHA-256, size, record count),
when it was processed and by which version of the healthbr-data
pipeline. This is what
[`sih_data()`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md)
reads by default; use it to see which competences are published, to
detect a re-issued file (the MD5 changes) and to record the exact files
behind a derived product.

## Usage

``` r
sih_status(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Character. Cache directory for the local copy of the manifest.
  Default: the SIH module cache.

## Value

A tibble with one row per partition and columns `dataset`, `year`,
`month`, `uf`, `records`, `processing_timestamp` (UTC), `source_url`,
`source_hash_md5`, `source_size_bytes` (the DATASUS `.dbc`),
`parquet_path`, `parquet_sha256`, `parquet_size_bytes` (the mirror's
Parquet), `pipeline_version` and `git_commit` (the healthbr-data
pipeline that wrote it). The manifest's `last_updated` timestamp and
`manifest_version` come along as attributes of the same names
(`attr(st, "last_updated")`). Empty (with a warning) if the manifest
cannot be read and no local copy exists.

## See also

Other sih:
[`sih_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sih_cache_status.md),
[`sih_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sih_clear_cache.md),
[`sih_data()`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md),
[`sih_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sih_dictionary.md),
[`sih_info()`](https://sidneybissoli.github.io/healthbR/reference/sih_info.md),
[`sih_variables()`](https://sidneybissoli.github.io/healthbR/reference/sih_variables.md),
[`sih_years()`](https://sidneybissoli.github.io/healthbR/reference/sih_years.md)

## Examples

``` r
if (FALSE) { # interactive()
st <- sih_status()
# competences published for Roraima in 2024
st[st$uf == "RR" & st$year == 2024, ]
# when the mirror's manifest was last updated
attr(st, "last_updated")
}
```
