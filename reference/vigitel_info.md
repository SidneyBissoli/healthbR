# Get VIGITEL survey information

Returns metadata about the VIGITEL survey.

## Usage

``` r
vigitel_info()
```

## Value

A list with survey information

## Examples

``` r
vigitel_info()
#> $name
#> [1] "VIGITEL"
#> 
#> $full_name
#> [1] "Vigilancia de Fatores de Risco e Protecao para Doencas Cronicas por Inquerito Telefonico"
#> 
#> $institution
#> [1] "Ministerio da Saude"
#> 
#> $description
#> [1] "Telephone survey monitoring risk and protective factors for chronic diseases in Brazilian state capitals."
#> 
#> $years_available
#>  [1] 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020
#> [16] 2021 2022 2023 2024
#> 
#> $url
#> [1] "https://www.gov.br/saude/pt-br/composicao/svsa/inqueritos-de-saude/vigitel"
#> 
#> $download_url
#> [1] "https://svs.aids.gov.br/daent/cgdnt/vigitel/"
#> 
#> $weight_variable
#> [1] "pesorake"
#> 
#> $geographic_coverage
#> [1] "26 state capitals + Federal District"
#> 
#> $sample_size
#> [1] "~54,000 adults per year (18+ years)"
#> 
#> $data_format
#> [1] "Stata (.dta)" "CSV (.csv)"  
#> 
#> $topics
#>  [1] "chronic diseases"    "risk factors"        "tobacco use"        
#>  [4] "alcohol consumption" "physical activity"   "diet and nutrition" 
#>  [7] "obesity"             "diabetes"            "hypertension"       
#> [10] "preventive exams"   
#> 
```
