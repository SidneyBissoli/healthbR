# List SI-PNI Variables

Returns a tibble with available variables in the SI-PNI data, including
descriptions and value types.

## Usage

``` r
sipni_variables(type = "DPNI", search = NULL, source = c("r2", "datasus"))
```

## Arguments

- type:

  Character. File type to show variables for. `"DPNI"` (default) for
  doses applied (1994-2019), `"CPNI"` for coverage (1994-2019), or
  `"API"` for individual-level microdata (2020+).

- search:

  Character. Optional search term to filter variables by name or
  description. Case-insensitive and accent-insensitive.

- source:

  Character. Which source's column set to list for `type = "API"`:
  `"r2"` (default; 56 fields from the Ministry's JSON exports, served by
  the R2 mirror) or `"datasus"` (~47 fields of the OpenDataSUS CSV
  exports). Ignored for DPNI/CPNI (identical in both sources).

## Value

A tibble with columns: variable, description, type, section.

## See also

Other sipni:
[`sipni_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sipni_cache_status.md),
[`sipni_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sipni_clear_cache.md),
[`sipni_data()`](https://sidneybissoli.github.io/healthbR/reference/sipni_data.md),
[`sipni_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sipni_dictionary.md),
[`sipni_info()`](https://sidneybissoli.github.io/healthbR/reference/sipni_info.md),
[`sipni_status()`](https://sidneybissoli.github.io/healthbR/reference/sipni_status.md),
[`sipni_years()`](https://sidneybissoli.github.io/healthbR/reference/sipni_years.md)

## Examples

``` r
sipni_variables()
#> # A tibble: 12 × 4
#>    variable  description                       type      section    
#>    <chr>     <chr>                             <chr>     <chr>      
#>  1 ANO       Ano de referência                 character temporal   
#>  2 ANOMES    Ano e mês (AAAAMM)                character temporal   
#>  3 MES       Mês (01-12)                       character temporal   
#>  4 UF        Código UF (IBGE 2 dígitos)        character localizacao
#>  5 MUNIC     Código município (IBGE 6 dígitos) character localizacao
#>  6 FX_ETARIA Faixa etária (codificada)         character paciente   
#>  7 IMUNO     Código do imunobiológico          character vacinacao  
#>  8 DOSE      Tipo de dose                      character vacinacao  
#>  9 QT_DOSE   Quantidade de doses aplicadas     integer   vacinacao  
#> 10 DOSE1     (Reservado)                       character vacinacao  
#> 11 DOSEN     (Reservado)                       character vacinacao  
#> 12 DIFER     (Reservado)                       character vacinacao  
sipni_variables(type = "CPNI")
#> # A tibble: 7 × 4
#>   variable description                       type      section    
#>   <chr>    <chr>                             <chr>     <chr>      
#> 1 ANO      Ano de referência                 character temporal   
#> 2 UF       Código UF (IBGE 2 dígitos)        character localizacao
#> 3 MUNIC    Código município (IBGE 6 dígitos) character localizacao
#> 4 IMUNO    Código do imunobiológico          character vacinacao  
#> 5 QT_DOSE  Quantidade de doses aplicadas     integer   vacinacao  
#> 6 POP      População alvo                    integer   vacinacao  
#> 7 COBERT   Cobertura vacinal (%)             double    vacinacao  
sipni_variables(type = "API")
#> # A tibble: 56 × 4
#>    variable              description                               type  section
#>    <chr>                 <chr>                                     <chr> <chr>  
#>  1 co_documento          Código único do registro de vacinação (R… char… regist…
#>  2 co_paciente           Código anonimizado do paciente            char… pacien…
#>  3 tp_sexo_paciente      Sexo do paciente (M/F)                    char… pacien…
#>  4 co_raca_cor_paciente  Código raça/cor do paciente               char… pacien…
#>  5 no_raca_cor_paciente  Nome raça/cor do paciente                 char… pacien…
#>  6 co_municipio_paciente Código município de residência do pacien… char… pacien…
#>  7 co_pais_paciente      Código país de residência do paciente     char… pacien…
#>  8 no_municipio_paciente Nome município de residência do paciente  char… pacien…
#>  9 no_pais_paciente      Nome país de residência do paciente       char… pacien…
#> 10 sg_uf_paciente        Sigla UF de residência do paciente        char… pacien…
#> # ℹ 46 more rows
sipni_variables(type = "API", source = "datasus")
#> # A tibble: 47 × 4
#>    variable                          description                   type  section
#>    <chr>                             <chr>                         <chr> <chr>  
#>  1 sigla_uf_estabelecimento          Sigla UF do estabelecimento   char… estabe…
#>  2 nome_uf_estabelecimento           Nome UF do estabelecimento    char… estabe…
#>  3 codigo_municipio_estabelecimento  Código município do estabele… char… estabe…
#>  4 nome_municipio_estabelecimento    Nome município do estabeleci… char… estabe…
#>  5 codigo_cnes_estabelecimento       Código CNES do estabelecimen… char… estabe…
#>  6 nome_razao_social_estabelecimento Razão social do estabelecime… char… estabe…
#>  7 nome_fantasia_estalecimento       Nome fantasia do estabelecim… char… estabe…
#>  8 codigo_tipo_estabelecimento       Código tipo do estabelecimen… char… estabe…
#>  9 descricao_tipo_estabelecimento    Descrição tipo do estabeleci… char… estabe…
#> 10 codigo_natureza_estabelecimento   Código natureza jurídica do … char… estabe…
#> # ℹ 37 more rows
sipni_variables(search = "dose")
#> # A tibble: 4 × 4
#>   variable description                   type      section  
#>   <chr>    <chr>                         <chr>     <chr>    
#> 1 DOSE     Tipo de dose                  character vacinacao
#> 2 QT_DOSE  Quantidade de doses aplicadas integer   vacinacao
#> 3 DOSE1    (Reservado)                   character vacinacao
#> 4 DOSEN    (Reservado)                   character vacinacao
```
