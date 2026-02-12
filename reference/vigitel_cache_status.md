# Get VIGITEL cache status

Shows cache status including downloaded files and their sizes.

## Usage

``` r
vigitel_cache_status(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Character. Optional custom cache directory. If NULL (default), uses
  the standard user cache directory.

## Value

A tibble with cache information

## Examples

``` r
# check cache status
vigitel_cache_status()
#> # A tibble: 6 × 4
#>   file_type     exists size_mb details
#>   <chr>         <lgl>    <dbl> <chr>  
#> 1 ZIP (Stata)   FALSE       NA NA     
#> 2 ZIP (CSV)     FALSE       NA NA     
#> 3 Data (Stata)  FALSE       NA NA     
#> 4 Data (CSV)    FALSE       NA NA     
#> 5 Dictionary    FALSE       NA NA     
#> 6 Parquet cache FALSE       NA NA     
```
