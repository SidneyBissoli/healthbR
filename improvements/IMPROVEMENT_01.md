# Especificação Técnica: Reformulação do Módulo VIGITEL no healthbR

**Data:** 2026-02-04  
**Versão:** 0.2.0 (proposta)  
**Motivo:** Reestruturação do portal de dados do Ministério da Saúde  
**Prioridade:** ALTA  
**Prazo sugerido:** Antes de 2026-02-17 (manter compliance CRAN)

---

## 1. Contexto e Motivação

### 1.1 O que aconteceu

O Ministério da Saúde do Brasil reformulou completamente o portal onde os dados da VIGITEL são disponibilizados. A estrutura anterior (arquivos separados por ano) foi substituída por arquivos consolidados contendo todos os anos em um único arquivo.

### 1.2 Impacto no pacote

As funções atuais do healthbR (`vigitel_years()`, `vigitel_data()`, `vigitel_dictionary()`, etc.) foram projetadas para a estrutura antiga e precisam ser completamente reformuladas para a nova estrutura.

### 1.3 Oportunidade

A nova estrutura é mais simples: um único download fornece todos os anos. Isso pode simplificar o código e melhorar a experiência do usuário.

---

## 2. Nova Estrutura de Dados do Ministério da Saúde

### 2.1 URLs dos arquivos (verificadas em 2026-02-04)

| Recurso | URL | Formato |
|---------|-----|---------|
| Base de dados (Stata) | `https://svs.aids.gov.br/daent/cgdnt/vigitel/vigitel-2006-2024-peso-rake-dta.zip` | ZIP contendo .dta |
| Base de dados (CSV) | `https://svs.aids.gov.br/daent/cgdnt/vigitel/vigitel-2006-2024-peso-rake-csv.zip` | ZIP contendo .csv |
| Dicionário de dados | `https://svs.aids.gov.br/daent/cgdnt/vigitel/dicionario-vigitel-2006-2024.xlsx` | Excel (.xlsx) |

### 2.2 Estrutura dos arquivos

- **Arquivos ZIP**: Contêm um único arquivo com dados de todos os anos (2006-2024)
- **Dicionário**: Arquivo Excel com descrição de todas as variáveis
- **Anos disponíveis**: 2006 a 2024 (19 anos)
- **Peso amostral**: Variável `pesorake` (peso rake)

### 2.3 Formatos disponíveis

O MS disponibiliza os dados em dois formatos:
1. **Stata (.dta)**: Formato binário, preserva labels das variáveis
2. **CSV (.csv)**: Formato texto, mais portátil

---

## 3. Requisitos do CRAN (OBRIGATÓRIOS)

Todas as mudanças DEVEM seguir estas diretrizes para manter o pacote no CRAN:

### 3.1 Dependência `arrow`

- **Status atual**: `arrow` está em `Suggests` (NÃO em `Imports`)
- **Motivo**: `arrow` não está disponível em todas as plataformas que o CRAN testa
- **Requisito**: Manter `arrow` em `Suggests` e usar verificação condicional

```r
# padrão obrigatório para usar arrow
if (requireNamespace("arrow", quietly = TRUE)) {
  # usar arrow::read_parquet(), arrow::write_parquet()
} else {
  # fallback ou mensagem informativa
  cli::cli_warn(
    "Package {.pkg arrow} is recommended for better performance. ",
    "Install with: {.code install.packages('arrow')}"
  )
  # usar alternativa (readr, data.table, etc.)
}
```

### 3.2 Exemplos e cache

- **Problema anterior**: Exemplos em `\donttest{}` criavam arquivos em `~/.cache/R/healthbR/`
- **Solução obrigatória**: Exemplos devem usar `tempdir()` como cache
- **Padrão**: Adicionar parâmetro `cache_dir` nas funções de download

```r
#' @examples
#' \donttest{
#' # usa tempdir() para não deixar arquivos no sistema
#' df <- vigitel_data(year = 2023, cache_dir = tempdir())
#' }
```

### 3.3 Outras diretrizes CRAN

