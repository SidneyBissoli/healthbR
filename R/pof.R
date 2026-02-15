# pof functions for healthbR package
# functions to download and process POF (Pesquisa de Orcamentos Familiares) data
# includes microdata access via FTP from IBGE

# ============================================================================
# internal constants and data
# ============================================================================

#' POF URL patterns for FTP access
#' @noRd
pof_url_patterns <- list(
  base_url = "https://ftp.ibge.gov.br/Orcamentos_Familiares/",
  "2017-2018" = list(
    data = "https://ftp.ibge.gov.br/Orcamentos_Familiares/Pesquisa_de_Orcamentos_Familiares_2017_2018/Microdados/Dados_20230713.zip",
    doc = "https://ftp.ibge.gov.br/Orcamentos_Familiares/Pesquisa_de_Orcamentos_Familiares_2017_2018/Microdados/Documentacao_20230713.zip"
  ),
  "2008-2009" = list(
    data = "https://ftp.ibge.gov.br/Orcamentos_Familiares/Pesquisa_de_Orcamentos_Familiares_2008_2009/Microdados/Dados_20231009.zip",
    doc = "https://ftp.ibge.gov.br/Orcamentos_Familiares/Pesquisa_de_Orcamentos_Familiares_2008_2009/Microdados/Documentacao_20231009.zip"
  ),
  "2002-2003" = list(
    data = "https://ftp.ibge.gov.br/Orcamentos_Familiares/Pesquisa_de_Orcamentos_Familiares_2002_2003/Microdados/Dados.zip",
    doc = "https://ftp.ibge.gov.br/Orcamentos_Familiares/Pesquisa_de_Orcamentos_Familiares_2002_2003/Microdados/Documentacao.zip"
  )
)

#' POF register file mapping
#' @noRd
pof_register_files <- list(
  "2017-2018" = list(
    domicilio = "DOMICILIO.txt",
    morador = "MORADOR.txt",
    caderneta_coletiva = "CADERNETA_COLETIVA.txt",
    despesa_individual = "DESPESA_INDIVIDUAL.txt",
    consumo_alimentar = "CONSUMO_ALIMENTAR.txt",
    rendimento = "RENDIMENTO.txt",
    inventario = "INVENTARIO.txt",
    despesa_coletiva = "DESPESA_COLETIVA.txt",
    aluguel_estimado = "ALUGUEL_ESTIMADO.txt",
    outros_rendimentos = "OUTROS_RENDIMENTOS.txt"
  ),
  "2008-2009" = list(
    domicilio = "T_DOMICILIO_S.txt",
    morador = "T_MORADOR_S.txt",
    caderneta_coletiva = "T_CADERNETA_COLETIVA_S.txt",
    despesa_individual = "T_DESPESA_INDIVIDUAL_S.txt",
    consumo_alimentar = "T_CONSUMO_S.txt",
    rendimento = "T_RENDIMENTO_S.txt",
    inventario = "T_INVENTARIO_S.txt",
    despesa_coletiva = "T_DESPESA_COLETIVA_S.txt",
    despesa_90dias = "T_DESPESA_90DIAS_S.txt",
    despesa_12meses = "T_DESPESA_12MESES_S.txt"
  ),
  "2002-2003" = list(
    domicilio = "T_DOMICILIO.txt",
    morador = "T_MORADOR.txt",
    caderneta_coletiva = "T_CADERNETA_DESPESA.txt",
    despesa_individual = "T_DESPESA_INDIVIDUAL.txt",
    rendimento = "T_RENDIMENTO.txt",
    inventario = "T_INVENTARIO.txt",
    despesa_coletiva = "T_DESPESA_COLETIVA.txt"
  )
)

#' POF valid registers per year
#' @noRd
pof_valid_registers <- list(
  "2017-2018" = c(
    "domicilio", "morador", "caderneta_coletiva", "despesa_individual",
    "consumo_alimentar", "rendimento", "inventario", "despesa_coletiva",
    "aluguel_estimado", "outros_rendimentos"
  ),
  "2008-2009" = c(
    "domicilio", "morador", "caderneta_coletiva", "despesa_individual",
    "consumo_alimentar", "rendimento", "inventario", "despesa_coletiva",
    "despesa_90dias", "despesa_12meses"
  ),
  "2002-2003" = c(
    "domicilio", "morador", "caderneta_coletiva", "despesa_individual",
    "rendimento", "inventario", "despesa_coletiva"
  )
)

#' Health-related registers in POF
#' @noRd
pof_health_registers <- c(
  "domicilio",
  "morador",
  "consumo_alimentar",
  "despesa_individual"
)

# ============================================================================
# internal helper functions
# ============================================================================

#' Get POF cache directory
#' @noRd
pof_cache_dir <- function(cache_dir = NULL) {
  .module_cache_dir("pof", cache_dir)
}

#' Validate POF year parameter
#' @noRd
.pof_validate_year <- function(year) {
  valid_years <- pof_years()

  if (!year %in% valid_years) {
    cli::cli_abort(c(
      "Year {.val {year}} is not available.",
      "i" = "Available years: {.val {valid_years}}"
    ))
  }

  invisible(NULL)
}

#' Validate POF register parameter
#' @noRd
.pof_validate_register <- function(register, year = "2017-2018") {
  valid_registers <- pof_valid_registers[[year]]

  if (is.null(valid_registers)) {
    valid_registers <- c(
      "domicilio", "morador", "caderneta_coletiva",
      "despesa_individual", "consumo_alimentar", "rendimento", "inventario"
    )
  }

  if (!tolower(register) %in% valid_registers) {
    cli::cli_abort(c(
      "Register {.val {register}} is not available for year {.val {year}}.",
      "i" = "Available registers: {.val {valid_registers}}"
    ))
  }

  invisible(NULL)
}

#' Build FTP URL for POF data
#' @noRd
.pof_build_url <- function(year, type = "data") {
  url_info <- pof_url_patterns[[year]]

  if (is.null(url_info)) {
    cli::cli_abort("Year {.val {year}} not configured.")
  }

  if (type == "data") {
    url_info$data
  } else {
    url_info$doc
  }
}

