# List CNES Variables

Returns a tibble with available variables in the CNES data (ST type),
including descriptions and value types.

## Usage

``` r
cnes_variables(type = "ST", search = NULL)
```

## Arguments

- type:

  Character. File type to show variables for. Currently only `"ST"` is
  fully documented. Default: `"ST"`.

- search:

  Character. Optional search term to filter variables by name or
  description. Case-insensitive and accent-insensitive.

## Value

A tibble with columns: variable, description, type, section.

## See also

Other cnes:
[`cnes_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/cnes_cache_status.md),
[`cnes_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/cnes_clear_cache.md),
[`cnes_data()`](https://sidneybissoli.github.io/healthbR/reference/cnes_data.md),
[`cnes_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/cnes_dictionary.md),
[`cnes_info()`](https://sidneybissoli.github.io/healthbR/reference/cnes_info.md),
[`cnes_years()`](https://sidneybissoli.github.io/healthbR/reference/cnes_years.md)

## Examples

``` r
cnes_variables()
#> # A tibble: 27 × 4
#>    variable description                                    type      section    
#>    <chr>    <chr>                                          <chr>     <chr>      
#>  1 CNES     Código CNES do estabelecimento                 character identifica…
#>  2 CODUFMUN Código UF + Município (IBGE 6 dígitos)         character identifica…
#>  3 COD_CEP  CEP do estabelecimento                         character identifica…
#>  4 CPF_CNPJ CPF ou CNPJ do estabelecimento                 character identifica…
#>  5 PF_PJ    Pessoa Física ou Jurídica (1=PF, 3=PJ)         character identifica…
#>  6 NIV_DEP  Nível de dependência (1=Individual, 3=Mantido) character identifica…
#>  7 CNPJ_MAN CNPJ da mantenedora                            character identifica…
#>  8 COD_IR   Código na Receita Federal                      character identifica…
#>  9 TP_UNID  Tipo de unidade (hospital, UBS, clínica, etc.) character classifica…
#> 10 TURNO_AT Turno de atendimento                           character classifica…
#> # ℹ 17 more rows
cnes_variables(search = "tipo")
#> # A tibble: 3 × 4
#>   variable  description                                            type  section
#>   <chr>     <chr>                                                  <chr> <chr>  
#> 1 TP_UNID   Tipo de unidade (hospital, UBS, clínica, etc.)         char… classi…
#> 2 TP_PREST  Tipo de prestador                                      char… classi…
#> 3 TP_GESTAO Tipo de gestão (M=Municipal, E=Estadual, D=Dupla, S=S… char… sus    
cnes_variables(search = "gestao")
#> # A tibble: 1 × 4
#>   variable  description                                            type  section
#>   <chr>     <chr>                                                  <chr> <chr>  
#> 1 TP_GESTAO Tipo de gestão (M=Municipal, E=Estadual, D=Dupla, S=S… char… sus    
```
