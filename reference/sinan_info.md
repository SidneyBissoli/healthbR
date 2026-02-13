# SINAN Module Information

Displays information about the Notifiable Diseases Information System
(SINAN), including data sources, available years, diseases, and usage
guidance.

## Usage

``` r
sinan_info()
```

## Value

A list with module information (invisibly).

## See also

Other sinan:
[`sinan_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sinan_cache_status.md),
[`sinan_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sinan_clear_cache.md),
[`sinan_data()`](https://sidneybissoli.github.io/healthbR/reference/sinan_data.md),
[`sinan_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sinan_dictionary.md),
[`sinan_diseases()`](https://sidneybissoli.github.io/healthbR/reference/sinan_diseases.md),
[`sinan_variables()`](https://sidneybissoli.github.io/healthbR/reference/sinan_variables.md),
[`sinan_years()`](https://sidneybissoli.github.io/healthbR/reference/sinan_years.md)

## Examples

``` r
sinan_info()
#> 
#> ── SINAN — Sistema de Informação de Agravos de Notificação ─────────────────────
#> 
#> Fonte: Ministério da Saúde / DATASUS
#> Acesso: FTP DATASUS
#> Cobertura: Nacional (um arquivo por agravo por ano)
#> Agravos: 31 doenças de notificação compulsória
#> 
#> ── Dados disponíveis ──
#> 
#> • `sinan_data()`: Microdados de agravos notificáveis
#>   Anos definitivos: 2007–2022
#>   Anos preliminares: 2023–2024
#> • `sinan_diseases()`: Lista de agravos disponíveis
#> • `sinan_variables()`: Lista de variáveis disponíveis
#> • `sinan_dictionary()`: Dicionário completo com categorias
#> 
#> ── Agravos mais comuns ──
#> 
#> DENG Dengue
#> CHIK Chikungunya
#> ZIKA Zika
#> TUBE Tuberculose
#> HANS Hanseníase
#> HEPA Hepatites virais
#> SIFA Sífilis adquirida
#> 
#> ── Variáveis-chave ──
#> 
#> DT_NOTIFIC Data da notificação
#> ID_AGRAVO Código do agravo (CID-10)
#> ID_MUNICIP Município de notificação (IBGE)
#> CS_SEXO Sexo
#> NU_IDADE_N Idade (codificada)
#> CS_RACA Raça/cor
#> CLASSI_FIN Classificação final
#> EVOLUCAO Evolução do caso
#> 
#> ℹ Arquivos são nacionais. Filtre por UF usando SG_UF_NOT ou ID_MUNICIP.
```