- [ ] `devtools::check()` deve passar com 0 errors, 0 warnings
- [ ] NOTEs aceitáveis: "New submission" ou "possibly misspelled words" (siglas brasileiras)
- [ ] URLs devem ser válidas e estáveis
- [ ] Exemplos devem rodar em < 5 segundos ou usar `\donttest{}`
- [ ] Não instalar arquivos fora de `tempdir()` durante checks

---

## 4. Arquitetura Proposta

### 4.1 Funções públicas (API do usuário)

| Função | Descrição | Mudança |
|--------|-----------|---------|
| `vigitel_years()` | Lista anos disponíveis | MANTER (atualizar range para 2006-2024) |
| `vigitel_variables()` | Lista variáveis disponíveis | REFORMULAR (ler do dicionário) |
| `vigitel_dictionary()` | Obtém dicionário de variáveis | REFORMULAR (nova URL) |
| `vigitel_data()` | Baixa e retorna os dados | REFORMULAR COMPLETAMENTE |
| `vigitel_info()` | Informações sobre a pesquisa | MANTER (atualizar texto) |
| `vigitel_cache_status()` | Status do cache local | REFORMULAR (nova estrutura) |
| `vigitel_clear_cache()` | Limpa cache local | MANTER |

### 4.2 Funções internas (helpers)

| Função | Descrição | Status |
|--------|-----------|--------|
| `vigitel_base_url()` | URL base do MS | ATUALIZAR |
| `vigitel_download_data()` | Baixa arquivo ZIP | NOVA |
| `vigitel_extract_zip()` | Extrai ZIP | NOVA |
| `vigitel_read_dta()` | Lê arquivo Stata | NOVA |
| `vigitel_read_csv()` | Lê arquivo CSV | NOVA |
| `vigitel_download_dictionary()` | Baixa dicionário | NOVA |
| `vigitel_cache_dir()` | Diretório de cache | MANTER |
| `vigitel_cache_path()` | Caminho do arquivo em cache | REFORMULAR |

### 4.3 Seleção flexível de anos

O parâmetro `year` deve aceitar múltiplos formatos:

```r
# um único ano
vigitel_data(year = 2024)

# vetor de anos específicos
vigitel_data(year = c(2020, 2022, 2024))

# sequência de anos
vigitel_data(year = 2020:2024)

# todos os anos (padrão)
vigitel_data(year = NULL)
vigitel_data()  # equivalente
```

### 4.4 Estratégia de performance para leitura filtrada

**Problema:** O arquivo fonte contém todos os anos (2006-2024). Se o usuário quer 
apenas 2024, seria ineficiente ler ~500MB de dados para filtrar depois.

**Solução:** Cache particionado por ano usando Parquet.

#### Estrutura de cache particionado

```
cache/healthbR/vigitel/
├── vigitel-2006-2024-peso-rake-dta.zip    # arquivo original (opcional manter)
├── vigitel-2006-2024-peso-rake.dta        # arquivo extraído (deletar após conversão)
└── vigitel_data/                          # PARQUET PARTICIONADO
    ├── ano=2006/
    │   └── part-0.parquet
    ├── ano=2007/
    │   └── part-0.parquet
    ├── ano=2008/
    │   └── part-0.parquet
    ...
    └── ano=2024/
        └── part-0.parquet
```

#### Comportamento de leitura por cenário

| Cenário | Com `arrow` | Sem `arrow` |
|---------|-------------|-------------|
| Cache particionado existe | Lê APENAS arquivos dos anos solicitados (muito rápido) | Lê arquivo fonte completo + filtra |
| Cache não existe | Download → Lê tudo → Cria partições → Retorna filtrado | Download → Lê tudo → Filtra |
| `force = TRUE` | Re-download, recria partições | Re-download |

#### Código para leitura particionada eficiente