#' Download POF data ZIP file
#' @noRd
.pof_download_data <- function(year, cache_dir) {
  # build destination path
  zip_file <- file.path(cache_dir, stringr::str_c("pof_", year, "_dados.zip"))

  # check if already downloaded
  if (file.exists(zip_file)) {
    cli::cli_inform("Using cached data file...")
    return(zip_file)
  }

  # build URL
  url <- .pof_build_url(year, "data")

  # download with progress
  cli::cli_inform("Downloading from {.url {url}}...")
  cli::cli_inform("This may take several minutes depending on your connection...")

  tryCatch(
    {
      curl::curl_download(url, zip_file, quiet = FALSE)
      cli::cli_alert_success("Download complete: {.path {zip_file}}")
    },
    error = function(e) {
      if (file.exists(zip_file)) file.remove(zip_file)
      cli::cli_abort(c(
        "Failed to download POF data.",
        "x" = "URL: {.url {url}}",
        "i" = "Check your internet connection.",
        "i" = "The IBGE FTP server may be temporarily unavailable.",
        "i" = "If this persists, the URL structure may have changed. Please open an issue."
      ))
    }
  )

  zip_file
}

#' Download POF documentation ZIP file
#' @noRd
.pof_download_documentation <- function(year, cache_dir) {
  # build destination path
  zip_file <- file.path(cache_dir, stringr::str_c("pof_", year, "_doc.zip"))

  # check if already downloaded
  if (file.exists(zip_file)) {
    cli::cli_inform("Using cached documentation file...")
    return(zip_file)
  }

  # build URL
  url <- .pof_build_url(year, "doc")

  # download
  cli::cli_inform("Downloading documentation from {.url {url}}...")

  tryCatch(
    {
      curl::curl_download(url, zip_file, quiet = FALSE)
      cli::cli_alert_success("Documentation downloaded: {.path {zip_file}}")
    },
    error = function(e) {
      if (file.exists(zip_file)) file.remove(zip_file)
      cli::cli_abort(c(
        "Failed to download POF documentation.",
        "x" = "URL: {.url {url}}",
        "i" = "Check your internet connection."
      ))
    }
  )

  zip_file
}

#' Find dictionary file in extracted documentation
#' @noRd
.pof_find_dictionary_file <- function(extracted_files, year) {
  # look for dictionary Excel file
  # use flexible patterns to handle encoding issues with Portuguese characters
  xls_files <- extracted_files[grepl("\\.xls", extracted_files, ignore.case = TRUE, useBytes = TRUE)]

  # approach 1: direct pattern matching
  dict_patterns <- c("dicion", "variav", "variaveis")
  for (pattern in dict_patterns) {
    for (f in xls_files) {
      if (grepl(pattern, f, ignore.case = TRUE, useBytes = TRUE)) {
        return(f)
      }
    }
  }

  # approach 2: check raw bytes for "Dicion" (handles encoding issues)
  dicion_raw <- charToRaw("Dicion")
  for (f in xls_files) {
    bn <- basename(f)
    if (nchar(bn, type = "bytes") >= 6) {
      first_bytes <- charToRaw(substr(bn, 1, 6))
      if (length(first_bytes) >= 6 && all(first_bytes == dicion_raw)) {
        return(f)
      }
    }
  }

  # approach 3: look for files with "variav" in accent-stripped name
  for (f in xls_files) {
    bn_ascii <- .strip_accents(basename(f))
    if (grepl("dicion|variav", bn_ascii, ignore.case = TRUE, useBytes = TRUE)) {
      return(f)
    }
  }

  NULL
}

