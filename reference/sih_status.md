# Status of the SIH-RD dataset on the healthbr-data R2 mirror

Reads the mirror's `manifest.json` (revalidated by ETag, cached locally)
and returns one row per published partition (billing competence x state
of the hospital), with the DATASUS source file it came from, its MD5 and
size, the record count and the processing timestamp. This is what
[`sih_data()`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md)
reads by default; use it to see which competences are published and to
detect a re-issued file (the MD5 changes).

## Usage

``` r
sih_status(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Character. Cache directory for the local copy of the manifest.
  Default: the SIH module cache.

## Value

A tibble with columns `dataset`, `year`, `month`, `uf`, `records`,
`processing_timestamp`, `source_url`, `source_hash_md5` and
`source_size_bytes`. Empty (with a warning) if the manifest cannot be
read and no local copy exists.

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
}
```
