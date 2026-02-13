# Create partitioned parquet cache

Create partitioned parquet cache

## Usage

``` r
create_partitioned_cache(df, cache_dir)
```

## Arguments

- df:

  A data frame with VIGITEL data

- cache_dir:

  Character. Cache directory path.

## Value

Invisible path to the parquet directory, or NULL if arrow not available.