#' Parse POF dictionary from Excel file
#' @noRd
.pof_parse_dictionary <- function(dict_path, year) {
  rlang::check_installed("readxl", reason = "to read POF dictionary Excel files")
  # read all sheets from Excel file
  sheets <- readxl::excel_sheets(dict_path)

  # filter to relevant sheets (register names)
  register_patterns <- c(
    "domicilio", "morador", "caderneta", "despesa",
    "consumo", "rendimento", "inventario", "aluguel"
  )

  all_dicts <- purrr::map(sheets, function(sheet) {
    # strip accents and lowercase for matching
    sheet_ascii <- tolower(.strip_accents(sheet))
    is_register <- any(purrr::map_lgl(register_patterns, ~ grepl(.x, sheet_ascii)))

    if (!is_register) {
      return(NULL)
    }

    tryCatch(
      {
        # the POF dictionary Excel has a specific structure:
        # row 1: register title (e.g. "REGISTRO - DOMICILIO")
        # row 2: blank
        # row 3: column headers (Posicao Inicial, Tamanho, Decimais, Codigo, Descricao, Categorias)
        # row 4+: data

        # first detect the header row by scanning for "Posi" pattern
        raw_df <- readxl::read_excel(dict_path, sheet = sheet, col_names = FALSE)
        header_row <- NULL
        for (i in seq_len(min(10, nrow(raw_df)))) {
          row_vals <- as.character(raw_df[i, ])
          if (any(grepl("Posi", row_vals, ignore.case = TRUE), na.rm = TRUE)) {
            header_row <- i
            break
          }
        }

        if (is.null(header_row)) {
          # fallback: try reading with default headers
          df <- readxl::read_excel(dict_path, sheet = sheet)
          names(df) <- .clean_names(names(df))
        } else {
          # read skipping rows before the header so the header row becomes col names
          df <- readxl::read_excel(dict_path, sheet = sheet, skip = header_row - 1)
          names(df) <- .clean_names(names(df))
        }

        # remove completely empty rows
        df <- df |> dplyr::filter(!dplyr::if_all(dplyr::everything(), is.na))

        # standardize column names to expected format
        col_names <- names(df)

        # position column
        pos_col <- col_names[grepl("posicao|inicio|start|pos", col_names, ignore.case = TRUE)]
        if (length(pos_col) > 0) {
          names(df)[names(df) == pos_col[1]] <- "position"
        }

        # length column
        len_col <- col_names[grepl("tamanho|length|tam|size", col_names, ignore.case = TRUE)]
        if (length(len_col) > 0) {
          names(df)[names(df) == len_col[1]] <- "length"
        }

        # variable column
        var_col <- col_names[grepl("codigo|variavel|variable|var|nome", col_names, ignore.case = TRUE)]
        if (length(var_col) > 0) {
          names(df)[names(df) == var_col[1]] <- "variable"
        }

        # description column
        desc_col <- col_names[grepl("descricao|description|desc|rotulo|label", col_names, ignore.case = TRUE)]
        if (length(desc_col) > 0) {
          names(df)[names(df) == desc_col[1]] <- "description"
        }

        # decimals column
        dec_col <- col_names[grepl("decimais|decimal|dec", col_names, ignore.case = TRUE)]
        if (length(dec_col) > 0) {
          names(df)[names(df) == dec_col[1]] <- "decimals"
        }

        # categories column
        cat_col <- col_names[grepl("categor|categ", col_names, ignore.case = TRUE)]
        if (length(cat_col) > 0) {
          names(df)[names(df) == cat_col[1]] <- "categories"
        }

        # map sheet name to standard register name
        # sheet_ascii already computed above (accent-stripped, lowercase)

        # more specific patterns first to avoid partial matches
        register_map <- list(
          "outros rendimentos" = "outros_rendimentos",
          "rendimento" = "rendimento",
          "consumo alimentar" = "consumo_alimentar",
          "consumo" = "consumo_alimentar",
          "despesa individual" = "despesa_individual",
          "despesa coletiva" = "despesa_coletiva",
          "aluguel estimado" = "aluguel_estimado",
          "caderneta" = "caderneta_coletiva",
          "inventario" = "inventario",
          "domicilio" = "domicilio",
          "morador" = "morador"
        )

        matched_register <- NULL
        for (pattern in names(register_map)) {
          if (grepl(pattern, sheet_ascii, ignore.case = TRUE)) {
            matched_register <- register_map[[pattern]]
            break
          }
        }

        # skip sheets that don't match any known register
        if (is.null(matched_register)) {
          return(NULL)
        }

        df <- df |>
          dplyr::mutate(register = matched_register)

        # select only standard columns and convert to character for safe binding
        standard_cols <- c("position", "length", "decimals", "variable",
                           "description", "categories", "register")
        available_cols <- intersect(standard_cols, names(df))
        df <- df |>
          dplyr::select(dplyr::all_of(available_cols)) |>
          dplyr::mutate(dplyr::across(dplyr::everything(), as.character))

        df
      },
      error = function(e) {
        cli::cli_warn("Could not parse sheet {.val {sheet}}: {e$message}")
        NULL
      }
    )
  })

  # remove NULLs and combine
  all_dicts <- purrr::compact(all_dicts)

  if (length(all_dicts) == 0) {
    cli::cli_abort("Could not parse any sheets from dictionary file.")
  }

  result <- dplyr::bind_rows(all_dicts) |>
    dplyr::mutate(year = year, .before = 1) |>
    tibble::as_tibble()

  # convert position and length back to numeric
  if ("position" %in% names(result)) {
    result <- result |>
      dplyr::mutate(position = as.integer(.data$position))
  }
  if ("length" %in% names(result)) {
    result <- result |>
      dplyr::mutate(length = as.integer(.data$length))
  }

  result
}

#' Download and parse POF dictionary
#' @noRd
.pof_download_and_parse_dictionary <- function(year, cache_dir) {
  # download documentation ZIP
  doc_zip <- .pof_download_documentation(year, cache_dir)

  # create temp dir for extraction
  temp_dir <- file.path(tempdir(), stringr::str_c("pof_dict_", year))
  if (dir.exists(temp_dir)) {
    unlink(temp_dir, recursive = TRUE)
  }
  dir.create(temp_dir)

  # extract all files - more reliable than trying to extract specific files
  # when there are encoding issues with Portuguese characters in filenames
  cli::cli_inform("Extracting documentation files...")

  extraction_success <- tryCatch(
    {
      utils::unzip(doc_zip, exdir = temp_dir)
      TRUE
    },
    error = function(e) {
      # if standard unzip fails, try PowerShell on Windows
      if (.Platform$OS.type == "windows") {
        cli::cli_warn("Standard extraction failed, trying PowerShell...")
        ps_cmd <- sprintf(
          "powershell -Command \"Expand-Archive -Path '%s' -DestinationPath '%s' -Force\"",
          normalizePath(doc_zip, winslash = "/"),
          normalizePath(temp_dir, winslash = "/", mustWork = FALSE)
        )
        result <- system(ps_cmd, ignore.stdout = TRUE, ignore.stderr = TRUE)
        return(result == 0)
      }
      FALSE
    }
  )

  if (!extraction_success) {
    unlink(temp_dir, recursive = TRUE)
    cli::cli_abort("Could not extract documentation ZIP file.")
  }

  # list extracted files
  extracted_files <- list.files(temp_dir, recursive = TRUE, full.names = TRUE)

  # find dictionary file
  dict_file <- .pof_find_dictionary_file(extracted_files, year)

  if (is.null(dict_file)) {
    # cleanup
    unlink(temp_dir, recursive = TRUE)
    cli::cli_abort(c(
      "Could not find dictionary file after extraction.",
      "i" = "Files found: {.val {basename(extracted_files)}}"
    ))
  }

  # rename to ASCII-safe name to avoid invalid UTF-8 issues downstream
  # (cli, readxl, etc. can choke on Latin-1 encoded filenames from unzip on Linux)
  safe_name <- file.path(dirname(dict_file),
                         paste0("dictionary_", year, ".", tools::file_ext(dict_file)))
  if (file.rename(dict_file, safe_name)) {
    dict_file <- safe_name
  }

  cli::cli_inform("Parsing dictionary from {.file {basename(dict_file)}}...")

  # parse dictionary
  dict <- .pof_parse_dictionary(dict_file, year)

  # cleanup
  unlink(temp_dir, recursive = TRUE)

  dict
}

