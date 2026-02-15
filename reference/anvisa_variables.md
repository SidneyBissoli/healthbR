# List ANVISA Variables

Returns a tibble with available variables for a given ANVISA data type,
including descriptions.

## Usage

``` r
anvisa_variables(type = "medicines", search = NULL)
```

## Arguments

- type:

  Character. ANVISA data type code. Default: `"medicines"`. Use
  [`anvisa_types()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_types.md)
  to see all valid types.

- search:

  Character. Optional search term to filter variables by name or
  description. Case-insensitive and accent-insensitive.

## Value

A tibble with columns: variable, description.

## See also

Other anvisa:
[`anvisa_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_cache_status.md),
[`anvisa_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_clear_cache.md),
[`anvisa_data()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_data.md),
[`anvisa_info()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_info.md),
[`anvisa_types()`](https://sidneybissoli.github.io/healthbR/reference/anvisa_types.md)

## Examples

``` r
anvisa_variables()
#> # A tibble: 11 × 2
#>    variable                   description                                       
#>    <chr>                      <chr>                                             
#>  1 TIPO_PRODUTO               Tipo de produto (Medicamento)                     
#>  2 NOME_PRODUTO               Nome do produto                                   
#>  3 DATA_FINALIZACAO_PROCESSO  Data de finalização do processo                   
#>  4 CATEGORIA_REGULATORIA      Categoria regulatória (Similar, Genérico, Novo, e…
#>  5 NUMERO_REGISTRO_PRODUTO    Número de registro do produto                     
#>  6 DATA_VENCIMENTO_REGISTRO   Data de vencimento do registro                    
#>  7 NUMERO_PROCESSO            Número do processo                                
#>  8 CLASSE_TERAPEUTICA         Classe terapêutica                                
#>  9 EMPRESA_DETENTORA_REGISTRO CNPJ e nome da empresa detentora do registro      
#> 10 SITUACAO_REGISTRO          Situação do registro (Ativo, Caduco/Cancelado, et…
#> 11 PRINCIPIO_ATIVO            Princípio ativo                                   
anvisa_variables(type = "hemovigilance")
#> # A tibble: 16 × 2
#>    variable                  description                                    
#>    <chr>                     <chr>                                          
#>  1 NU_NOTIFICACAO            Número da notificação                          
#>  2 DATA_OCORRENCIA_EVENTO    Data de ocorrência do evento                   
#>  3 DATA_NOTIFICACAO_EVENTO   Data da notificação                            
#>  4 STATUS_ANALISE            Status da análise (Concluída, Não Concluída)   
#>  5 PRODUTO_MOTIVO            Produto motivo do evento                       
#>  6 TIPO_REACAO_TRANSFUSIONAL Tipo de reação transfusional                   
#>  7 GRAU_RISCO                Grau de risco (Grau I, II, III, IV)            
#>  8 CATEGORIA_NOTIFICADOR     Categoria do notificador (Rede Sentinela, etc.)
#>  9 TIPO_HEMOCOMPONENTE       Tipo de hemocomponente                         
#> 10 FAIXA_ETARIA_PACIENTE     Faixa etária do paciente                       
#> 11 CIDADE_NOTIFICACAO        Cidade da notificação                          
#> 12 UF_NOTIFICACAO            UF da notificação                              
#> 13 DS_TEMPORALIDADE_REACAO   Temporalidade da reação (Imediata, Tardia)     
#> 14 TIPO_EVENTO_ADVERSO       Tipo de evento adverso                         
#> 15 ETAPA_CICLO_SANGUE        Etapa do ciclo do sangue                       
#> 16 DS_ESPECIFICACAO_EVENTO   Especificação do evento                        
anvisa_variables(search = "registro")
#> # A tibble: 4 × 2
#>   variable                   description                                        
#>   <chr>                      <chr>                                              
#> 1 NUMERO_REGISTRO_PRODUTO    Número de registro do produto                      
#> 2 DATA_VENCIMENTO_REGISTRO   Data de vencimento do registro                     
#> 3 EMPRESA_DETENTORA_REGISTRO CNPJ e nome da empresa detentora do registro       
#> 4 SITUACAO_REGISTRO          Situação do registro (Ativo, Caduco/Cancelado, etc…
```
