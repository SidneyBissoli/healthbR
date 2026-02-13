# List PNS SIDRA tables

Returns a catalog of available SIDRA tables for the PNS, organized by
health theme.

## Usage

``` r
pns_sidra_tables(theme = NULL, year = NULL)
```

## Arguments

- theme:

  Character. Filter by theme. NULL returns all themes. Available themes:
  "chronic_diseases", "lifestyle", "health_services",
  "health_perception", "womens_health", "accidents_violence",
  "oral_health", "anthropometry", "health_insurance", "disability",
  "elderly", "tobacco", "alcohol", "physical_activity", "nutrition",
  "medications", "mental_health", "work_health", "child_health".

- year:

  Numeric. Filter tables that contain data for this year. NULL returns
  tables for all years.

## Value

A tibble with columns: table_code, table_name, theme, theme_label,
years, territorial_levels.

## Examples

``` r
# list all tables
pns_sidra_tables()
#> # A tibble: 69 × 6
#>    table_code table_name              theme theme_label years territorial_levels
#>    <chr>      <chr>                   <chr> <chr>       <lis> <list>            
#>  1 5133       Acidentes de trânsito … acci… Acidentes … <chr> <chr [3]>         
#>  2 5135       Acidentes de trânsito … acci… Acidentes … <chr> <chr [3]>         
#>  3 5137       Violência física        acci… Acidentes … <chr> <chr [3]>         
#>  4 4352       Consumo de bebida alco… alco… Consumo de… <chr> <chr [3]>         
#>  5 4354       Consumo de bebida alco… alco… Consumo de… <chr> <chr [3]>         
#>  6 4356       Consumo abusivo de álc… alco… Consumo de… <chr> <chr [3]>         
#>  7 7720       Consumo de álcool - To… alco… Consumo de… <chr> <chr [3]>         
#>  8 7722       Consumo de álcool por … alco… Consumo de… <chr> <chr [3]>         
#>  9 8167       Antropometria - Total   anth… Antropomet… <chr> <chr [3]>         
#> 10 8169       Antropometria por sexo  anth… Antropomet… <chr> <chr [3]>         
#> # ℹ 59 more rows

# filter by theme
pns_sidra_tables(theme = "chronic_diseases")
#> # A tibble: 12 × 6
#>    table_code table_name              theme theme_label years territorial_levels
#>    <chr>      <chr>                   <chr> <chr>       <lis> <list>            
#>  1 4416       Diagnóstico de hiperte… chro… Doenças cr… <chr> <chr [3]>         
#>  2 4418       Diagnóstico de hiperte… chro… Doenças cr… <chr> <chr [3]>         
#>  3 4420       Diagnóstico de hiperte… chro… Doenças cr… <chr> <chr [3]>         
#>  4 4432       Diagnóstico de doença … chro… Doenças cr… <chr> <chr [3]>         
#>  5 4434       Diagnóstico de doença … chro… Doenças cr… <chr> <chr [3]>         
#>  6 4436       Diagnóstico de doença … chro… Doenças cr… <chr> <chr [3]>         
#>  7 4450       Diagnóstico de coleste… chro… Doenças cr… <chr> <chr [3]>         
#>  8 4452       Diagnóstico de coleste… chro… Doenças cr… <chr> <chr [3]>         
#>  9 4454       Diagnóstico de coleste… chro… Doenças cr… <chr> <chr [3]>         
#> 10 4487       Diagnóstico de diabete… chro… Doenças cr… <chr> <chr [3]>         
#> 11 4489       Diagnóstico de diabete… chro… Doenças cr… <chr> <chr [3]>         
#> 12 4491       Diagnóstico de diabete… chro… Doenças cr… <chr> <chr [3]>         

# tables with 2013 data
pns_sidra_tables(year = 2013)
#> # A tibble: 49 × 6
#>    table_code table_name              theme theme_label years territorial_levels
#>    <chr>      <chr>                   <chr> <chr>       <lis> <list>            
#>  1 5133       Acidentes de trânsito … acci… Acidentes … <chr> <chr [3]>         
#>  2 5135       Acidentes de trânsito … acci… Acidentes … <chr> <chr [3]>         
#>  3 5137       Violência física        acci… Acidentes … <chr> <chr [3]>         
#>  4 4352       Consumo de bebida alco… alco… Consumo de… <chr> <chr [3]>         
#>  5 4354       Consumo de bebida alco… alco… Consumo de… <chr> <chr [3]>         
#>  6 4356       Consumo abusivo de álc… alco… Consumo de… <chr> <chr [3]>         
#>  7 4416       Diagnóstico de hiperte… chro… Doenças cr… <chr> <chr [3]>         
#>  8 4418       Diagnóstico de hiperte… chro… Doenças cr… <chr> <chr [3]>         
#>  9 4420       Diagnóstico de hiperte… chro… Doenças cr… <chr> <chr [3]>         
#> 10 4432       Diagnóstico de doença … chro… Doenças cr… <chr> <chr [3]>         
#> # ℹ 39 more rows
```