```r
# com arrow: lê apenas partições necessárias
read_vigitel_partitioned <- function(cache_dir, year = NULL) {
 
 parquet_dir <- file.path(cache_dir, "vigitel_data")
 
 # abre o dataset particionado
 ds <- arrow::open_dataset(parquet_dir)
 
 # se year especificado, filtra ANTES de carregar na memória
 if (!is.null(year)) {
    ds <- ds |> dplyr::filter(ano %in% year)
 }
 
 # coleta apenas os dados filtrados
 ds |> dplyr::collect()
}
```

**Importante:** Com Parquet particionado, quando o usuário pede `year = 2024`, 
o `arrow` lê APENAS o arquivo `ano=2024/part-0.parquet` (~25MB), não os ~500MB 
do dataset completo.

#### Código para criar cache particionado

```r
# após primeira leitura do arquivo fonte, particiona por ano
create_partitioned_cache <- function(df, cache_dir) {
 
 if (!requireNamespace("arrow", quietly = TRUE)) {
    cli::cli_warn(
      "Package {.pkg arrow} not available. ",
      "Partitioned cache not created. Future reads will be slower."
    )
    return(invisible(NULL))
 }
 
 parquet_dir <- file.path(cache_dir, "vigitel_data")
 
 cli::cli_inform("Creating partitioned parquet cache for faster future reads...")
 
 # identifica coluna de ano
 year_col <- vigitel_identify_year_column(df)
 
 # escreve particionado por ano
 df |>
    dplyr::group_by(.data[[year_col]]) |>
    arrow::write_dataset(
      path = parquet_dir,
      format = "parquet",
      partitioning = year_col
    )
 
 cli::cli_alert_success("Partitioned cache created at {.path {parquet_dir}}")
 
 invisible(parquet_dir)
}
```

### 4.5 Fluxo de dados completo

```
┌─────────────────────────────────────────────────────────────────┐
│       vigitel_data(year = 2024, format = "dta", cache_dir)      │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  1. Verificar se cache particionado existe                      │
│     - Pasta vigitel_data/ com subpastas ano=XXXX/?              │
│     - Se sim E arrow disponível: ir para passo 6 (leitura)      │
│     - Se não: continuar para download                           │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. Download do arquivo ZIP (se necessário)                     │
│     - URL: vigitel-2006-2024-peso-rake-{format}.zip             │
│     - Mostrar progresso com cli                                 │
│     - Salvar em cache_dir                                       │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. Extrair arquivo do ZIP                                      │
│     - Extrair .dta ou .csv para cache_dir                       │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. Ler dados completos (apenas na primeira vez)                │
│     - .dta: usar haven::read_dta()                              │
│     - .csv: usar readr::read_csv()                              │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  5. Criar cache particionado (se arrow disponível)              │
│     - arrow::write_dataset(partitioning = "ano")                │
│     - Cria pasta vigitel_data/ com subpastas por ano            │
│     - Deletar arquivo fonte (.dta/.csv) para economizar espaço  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  6. Ler dados filtrados                                         │
│     - COM arrow: arrow::open_dataset() + filter() + collect()   │
│       → Lê APENAS arquivos dos anos solicitados                 │
│     - SEM arrow: ler arquivo fonte + dplyr::filter()            │
│       → Lê tudo, filtra depois (mais lento)                     │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  7. Selecionar variáveis (se vars especificado)                 │
│     - dplyr::select(all_of(vars))                               │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  8. Retornar tibble                                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. Especificação das Funções

### 5.1 `vigitel_data()`

```r
#' Download VIGITEL microdata
#'
#' Downloads and returns VIGITEL survey microdata from the Ministry of Health.
#' Data is cached locally to avoid repeated downloads.
#'
#' @param year Integer or vector of integers. Years to return (2006-2024).
#'   Use NULL to return all years. Default is NULL.
#' @param format Character. File format to download: "dta" (Stata, default) 
#'   or "csv". Stata format preserves variable labels.
#' @param vars Character vector. Variables to select. Use NULL for all variables.
#'   Default is NULL.
#' @param cache_dir Character. Directory for caching downloaded files.
#'   Default uses `tools::R_user_dir("healthbR", "cache")`.
#' @param force Logical. If TRUE, re-download even if file exists in cache.
#'   Default is FALSE.
#'
#' @return A tibble with VIGITEL microdata.
#'
#' @details
#' The VIGITEL survey (Vigilância de Fatores de Risco e Proteção para Doenças
#' Crônicas por Inquérito Telefônico) is conducted annually by the Brazilian