#' Read POF fixed-width file using dictionary
#' @noRd
.pof_read_fwf <- function(zip_path, register, dictionary, year) {
  # get file name for this register
  file_map <- pof_register_files[[year]]

  if (is.null(file_map)) {
    cli::cli_abort("No file mapping for year {.val {year}}")
  }

  file_name <- file_map[[tolower(register)]]
  if (is.null(file_name)) {
    cli::cli_abort("Unknown register: {.val {register}}")
  }

  # list files in ZIP to find the correct one
  zip_contents <- utils::unzip(zip_path, list = TRUE)
  matching_files <- zip_contents$Name[grepl(file_name, zip_contents$Name, ignore.case = TRUE)]

  if (length(matching_files) == 0) {
    cli::cli_abort(c(
      "Could not find file {.val {file_name}} in ZIP archive.",
      "i" = "Available files: {.val {basename(zip_contents$Name)}}"
    ))
  }

  # extract file from ZIP to temp location
  temp_dir <- tempdir()
  utils::unzip(zip_path, files = matching_files[1], exdir = temp_dir, overwrite = TRUE)
  txt_path <- file.path(temp_dir, matching_files[1])

  # filter dictionary for this register (use base R to avoid dplyr data masking)
  dict_filtered <- dictionary[tolower(dictionary$register) == tolower(register), ]
  dict_filtered <- dict_filtered[
    !is.na(dict_filtered$position) & !is.na(dict_filtered$length) & !is.na(dict_filtered$variable),
  ]

  if (nrow(dict_filtered) == 0) {
    # cleanup
    unlink(txt_path)
    cli::cli_abort(c(
      "No column specifications found in dictionary for register {.val {register}}.",
      "i" = "Check if the dictionary was parsed correctly."
    ))
  }

  # get unique column specifications (deduplicate by variable name,
  # keeping first occurrence to avoid duplicate columns from merged sheets)
  dict_unique <- dict_filtered |>
    dplyr::mutate(
      position = as.integer(.data$position),
      length = as.integer(.data$length)
    ) |>
    dplyr::filter(!is.na(.data$position), !is.na(.data$length)) |>
    dplyr::distinct(.data$variable, .keep_all = TRUE) |>
    dplyr::arrange(.data$position)

  # create fwf_positions
  col_positions <- readr::fwf_positions(
    start = dict_unique$position,
    end = dict_unique$position + dict_unique$length - 1,
    col_names = dict_unique$variable
  )

  # read fixed-width file
  cli::cli_inform("Reading {.file {basename(matching_files[1])}}...")

  df <- readr::read_fwf(
    txt_path,
    col_positions = col_positions,
    col_types = readr::cols(.default = readr::col_character()),
    progress = TRUE,
    locale = readr::locale(encoding = "latin1")
  )

  # convert numeric columns
  df <- df |>
    dplyr::mutate(
      dplyr::across(
        dplyr::where(\(x) !any(stringr::str_detect(x, "[^0-9.\\-]"), na.rm = TRUE)),
        as.numeric
      )
    )

  # cleanup temp file
  unlink(txt_path)

  tibble::as_tibble(df)
}

#' Download post-stratification totals
#' @noRd
.pof_download_post_strat <- function(year, cache_dir) {
  # download documentation if not already cached
  doc_zip <- .pof_download_documentation(year, cache_dir)

  # create temp dir for extraction
  temp_dir <- file.path(tempdir(), stringr::str_c("pof_posstrat_", year))
  if (dir.exists(temp_dir)) {
    unlink(temp_dir, recursive = TRUE)
  }
  dir.create(temp_dir)

  # list files in ZIP first
  zip_contents <- tryCatch(
    utils::unzip(doc_zip, list = TRUE),
    error = function(e) {
      cli::cli_warn("Could not read ZIP contents for post-stratification: {e$message}")
      return(NULL)
    }
  )

  if (is.null(zip_contents)) {
    unlink(temp_dir, recursive = TRUE)
    return(NULL)
  }

  # find post-stratification file in ZIP
  pos_strat_patterns <- c("pos.*estrat.*\\.xls", "calibra.*\\.xls", "pos.*estrat.*\\.txt")
  pos_strat_in_zip <- NULL

  for (pattern in pos_strat_patterns) {
    matches <- zip_contents$Name[grepl(pattern, zip_contents$Name, ignore.case = TRUE)]
    if (length(matches) > 0) {
      pos_strat_in_zip <- matches[1]
      break
    }
  }

  if (is.null(pos_strat_in_zip)) {
    # cleanup
    unlink(temp_dir, recursive = TRUE)
    cli::cli_warn("Could not find post-stratification file. Survey weights may not be fully calibrated.")
    return(NULL)
  }

  # extract only the post-stratification file
  tryCatch(
    utils::unzip(doc_zip, files = pos_strat_in_zip, exdir = temp_dir, junkpaths = TRUE),
    error = function(e) {
      cli::cli_warn("Could not extract post-stratification file: {e$message}")
      return(NULL)
    }
  )

  # list extracted files
  extracted_files <- list.files(temp_dir, recursive = TRUE, full.names = TRUE)
  pos_strat_file <- extracted_files[1]

  if (length(extracted_files) == 0) {
    unlink(temp_dir, recursive = TRUE)
    cli::cli_warn("Could not find post-stratification file after extraction.")
    return(NULL)
  }

  # read post-stratification file
  pos_strat <- tryCatch(
    {
      if (grepl("\\.xlsx?$", pos_strat_file, ignore.case = TRUE)) {
        rlang::check_installed("readxl", reason = "to read POF post-stratification files")
        readxl::read_excel(pos_strat_file)
      } else {
        readr::read_delim(pos_strat_file, delim = ";", show_col_types = FALSE)
      }
    },
    error = function(e) {
      cli::cli_warn("Could not read post-stratification file: {e$message}")
      NULL
    }
  )

  # cleanup
  unlink(temp_dir, recursive = TRUE)

  if (!is.null(pos_strat)) {
    names(pos_strat) <- .clean_names(names(pos_strat))
    pos_strat <- tibble::as_tibble(pos_strat)
  }

  pos_strat
}

