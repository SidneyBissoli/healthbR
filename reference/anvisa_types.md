# List ANVISA Data Types

Returns a tibble with available ANVISA data types, their names,
descriptions, and categories.

## Usage

``` r
anvisa_types()
```

## Value

A tibble with columns: code, name, description, category.

## See also

Other anvisa:
[`anvisa_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_cache_status.md),
[`anvisa_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_clear_cache.md),
[`anvisa_data()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_data.md),
[`anvisa_info()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_info.md),
[`anvisa_variables()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_variables.md)

## Examples

``` r
anvisa_types()
#> # A tibble: 14 × 4
#>    code                  name                     description           category
#>    <chr>                 <chr>                    <chr>                 <chr>   
#>  1 medicines             Medicamentos             Registro de medicame… product…
#>  2 medical_devices       Produtos para Saúde      Registro de produtos… product…
#>  3 food                  Alimentos                Registro de alimentos product…
#>  4 cosmetics             Cosméticos               Registro de cosmétic… product…
#>  5 sanitizers            Saneantes                Registro de saneantes product…
#>  6 tobacco               Produtos Fumígenos       Registro de produtos… product…
#>  7 pesticides            Agrotóxicos              Monografias de agrot… referen…
#>  8 hemovigilance         Hemovigilância           Notificações de even… surveil…
#>  9 technovigilance       Tecnovigilância          Notificações de even… surveil…
#> 10 vigimed_notifications VigiMed - Notificações   Notificações de farm… surveil…
#> 11 vigimed_medicines     VigiMed - Medicamentos   Medicamentos envolvi… surveil…
#> 12 vigimed_reactions     VigiMed - Reações        Reações adversas rep… surveil…
#> 13 sngpc                 SNGPC - Industrializados Venda de medicamento… sngpc   
#> 14 sngpc_compounded      SNGPC - Manipulados      Venda de medicamento… sngpc   
```