#' Ministry of Health in all state capitals and the Federal District.
#'
#' Data includes information on:
#' - Demographics (age, sex, education, race)
#' - Health behaviors (smoking, alcohol, diet, physical activity)
#' - Health conditions (hypertension, diabetes, obesity)
#' - Healthcare utilization
#'
#' The survey uses post-stratification weights (variable `pesorake`) to produce
#' population estimates. Always use these weights for statistical inference.
#'
#' @section Data source:
#' Data is downloaded from the Ministry of Health website:
#' \url{https://svs.aids.gov.br/daent/cgdnt/vigitel/}
#'
#' @export
#'
#' @examples
#' \donttest{
#' # download all years (uses tempdir to avoid leaving files)
#' df <- vigitel_data(cache_dir = tempdir())
#'
#' # download specific year
#' df_2023 <- vigitel_data(year = 2023, cache_dir = tempdir())
#'
#' # download multiple years
#' df_recent <- vigitel_data(year = 2020:2024, cache_dir = tempdir())
#'
#' # select specific variables
#' df_subset <- vigitel_data(
#'   year = 2024,
#'   vars = c("ano", "cidade", "sexo", "idade", "pesorake"),
#'   cache_dir = tempdir()
#' )
#' }
vigitel_data <- function(year = NULL,
                         format = c("dta", "csv"),
                         vars = NULL,
                         cache_dir = vigitel_cache_dir(),
                         force = FALSE) {
```

**Implementação (pseudocódigo):**

```r
vigitel_data <- function(year = NULL,
                         format = c("dta", "csv"),
                         vars = NULL,
                         cache_dir = vigitel_cache_dir(),
                         force = FALSE) {
  
  format <- match.arg(format)
  
  # validate year parameter
  available_years <- vigitel_years()
  if (!is.null(year)) {
    # aceita integer, vetor, ou sequência
    year <- as.integer(year)
    invalid_years <- setdiff(year, available_years)
    if (length(invalid_years) > 0) {
      cli::cli_abort(
        "Year{?s} {.val {invalid_years}} not available. ",
        "Available years: {.val {min(available_years)}}-{.val {max(available_years)}}. ",
        "Use {.fn vigitel_years} to see all available years."
      )
    }
  }
  
  # paths
  parquet_dir <- file.path(cache_dir, "vigitel_data")
  zip_filename <- str_c("vigitel-2006-2024-peso-rake-", format, ".zip")
  zip_path <- file.path(cache_dir, zip_filename)
  data_filename <- str_c("vigitel-2006-2024-peso-rake.", format)
  data_path <- file.path(cache_dir, data_filename)
  
  # ESTRATÉGIA DE LEITURA
  # 1. Se cache particionado existe E arrow disponível: leitura eficiente
  # 2. Caso contrário: download → leitura completa → criar cache particionado
  
  has_arrow <- requireNamespace("arrow", quietly = TRUE)
  has_partitioned_cache <- dir.exists(parquet_dir) && 
    length(list.dirs(parquet_dir, recursive = FALSE)) > 0
  
  if (!force && has_partitioned_cache && has_arrow) {
    # CAMINHO RÁPIDO: leitura particionada
    cli::cli_inform("Reading from partitioned cache...")
    
    ds <- arrow::open_dataset(parquet_dir)
    
    # filtrar por ano ANTES de carregar na memória
    if (!is.null(year)) {
      year_col <- vigitel_identify_year_column_from_schema(ds)
      ds <- ds |> dplyr::filter(.data[[year_col]] %in% year)
    }
    
    # selecionar variáveis ANTES de carregar (se especificado)
    if (!is.null(vars)) {
      # sempre incluir coluna de ano para consistência
      year_col <- vigitel_identify_year_column_from_schema(ds)
      vars_to_select <- unique(c(year_col, vars))
      available_vars <- names(ds$schema)
      missing_vars <- setdiff(vars_to_select, available_vars)
      if (length(missing_vars) > 0) {
        cli::cli_warn("Variable{?s} not found: {.val {missing_vars}}")
        vars_to_select <- intersect(vars_to_select, available_vars)
      }
      ds <- ds |> dplyr::select(dplyr::all_of(vars_to_select))
    }
    
    # coletar dados filtrados
    df <- ds |> dplyr::collect()
    
  } else {
    # CAMINHO COMPLETO: download e processamento
    
    # download se necessário
    if (force || !file.exists(data_path)) {
      if (force || !file.exists(zip_path)) {
        vigitel_download_data(format, zip_path)
      }
      vigitel_extract_zip(zip_path, cache_dir)
    }
    
    # ler arquivo completo
    cli::cli_inform("Reading {format} file (this may take a moment)...")
    df <- vigitel_read_data(data_path, format)
    
    # criar cache particionado para futuras leituras
    if (has_arrow) {
      create_partitioned_cache(df, cache_dir)
      
      # opcional: deletar arquivo fonte para economizar espaço
      # unlink(data_path)
    }
    
    # filtrar por ano
    if (!is.null(year)) {
      year_col <- vigitel_identify_year_column(df)
      df <- df |> dplyr::filter(.data[[year_col]] %in% year)
    }
    
    # selecionar variáveis
    if (!is.null(vars)) {
      missing_vars <- setdiff(vars, names(df))
      if (length(missing_vars) > 0) {
        cli::cli_warn("Variable{?s} not found: {.val {missing_vars}}")
      }
      vars_to_select <- intersect(vars, names(df))
      df <- df |> dplyr::select(dplyr::all_of(vars_to_select))
    }
  }
  
  # informar usuário sobre o resultado
  year_col <- vigitel_identify_year_column(df)
  years_in_data <- sort(unique(df[[year_col]]))
  cli::cli_alert_success(
    "Loaded {.val {nrow(df)}} observations from {.val {length(years_in_data)}} year{?s}: {.val {years_in_data}}"
  )
  
  tibble::as_tibble(df)
}
```

#### Funções auxiliares para identificar coluna de ano

```r
#' Identify year column in VIGITEL data
#' @keywords internal
vigitel_identify_year_column <- function(df) {
  # possíveis nomes da coluna de ano
  possible_names <- c("ano", "year", "ANO", "YEAR", "Ano", "Year")
  
  found <- intersect(possible_names, names(df))
  
  if (length(found) == 0) {
    cli::cli_abort("Could not identify year column in the data.")
  }
  
  found[1]
}

#' Identify year column from Arrow schema
#' @keywords internal
vigitel_identify_year_column_from_schema <- function(dataset) {
  possible_names <- c("ano", "year", "ANO", "YEAR", "Ano", "Year")
  schema_names <- names(dataset$schema)
  
  found <- intersect(possible_names, schema_names)
  
  if (length(found) == 0) {
    cli::cli_abort("Could not identify year column in the dataset schema.")
  }
  
  found[1]
}
```

### 5.2 `vigitel_years()`

```r
#' List available VIGITEL survey years
#'
#' Returns a vector of years for which VIGITEL microdata is available.
#'
#' @return An integer vector of available years (2006-2024).
#'
#' @export
#'
#' @examples
#' vigitel_years()
#' # [1] 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024
vigitel_years <- function() {
  2006L:2024L
}
```

### 5.3 `vigitel_dictionary()`

```r
#' Get VIGITEL variable dictionary
#'
#' Downloads and returns the VIGITEL data dictionary containing variable
#' descriptions, codes, and categories.
#'
#' @param cache_dir Character. Directory for caching downloaded files.
#'   Default uses `tools::R_user_dir("healthbR", "cache")`.
#' @param force Logical. If TRUE, re-download even if file exists in cache.
#'   Default is FALSE.
#'
#' @return A tibble with variable dictionary.
#'
#' @export
#'
#' @examples
#' \donttest{
#' dict <- vigitel_dictionary(cache_dir = tempdir())
#' head(dict)
#' }
vigitel_dictionary <- function(cache_dir = vigitel_cache_dir(),
                               force = FALSE) {
  
  dict_url <- "https://svs.aids.gov.br/daent/cgdnt/vigitel/dicionario-vigitel-2006-2024.xlsx"
  dict_path <- file.path(cache_dir, "dicionario-vigitel-2006-2024.xlsx")
  
  # download if needed
  if (force || !file.exists(dict_path)) {
    cli::cli_inform("Downloading VIGITEL dictionary...")
    curl::curl_download(dict_url, dict_path, quiet = FALSE)
  }
  
  # read excel
  df <- readxl::read_excel(dict_path)
  
  # clean column names
  df <- janitor::clean_names(df)
  
  tibble::as_tibble(df)
}
```

### 5.4 `vigitel_variables()`

```r
#' List VIGITEL variables
#'
#' Returns a tibble with information about available variables in the
#' VIGITEL dataset.
#'
#' @inheritParams vigitel_dictionary
#'
#' @return A tibble with columns: variable (name), description, type.
#'
#' @export
#'
#' @examples
#' \donttest{
#' vars <- vigitel_variables(cache_dir = tempdir())
#' head(vars)
#'
#' # search for weight-related variables
#' vars |> dplyr::filter(stringr::str_detect(description, "peso"))
#' }
vigitel_variables <- function(cache_dir = vigitel_cache_dir(),
                              force = FALSE) {
  
  dict <- vigitel_dictionary(cache_dir = cache_dir, force = force)
  
  # extract variable list from dictionary
  # (adjust column names based on actual dictionary structure)
  dict |>
    dplyr::select(
      variable = 1,  # adjust based on actual structure
      description = 2
    ) |>
    dplyr::distinct()
}
```

---

## 6. Funções Internas (Helpers)

### 6.1 `vigitel_download_data()`

```r
#' Download VIGITEL data file
#'
#' @param format Character. "dta" or "csv".
#' @param destfile Character. Destination path for the ZIP file.
#'
#' @return Invisible NULL. Called for side effect (file download).
#'
#' @keywords internal
vigitel_download_data <- function(format, destfile) {
  
  base_url <- "https://svs.aids.gov.br/daent/cgdnt/vigitel/"
  filename <- str_c("vigitel-2006-2024-peso-rake-", format, ".zip")
  url <- str_c(base_url, filename)
  
  cli::cli_inform("Downloading VIGITEL data ({format} format)...")
  cli::cli_inform("URL: {.url {url}}")
  cli::cli_inform("This may take a few minutes...")
  
  # ensure directory exists
  dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
  
  # download with progress
  curl::curl_download(url, destfile, quiet = FALSE)
  
  cli::cli_alert_success("Download complete: {.file {destfile}}")
  
  invisible(NULL)
}
```

### 6.2 `vigitel_extract_zip()`

```r
#' Extract VIGITEL ZIP file
#'
#' @param zip_path Character. Path to the ZIP file.
#' @param exdir Character. Directory to extract to.
#'
#' @return Character. Path to the extracted file.
#'
#' @keywords internal
vigitel_extract_zip <- function(zip_path, exdir) {
  
  cli::cli_inform("Extracting ZIP file...")
  
  # list files in zip
  files_in_zip <- utils::unzip(zip_path, list = TRUE)$Name
  
  # extract
  utils::unzip(zip_path, exdir = exdir, overwrite = TRUE)
  
  # return path to extracted file
  extracted_path <- file.path(exdir, files_in_zip[1])
  
  cli::cli_alert_success("Extracted: {.file {extracted_path}}")
  
  extracted_path
}
```

### 6.3 `vigitel_read_data()`

```r
#' Read VIGITEL data file
#'
#' @param path Character. Path to the data file (.dta or .csv).
#' @param format Character. "dta" or "csv".
#'
#' @return A tibble.
#'
#' @keywords internal
vigitel_read_data <- function(path, format) {
  
  cli::cli_inform("Reading {format} file...")
  
  if (format == "dta") {
    # stata format - preserves labels
    df <- haven::read_dta(path)
  } else {
    # csv format
    df <- readr::read_csv(path, show_col_types = FALSE)
  }
  
  tibble::as_tibble(df)
}
```

### 6.4 `vigitel_cache_dir()`

```r
#' Get VIGITEL cache directory
#'
#' Returns the path to the cache directory for VIGITEL data.
#' Creates the directory if it doesn't exist.
#'
#' @return Character. Path to cache directory.
#'
#' @keywords internal
vigitel_cache_dir <- function() {
  cache_dir <- tools::R_user_dir("healthbR", which = "cache")
  vigitel_dir <- file.path(cache_dir, "vigitel")
  
  if (!dir.exists(vigitel_dir)) {
    dir.create(vigitel_dir, recursive = TRUE)
  }
  
  vigitel_dir
}
```

---

## 7. Dependências

### 7.1 DESCRIPTION - Imports

```
Imports:
    tibble,
    dplyr,
    readxl,
    curl,
    cli,
    rlang,
    stringr,
    janitor,
    purrr,
    haven,
    readr
```

### 7.2 DESCRIPTION - Suggests

```
Suggests:
    arrow,
    testthat (>= 3.0.0),
    knitr,
    rmarkdown,
    srvyr
```

**Nota importante**: `haven` precisa ser adicionado às Imports para leitura de arquivos .dta.

---

## 8. Testes Unitários

### 8.1 Estrutura de testes

```
tests/
├── testthat.R
└── testthat/
    ├── helper.R                    # skip_if_offline(), etc.
    ├── test-vigitel-years.R        # testes para vigitel_years()
    ├── test-vigitel-dictionary.R   # testes para vigitel_dictionary()
    ├── test-vigitel-variables.R    # testes para vigitel_variables()
    └── test-vigitel-data.R         # testes para vigitel_data()
```

### 8.2 Testes obrigatórios

```r
# test-vigitel-years.R
test_that("vigitel_years returns integer vector", {
  years <- vigitel_years()
  expect_type(years, "integer")
  expect_true(length(years) > 0)
})

test_that("vigitel_years includes expected range", {
  years <- vigitel_years()
  expect_true(2006L %in% years)
  expect_true(2024L %in% years)
  expect_equal(min(years), 2006L)
  expect_equal(max(years), 2024L)
})

# test-vigitel-data.R
test_that("vigitel_data validates year parameter", {
  expect_error(
    vigitel_data(year = 1999, cache_dir = tempdir()),
    "not available"
  )
  expect_error(
    vigitel_data(year = 2030, cache_dir = tempdir()),
    "not available"
  )
})

# testes de integração (skip on CRAN)
test_that("vigitel_data downloads and returns tibble", {
  skip_on_cran()
  skip_if_offline()
  
  df <- vigitel_data(year = 2024, cache_dir = tempdir())
  
  expect_s3_class(df, "tbl_df")
  expect_true(nrow(df) > 0)
  expect_true("pesorake" %in% names(df))
})
```

---

## 9. Documentação

### 9.1 Atualizar README.md

- Atualizar exemplo de uso com nova sintaxe
- Mencionar range de anos disponíveis (2006-2024)
- Adicionar seção sobre cache e performance

### 9.2 Atualizar vignette

- Atualizar exemplos para usar nova API
- Adicionar seção sobre formatos disponíveis (dta vs csv)
- Mencionar recomendação de usar formato Stata para preservar labels

### 9.3 Atualizar NEWS.md

```markdown
# healthbR 0.2.0

## Breaking changes

* Complete refactoring of VIGITEL functions due to Ministry of Health website 
  restructuring. Data is now distributed as a single file containing all years
  (2006-2024).

## New features
)
* `vigitel_data()` now supports downloading data in Stata (.dta) or CSV format
  via the `format` parameter.
