# List POF registers

Returns information about the data registers available in the POF.

## Usage

``` r
pof_registers(year = "2017-2018", health_only = FALSE)
```

## Arguments

- year:

  Character. POF edition (e.g., "2017-2018"). Default is "2017-2018".

- health_only:

  Logical. If TRUE, returns only health-related registers. Default is
  FALSE.

## Value

A tibble with register names and descriptions.

## See also

Other pof:
[`pof_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/pof_cache_status.md),
[`pof_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/pof_clear_cache.md),
[`pof_data()`](https://sidneybissoli.github.io/healthbR/reference/pof_data.md),
[`pof_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/pof_dictionary.md),
[`pof_info()`](https://sidneybissoli.github.io/healthbR/reference/pof_info.md),
[`pof_variables()`](https://sidneybissoli.github.io/healthbR/reference/pof_variables.md),
[`pof_years()`](https://sidneybissoli.github.io/healthbR/reference/pof_years.md)

## Examples

``` r
pof_registers()
#> # A tibble: 10 × 3
#>    register           description                                 health_related
#>    <chr>              <chr>                                       <lgl>         
#>  1 domicilio          Características do domicílio, saneamento, … TRUE          
#>  2 morador            Dados dos moradores, demografia, pesos amo… TRUE          
#>  3 caderneta_coletiva Aquisição alimentar domiciliar              TRUE          
#>  4 despesa_individual Despesas individuais (inclui saúde)         TRUE          
#>  5 consumo_alimentar  Consumo alimentar pessoal detalhado (subam… TRUE          
#>  6 rendimento         Rendimentos dos moradores                   FALSE         
#>  7 inventario         Bens duráveis do domicílio                  FALSE         
#>  8 despesa_coletiva   Despesas coletivas do domicílio             FALSE         
#>  9 aluguel_estimado   Aluguel estimado para domicílios próprios   FALSE         
#> 10 outros_rendimentos Outros rendimentos não monetários           FALSE         
pof_registers("2017-2018", health_only = TRUE)
#> # A tibble: 5 × 3
#>   register           description                                  health_related
#>   <chr>              <chr>                                        <lgl>         
#> 1 domicilio          Características do domicílio, saneamento, E… TRUE          
#> 2 morador            Dados dos moradores, demografia, pesos amos… TRUE          
#> 3 caderneta_coletiva Aquisição alimentar domiciliar               TRUE          
#> 4 despesa_individual Despesas individuais (inclui saúde)          TRUE          
#> 5 consumo_alimentar  Consumo alimentar pessoal detalhado (subamo… TRUE          
```
