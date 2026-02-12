# List Available SINAN Diseases

Returns a tibble with all notifiable diseases (agravos) available in
SINAN, including codes, names, and descriptions.

## Usage

``` r
sinan_diseases(search = NULL)
```

## Arguments

- search:

  Character. Optional search term to filter diseases by code, name, or
  description. Case-insensitive and accent-insensitive.

## Value

A tibble with columns: code, name, description.

## See also

Other sinan:
[`sinan_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sinan_cache_status.md),
[`sinan_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sinan_clear_cache.md),
[`sinan_data()`](https://sidneybissoli.github.io/healthbR/reference/sinan_data.md),
[`sinan_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sinan_dictionary.md),
[`sinan_info()`](https://sidneybissoli.github.io/healthbR/reference/sinan_info.md),
[`sinan_variables()`](https://sidneybissoli.github.io/healthbR/reference/sinan_variables.md),
[`sinan_years()`](https://sidneybissoli.github.io/healthbR/reference/sinan_years.md)

## Examples

``` r
sinan_diseases()
#> # A tibble: 31 × 3
#>    code  name                description                                
#>    <chr> <chr>               <chr>                                      
#>  1 ACBI  Acidente Biologico  Acidente de trabalho com material biologico
#>  2 ACGR  Acidente Grave      Acidente de trabalho grave                 
#>  3 ANIM  Animais Peconhentos Acidentes por animais peçonhentos          
#>  4 BOTU  Botulismo           Botulismo                                  
#>  5 CHAG  Chagas              Doença de Chagas                           
#>  6 CHIK  Chikungunya         Febre de Chikungunya                       
#>  7 COQU  Coqueluche          Coqueluche (pertussis)                     
#>  8 DENG  Dengue              Dengue                                     
#>  9 DIFT  Difteria            Difteria                                   
#> 10 ESQU  Esquistossomose     Esquistossomose                            
#> # ℹ 21 more rows
sinan_diseases(search = "dengue")
#> # A tibble: 1 × 3
#>   code  name   description
#>   <chr> <chr>  <chr>      
#> 1 DENG  Dengue Dengue     
sinan_diseases(search = "sifilis")
#> # A tibble: 3 × 3
#>   code  name                description        
#>   <chr> <chr>               <chr>              
#> 1 SIFA  Sifilis Adquirida   Sífilis adquirida  
#> 2 SIFC  Sifilis Congenita   Sífilis congênita  
#> 3 SIFG  Sifilis Gestacional Sífilis em gestante
```
