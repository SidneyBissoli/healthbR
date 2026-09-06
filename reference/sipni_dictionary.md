# SI-PNI Data Dictionary

Returns a tibble with the data dictionary for the SI-PNI aggregated data
(1994–2019), including variable descriptions and category labels.

## Usage

``` r
sipni_dictionary(
  variable = NULL,
  source = c("r2", "datasus"),
  cache = TRUE,
  cache_dir = NULL,
  lookup = FALSE
)
```

## Arguments

- variable:

  Character. If provided, returns dictionary for a specific variable
  only. Default: NULL (returns all variables).

- source:

  Character vector. `"r2"` (default) reads the full dictionaries
  published by the healthbr-data mirror (converted from the Ministry's
  original .cnv/.dbf files, including the `source_codes` traceability
  column); `"datasus"` uses the abridged dictionary built into the
  package. With the default `c("r2", "datasus")`, the built-in
  dictionary is used automatically if the mirror is unreachable.

- cache:

  Logical. If TRUE (default), caches the R2 dictionary locally after the
  first read.

- cache_dir:

  Character. Cache directory. Default:
  `tools::R_user_dir("healthbR", "cache")`.

- lookup:

  Logical. If TRUE, returns a **data-code lookup**: one row per value as
  it appears in the data columns (the .cnv `source_codes`, expanded),
  ready to join against
  [`sipni_data()`](https://sidneybissoli.github.io/healthbR/reference/sipni_data.md)
  results. Default FALSE returns the dictionaries in their published
  form. See Details – for decoding data you almost always want
  `lookup = TRUE`.

## Value

A tibble with columns: variable, description, code, label (and
`source_codes` when served from R2 with `lookup = FALSE` – the original
data codes each dictionary entry groups, for traceability to the .cnv
files).

## Details

The dictionary covers aggregated data variables (DPNI/CPNI, 1994–2019):
IMUNO (separately for doses and coverage), DOSE, FX_ETARIA, ANO, MES.
API microdata (2020+) has description fields embedded in the data itself
(e.g., `ds_vacina`, `no_raca_cor_paciente`), so a separate dictionary is
not needed.

**code vs source_codes.** In the Ministry's .cnv dictionary files,
`code` is a sequential category code and `source_codes` holds the
value(s) actually found in the data – possibly several per label
(comma-separated or ranges), reflecting code changes over the years.
Joining data against `code` silently decodes to the wrong labels. Use
`lookup = TRUE` to get one row per data code. When more than one
category claims the same data code, the more specific claim wins:
explicitly listed codes take precedence over codes that only fall inside
a range – ranges are residual catch-alls by construction (e.g. FX_ETARIA
"Idade ignorada" spans `00-99` and must not override the explicit age
groups). The built-in fallback dictionary (`source = "datasus"`) is
already stored as a data-code lookup, so `lookup` has no effect there.

## See also

Other sipni:
[`sipni_cache_status()`](https://sidneybissoli.github.io/healthbR/reference/sipni_cache_status.md),
[`sipni_clear_cache()`](https://sidneybissoli.github.io/healthbR/reference/sipni_clear_cache.md),
[`sipni_data()`](https://sidneybissoli.github.io/healthbR/reference/sipni_data.md),
[`sipni_info()`](https://sidneybissoli.github.io/healthbR/reference/sipni_info.md),
[`sipni_status()`](https://sidneybissoli.github.io/healthbR/reference/sipni_status.md),
[`sipni_variables()`](https://sidneybissoli.github.io/healthbR/reference/sipni_variables.md),
[`sipni_years()`](https://sidneybissoli.github.io/healthbR/reference/sipni_years.md)

## Examples

``` r
# built-in fallback dictionary: no network, no cache
sipni_dictionary(source = "datasus")
#> # A tibble: 387 × 4
#>    variable description       code  label
#>    <chr>    <chr>             <chr> <chr>
#>  1 ANO      Ano de referência 1994  1994 
#>  2 ANO      Ano de referência 1995  1995 
#>  3 ANO      Ano de referência 1996  1996 
#>  4 ANO      Ano de referência 1997  1997 
#>  5 ANO      Ano de referência 1998  1998 
#>  6 ANO      Ano de referência 1999  1999 
#>  7 ANO      Ano de referência 2000  2000 
#>  8 ANO      Ano de referência 2001  2001 
#>  9 ANO      Ano de referência 2002  2002 
#> 10 ANO      Ano de referência 2003  2003 
#> # ℹ 377 more rows
sipni_dictionary("IMUNO", source = "datasus")
#> # A tibble: 112 × 4
#>    variable description                                  code  label            
#>    <chr>    <chr>                                        <chr> <chr>            
#>  1 IMUNO    Código do imunobiológico (cobertura vacinal) 003   dTpa gestante    
#>  2 IMUNO    Código do imunobiológico (cobertura vacinal) 006   Febre Amarela    
#>  3 IMUNO    Código do imunobiológico (cobertura vacinal) 009   Haemophilus infl…
#>  4 IMUNO    Código do imunobiológico (cobertura vacinal) 012   Pneumocócica     
#>  5 IMUNO    Código do imunobiológico (cobertura vacinal) 018   Sarampo          
#>  6 IMUNO    Código do imunobiológico (cobertura vacinal) 020   Influenza Campan…
#>  7 IMUNO    Código do imunobiológico (cobertura vacinal) 021   Tríplice Viral  …
#>  8 IMUNO    Código do imunobiológico (cobertura vacinal) 053   Meningococo C    
#>  9 IMUNO    Código do imunobiológico (cobertura vacinal) 061   Rotavírus Humano 
#> 10 IMUNO    Código do imunobiológico (cobertura vacinal) 072   BCG              
#> # ℹ 102 more rows

# join-ready lookup (data code -> label)
sipni_dictionary("IMUNO", source = "datasus", lookup = TRUE)
#> # A tibble: 112 × 4
#>    variable description                                  code  label            
#>    <chr>    <chr>                                        <chr> <chr>            
#>  1 IMUNO    Código do imunobiológico (cobertura vacinal) 003   dTpa gestante    
#>  2 IMUNO    Código do imunobiológico (cobertura vacinal) 006   Febre Amarela    
#>  3 IMUNO    Código do imunobiológico (cobertura vacinal) 009   Haemophilus infl…
#>  4 IMUNO    Código do imunobiológico (cobertura vacinal) 012   Pneumocócica     
#>  5 IMUNO    Código do imunobiológico (cobertura vacinal) 018   Sarampo          
#>  6 IMUNO    Código do imunobiológico (cobertura vacinal) 020   Influenza Campan…
#>  7 IMUNO    Código do imunobiológico (cobertura vacinal) 021   Tríplice Viral  …
#>  8 IMUNO    Código do imunobiológico (cobertura vacinal) 053   Meningococo C    
#>  9 IMUNO    Código do imunobiológico (cobertura vacinal) 061   Rotavírus Humano 
#> 10 IMUNO    Código do imunobiológico (cobertura vacinal) 072   BCG              
#> # ℹ 102 more rows
if (FALSE) { # interactive()
# official .cnv dictionaries from the healthbr-data mirror (downloads once)
sipni_dictionary()
sipni_dictionary("DOSE")
}
```
