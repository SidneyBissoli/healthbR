# List SISAB Variables

Returns a tibble with available variables in the SISAB coverage data,
including descriptions and value types.

## Usage

``` r
sisab_variables(type = "aps", search = NULL)
```

## Arguments

- type:

  Character. Report type to show variables for. `"aps"` (default),
  `"sb"`, `"acs"`, or `"pns"`.

- search:

  Character. Optional search term to filter variables by name or
  description. Case-insensitive and accent-insensitive.

## Value

A tibble with columns: variable, description, type, section.

## See also

Other sisab:
[`sisab_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sisab_cache_status.md),
[`sisab_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sisab_clear_cache.md),
[`sisab_data()`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md),
[`sisab_info()`](https://sidneybissoli.github.io/healthbR/reference/sisab_info.md),
[`sisab_years()`](https://sidneybissoli.github.io/healthbR/reference/sisab_years.md)

## Examples

``` r
sisab_variables()
#> # A tibble: 29 × 4
#>    variable        description                type      section  
#>    <chr>           <chr>                      <chr>     <chr>    
#>  1 nuComp          Competência CNES (MM/YYYY) character temporal 
#>  2 coRegiao        Código da região           character geografia
#>  3 noRegiao        Nome da região             character geografia
#>  4 sgRegiao        Sigla da região            character geografia
#>  5 coUfIbge        Código UF IBGE             character geografia
#>  6 noUf            Nome da UF                 character geografia
#>  7 noUfAcentuado   Nome da UF (com acentos)   character geografia
#>  8 sgUf            Sigla da UF                character geografia
#>  9 coMunicipioIbge Código município IBGE      character geografia
#> 10 noMunicipioIbge Nome do município          character geografia
#> # ℹ 19 more rows
sisab_variables(type = "sb")
#> # A tibble: 24 × 4
#>    variable        description               type      section  
#>    <chr>           <chr>                     <chr>     <chr>    
#>  1 nuCompetencia   Competência CNES (YYYYMM) character temporal 
#>  2 coRegiao        Código da região          character geografia
#>  3 noRegiao        Nome da região            character geografia
#>  4 sgRegiao        Sigla da região           character geografia
#>  5 coUfIbge        Código UF IBGE            character geografia
#>  6 noUf            Nome da UF                character geografia
#>  7 noUfAcentuado   Nome da UF (com acentos)  character geografia
#>  8 sgUf            Sigla da UF               character geografia
#>  9 coMunicipioIbge Código município IBGE     character geografia
#> 10 noMunicipioIbge Nome do município         character geografia
#> # ℹ 14 more rows
sisab_variables(search = "cobertura")
#> # A tibble: 1 × 4
#>   variable    description   type    section  
#>   <chr>       <chr>         <chr>   <chr>    
#> 1 qtCobertura Cobertura (%) numeric cobertura
```