#' Create survey design object with post-stratification
#' @noRd
.pof_create_survey_design <- function(data, year, cache_dir) {
  # check required packages
  if (!requireNamespace("survey", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg survey} is required. Install with: {.code install.packages('survey')}")
  }
  if (!requireNamespace("srvyr", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg srvyr} is required. Install with: {.code install.packages('srvyr')}")
  }

  # identify design variables in data
  # POF uses different variable names across years
  col_names <- toupper(names(data))

  # find weight variable
  weight_patterns <- c("PESO_FINAL", "PESO", "FATOR_ANUALIZACAO", "V9001")
  weight_var <- NULL
  for (pattern in weight_patterns) {
    if (pattern %in% col_names) {
      weight_var <- names(data)[toupper(names(data)) == pattern]
      break
    }
  }

  # find stratum variable
  strata_patterns <- c("ESTRATO_POF", "ESTRATO", "V0024")
  strata_var <- NULL
  for (pattern in strata_patterns) {
    if (pattern %in% col_names) {
      strata_var <- names(data)[toupper(names(data)) == pattern]
      break
    }
  }

  # find PSU variable
  psu_patterns <- c("COD_UPA", "UPA", "V0001")
  psu_var <- NULL
  for (pattern in psu_patterns) {
    if (pattern %in% col_names) {
      psu_var <- names(data)[toupper(names(data)) == pattern]
      break
    }
  }

  # check if required variables are found
  if (is.null(weight_var) || is.null(strata_var) || is.null(psu_var)) {
    missing <- c(
      if (is.null(weight_var)) "weight" else NULL,
      if (is.null(strata_var)) "stratum" else NULL,
      if (is.null(psu_var)) "PSU" else NULL
    )
    cli::cli_abort(c(
      "Missing required variables for survey design.",
      "x" = "Could not identify: {.val {missing}}",
      "i" = "Make sure you're using the 'morador' or 'domicilio' register."
    ))
  }

  cli::cli_inform("Creating survey design with: weight={.val {weight_var}}, strata={.val {strata_var}}, psu={.val {psu_var}}")

  # create formula objects
  weight_formula <- stats::as.formula(paste0("~", weight_var))
  strata_formula <- stats::as.formula(paste0("~", strata_var))
  psu_formula <- stats::as.formula(paste0("~", psu_var))

  # create survey design
  pof_design <- survey::svydesign(
    id = psu_formula,
    strata = strata_formula,
    weights = weight_formula,
    data = data,
    nest = TRUE
  )

  # try to apply post-stratification if available
  pos_strat <- .pof_download_post_strat(year, cache_dir)

  if (!is.null(pos_strat)) {
    # note: post-stratification requires matching variables
    # this is a simplified implementation
    cli::cli_inform("Post-stratification totals available but not automatically applied.")
    cli::cli_inform("For full calibration, see POF documentation.")
  }

  # convert to srvyr
  srvyr::as_survey_design(pof_design)
}

# ============================================================================
# public api functions - basic info
# ============================================================================

#' List available POF survey years
#'
#' Returns a character vector with available POF survey years.
#'
#' @return A character vector of available years in "YYYY-YYYY" format.
#'
#' @export
#'
#' @family pof
#'
#' @examples
#' pof_years()
pof_years <- function() {
  c("2002-2003", "2008-2009", "2017-2018")
}

#' Get POF survey information
#'
#' Returns metadata about the POF survey edition including available
#' health modules and sampling design information.
#'
#' @param year Character. POF edition (e.g., "2017-2018"). Default is "2017-2018".
#'
#' @return A list with survey metadata (invisibly).
#'
#' @export
#'
#' @family pof
#'
#' @seealso \code{\link{pof_years}}, \code{\link{pof_data}}
#'
#' @examples
#' pof_info()
#' pof_info("2017-2018")
#' pof_info("2008-2009")
pof_info <- function(year = "2017-2018") {
  # validate year
  .pof_validate_year(year)

  info <- list(
    name = "Pesquisa de Or\u00e7amentos Familiares",
    name_en = "Household Budget Survey",
    acronym = "POF",
    source = "IBGE",
    year = year,
    description = "Pesquisa sobre or\u00e7amentos dom\u00e9sticos, condi\u00e7\u00f5es de vida e perfil nutricional",
    url = "https://www.ibge.gov.br/estatisticas/sociais/saude/24786-pesquisa-de-orcamentos-familiares-2.html",
    ftp_url = "https://ftp.ibge.gov.br/Orcamentos_Familiares/",
    available_registers = pof_valid_registers[[year]],
    health_modules = list(
      ebia = list(
        available = year == "2017-2018",
        register = "domicilio",
        variable = "V6199",
        description = "Escala Brasileira de Inseguran\u00e7a Alimentar"
      ),
      antropometria = list(
        available = year == "2008-2009",
        register = "morador",
        description = "Peso, altura e estado nutricional"
      ),
      consumo_alimentar = list(
        available = year %in% c("2008-2009", "2017-2018"),
        register = "consumo_alimentar",
        description = "Consumo alimentar pessoal detalhado (subamostra)"
      ),
      despesas_saude = list(
        available = TRUE,
        register = "despesa_individual",
        description = "Gastos com medicamentos, planos de sa\u00fade, consultas"
      )
    ),
    sample_design = list(
      type = "Amostragem conglomerada em dois est\u00e1gios com estratifica\u00e7\u00e3o",
      weight_var = "PESO_FINAL",
      strata_var = "ESTRATO_POF",
      psu_var = "COD_UPA",
      post_stratification = TRUE
    )
  )

  # year-specific information
  year_details <- list(
    "2017-2018" = list(
      sample_size = "approximately 58,000 households",
      reference_period = "July 2017 - July 2018",
      notes = "Latest edition with EBIA and detailed food consumption"
    ),
    "2008-2009" = list(
      sample_size = "approximately 56,000 households",
      reference_period = "May 2008 - May 2009",
      notes = "Includes anthropometry module"
    ),
    "2002-2003" = list(
      sample_size = "approximately 48,000 households",
      reference_period = "July 2002 - June 2003",
      notes = "First edition with microdata in current format"
    )
  )

  info$year_details <- year_details[[year]]

  # print summary
  cli::cli_h1("POF {year}")
  cli::cli_text("{info$description}")
  cli::cli_text("")
  cli::cli_text("Registros dispon\u00edveis: {.val {info$available_registers}}")
  cli::cli_text("")
  cli::cli_h2("M\u00f3dulos de sa\u00fade")

  for (mod_name in names(info$health_modules)) {
    mod <- info$health_modules[[mod_name]]
    status <- if (mod$available) cli::col_green("\u2713") else cli::col_red("\u2717")
    cli::cli_text("{status} {mod_name}: {mod$description}")
  }

  if (!is.null(info$year_details)) {
    cli::cli_text("")
    cli::cli_h2("Detalhes da edi\u00e7\u00e3o")
    cli::cli_alert_info("Sample size: {info$year_details$sample_size}")
    cli::cli_alert_info("Reference period: {info$year_details$reference_period}")
    if (!is.null(info$year_details$notes)) {
      cli::cli_alert_info("Notes: {info$year_details$notes}")
    }
  }

  cli::cli_text("")
  cli::cli_text("URL: {.url {info$url}}")
  cli::cli_text("FTP: {.url {info$ftp_url}}")

  invisible(info)
}

