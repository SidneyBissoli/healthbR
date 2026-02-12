# List Census SIDRA tables

Returns a catalog of available SIDRA tables for the Census, organized by
theme.

## Usage

``` r
censo_sidra_tables(theme = NULL, year = NULL)
```

## Arguments

- theme:

  Character. Filter by theme. NULL returns all themes. Available themes:
  `"population"`, `"race"`, `"estimates"`, `"literacy"`, `"housing"`,
  `"sanitation"`, `"disability"`, `"indigenous"`, `"quilombola"`,
  `"fertility"`, `"education"`, `"labor"`, `"income"`, `"age_sex"`,
  `"urbanization"`.

- year:

  Character or numeric. Filter tables that contain data for this year.
  NULL returns tables for all years.

## Value

A tibble with columns: table_code, table_name, theme, years,
territorial_levels.

## Examples

``` r
# list all Census tables
censo_sidra_tables()
#> # A tibble: 28 × 5
#>    table_code table_name                          theme years territorial_levels
#>    <chr>      <chr>                               <chr> <lis> <list>            
#>  1 1378       População residente por sexo e fai… age_… <chr> <chr [4]>         
#>  2 9513       População residente por sexo e fai… age_… <chr> <chr [4]>         
#>  3 3426       Pessoas com deficiência por tipo (… disa… <chr> <chr [4]>         
#>  4 9567       Pessoas com deficiência por tipo (… disa… <chr> <chr [4]>         
#>  5 3541       Pessoas de 10 anos ou mais por nív… educ… <chr> <chr [4]>         
#>  6 9544       Pessoas de 10 anos ou mais por nív… educ… <chr> <chr [4]>         
#>  7 6579       Estimativas de população (2001-202… esti… <chr> <chr [4]>         
#>  8 2445       Mulheres de 10 anos ou mais por fi… fert… <chr> <chr [4]>         
#>  9 9583       Mulheres de 10 anos ou mais por fi… fert… <chr> <chr [4]>         
#> 10 1288       Domicílios particulares permanente… hous… <chr> <chr [4]>         
#> # ℹ 18 more rows

# filter by theme
censo_sidra_tables(theme = "population")
#> # A tibble: 2 × 5
#>   table_code table_name                           theme years territorial_levels
#>   <chr>      <chr>                                <chr> <lis> <list>            
#> 1 200        População residente por sexo, situa… popu… <chr> <chr [4]>         
#> 2 9514       População residente por sexo e idad… popu… <chr> <chr [4]>         

# tables with 2022 data
censo_sidra_tables(year = 2022)
#> # A tibble: 14 × 5
#>    table_code table_name                          theme years territorial_levels
#>    <chr>      <chr>                               <chr> <lis> <list>            
#>  1 9513       População residente por sexo e fai… age_… <chr> <chr [4]>         
#>  2 9567       Pessoas com deficiência por tipo (… disa… <chr> <chr [4]>         
#>  3 9544       Pessoas de 10 anos ou mais por nív… educ… <chr> <chr [4]>         
#>  4 9583       Mulheres de 10 anos ou mais por fi… fert… <chr> <chr [4]>         
#>  5 9547       Domicílios particulares permanente… hous… <chr> <chr [4]>         
#>  6 9575       Pessoas de 10 anos ou mais por cla… inco… <chr> <chr [4]>         
#>  7 9573       População indígena por sexo e idad… indi… <chr> <chr [4]>         
#>  8 9574       Pessoas de 10 anos ou mais por sit… labor <chr> <chr [4]>         
#>  9 9543       Pessoas de 5 anos ou mais por alfa… lite… <chr> <chr [4]>         
#> 10 9514       População residente por sexo e ida… popu… <chr> <chr [4]>         
#> 11 9929       População quilombola (2022)         quil… <chr> <chr [4]>         
#> 12 9605       População residente por cor ou raç… race  <chr> <chr [4]>         
#> 13 9560       Domicílios por forma de abastecime… sani… <chr> <chr [4]>         
#> 14 9515       População residente por situação d… urba… <chr> <chr [4]>         
```
