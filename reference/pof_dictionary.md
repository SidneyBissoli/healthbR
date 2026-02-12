# Get POF variable dictionary

Downloads and returns the variable dictionary for POF microdata. The
dictionary is cached locally to avoid repeated downloads.

## Usage

``` r
pof_dictionary(
  year = "2017-2018",
  register = NULL,
  cache_dir = NULL,
  refresh = FALSE
)
```

## Arguments

- year:

  Character. POF edition (e.g., "2017-2018"). Default is "2017-2018".

- register:

  Character. Register name. If NULL, returns all registers. Default is
  NULL.

- cache_dir:

  Character. Directory for caching downloaded files. Default uses
  `tools::R_user_dir("healthbR", "cache")`.

- refresh:

  Logical. If TRUE, re-download even if file exists in cache. Default is
  FALSE.

## Value

A tibble with variable definitions including: variable, description,
position, length, decimals, register.

## See also

[`pof_variables`](https://sidneybissoli.github.io/healthbR/reference/pof_variables.md),
[`pof_data`](https://sidneybissoli.github.io/healthbR/reference/pof_data.md)

Other pof:
[`pof_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/pof_cache_status.md),
[`pof_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/pof_clear_cache.md),
[`pof_data()`](https://sidneybissoli.github.io/healthbR/reference/pof_data.md),
[`pof_info()`](https://sidneybissoli.github.io/healthbR/reference/pof_info.md),
[`pof_registers()`](https://sidneybissoli.github.io/healthbR/reference/pof_registers.md),
[`pof_variables()`](https://sidneybissoli.github.io/healthbR/reference/pof_variables.md),
[`pof_years()`](https://sidneybissoli.github.io/healthbR/reference/pof_years.md)

## Examples

``` r
# \donttest{
pof_dictionary("2017-2018", "morador", cache_dir = tempdir())
#> Downloading POF dictionary...
#> Downloading documentation from
#> <https://ftp.ibge.gov.br/Orcamentos_Familiares/Pesquisa_de_Orcamentos_Familiares_2017_2018/Microdados/Documentacao_20230713.zip>...
#> ✔ Documentation downloaded: /tmp/RtmpmPcNsW/pof/pof_2017-2018_doc.zip
#> Extracting documentation files...
#> Warning: unable to translate '/tmp/RtmpmPcNsW/pof_dict_2017-2018/Cadastro de Locais de Aquisi<87><c6>o.xls' to a wide string
#> Warning: input string 2 is invalid
#> Warning: unable to translate '/tmp/RtmpmPcNsW/pof_dict_2017-2018/Classifica<87><c6>o dos grupos de Consumo Alimentar.xlsx' to a wide string
#> Warning: input string 8 is invalid
#> Warning: unable to translate '/tmp/RtmpmPcNsW/pof_dict_2017-2018/Composi<87><c6>o do indicador de perda de qualidade de vida - IPQV.xlsx' to a wide string
#> Warning: input string 9 is invalid
#> Warning: unable to translate '/tmp/RtmpmPcNsW/pof_dict_2017-2018/Dicion<a0>rios de v<a0>riaveis.xls' to a wide string
#> Warning: input string 10 is invalid
#> Warning: unable to translate '/tmp/RtmpmPcNsW/pof_dict_2017-2018/Ocupa<87><c6>o COD.xlsx' to a wide string
#> Warning: input string 13 is invalid
#> Warning: unable to translate '/tmp/RtmpmPcNsW/pof_dict_2017-2018/Relat<a2>rio de Medidas Caseiras do Consumo Alimentar.docx' to a wide string
#> Warning: unable to translate 'Cadastro de Locais de Aquisi<87><c6>o.xls' to a wide string
#> Warning: input string 2 is invalid
#> Warning: unable to translate 'Classifica<87><c6>o dos grupos de Consumo Alimentar.xlsx' to a wide string
#> Warning: input string 8 is invalid
#> Warning: unable to translate 'Composi<87><c6>o do indicador de perda de qualidade de vida - IPQV.xlsx' to a wide string
#> Warning: input string 9 is invalid
#> Warning: unable to translate 'Dicion<a0>rios de v<a0>riaveis.xls' to a wide string
#> Warning: input string 10 is invalid
#> Warning: unable to translate 'Ocupa<87><c6>o COD.xlsx' to a wide string
#> Warning: input string 13 is invalid
#> Warning: unable to translate 'Relat<a2>rio de Medidas Caseiras do Consumo Alimentar.docx' to a wide string
#> Error in .pof_download_and_parse_dictionary(year, cache_dir): Could not find dictionary file after extraction.
#> ℹ Files found: "Atividade CNAE Domiciliar 2.0.xlsx", "Cadastro de Locais de
#>   Aquisi\x87\xc6o.xls", "Cadastro de Pesos ou Volumes.xls", "Cadastro de
#>   Produtos do Consumo Alimentar.xls", "Cadastro de Produtos.xls", "Cadastro de
#>   Unidades de Medida.xls", "Cadastro de Unidades de Medidas do Consumo
#>   Alimentar.xls", "Classifica\x87\xc6o dos grupos de Consumo Alimentar.xlsx",
#>   "Composi\x87\xc6o do indicador de perda de qualidade de vida - IPQV.xlsx",
#>   "Dicion\xa0rios de v\xa0riaveis.xls", "Estratos POF 2017-2018.xls", "Manual
#>   do Agente de Pesquisa.pdf", "Ocupa\x87\xc6o COD.xlsx",
#>   "Pos_estratos_totais.xlsx", "Relat\xa2rio de Medidas Caseiras do Consumo
#>   Alimentar.docx", and "Tabela de Medidas Caseiras do Consumo Alimentar.xls"
# }
```