#' List POF registers
#'
#' Returns information about the data registers available in the POF.
#'
#' @param year Character. POF edition (e.g., "2017-2018").
#'   Default is "2017-2018".
#' @param health_only Logical. If TRUE, returns only health-related registers.
#'   Default is FALSE.
#'
#' @return A tibble with register names and descriptions.
#'
#' @export
#'
#' @family pof
#'
#' @examples
#' pof_registers()
#' pof_registers("2017-2018", health_only = TRUE)
pof_registers <- function(year = "2017-2018", health_only = FALSE) {
  .pof_validate_year(year)

  # register descriptions
  register_info <- tibble::tibble(
    register = c(
      "domicilio", "morador", "caderneta_coletiva", "despesa_individual",
      "consumo_alimentar", "rendimento", "inventario", "despesa_coletiva",
      "aluguel_estimado", "outros_rendimentos", "despesa_90dias", "despesa_12meses"
    ),
    description = c(
      "Caracter\u00edsticas do domic\u00edlio, saneamento, EBIA (2017-2018)",
      "Dados dos moradores, demografia, pesos amostrais",
      "Aquisi\u00e7\u00e3o alimentar domiciliar",
      "Despesas individuais (inclui sa\u00fade)",
      "Consumo alimentar pessoal detalhado (subamostra)",
      "Rendimentos dos moradores",
      "Bens dur\u00e1veis do domic\u00edlio",
      "Despesas coletivas do domic\u00edlio",
      "Aluguel estimado para domic\u00edlios pr\u00f3prios",
      "Outros rendimentos n\u00e3o monet\u00e1rios",
      "Despesas com per\u00edodo de refer\u00eancia de 90 dias",
      "Despesas com per\u00edodo de refer\u00eancia de 12 meses"
    ),
    health_related = c(
      TRUE, TRUE, TRUE, TRUE,
      TRUE, FALSE, FALSE, FALSE,
      FALSE, FALSE, FALSE, FALSE
    )
  )

  # filter by year availability
  available <- pof_valid_registers[[year]]
  result <- register_info |>
    dplyr::filter(.data$register %in% available)

  # filter by health relevance
  if (health_only) {
    result <- result |>
      dplyr::filter(.data$health_related)
  }

  result
}

# ============================================================================
# public api functions - dictionary
# ============================================================================

#' Get POF variable dictionary
#'
#' Downloads and returns the variable dictionary for POF microdata.
#' The dictionary is cached locally to avoid repeated downloads.
#'
#' @param year Character. POF edition (e.g., "2017-2018"). Default is "2017-2018".
#' @param register Character. Register name. If NULL, returns all registers.
#'   Default is NULL.
#' @param cache_dir Character. Directory for caching downloaded files.
#'   Default uses `tools::R_user_dir("healthbR", "cache")`.
#' @param refresh Logical. If TRUE, re-download even if file exists in cache.
#'   Default is FALSE.
#'
#' @return A tibble with variable definitions including: variable, description,
#'   position, length, decimals, register.
#'
#' @export
#'
#' @family pof
#'
#' @seealso \code{\link{pof_variables}}, \code{\link{pof_data}}
#'
#' @examplesIf interactive()
#' pof_dictionary("2017-2018", "morador", cache_dir = tempdir())
pof_dictionary <- function(year = "2017-2018",
                           register = NULL,
                           cache_dir = NULL,
                           refresh = FALSE) {
  # validate year
  .pof_validate_year(year)

  # validate register early (before download)
  if (!is.null(register)) {
    .pof_validate_register(register, year)
  }

  # set cache directory
  cache_dir <- pof_cache_dir(cache_dir)

  # check cache first
  cache_file <- file.path(cache_dir, stringr::str_c("pof_dictionary_", year, ".rds"))

  if (file.exists(cache_file) && !refresh) {
    cli::cli_inform("Loading dictionary from cache...")
    dict <- readRDS(cache_file)
  } else {
    # download and parse dictionary
    cli::cli_inform("Downloading POF dictionary...")
    dict <- .pof_download_and_parse_dictionary(year, cache_dir)

    # save to cache
    saveRDS(dict, cache_file)
    cli::cli_alert_success("Dictionary cached: {.file {cache_file}}")
  }

  # filter by register if specified (use base R to avoid dplyr data masking)
  if (!is.null(register)) {
    dict <- dict[tolower(dict$register) == tolower(register), ]
  }

  dict
}

