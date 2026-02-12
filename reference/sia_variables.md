# List SIA Variables

Returns a tibble with available variables in the SIA microdata (PA
type), including descriptions and value types.

## Usage

``` r
sia_variables(type = "PA", search = NULL)
```

## Arguments

- type:

  Character. File type to show variables for. Currently only `"PA"` is
  fully documented. Default: `"PA"`.

- search:

  Character. Optional search term to filter variables by name or
  description. Case-insensitive and accent-insensitive.

## Value

A tibble with columns: variable, description, type, section.

## See also

Other sia:
[`sia_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sia_cache_status.md),
[`sia_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sia_clear_cache.md),
[`sia_data()`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md),
[`sia_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sia_dictionary.md),
[`sia_info()`](https://sidneybissoli.github.io/healthbR/reference/sia_info.md),
[`sia_years()`](https://sidneybissoli.github.io/healthbR/reference/sia_years.md)

## Examples

``` r
sia_variables()
#> # A tibble: 28 × 4
#>    variable   description                       type      section     
#>    <chr>      <chr>                             <chr>     <chr>       
#>  1 PA_CODUNI  Código CNES do estabelecimento    character gestao      
#>  2 PA_GESTAO  Código de gestão (UF + município) character gestao      
#>  3 PA_CONDIC  Condição de gestão (EP, EC, etc.) character gestao      
#>  4 PA_PROC_ID Código do procedimento (SIGTAP)   character procedimento
#>  5 PA_TPFIN   Tipo de financiamento             character procedimento
#>  6 PA_SUBFIN  Subtipo de financiamento          character procedimento
#>  7 PA_CODOCO  Código de ocorrência              character procedimento
#>  8 PA_DOCORIG Documento de origem               character procedimento
#>  9 PA_CODESP  Código da especialidade           character procedimento
#> 10 PA_TIPATE  Tipo de atendimento               character procedimento
#> # ℹ 18 more rows
sia_variables(search = "sexo")
#> # A tibble: 1 × 4
#>   variable description                    type      section 
#>   <chr>    <chr>                          <chr>     <chr>   
#> 1 PA_SEXO  Sexo (1=Masculino, 2=Feminino) character paciente
sia_variables(search = "procedimento")
#> # A tibble: 1 × 4
#>   variable   description                     type      section     
#>   <chr>      <chr>                           <chr>     <chr>       
#> 1 PA_PROC_ID Código do procedimento (SIGTAP) character procedimento
```
