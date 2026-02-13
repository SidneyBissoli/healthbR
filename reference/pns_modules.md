# List PNS survey modules

Returns information about the questionnaire modules available in the
PNS.

## Usage

``` r
pns_modules(year = NULL)
```

## Arguments

- year:

  Numeric. Year to get modules for (2013 or 2019). NULL returns modules
  for all years. Default is NULL.

## Value

A tibble with module codes, names, and descriptions.

## Examples

``` r
pns_modules()
#> # A tibble: 23 × 3
#>    module name                                 name_en                          
#>    <chr>  <chr>                                <chr>                            
#>  1 A      Informações do domicílio             Household information            
#>  2 C      Características gerais dos moradores General characteristics of resid…
#>  3 D      Educação                             Education                        
#>  4 E      Trabalho e rendimento                Work and income                  
#>  5 F      Pessoas com deficiência              Persons with disabilities        
#>  6 G      Cobertura de plano de saúde          Health insurance coverage        
#>  7 H      Utilização de serviços de saúde      Health services utilization      
#>  8 I      Saúde dos moradores do domicílio     Health of household residents    
#>  9 J      Percepção do estado de saúde         Health status perception         
#> 10 K      Acidentes e violências               Accidents and violence           
#> # ℹ 13 more rows
pns_modules(year = 2019)
#> # A tibble: 20 × 3
#>    module name                                 name_en                          
#>    <chr>  <chr>                                <chr>                            
#>  1 A      Informações do domicílio             Household information            
#>  2 C      Características gerais dos moradores General characteristics of resid…
#>  3 E      Trabalho e rendimento                Work and income                  
#>  4 F      Pessoas com deficiência              Persons with disabilities        
#>  5 G      Cobertura de plano de saúde          Health insurance coverage        
#>  6 J      Percepção do estado de saúde         Health status perception         
#>  7 K      Acidentes e violências               Accidents and violence           
#>  8 L      Estilos de vida                      Lifestyles                       
#>  9 M      Atendimento médico                   Medical care                     
#> 10 N      Doenças crônicas                     Chronic diseases                 
#> 11 O      Saúde da mulher                      Women's health                   
#> 12 P      Atendimento pré-natal                Prenatal care                    
#> 13 Q      Internações                          Hospitalizations                 
#> 14 R      Urgências                            Emergencies                      
#> 15 S      Saúde bucal                          Oral health                      
#> 16 U      Acidentes de trabalho                Work accidents                   
#> 17 W      Antropometria e pressão arterial     Anthropometry and blood pressure 
#> 18 X      Exames laboratoriais                 Laboratory tests                 
#> 19 Y      Atividade física de crianças         Physical activity of children    
#> 20 Z      Consumo alimentar de crianças        Food consumption of children     
```