#' List POF variables
#'
#' Returns a list of available variables in the POF microdata with their labels.
#' This is a convenience wrapper around \code{\link{pof_dictionary}} that
#' returns a simplified view.
#'
#' @param year Character. POF edition (e.g., "2017-2018"). Default is "2017-2018".
#' @param register Character. Register name (e.g., "morador", "domicilio").
#'   If NULL, returns variables from all registers. Default is NULL.
#' @param search Character. Optional search term to filter variables by name
#'   or description. Default is NULL.
#' @param cache_dir Character. Directory for caching downloaded files.
#'   Default uses `tools::R_user_dir("healthbR", "cache")`.
#' @param refresh Logical. If TRUE, re-download even if file exists in cache.
#'   Default is FALSE.
#'
#' @return A tibble with columns: variable, description, position, length, register.
#'
#' @export
#'
#' @family pof
#'
#' @seealso \code{\link{pof_dictionary}}, \code{\link{pof_data}}
#'
#' @examplesIf interactive()
#' pof_variables("2017-2018", "morador", cache_dir = tempdir())
#' pof_variables("2017-2018", "domicilio", search = "ebia", cache_dir = tempdir())
pof_variables <- function(year = "2017-2018",
                          register = NULL,
                          search = NULL,
                          cache_dir = NULL,
                          refresh = FALSE) {
  # validate parameters
  .pof_validate_year(year)
  if (!is.null(register)) {
    .pof_validate_register(register, year)
  }

  # load dictionary
  dict <- pof_dictionary(year, register, cache_dir, refresh)

  # filter by search term if provided
  if (!is.null(search)) {
    search_lower <- tolower(search)
    dict <- dict |>
      dplyr::filter(
        stringr::str_detect(tolower(.data$variable), search_lower) |
          stringr::str_detect(tolower(.data$description), search_lower)
      )

    if (nrow(dict) == 0) {
      cli::cli_alert_warning("No variables found matching '{search}'")
    } else {
      cli::cli_alert_info("Found {nrow(dict)} variable(s) matching '{search}'")
    }
  }

  # return simplified view
  cols_to_select <- intersect(
    c("variable", "description", "position", "length", "register"),
    names(dict)
  )

  dict |>
    dplyr::select(dplyr::all_of(cols_to_select)) |>
    dplyr::distinct()
}

# ============================================================================
# public api functions - data
# ============================================================================

