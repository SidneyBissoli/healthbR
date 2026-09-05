# healthbR vs microdatasus: reading DATASUS microdata (SIM, SINASC, SIH) in R

## Why this vignette

If you read DATASUS microdata in R – deaths from SIM, live births from
SINASC, hospital admissions from SIH – you have two packages to choose
from: [microdatasus](https://CRAN.R-project.org/package=microdatasus),
by Raphael Saldanha, described in Saldanha et al. (2019) and the usual
answer to “how do I get DATASUS into R”, and healthbR. They overlap on
six DATASUS systems and differ in almost everything they do with the
bytes after the download. This vignette puts the two side by side on the
*same* three downloads and shows what each one returns, so you can pick
the one that fits your workflow – or use both.

Everything below was measured on 2026-09-05 with healthbR 0.3.1
(development version), microdatasus 3.0.0, arrow 25.0.0, dplyr 1.2.1 and
R 4.6.1 on Windows, from a residential connection in Brazil. Timings are
single runs and will vary with your network; the row counts, column
types and values will not. Nothing here runs at build time
(`eval = FALSE`): the outputs are pasted from that session, and the code
is complete so you can rerun it.

## What each package covers

|  | healthbR | microdatasus 3.0.0 |
|----|----|----|
| SIM (mortality) | [`sim_data()`](https://sidneybissoli.github.io/healthbR/reference/sim_data.md): DO, 1996–2024 | `"SIM-DO"`, `"SIM-DOFET"`, `"SIM-DOEXT"`, `"SIM-DOINF"`, `"SIM-DOMAT"` |
| SINASC (live births) | [`sinasc_data()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_data.md): 1996–2024 | `"SINASC"` |
| SIH (admissions) | [`sih_data()`](https://sidneybissoli.github.io/healthbR/reference/sih_data.md): RD (reduced AIH), 2008–2026 | `"SIH-RD"`, `"SIH-RJ"`, `"SIH-SP"`, `"SIH-ER"` |
| SIA (outpatient) | [`sia_data()`](https://sidneybissoli.github.io/healthbR/reference/sia_data.md): 13 file types, 2008–2026 | 12 file types |
| CNES (facilities) | [`cnes_data()`](https://sidneybissoli.github.io/healthbR/reference/cnes_data.md): 13 file types, 2005–2026 | 13 file types |
| SINAN (notifiable diseases) | [`sinan_data()`](https://sidneybissoli.github.io/healthbR/reference/sinan_data.md): 31 diseases, 2007–2026 | 8 diseases (dengue, chikungunya, zika, malaria, Chagas, visceral and cutaneous leishmaniasis, leptospirosis) |
| SI-PNI (vaccination) | [`sipni_data()`](https://sidneybissoli.github.io/healthbR/reference/sipni_data.md): 1994–2026 | – |
| SISAB (primary care) | [`sisab_data()`](https://sidneybissoli.github.io/healthbR/reference/sisab_data.md) | – |
| Surveys | VIGITEL, PNS, PNAD Continua, POF, Censo denominators | – |
| Regulatory agencies | ANS, ANVISA | – |
| Auxiliary tables | `*_dictionary()`, `*_variables()` per module | SIGTAP (`fetch_sigtab()`), CADGER (`fetch_cadger()`), `tabMun`, `tabCBO`, `tabOcupacao`, `tabNaturalidade` |

microdatasus goes deeper into SIM and SIH (the fetal, external-cause,
infant and maternal SIM extracts; the RJ, SP and ER SIH files) and ships
the SIGTAP procedure table. healthbR goes wider: more SINAN diseases,
SI-PNI, SISAB, the household surveys and the regulatory agencies, all
under one `*_years()` / `*_data()` / `*_dictionary()` API.

## The same reader, two philosophies

Both packages decompress the Ministry’s `.dbc` files (DBF compressed
with PKWare DCL) with the same vendored C code: microdatasus 3.0.0
dropped its dependency on `read.dbc` and adopted the implementation from
healthbR (its NEWS says so, and thanks the author). So the *bytes* the
two packages read are identical; the difference starts right after.

**healthbR keeps the codes and types the columns.** `SEXO` stays
`1`/`3`, `MORTE` stays `0`/`1`, `DT_INTER` becomes a `Date`, `VAL_TOT` a
double, `IDADE` an integer. Labels live in
[`sih_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sih_dictionary.md),
[`sim_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sim_dictionary.md),
[`sinasc_dictionary()`](https://sidneybissoli.github.io/healthbR/reference/sinasc_dictionary.md),
joined when you want them. The default `parse = TRUE` converts only
genuinely quantitative and date fields; coded categorical fields stay
character so they join cleanly with the dictionaries and with other
years.

**microdatasus separates fetching from processing.** `fetch_datasus()`
returns every column as character, exactly as the DBF has it.
`process_sih()`, `process_sim()`, `process_sinasc()` then replace the
codes with labels (`SEXO` becomes `"Masculino"`/`"Feminino"`, `MORTE`
becomes `"Não"`/`"Sim"`), convert dates, split the SIM age field into
one column per unit and, with `municipality_data = TRUE`, join
municipality names, coordinates and altitude. The result is a tibble of
character columns.

Neither is wrong. Labels are what you want for a table in a report;
codes are what you want to join against a dictionary, compare years, or
feed a model. The trap is mixing the two: after `process_sih()`,
`MORTE == 1` is `FALSE` on every row, and `substr(DT_INTER, 5, 6)` is no
longer the month, because both were rewritten. Read the outputs below
before choosing.

## One download in both packages: SIH, Roraima, competence 2023-01

Roraima is the smallest SIH file; January 2023 has 4,734 admissions.
Both runs start from an empty cache.

``` r

library(healthbR)
library(microdatasus)
library(dplyr)

# healthbR ---------------------------------------------------------------
rr_h <- sih_data(year = 2023, month = 1, uf = "RR")
#> ℹ Reading SIH data from R2: 2023/01 (1 UF(s))...

dim(rr_h)
#> [1] 4734  116
table(vapply(rr_h, function(x) class(x)[1], ""))
#> character      Date   integer   numeric
#>       101         3         7         5

# microdatasus -------------------------------------------------------------
rr_m <- fetch_datasus(year_start = 2023, month_start = 1,
                      year_end = 2023, month_end = 1,
                      uf = "RR", information_system = "SIH-RD")
dim(rr_m)
#> [1] 4734  113
table(vapply(rr_m, function(x) class(x)[1], ""))
#> character
#>       113

rr_mp <- process_sih(rr_m)
dim(rr_mp)
#> [1] 4734  121
```

Same 4,734 rows; the sets of `N_AIH` are identical. healthbR adds three
columns (`year`, `month`, `uf_source`: the competence and state the file
belongs to, which the AIH record itself does not carry); `process_sih()`
adds eight (`munResStatus`, `munResTipo`, `munResNome`, `munResUf`,
`munResLat`, `munResLon`, `munResAlt`, `munResArea`).

The same five records, three ways:

``` r

cols <- c("N_AIH", "SEXO", "COD_IDADE", "IDADE", "MORTE", "DT_INTER",
          "DIAG_PRINC", "MUNIC_RES", "VAL_TOT")

as.data.frame(head(rr_h[cols], 5))
#>           N_AIH SEXO COD_IDADE IDADE MORTE   DT_INTER DIAG_PRINC MUNIC_RES  VAL_TOT
#> 1 1423100411392    3         4    18     0 2022-12-13       O809    140017   568.80
#> 2 1423100911661    1         4    83     0 2022-12-26       J189    140010   994.59
#> 3 1423100911672    3         4    65     0 2022-12-03       I219    140010   620.12
#> 4 1423100911683    1         4    58     0 2022-12-26       I248    140020   333.08
#> 5 1423100911694    1         4    35     0 2022-11-01       A499    140010 11202.59

as.data.frame(head(rr_m[cols], 5))
#>           N_AIH SEXO COD_IDADE IDADE MORTE DT_INTER DIAG_PRINC MUNIC_RES  VAL_TOT
#> 1 1423100411392    3         4    18     0 20221213       O809    140017    568.8
#> 2 1423100911661    1         4    83     0 20221226       J189    140010   994.59
#> 3 1423100911672    3         4    65     0 20221203       I219    140010   620.12
#> 4 1423100911683    1         4    58     0 20221226       I248    140020   333.08
#> 5 1423100911694    1         4    35     0 20221101       A499    140010 11202.59

as.data.frame(head(rr_mp[c(cols, "munResNome")], 5))
#>           N_AIH      SEXO COD_IDADE IDADE MORTE   DT_INTER DIAG_PRINC MUNIC_RES  VAL_TOT munResNome
#> 1 1423100411392  Feminino      Anos    18   Não 2022-12-13       O809    140017    568.8      Cantá
#> 2 1423100911661 Masculino      Anos    83   Não 2022-12-26       J189    140010   994.59  Boa Vista
#> 3 1423100911672  Feminino      Anos    65   Não 2022-12-03       I219    140010   620.12  Boa Vista
#> 4 1423100911683 Masculino      Anos    58   Não 2022-12-26       I248    140020   333.08  Caracaraí
#> 5 1423100911694 Masculino      Anos    35   Não 2022-11-01       A499    140010 11202.59  Boa Vista
```

Note `DT_INTER`: the admissions billed in competence 2023-01 happened in
November and December 2022. In both packages `year`/`month` (or
`year_start`/`month_start`) select the **billing competence**, not the
admission date; the admissions of a calendar year keep arriving for a
few competences after it (measured on the whole mirror: the four
competences after a year close 99.7–99.9% of its admissions). Neither
package can change that; both should be used with it in mind.

And the trap, in one line each:

``` r

sum(rr_h$MORTE == 1)          # healthbR: integer code
#> [1] 113
sum(rr_m$MORTE == "1")        # microdatasus, raw: character code
#> [1] 113
sum(rr_mp$MORTE == 1)         # microdatasus, processed: the code is gone
#> [1] 0
table(rr_mp$MORTE)
#>  Não  Sim
#> 4621  113
```

Same 113 deaths; the third line is the one that silently returns zero in
a script written against codes. With healthbR the label is a join away:

``` r

sih_dictionary("MORTE")
#> # A tibble: 2 × 4
#>   variable description              code  label
#>   <chr>    <chr>                    <chr> <chr>
#> 1 MORTE    Óbito durante internação 0     Não
#> 2 MORTE    Óbito durante internação 1     Sim

rr_h |>
  count(MORTE) |>
  left_join(sih_dictionary("MORTE"), by = c("MORTE" = "code"))
```

### Timing

| Step | healthbR | microdatasus |
|----|----|----|
| Fresh cache, mirror (manifest of 11,157 partitions + one Parquet) | 11.4 s | – |
| Fresh cache, DATASUS FTP `.dbc` (`source = "datasus"`) | 1.1 s | 2.7 s |
| Same call again in the session | 0.5 s (local Parquet cache) | downloads again (no cache) |
| Labels (`process_sih()`) | – | 0.8 s |
| Object size in memory | 4.8 MB | 5.4 MB raw, 5.7 MB processed |

On a 349 KB file the FTP wins the first read: the mirror’s price of
entry is its 10 MB manifest, downloaded once and revalidated by ETag
afterwards
([`sih_status()`](https://sidneybissoli.github.io/healthbR/reference/sih_status.md)
reads it in 0.4 s from then on). The mirror pays back on repeated reads,
on lazy queries over many competences (next section), and in what comes
with the data.

## What comes with the data: provenance

From the mirror, the tibble carries the source it was served from and
one row per DATASUS file behind it – URL, MD5 and size of the `.dbc`,
record count, when it was processed and by which pipeline version:

``` r

attr(rr_h, "healthbr_source")
#> [1] "r2"

attr(rr_h, "healthbr_provenance") |>
  select(year, month, uf, records, source_hash_md5, source_size_bytes,
         processing_timestamp)
#> # A tibble: 1 × 7
#>    year month uf    records source_hash_md5                  source_size_bytes processing_timestamp
#>   <int> <int> <chr>   <dbl> <chr>                                        <dbl> <chr>
#> 1  2023     1 RR       4734 12e74d4b059589ceb47e4136e3b2ce5f            349244 2026-03-09 03:05:34.463049
```

[`sih_status()`](https://sidneybissoli.github.io/healthbR/reference/sih_status.md)
gives the same for every published partition, which is how you find out
which competences exist and whether the Ministry re-issued a file (the
MD5 changes):

``` r

st <- sih_status()
nrow(st)
#> [1] 11157
attr(st, "last_updated")
#> [1] "2026-08-18T12:33:31"
range(st$year)
#> [1] 1992 2026
st |> filter(uf == "RR", year == 2023, month == 1) |>
  select(records, source_hash_md5, parquet_sha256, pipeline_version)
#> # A tibble: 1 × 4
#>   records source_hash_md5                  parquet_sha256                                                   pipeline_version
#>     <dbl> <chr>                            <chr>                                                            <chr>
#> 1    4734 12e74d4b059589ceb47e4136e3b2ce5f bab1c2fdda7b09a6117169156f51846e095de0bc502fec9adecf90d2e1f08474 1.0.0
```

microdatasus 3.0.0 has `track_source = TRUE`, which appends a `source`
column with the name of the `.dbc` each row came from; it does not
record hashes or timestamps, and the FTP does not offer them. If your
derived product needs to say exactly which files it was built from, this
is the difference that matters.

## Lazy evaluation: a year without downloading it

healthbR’s `lazy = TRUE` returns an arrow (or duckdb) dataset over the
mirror; filters and column selections are pushed down and only the
matching bytes travel. Deaths per competence in Roraima for all of 2023,
nothing cached:

``` r

sih_data(year = 2023, uf = "RR", lazy = TRUE) |>
  filter(MORTE == 1) |>
  count(month) |>
  collect() |>
  arrange(month)
#> # A tibble: 12 × 2
#>    month     n
#>    <int> <int>
#>  1     1   113
#>  2     2   120
#>  3     3   175
#>  4     4   166
#>  5     5   118
#>  6     6    78
#>  7     7    97
#>  8     8   144
#>  9     9   105
#> 10    10   104
#> 11    11   128
#> 12    12   102
```

19.4 s for twelve competences, no local copy left behind. With
microdatasus the equivalent is
`fetch_datasus(2023, 1, 2023, 12, uf = "RR", information_system = "SIH-RD")`:
twelve `.dbc` downloads, all rows in memory, then
[`filter()`](https://dplyr.tidyverse.org/reference/filter.html). For one
small state that is fine; for the whole country (a year of SIH is about
2 GB of `.dbc`) the difference decides whether the query is feasible on
a laptop.

## SIM: mortality, Acre 2022

``` r

# healthbR
ac_h <- sim_data(year = 2022, uf = "AC")
#> ℹ Downloading SIM data: AC 2022...
dim(ac_h)
#> [1] 4159   90

# microdatasus
ac_m  <- fetch_datasus(year_start = 2022, year_end = 2022, uf = "AC",
                       information_system = "SIM-DO")
ac_mp <- process_sim(ac_m)
dim(ac_m); dim(ac_mp)
#> [1] 4159   87
#> [1] 4159  100
```

Same 4,159 deaths (1.5 s healthbR, 2.1 s + 0.7 s microdatasus). The
interesting column is age. SIM stores it as three characters: the first
is the unit (0 minutes, 1 hours, 2 days, 3 months, 4 years, 5 years over
100) and the last two the value. The two packages decode it differently:

``` r

sim_dictionary("IDADE")
#> # A tibble: 6 × 4
#>   variable description                 code  label
#>   <chr>    <chr>                       <chr> <chr>
#> 1 IDADE    Idade (1º dígito = unidade) 0     Minutos (< 1 hora)
#> 2 IDADE    Idade (1º dígito = unidade) 1     Horas
#> 3 IDADE    Idade (1º dígito = unidade) 2     Dias
#> 4 IDADE    Idade (1º dígito = unidade) 3     Meses
#> 5 IDADE    Idade (1º dígito = unidade) 4     Anos (0-99)
#> 6 IDADE    Idade (1º dígito = unidade) 5     Anos (100+)

# six infant deaths, the same rows in both
#>   IDADE healthbR_age_years md_IDADEanos md_IDADEmeses md_IDADEdias md_IDADEhoras
#> 1   021       3.992699e-05         <NA>          <NA>         <NA>          <NA>
#> 2   101       1.140771e-04         <NA>          <NA>         <NA>             1
#> 3   201       2.737851e-03         <NA>          <NA>            1          <NA>
#> 4   302       1.666667e-01         <NA>             2         <NA>          <NA>
#> 5   102       2.281542e-04         <NA>          <NA>         <NA>             2
#> 6   108       9.126169e-04         <NA>          <NA>         <NA>             8
```

healthbR (`decode_age = TRUE`, the default) adds one numeric `age_years`
that is continuous – 21 minutes is 0.00004 years, 2 months is 0.167 – so
age bands and rates come out of one column; `IDADE` itself is kept.
microdatasus splits the field into `IDADEminutos`, `IDADEhoras`,
`IDADEdias`, `IDADEmeses`, `IDADEanos`, each `NA` outside its unit,
which is closer to how the DO form reads and keeps the unit explicit.
For adult mortality the two agree to the year; for infant mortality you
will reach for different columns.

## SINASC: live births, Acre 2022

``` r

# healthbR
ac_n <- sinasc_data(year = 2022, uf = "AC")
dim(ac_n)
#> [1] 14483    63
class(ac_n$PESO); sum(is.na(ac_n$PESO)); median(ac_n$PESO, na.rm = TRUE)
#> [1] "integer"
#> [1] 94
#> [1] 3230

# microdatasus
ac_nm  <- fetch_datasus(year_start = 2022, year_end = 2022, uf = "AC",
                        information_system = "SINASC")
ac_nmp <- process_sinasc(ac_nm)
sum(is.na(ac_nm$PESO)); sum(is.na(ac_nmp$PESO))
#> [1] 94
#> [1] 14483
```

Same 14,483 births (3.1 s healthbR; 3.3 s + 3.5 s microdatasus). One
thing to know before relying on `process_sinasc()` in the versions
measured here: it returned `PESO` (birth weight) as `NA` on every row,
while the raw column had 94 missing values out of 14,483. The behaviour
reproduces offline with the package’s own sample:

``` r

sum(is.na(microdatasus::sinasc_sample$PESO))
#> [1] 2
sum(is.na(process_sinasc(microdatasus::sinasc_sample)$PESO))
#> [1] 100
```

The recode of the sentinel values (`"0"` and `"9999"` to `NA`) is
followed by an [`as.numeric()`](https://rdrr.io/r/base/numeric.html),
and with dplyr 1.2.1 the whole column comes back missing. It is the kind
of thing a maintainer fixes in an afternoon once reported; check the
package’s news and issue tracker for your versions, and in the meantime
take `PESO` from the raw tibble. healthbR does not rewrite the column:
`PESO` is parsed to integer and the sentinels are left for you to treat.

## Where the bytes come from

|  | healthbR | microdatasus |
|----|----|----|
| SIM, SINASC, SIA, SINAN, CNES | DATASUS FTP, `.dbc`, decompressed locally | DATASUS FTP, `.dbc`, decompressed locally |
| SIH, SI-PNI | [healthbr-data](https://github.com/SidneyBissoli/healthbr-data) mirror: hive-partitioned Parquet on Cloudflare R2, one partition per DATASUS file, byte-identical values, provenance per file; DATASUS FTP as fallback (`source = c("r2", "datasus")`) | DATASUS FTP |
| Local cache | Partitioned Parquet per module (`*_cache_status()`, `*_clear_cache()`); a second call never touches the network | none (every call downloads) |
| Re-issued files | [`sih_status()`](https://sidneybissoli.github.io/healthbR/reference/sih_status.md): MD5 and size per partition, `last_updated` of the mirror | – |
| Lazy queries | `lazy = TRUE`, `backend = "arrow"` or `"duckdb"`, over the cache or the mirror | – |
| Parallel downloads | `future::plan(multisession)` + furrr | sequential |

The mirror is refreshed weekly against the FTP by file size (the FTP
offers neither ETag nor hash), and a re-issued file is republished with
a new MD5 in the manifest – that is what
[`sih_status()`](https://sidneybissoli.github.io/healthbR/reference/sih_status.md)
reads.

## Other routes

Two other projects answer the same question and were not measured here:
[PySUS](https://github.com/AlertaDengue/PySUS), the Python package that
covers SIM, SINASC, SIH, SIA, CNES and SINAN from the same FTP, and
[basedosdados](https://basedosdados.org), which serves treated SIM and
SINASC tables through BigQuery with an R client. If your pipeline is in
Python, PySUS is the natural pick; if you want SQL over already-treated
tables and accept the BigQuery account, basedosdados.

## Which one

- **You want labels in the tibble and a quick table**: microdatasus.
  `process_*()` does in one call what would take a few joins in
  healthbR, and it also brings municipality names and coordinates.
- **You join, compare years, or model**: healthbR. Codes stay codes,
  types are already parsed, dictionaries are functions, and nothing is
  rewritten under you.
- **You read SIH at scale, or repeatedly**: healthbR. Local Parquet
  cache, lazy arrow/duckdb queries over the mirror, provenance you can
  cite.
- **You need the SIM fetal/infant/maternal extracts, the RJ/SP/ER SIH
  files, or SIGTAP**: microdatasus, which has them and healthbR does not
  (yet).
- **You need SI-PNI, SISAB, the household surveys, ANS or ANVISA**:
  healthbR; microdatasus stops at DATASUS.

They also compose. `fetch_datasus()` and `sih_data(parse = FALSE)`
return the same character columns for the same file, so a script can
read with one and label with the other:

``` r

# read with healthbR (cache, provenance), label with microdatasus
sih_data(year = 2023, month = 1, uf = "RR", parse = FALSE) |>
  process_sih()
```

## Reproducing this vignette

The three downloads are small (the SIH file is 349 KB). To rerun the
comparison from a fresh cache:

``` r

install.packages(c("microdatasus", "arrow"))
# install.packages("pak"); pak::pak("SidneyBissoli/healthbR")   # dev version

sih_clear_cache(); sim_clear_cache(); sinasc_clear_cache()
system.time(sih_data(year = 2023, month = 1, uf = "RR"))
system.time(fetch_datasus(2023, 1, 2023, 1, uf = "RR",
                          information_system = "SIH-RD"))
```

Related: [SIH – Hospital
admissions](https://sidneybissoli.github.io/healthbR/articles/sih-hospital-admissions.md),
[SIM –
Mortality](https://sidneybissoli.github.io/healthbR/articles/sim-mortality.md),
[SINASC – Live
births](https://sidneybissoli.github.io/healthbR/articles/sinasc-live-births.md),
[DATASUS modules
overview](https://sidneybissoli.github.io/healthbR/articles/datasus-modules.md).