* Added 2024 data (newly released by Ministry of Health).
* Performance improvement: parquet caching for faster subsequent reads.

## Bug fixes

* Fixed CRAN check issues related to `arrow` dependency and cache files.
```

---

## 10. Checklist de Implementação

### Fase 1: Preparação
- [ ] Criar branch `feature/vigitel-refactor`
- [ ] Criar/atualizar pasta `cran-fixes/` com este documento
- [ ] Adicionar `^cran-fixes$` ao `.Rbuildignore`

### Fase 2: Código
- [ ] Adicionar `haven` às Imports no DESCRIPTION
- [ ] Atualizar `vigitel_years()` para retornar 2006:2024
- [ ] Implementar `vigitel_download_data()` (nova)
- [ ] Implementar `vigitel_extract_zip()` (nova)
- [ ] Implementar `vigitel_read_data()` (nova)
- [ ] Reformular `vigitel_data()` completamente
- [ ] Reformular `vigitel_dictionary()` (nova URL)
- [ ] Reformular `vigitel_variables()` (usar dicionário)
- [ ] Atualizar `vigitel_info()` (texto)
- [ ] Atualizar `vigitel_cache_status()` (nova estrutura)
- [ ] Remover funções obsoletas (URLs antigas, etc.)

### Fase 3: Documentação
- [ ] Rodar `devtools::document()` para regenerar .Rd
- [ ] Atualizar README.md
- [ ] Atualizar vignette
- [ ] Atualizar NEWS.md

### Fase 4: Testes
- [ ] Atualizar testes unitários
- [ ] Rodar `devtools::test()`
- [ ] Verificar cobertura de testes

### Fase 5: Verificação CRAN
- [ ] Rodar `devtools::check()` localmente
- [ ] Verificar: 0 errors, 0 warnings
- [ ] Rodar `devtools::check_win_devel()`
- [ ] Rodar `rhub::rhub_check()` (se disponível)

### Fase 6: Submissão
- [ ] Incrementar versão para 0.2.0
- [ ] Commit com mensagem descritiva
- [ ] Push para GitHub
- [ ] Submeter ao CRAN via `devtools::submit_cran()`

---

## 11. Padrões de Código (OBRIGATÓRIOS)

### 11.1 Tidyverse

- Usar `str_c()` em vez de `paste0()`
- Usar `|>` (pipe nativo) em vez de `%>%`
- Usar `tibble::tibble()` em vez de `data.frame()`
- Usar funções do `dplyr` para manipulação

### 11.2 Comentários

- Sempre em inglês
- Primeira letra minúscula após `#`
- Exemplo: `# download file from ministry of health`

### 11.3 Mensagens ao usuário

- Usar `cli::cli_inform()` para mensagens informativas
- Usar `cli::cli_warn()` para avisos
- Usar `cli::cli_abort()` para erros
- Usar `cli::cli_alert_success()` para confirmações

### 11.4 Validação de inputs

- Usar `rlang::arg_match()` para argumentos com opções fixas
- Usar `cli::cli_abort()` com mensagens descritivas
- Validar tipos e ranges antes de processar

---

## 12. Observações Finais

### 12.1 Sobre o cache

O sistema de cache deve:
1. Usar `tools::R_user_dir()` como padrão (recomendação CRAN)
2. Aceitar `tempdir()` nos exemplos (requisito CRAN)
3. Converter para parquet quando `arrow` disponível (performance)
4. Permitir limpeza seletiva (manter parquet, limpar originais)

### 12.2 Sobre formatos

- Recomendação: usar formato Stata (.dta) por preservar labels
- Fallback: CSV para máxima compatibilidade
- Cache: parquet para máxima performance

### 12.3 Monitoramento futuro

O Ministério da Saúde pode mudar URLs novamente. Considerar:
- Função para verificar disponibilidade das URLs
- Mensagens claras quando URLs falharem
- Documentar URLs no código para fácil atualização