#' Download and import POF microdata
#'
#' Downloads POF microdata from IBGE FTP and returns as a tibble.
#' Data is cached locally to avoid repeated downloads.
#'
#' @param year Character. POF edition (e.g., "2017-2018"). Default is "2017-2018".
#' @param register Character. Which register to download.
#'   Use \code{pof_registers()} to see available options.
#'   Default is "morador".
#' @param vars Character vector. Optional: specific variables to select.
#'   If NULL, returns all variables from the register. Default is NULL.
#' @param cache_dir Character. Directory for caching downloaded files.
#'   Default uses `tools::R_user_dir("healthbR", "cache")`.
#' @param as_survey Logical. If TRUE, returns survey design object.
#'   Requires srvyr package. Default is FALSE.
#' @param refresh Logical. If TRUE, re-download even if file exists in cache.
#'   Default is FALSE.
#'
#' @param lazy Logical. If TRUE, returns a lazy query object instead of a
#'   tibble. Requires the \pkg{arrow} package. The lazy object supports
#'   dplyr verbs (filter, select, mutate, etc.) which are pushed down
#'   to the query engine before collecting into memory. Call
#'   \code{dplyr::collect()} to materialize the result. Default: FALSE.
#' @param backend Character. Backend for lazy evaluation: \code{"arrow"}
#'   (default) or \code{"duckdb"}. Only used when \code{lazy = TRUE}.
#'   DuckDB backend requires the \pkg{duckdb} package.
#'
#' @return A tibble with microdata, or tbl_svy if as_survey = TRUE.
#'
#' @details
#' The POF (Pesquisa de Orcamentos Familiares) is a household survey conducted
#' by IBGE that investigates household budgets, living conditions, and
#' nutritional profiles of the Brazilian population.
#'
#' ## Health-related data
#'
#' The POF contains several health-related modules:
#' - **EBIA** (Food Security Scale): Available in 2017-2018, variable V6199
#'   in the domicilio register
#' - **Food Consumption**: Detailed food consumption data in the
#'   consumo_alimentar register (2008-2009, 2017-2018)
#' - **Health Expenses**: Expenses with medications, health insurance,
#'   consultations in the despesa_individual register
#' - **Anthropometry**: Weight, height, BMI in morador register (2008-2009 only)
#'
#' ## Survey design
#'
#' For proper statistical analysis with complex survey design, use
#' `as_survey = TRUE` which creates a survey design object with:
#' - Weight variable: PESO_FINAL
#' - Stratum variable: ESTRATO_POF
#' - PSU variable: COD_UPA
#'
#' @section Data source:
#' Data is downloaded from the IBGE FTP server:
#' \verb{https://ftp.ibge.gov.br/Orcamentos_Familiares/}
#'
#' @export
#'
#' @family pof
#'
#' @seealso \code{\link{pof_years}}, \code{\link{pof_info}},
#'   \code{\link{pof_registers}}, \code{\link{pof_variables}}
#'
#' @examplesIf interactive()
#' # basic usage - download morador register
#' morador <- pof_data("2017-2018", "morador", cache_dir = tempdir())
#'
#' # download domicilio register (includes EBIA)
#' domicilio <- pof_data("2017-2018", "domicilio", cache_dir = tempdir())
#'
#' # select specific variables
#' df <- pof_data(
#'   "2017-2018", "morador",
#'   vars = c("COD_UPA", "ESTRATO_POF", "PESO_FINAL", "V0403"),
#'   cache_dir = tempdir()
#' )
#'
#' # with survey design (requires srvyr package)
#' morador_svy <- pof_data("2017-2018", "morador", as_survey = TRUE,
#'                          cache_dir = tempdir())
pof_data <- function(year = "2017-2018",
                     register = "morador",
                     vars = NULL,
                     cache_dir = NULL,
                     as_survey = FALSE,
                     refresh = FALSE,
                     lazy = FALSE, backend = c("arrow", "duckdb")) {
  # 1. validate parameters
  .pof_validate_year(year)
  .pof_validate_register(register, year)

  # 2. check if srvyr is available when as_survey = TRUE
  if (as_survey) {
    if (!requireNamespace("srvyr", quietly = TRUE)) {
      cli::cli_abort(c(
        "Package {.pkg srvyr} is required for survey analysis.",
        "i" = "Install with: {.code install.packages('srvyr')}"
      ))
    }
  }

  # 3. set cache directory
  cache_dir <- pof_cache_dir(cache_dir)
  dataset_name <- stringr::str_c("pof_", register, "_data")
  df <- NULL

  # lazy evaluation: return from partitioned cache if available
  if (isTRUE(lazy)) {
    backend <- match.arg(backend)
    cache_dir_resolved <- .module_cache_dir("pof", cache_dir)
    ds_name <- stringr::str_c("pof_", register, "_data")
    select_cols <- if (!is.null(vars)) unique(c("year", vars)) else NULL
    ds <- .lazy_return(cache_dir_resolved, ds_name, backend,
                       filters = list(year = year),
                       select_cols = select_cols)
    if (!is.null(ds)) return(ds)
  }

  # 4. check partitioned cache first (preferred path)
  if (!refresh && .has_arrow() &&
      .has_partitioned_cache(cache_dir, dataset_name)) {
    ds <- arrow::open_dataset(file.path(cache_dir, dataset_name))
    cached <- ds |>
      dplyr::filter(.data$year == !!year) |>
      dplyr::collect()
    if (nrow(cached) > 0) {
      cli::cli_inform("Loading {register} data from cache...")
      df <- cached
    }
  }

  # 5. download data if not cached
  if (is.null(df)) {
    cli::cli_inform("Downloading POF {year} {register} data...")

    # download zip file
    zip_path <- .pof_download_data(year, cache_dir)

    # get dictionary for this register
    dict <- pof_dictionary(year, register, cache_dir)

    # read fixed-width file
    df <- .pof_read_fwf(zip_path, register, dict, year)

    # add year column
    df <- df |>
      dplyr::mutate(year = year, .before = 1)

    # write to partitioned cache
    .cache_append_partitioned(df, cache_dir, dataset_name, c("year"))
  }

  # if lazy was requested, return from cache after download
  if (isTRUE(lazy)) {
    backend <- match.arg(backend)
    cache_dir_resolved <- .module_cache_dir("pof", cache_dir)
    ds_name <- stringr::str_c("pof_", register, "_data")
    select_cols <- if (!is.null(vars)) unique(c("year", vars)) else NULL
    ds <- .lazy_return(cache_dir_resolved, ds_name, backend,
                       filters = list(year = year),
                       select_cols = select_cols)
    if (!is.null(ds)) return(ds)
  }

  # 7. select specific variables if requested
  if (!is.null(vars)) {
    # always include design variables and year
    design_vars <- c("COD_UPA", "ESTRATO_POF", "PESO_FINAL", "UF")
    all_vars <- unique(c(design_vars, toupper(vars)))
    # also include year column if present (lowercase)
    year_col <- if ("year" %in% names(df)) "year" else NULL

    # find matching columns (case-insensitive)
    col_names_upper <- toupper(names(df))
    available_vars <- names(df)[col_names_upper %in% all_vars]

    missing <- setdiff(all_vars, col_names_upper)
    if (length(missing) > 0) {
      cli::cli_warn("Variables not found: {.val {missing}}")
    }

    available_vars <- unique(c(year_col, available_vars))
    df <- df |>
      dplyr::select(dplyr::all_of(available_vars))
  }

  # 8. report
  cli::cli_alert_success(
    "Loaded {.val {nrow(df)}} observations from POF {year} {register}"
  )

  # 9. apply survey design if requested
  if (as_survey) {
    df <- .pof_create_survey_design(df, year, cache_dir)
  }

  df
}

# ============================================================================
# cache management functions
# ============================================================================

#' Clear POF cache
#'
#' Removes all cached POF data files.
#'
#' @param cache_dir Character. Optional custom cache directory. If NULL (default),
#'   uses the standard user cache directory.
#'
#' @return NULL (invisibly)
#'
#' @export
#'
#' @family pof
#'
#' @examples
#' pof_clear_cache()
pof_clear_cache <- function(cache_dir = NULL) {
  cache_dir <- pof_cache_dir(cache_dir)

  # list all files
  files <- list.files(cache_dir, full.names = TRUE, recursive = TRUE)

  if (length(files) == 0) {
    cli::cli_alert_info("Cache is already empty")
    return(invisible(NULL))
  }

  # remove all files
  unlink(cache_dir, recursive = TRUE)
  dir.create(cache_dir, recursive = TRUE)

  cli::cli_alert_success("POF cache cleared")

  invisible(NULL)
}

#' Get POF cache status
#'
#' Shows cache status including downloaded files and their sizes.
#'
#' @param cache_dir Character. Optional custom cache directory. If NULL (default),
#'   uses the standard user cache directory.
#'
#' @return A tibble with cache information
#'
#' @export
#'
#' @family pof
#'
#' @examples
#' pof_cache_status()
pof_cache_status <- function(cache_dir = NULL) {
  cache_dir <- pof_cache_dir(cache_dir)

  # list all files
  files <- list.files(cache_dir, full.names = TRUE, recursive = FALSE)

  if (length(files) == 0) {
    cli::cli_alert_info("Cache is empty")
    return(tibble::tibble(
      file = character(),
      size_mb = numeric(),
      modified = as.POSIXct(character())
    ))
  }

  # get file info
  file_info <- file.info(files)

  result <- tibble::tibble(
    file = basename(files),
    size_mb = round(file_info$size / 1024^2, 1),
    modified = file_info$mtime
  )

  # print summary
  total_size <- sum(result$size_mb)
  cli::cli_alert_info("POF cache: {nrow(result)} file(s), {round(total_size, 1)} MB total")

  result
}
