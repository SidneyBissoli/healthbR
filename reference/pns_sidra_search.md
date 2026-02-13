# Search PNS SIDRA tables

Searches PNS SIDRA tables by keyword in the table name/description.
Supports partial matching, case-insensitive, and accent-insensitive
search.

## Usage

``` r
pns_sidra_search(keyword, year = NULL)
```

## Arguments

- keyword:

  Character. Search term (minimum 2 characters).

- year:

  Numeric. Filter tables containing data for this year. NULL returns
  all.

## Value

A tibble with matching tables (same structure as pns_sidra_tables()).

## Examples

``` r
pns_sidra_search("diabetes")
#> ℹ Found 3 table(s) matching 'diabetes'
#> # A tibble: 3 × 6
#>   table_code table_name               theme theme_label years territorial_levels
#>   <chr>      <chr>                    <chr> <chr>       <lis> <list>            
#> 1 4487       Diagnóstico de diabetes… chro… Doenças cr… <chr> <chr [3]>         
#> 2 4489       Diagnóstico de diabetes… chro… Doenças cr… <chr> <chr [3]>         
#> 3 4491       Diagnóstico de diabetes… chro… Doenças cr… <chr> <chr [3]>         
pns_sidra_search("hipertensao")
#> ℹ Found 3 table(s) matching 'hipertensao'
#> # A tibble: 3 × 6
#>   table_code table_name               theme theme_label years territorial_levels
#>   <chr>      <chr>                    <chr> <chr>       <lis> <list>            
#> 1 4416       Diagnóstico de hiperten… chro… Doenças cr… <chr> <chr [3]>         
#> 2 4418       Diagnóstico de hiperten… chro… Doenças cr… <chr> <chr [3]>         
#> 3 4420       Diagnóstico de hiperten… chro… Doenças cr… <chr> <chr [3]>         
pns_sidra_search("fumante")
#> ℹ Found 2 table(s) matching 'fumante'
#> # A tibble: 2 × 6
#>   table_code table_name               theme theme_label years territorial_levels
#>   <chr>      <chr>                    <chr> <chr>       <lis> <list>            
#> 1 4173       Fumantes atuais de taba… toba… Tabagismo   <chr> <chr [3]>         
#> 2 4175       Fumantes atuais de taba… toba… Tabagismo   <chr> <chr [3]>         
```
