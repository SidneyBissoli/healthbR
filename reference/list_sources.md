# List Available Data Sources

Returns information about all data sources available in healthbR.

## Usage

``` r
list_sources()
```

## Value

A tibble with columns:

- `source`: Source code (e.g., "vigitel", "sim")

- `name`: Full name of the data source

- `description`: Brief description

- `years`: Range of available years

- `status`: Implementation status ("available", "planned")

## Examples

``` r
list_sources()
#> # A tibble: 11 × 5
#>    source  name                                         description years status
#>    <chr>   <chr>                                        <chr>       <chr> <chr> 
#>  1 vigitel VIGITEL                                      Telephone … 2006… avail…
#>  2 pns     PNS - Pesquisa Nacional de Saude             National h… 2013… avail…
#>  3 pnad    PNAD Continua                                Continuous… 2012… avail…
#>  4 pof     POF - Pesquisa de Orcamentos Familiares      Household … 2002… avail…
#>  5 censo   Censo Demografico                            Demographi… 1991… avail…
#>  6 sim     SIM - Sistema de Informacoes sobre Mortalid… Mortality … 1996… avail…
#>  7 sinasc  SINASC - Sistema de Informacoes sobre Nasci… Live birth… 1996… avail…
#>  8 sih     SIH - Sistema de Informacoes Hospitalares    Hospital a… 2008… avail…
#>  9 sia     SIA - Sistema de Informacoes Ambulatoriais   Outpatient… 1994… plann…
#> 10 sinan   SINAN - Sistema de Informacao de Agravos de… Notifiable… 2001… plann…
#> 11 cnes    CNES - Cadastro Nacional de Estabelecimento… Health fac… 2005… plann…
```
