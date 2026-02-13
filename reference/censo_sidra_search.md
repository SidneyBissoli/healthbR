# Search Census SIDRA tables

Searches Census SIDRA tables by keyword in the table name. Supports
partial matching, case-insensitive, and accent-insensitive search.

## Usage

``` r
censo_sidra_search(keyword, year = NULL)
```

## Arguments

- keyword:

  Character. Search term (minimum 2 characters).

- year:

  Character or numeric. Filter tables containing data for this year.
  NULL returns all.

## Value

A tibble with matching tables (same structure as
[`censo_sidra_tables`](https://sidneybissoli.github.io/healthbR/reference/censo_sidra_tables.md)).

## Examples

``` r
censo_sidra_search("deficiencia")
#> ℹ Found 2 table(s) matching 'deficiencia'
#> # A tibble: 2 × 5
#>   table_code table_name                           theme years territorial_levels
#>   <chr>      <chr>                                <chr> <lis> <list>            
#> 1 3426       Pessoas com deficiência por tipo (2… disa… <chr> <chr [4]>         
#> 2 9567       Pessoas com deficiência por tipo (2… disa… <chr> <chr [4]>         
censo_sidra_search("raca")
#> ℹ Found 2 table(s) matching 'raca'
#> # A tibble: 2 × 5
#>   table_code table_name                           theme years territorial_levels
#>   <chr>      <chr>                                <chr> <lis> <list>            
#> 1 136        População residente por cor ou raça… race  <chr> <chr [4]>         
#> 2 9605       População residente por cor ou raça… race  <chr> <chr [4]>         
censo_sidra_search("indigena")
#> ℹ Found 2 table(s) matching 'indigena'
#> # A tibble: 2 × 5
#>   table_code table_name                           theme years territorial_levels
#>   <chr>      <chr>                                <chr> <lis> <list>            
#> 1 3175       População indígena por sexo e idade… indi… <chr> <chr [4]>         
#> 2 9573       População indígena por sexo e idade… indi… <chr> <chr [4]>         
```
