# Migrate flat cache files to partitioned parquet datasets

Converts legacy flat cache files (`.parquet` or `.rds`) to Hive-style
partitioned parquet datasets. This is a one-time operation that prepares
your cache for faster lazy queries and future versions of healthbR.

## Usage

``` r
healthbR_migrate_cache(cache_dir = NULL, dry_run = FALSE)
```

## Arguments

- cache_dir:

  Character or NULL. Custom cache directory. If NULL (default), uses the
  standard healthbR cache location
  (`tools::R_user_dir("healthbR", "cache")`).

- dry_run:

  Logical. If TRUE, lists files that would be migrated without actually
  modifying anything. Default: FALSE.

## Value

Invisible list with migration summary: number of files migrated and
skipped per module.

## Examples

``` r
if (FALSE) { # interactive()
# Preview what would be migrated
healthbR_migrate_cache(dry_run = TRUE)

# Run the migration
healthbR_migrate_cache()
}
```
