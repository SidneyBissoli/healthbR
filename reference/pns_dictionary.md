# Download PNS variable dictionary

Downloads and returns the variable dictionary for PNS microdata. The
dictionary is cached locally to avoid repeated downloads.

## Usage

``` r
pns_dictionary(year = 2019, cache_dir = NULL, refresh = FALSE)
```

## Arguments

- year:

  Numeric. Year to get dictionary for (2013 or 2019). Default is 2019.

- cache_dir:

  Character. Directory for caching downloaded files. Default uses
  `tools::R_user_dir("healthbR", "cache")`.

- refresh:

  Logical. If TRUE, re-download even if file exists in cache. Default is
  FALSE.

## Value

A tibble with variable definitions.

## Details

The dictionary includes variable names, labels, and response categories
for the PNS microdata. This is useful for understanding the structure of
the data returned by
[`pns_data`](https://sidneybissoli.github.io/healthbR/reference/pns_data.md).

## Data source

Dictionaries are downloaded from the IBGE FTP server:
<https://ftp.ibge.gov.br/PNS/>

## Examples

``` r
# \donttest{
# get dictionary for 2019
dict <- pns_dictionary(year = 2019, cache_dir = tempdir())
#> Downloading PNS 2019 dictionary from IBGE...
#> URL:
#> <https://ftp.ibge.gov.br/PNS/2019/Microdados/Documentacao/Dicionario_e_input_20220530.zip>
#> ✔ Download complete: /tmp/RtmpmPcNsW/pns/Dicionario_e_input_20220530.zip
#> Extracting dictionary...
#> Reading Excel dictionary...
#> New names:
#> • `` -> `...2`
#> • `` -> `...3`
#> • `` -> `...4`
#> • `` -> `...5`
#> • `` -> `...6`
#> • `` -> `...7`
#> ✔ Dictionary cached: /tmp/RtmpmPcNsW/pns/pns_dictionary_2019.rds

# get dictionary for 2013
dict_2013 <- pns_dictionary(year = 2013, cache_dir = tempdir())
#> Downloading PNS 2013 dictionary from IBGE...
#> URL:
#> <https://ftp.ibge.gov.br/PNS/2013/Microdados/Documentacao/Dicionario_e_input_20200930.zip>
#> ✔ Download complete: /tmp/RtmpmPcNsW/pns/Dicionario_e_input_20200930.zip
#> Extracting dictionary...
#> Reading Excel dictionary...
#> New names:
#> • `` -> `...2`
#> • `` -> `...3`
#> • `` -> `...4`
#> • `` -> `...5`
#> • `` -> `...6`
#> • `` -> `...7`
#> ✔ Dictionary cached: /tmp/RtmpmPcNsW/pns/pns_dictionary_2013.rds
# }
```
