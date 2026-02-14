# pnadc functions for healthbR package
# functions to download and process PNAD Continua (IBGE) data
# includes microdata access via FTP for health-related supplementary modules

# global variables for NSE
utils::globalVariables(c("UPA", "Estrato", "V1028"))

# ============================================================================
# internal constants and data
# ============================================================================

#' PNADC module registry
#' @noRd
pnadc_module_registry <- list(
  deficiencia = list(
    name = "Pessoas com Defici\u00eancia",
    name_en = "Persons with Disabilities",
    years = c(2019L, 2022L, 2024L),
    quarter = 3L,
    path_type = "trimestre",
    prefix = "S11",
    description = paste0(
      "M\u00f3dulo suplementar sobre caracter\u00edsticas das pessoas com ",
      "defici\u00eancia, incluindo tipos de defici\u00eancia, grau de dificuldade ",
      "e uso de recursos de acessibilidade."
    )
  ),
  habitacao = list(
    name = "Caracter\u00edsticas da Habita\u00e7\u00e3o",
    name_en = "Housing Characteristics",
    years = c(2012L:2019L, 2022L:2024L),
    quarter = NULL,
    path_type = "visita",
    prefix = "S01",
    description = paste0(
      "M\u00f3dulo sobre caracter\u00edsticas do domic\u00edlio, incluindo ",
      "condi\u00e7\u00f5es de moradia, saneamento, e acesso a servi\u00e7os."
    )
  ),
  moradores = list(
    name = "Caracter\u00edsticas Gerais dos Moradores",
    name_en = "General Characteristics of Residents",
    years = c(2012L:2019L, 2022L:2024L),
    quarter = NULL,
    path_type = "visita",
    prefix = c("V", "VD"),
    description = paste0(
      "M\u00f3dulo com caracter\u00edsticas gerais dos moradores, incluindo ",
      "dados demogr\u00e1ficos, educa\u00e7\u00e3o e rendimento."
    )
  ),
  aps = list(
    name = "Aten\u00e7\u00e3o Prim\u00e1ria \u00e0 Sa\u00fade",
    name_en = "Primary Health Care",
    years = 2022L,
    quarter = 2L,
    path_type = "trimestre",
    prefix = "S12",
    description = paste0(
      "M\u00f3dulo suplementar sobre acesso e utiliza\u00e7\u00e3o da aten\u00e7\u00e3o ",
      "prim\u00e1ria \u00e0 sa\u00fade, incluindo Estrat\u00e9gia Sa\u00fade da Fam\u00edlia."
    )
  )
)

#' PNADC base URLs
#' @noRd
pnadc_base_url <- function() {
  "https://ftp.ibge.gov.br/Trabalho_e_Rendimento/Pesquisa_Nacional_por_Amostra_de_Domicilios_continua/"
}

#' PNADC required variables (always included in downloads)
#' @noRd
pnadc_required_vars <- function() {
  c(
    # identification
    "Ano", "Trimestre", "UF", "Capital", "RM_RIDE", "V1008", "V1014",
    # demographics
    "V2007", "V2009", "V2010",
    # survey design
    "UPA", "Estrato", "V1028", "V1027"
  )
}

# ============================================================================
# internal helper functions
# ============================================================================

#' Check if srvyr package is available
#' @noRd
pnadc_has_srvyr <- function() {
  requireNamespace("srvyr", quietly = TRUE)
}

#' Get PNADC cache directory
#' @noRd
pnadc_cache_dir <- function(cache_dir = NULL) {
  .module_cache_dir("pnadc", cache_dir)
}

#' Validate PNADC module parameter
#' @noRd
validate_pnadc_module <- function(module) {
  available <- names(pnadc_module_registry)

  if (is.null(module) || length(module) != 1) {
    cli::cli_abort(c(
      "Module must be specified",
      "i" = "Available modules: {.val {available}}",
      "i" = "Use {.fn pnadc_modules} to see all available modules"
    ))
  }

  module <- tolower(module)

  if (!module %in% available) {
    cli::cli_abort(c(
      "Invalid module: {.val {module}}",
      "i" = "Available modules: {.val {available}}",
      "i" = "Use {.fn pnadc_modules} to see all available modules"
    ))
  }

  module
}

#' Validate PNADC year parameter for a given module
#' @noRd
validate_pnadc_year <- function(year, module) {
  module_info <- pnadc_module_registry[[module]]
  available <- module_info$years

  if (is.null(year)) {
    return(available)
  }

  year <- as.integer(year)
  invalid <- year[!year %in% available]

  if (length(invalid) > 0) {
    invalid_str <- paste(invalid, collapse = ", ")
    available_str <- paste(available, collapse = ", ")
    cli::cli_abort(c(
      "Invalid year(s) for module '{module}': {invalid_str}",
      "i" = "Available years: {available_str}"
    ))
  }

  year
}

#' List files in IBGE FTP directory
#' @noRd
pnadc_list_ftp_files <- function(url, extension = "zip") {
  # fetch directory listing
  response <- tryCatch(
    {
      handle <- curl::new_handle(timeout = 30)
      curl::curl_fetch_memory(url, handle = handle)
    },
    error = function(e) {
      return(NULL)
    }
  )

  if (is.null(response) || response$status_code != 200) {
    return(character(0))
  }

  # parse HTML to extract filenames
  content <- rawToChar(response$content)
  Encoding(content) <- "UTF-8"

  # extract href links that match the extension
  pattern <- paste0('href="([^"]+\\.', extension, ')"')
  matches <- stringr::str_extract_all(content, pattern)[[1]]

  # extract just the filename
  filenames <- stringr::str_replace(matches, 'href="([^"]+)"', "\\1")

  filenames
}

#' Find data and input file URLs for a specific module and year
#' @noRd
pnadc_find_data_url <- function(module, year) {
  module_info <- pnadc_module_registry[[module]]
  base <- pnadc_base_url()

  if (module_info$path_type == "visita") {
    data_dir_url <- stringr::str_c(
      base,
      "Anual/Microdados/Visita/Visita_1/Dados/"
    )
    doc_dir_url <- stringr::str_c(
      base,
      "Anual/Microdados/Visita/Visita_1/Documentacao/"
    )
    data_pattern <- stringr::str_c("PNADC_", year, "_visita1")
    # Visita input files are year-specific (e.g., input_PNADC_2022_visita1_*.txt)
    # For years 2012-2014, there's a combined file: input_PNADC_2012_a_2014_visita1_*.txt
    if (year %in% 2012:2014) {
      input_pattern <- "input_PNADC_2012_a_2014_visita1"
    } else {
      input_pattern <- stringr::str_c("input_PNADC_", year, "_visita1")
    }
  } else if (module_info$path_type == "trimestre") {
    quarter <- module_info$quarter
    data_dir_url <- stringr::str_c(
      base,
      "Anual/Microdados/Trimestre/Trimestre_", quarter, "/Dados/"
    )
    doc_dir_url <- stringr::str_c(
      base,
      "Anual/Microdados/Trimestre/Trimestre_", quarter, "/Documentacao/"
    )
    data_pattern <- stringr::str_c("PNADC_", year, "_trimestre", quarter)
    input_pattern <- stringr::str_c("input_PNADC_trimestre", quarter)
  } else {
    cli::cli_abort("Unknown path_type for module: {module}")
  }

  # list files in data directory
  data_files <- pnadc_list_ftp_files(data_dir_url)

  if (length(data_files) == 0) {
    cli::cli_abort(c(
      "Could not list files in FTP directory",
      "i" = "URL: {.url {data_dir_url}}",
      "i" = "Check your internet connection"
    ))
  }

  # find matching data file
  matching_data <- data_files[stringr::str_detect(data_files, data_pattern)]

  if (length(matching_data) == 0) {
    cli::cli_abort(c(
      "No data file found for {module} {year}",
      "i" = "Pattern: {data_pattern}",
      "i" = "Available files: {.val {basename(data_files)}}"
    ))
  }

  # use the most recent data file
  data_filename <- matching_data[length(matching_data)]

  # list files in documentation directory (txt files for input specs)
  doc_files <- pnadc_list_ftp_files(doc_dir_url, extension = "txt")

  # find matching input file
  matching_input <- doc_files[stringr::str_detect(doc_files, input_pattern)]

  input_url <- NULL
  input_filename <- NULL
  if (length(matching_input) > 0) {
    input_filename <- matching_input[length(matching_input)]
    input_url <- stringr::str_c(doc_dir_url, input_filename)
  }

  list(
    data_url = stringr::str_c(data_dir_url, data_filename),
    data_dir_url = data_dir_url,
    data_filename = data_filename,
    input_url = input_url,
    input_filename = input_filename,
    doc_dir_url = doc_dir_url
  )
}

#' Download PNADC file from FTP
#' @noRd
pnadc_download_file <- function(url, destfile, refresh = FALSE) {
  if (file.exists(destfile) && !refresh) {
    cli::cli_alert_info("Using cached file: {.file {basename(destfile)}}")
    return(invisible(destfile))
  }

  cli::cli_inform("Downloading from IBGE FTP...")
  cli::cli_inform("URL: {.url {url}}")
  cli::cli_inform("This may take a few minutes...")

  tryCatch(
    {
      curl::curl_download(url, destfile, quiet = FALSE)
      cli::cli_alert_success("Download complete: {.file {basename(destfile)}}")
    },
    error = function(e) {
      if (file.exists(destfile)) file.remove(destfile)
      cli::cli_abort(c(
        "Download failed: {e$message}",
        "i" = "URL: {.url {url}}",
        "i" = "Check your internet connection or try again later"
      ))
    }
  )

  invisible(destfile)
}

#' Parse IBGE input file for fixed-width format
#' @noRd
pnadc_parse_input_file <- function(input_file) {
  # read input file (IBGE files use LATIN1 encoding)
  input_lines <- readr::read_lines(
    input_file,
    locale = readr::locale(encoding = "LATIN1")
  )

  # IBGE input file format:
  # @position variable $format.
  # or @position variable format.
  spec_lines <- input_lines[grepl("^\\s*@", input_lines)]

  if (length(spec_lines) == 0) {
    cli::cli_abort(c(
      "Could not parse input file format",
      "i" = "File: {.file {input_file}}"
    ))
  }

  # parse specifications
  col_specs <- purrr::map(spec_lines, function(line) {
    # remove leading/trailing whitespace
    line <- stringr::str_trim(line)

    # extract @position variable format
    # handles: @1 UF $2. (character) or @1 UF 2. (numeric)
    # The $ indicates character type
    parts <- stringr::str_match(line, "@(\\d+)\\s+(\\S+)\\s+(\\$?)(\\d+)")

    if (is.na(parts[1, 1])) {
      return(NULL)
    }

    list(
      start = as.integer(parts[1, 2]),
      name = parts[1, 3],
      is_char = parts[1, 4] == "$",
      width = as.integer(parts[1, 5])
    )
  })

  col_specs <- purrr::compact(col_specs)

  if (length(col_specs) == 0) {
    cli::cli_abort("Could not parse column specifications from input file")
  }

  col_specs
}

#' Read PNADC fixed-width format data
#' @noRd
pnadc_read_fwf <- function(data_file, input_file) {
  cli::cli_inform("Parsing input file for column specifications...")
  col_specs <- pnadc_parse_input_file(input_file)

  cli::cli_inform("Reading fixed-width data ({length(col_specs)} columns)...")

  # create fwf_positions
  positions <- readr::fwf_positions(
    start = purrr::map_int(col_specs, "start"),
    end = purrr::map_int(col_specs, ~ .x$start + .x$width - 1),
    col_names = purrr::map_chr(col_specs, "name")
  )

  # create column types: c = character, d = double (numeric)
  col_types <- paste0(
    purrr::map_chr(col_specs, ~ if (.x$is_char) "c" else "d"),
    collapse = ""
  )

  readr::read_fwf(
    data_file,
    col_positions = positions,
    col_types = col_types,
    locale = readr::locale(encoding = "LATIN1"),
    progress = TRUE
  )
}

#' Read PNADC data from ZIP file using separate input file
#' @noRd
pnadc_read_zip <- function(zip_path, input_path, module, year) {
  cli::cli_inform("Extracting and reading PNADC {module} {year} data...")

  # create temp directory for extraction
  temp_dir <- file.path(tempdir(), paste0("pnadc_", module, "_", year))
  if (dir.exists(temp_dir)) {
    unlink(temp_dir, recursive = TRUE)
  }
  dir.create(temp_dir)

  # extract ZIP
  utils::unzip(zip_path, exdir = temp_dir)

  # find extracted files
  extracted_files <- list.files(temp_dir, recursive = TRUE, full.names = TRUE)

  # look for data file (TXT)
  txt_files <- extracted_files[grepl("\\.txt$", extracted_files, ignore.case = TRUE)]
  # exclude input/documentation files
  data_files <- txt_files[!grepl("input|dicionario|leitura", txt_files, ignore.case = TRUE)]

  if (length(data_files) == 0) {
    # cleanup and abort
    unlink(temp_dir, recursive = TRUE)
    cli::cli_abort(c(
      "Could not find data file in PNADC {module} {year} archive",
      "i" = "Files found: {.val {basename(extracted_files)}}"
    ))
  }

  # read data with externally provided input file
  data <- pnadc_read_fwf(data_files[1], input_path)

  # cleanup temp directory
  unlink(temp_dir, recursive = TRUE)

  tibble::as_tibble(data)
}

#' Apply survey design to PNADC data
#' @noRd
pnadc_apply_survey_design <- function(data) {
  if (!pnadc_has_srvyr()) {
    cli::cli_abort(c(
      "Package {.pkg srvyr} is required for survey design",
      "i" = "Install with: {.code install.packages('srvyr')}"
    ))
  }

  # check required variables
  required_design_vars <- c("UPA", "Estrato", "V1028")
  missing <- setdiff(required_design_vars, names(data))

  if (length(missing) > 0) {
    missing_str <- paste(missing, collapse = ", ")
    cli::cli_abort(c(
      "Missing survey design variables: {missing_str}",
      "i" = "These variables are required for survey design"
    ))
  }

  cli::cli_inform("Applying survey design (PSU: UPA, Strata: Estrato, Weight: V1028)...")

  # create survey design using srvyr
  svy <- srvyr::as_survey_design(
    data,
    ids = UPA,
    strata = Estrato,
    weights = V1028,
    nest = TRUE
  )

  svy
}

# ============================================================================
# public api functions - basic info
# ============================================================================

#' List available PNADC modules
#'
#' Returns information about the available supplementary modules in PNAD Continua
#' that are supported by this package.
#'
#' @return A tibble with module information including name, available years,
#'   and descriptions.
#'
#' @export
#'
#' @examples
#' pnadc_modules()
pnadc_modules <- function() {
  modules <- purrr::imap(pnadc_module_registry, function(info, module_id) {
    tibble::tibble(
      module = module_id,
      name = info$name,
      name_en = info$name_en,
      years = list(info$years),
      quarter = info$quarter %||% NA_integer_,
      description = info$description
    )
  })

  dplyr::bind_rows(modules)
}

#' List available years for a PNADC module
#'
#' Returns a vector of years for which data is available for the specified module.
#'
#' @param module Character. The module identifier. Use \code{\link{pnadc_modules}}
#'   to see available modules.
#'
#' @return An integer vector of available years.
#'
#' @export
#'
#' @examples
#' pnadc_years("deficiencia")
#' pnadc_years("habitacao")
pnadc_years <- function(module) {
  module <- validate_pnadc_module(module)
  pnadc_module_registry[[module]]$years
}

#' PNADC survey information
#'
#' Displays information about PNAD Continua and returns metadata.
#'
#' @return Invisibly returns a list with survey metadata.
#'
#' @export
#'
#' @examples
#' pnadc_info()
pnadc_info <- function() {
  info <- list(
    name = "Pesquisa Nacional por Amostra de Domic\u00edlios Cont\u00ednua (PNAD Cont\u00ednua)",
    name_en = "Continuous National Household Sample Survey",
    institution = "IBGE - Instituto Brasileiro de Geografia e Estat\u00edstica",
    description = paste0(
      "A PNAD Cont\u00ednua \u00e9 uma pesquisa domiciliar que investiga caracter\u00edsticas ",
      "gerais da popula\u00e7\u00e3o, educa\u00e7\u00e3o, trabalho e rendimento. Al\u00e9m dos ",
      "temas permanentes, a pesquisa inclui suplementos tem\u00e1ticos sobre sa\u00fade, ",
      "defici\u00eancia, habita\u00e7\u00e3o e outros temas."
    ),
    url = "https://www.ibge.gov.br/estatisticas/sociais/trabalho/9171-pesquisa-nacional-por-amostra-de-domicilios-continua-mensal.html",
    ftp_url = pnadc_base_url(),
    modules = pnadc_modules(),
    survey_design = list(
      psu = "UPA",
      strata = "Estrato",
      weight = "V1028"
    ),
    citation = paste0(
      "IBGE - Instituto Brasileiro de Geografia e Estat\u00edstica. ",
      "Pesquisa Nacional por Amostra de Domic\u00edlios Cont\u00ednua. Rio de Janeiro: IBGE."
    )
  )

  # display information
  cli::cli_h1("PNAD Cont\u00ednua")
  cli::cli_text("")
  cli::cli_text(info$description)
  cli::cli_text("")
  cli::cli_alert_info("Institution: {info$institution}")
  cli::cli_text("")
  cli::cli_h2("Available Modules")

  modules <- info$modules
  for (i in seq_len(nrow(modules))) {
    m <- modules[i, ]
    years_str <- if (length(m$years[[1]]) > 2) {
      stringr::str_c(min(m$years[[1]]), "-", max(m$years[[1]]))
    } else {
      stringr::str_c(m$years[[1]], collapse = ", ")
    }
    cli::cli_alert("{.val {m$module}}: {m$name} ({years_str})")
  }

  cli::cli_text("")
  cli::cli_h2("Data access")
  cli::cli_alert("Microdata: {.fn pnadc_data}")
  cli::cli_alert("Dictionary: {.fn pnadc_dictionaries}")
  cli::cli_alert("Variables: {.fn pnadc_variables}")
  cli::cli_text("")
  cli::cli_text("URL: {.url {info$url}}")
  cli::cli_text("FTP: {.url {info$ftp_url}}")

  invisible(info)
}

# ============================================================================
# public api functions - dictionaries and variables
# ============================================================================

#' Download PNADC variable dictionary
#'
#' Downloads and returns the variable dictionary for PNADC microdata.
#' The dictionary is cached locally to avoid repeated downloads.
#'
#' @param module Character. The module identifier (e.g., "deficiencia", "habitacao").
#' @param year Numeric. Year to get dictionary for. Uses most recent year if NULL.
#' @param cache_dir Character. Directory for caching downloaded files.
#'   Default uses `tools::R_user_dir("healthbR", "cache")`.
#' @param refresh Logical. If TRUE, re-download even if file exists in cache.
#'   Default is FALSE.
#'
#' @return A tibble with variable definitions.
#'
#' @details
#' The dictionary includes variable names, positions, and widths from the
#' IBGE input specification file. This is useful for understanding the structure
#' of the data returned by \code{\link{pnadc_data}}.
#'
#' @section Data source:
#' Dictionaries are downloaded from the IBGE FTP server.
#'
#' @export
#'
#' @examplesIf interactive()
#' # get dictionary for deficiencia module
#' dict <- pnadc_dictionaries(module = "deficiencia", cache_dir = tempdir())
pnadc_dictionaries <- function(module,
                                year = NULL,
                                cache_dir = NULL,
                                refresh = FALSE) {
  # validate parameters
  module <- validate_pnadc_module(module)
  years <- validate_pnadc_year(year, module)

  if (length(years) > 1) {
    year <- max(years)
    cli::cli_inform("Using year {year} for dictionary (only one year at a time).")
  } else {
    year <- years[1]
  }

  # set cache directory
  cache_dir <- pnadc_cache_dir(cache_dir)

  # check for cached dictionary
  dict_cache_file <- file.path(cache_dir, paste0("pnadc_dict_", module, "_", year, ".rds"))

  if (file.exists(dict_cache_file) && !refresh) {
    cli::cli_inform("Loading PNADC {module} {year} dictionary from cache...")
    return(readRDS(dict_cache_file))
  }

  # find the correct URL for this module and year
  url_info <- pnadc_find_data_url(module, year)

  # download input file from documentation folder
  if (is.null(url_info$input_url)) {
    cli::cli_abort(c(
      "Could not find input specification file for {module} {year}",
      "i" = "Documentation URL: {.url {url_info$doc_dir_url}}"
    ))
  }
  input_path <- file.path(cache_dir, url_info$input_filename)
  pnadc_download_file(url_info$input_url, input_path, refresh)

  # parse input file
  col_specs <- pnadc_parse_input_file(input_path)

  # create tibble
  dict_df <- tibble::tibble(
    year = as.integer(year),
    module = module,
    position = purrr::map_int(col_specs, "start"),
    variable = purrr::map_chr(col_specs, "name"),
    width = purrr::map_int(col_specs, "width")
  )

  # save to cache
  saveRDS(dict_df, dict_cache_file)
  cli::cli_alert_success("Dictionary cached: {.file {basename(dict_cache_file)}}")

  dict_df
}

#' List PNADC variables
#'
#' Returns a list of available variables in the PNADC microdata for a given module.
#' This is a convenience wrapper around \code{\link{pnadc_dictionaries}}.
#'
#' @param module Character. The module identifier (e.g., "deficiencia", "habitacao").
#' @param year Numeric. Year to get variables for. Uses most recent year if NULL.
#' @param cache_dir Character. Directory for caching downloaded files.
#'   Default uses `tools::R_user_dir("healthbR", "cache")`.
#' @param refresh Logical. If TRUE, re-download even if file exists in cache.
#'   Default is FALSE.
#'
#' @return A character vector of variable names.
#'
#' @export
#'
#' @examplesIf interactive()
#' # list variables for deficiencia module
#' pnadc_variables(module = "deficiencia", cache_dir = tempdir())
pnadc_variables <- function(module,
                             year = NULL,
                             cache_dir = NULL,
                             refresh = FALSE) {
  dict <- pnadc_dictionaries(
    module = module,
    year = year,
    cache_dir = cache_dir,
    refresh = refresh
  )

  dict$variable
}

# ============================================================================
# public api functions - microdata
# ============================================================================

#' Download PNADC microdata
#'
#' Downloads and returns PNADC microdata for the specified module and year(s)
#' from the IBGE FTP. Data is cached locally to avoid repeated downloads.
#' When the `arrow` package is installed, data is cached in parquet format
#' for faster subsequent reads.
#'
#' @param module Character. The module identifier. Use \code{\link{pnadc_modules}}
#'   to see available modules. Required.
#' @param year Numeric or vector. Year(s) to download. Use NULL for all available
#'   years for the module. Default is NULL.
#' @param vars Character vector. Variables to select. Use NULL for all variables.
#'   Survey design variables (UPA, Estrato, V1028) and key demographic variables
#'   are always included. Default is NULL.
#' @param as_survey Logical. If TRUE, returns a survey design object (requires
#'   the `srvyr` package). Default is FALSE.
#' @param cache_dir Character. Directory for caching downloaded files.
#'   Default uses `tools::R_user_dir("healthbR", "cache")`.
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
#' @return A tibble with PNADC microdata, or a `srvyr` survey design object
#'   if `as_survey = TRUE`.
#'
#' @details
#' PNAD Continua (Pesquisa Nacional por Amostra de Domicilios Continua) is a
#' quarterly household survey conducted by IBGE. This function provides access
#' to supplementary modules with health-related content.
#'
#' ## Available modules
#'
#' - `deficiencia`: Persons with disabilities (2019, 2022, 2024)
#' - `habitacao`: Housing characteristics (2012-2019, 2022-2024)
#' - `moradores`: General characteristics of residents (2012-2019, 2022-2024)
#' - `aps`: Primary health care (2022)
#'
#' ## Survey design variables
#'
#' For proper statistical analysis with complex survey design, the following
#' variables are always included:
#' - `UPA`: Primary sampling unit
#' - `Estrato`: Stratum
#' - `V1028`: Survey weight
#'
#' Use `as_survey = TRUE` to get a properly weighted survey design object
#' for analysis with the `srvyr` package.
#'
#' @section Data source:
#' Data is downloaded from the IBGE FTP server:
#' \url{https://ftp.ibge.gov.br/Trabalho_e_Rendimento/Pesquisa_Nacional_por_Amostra_de_Domicilios_continua/}
#'
#' @export
#'
#' @examplesIf interactive()
#' # download deficiencia module for 2022
#' df <- pnadc_data(module = "deficiencia", year = 2022, cache_dir = tempdir())
#'
#' # download with survey design
#' svy <- pnadc_data(
#'   module = "deficiencia",
#'   year = 2022,
#'   as_survey = TRUE,
#'   cache_dir = tempdir()
#' )
#'
#' # select specific variables
#' df_subset <- pnadc_data(
#'   module = "deficiencia",
#'   year = 2022,
#'   vars = c("S11001", "S11002"),
#'   cache_dir = tempdir()
#' )
pnadc_data <- function(module,
                       year = NULL,
                       vars = NULL,
                       as_survey = FALSE,
                       cache_dir = NULL,
                       refresh = FALSE,
                       lazy = FALSE, backend = c("arrow", "duckdb")) {
  # validate parameters
  module <- validate_pnadc_module(module)
  years <- validate_pnadc_year(year, module)

  # set cache directory
  cache_dir <- pnadc_cache_dir(cache_dir)

  # lazy evaluation: return from partitioned cache if available
  if (isTRUE(lazy)) {
    backend <- match.arg(backend)
    cache_dir_resolved <- .module_cache_dir("pnadc", cache_dir)
    ds_name <- paste0("pnadc_", module, "_data")
    year_filter <- if (!is.null(year)) as.integer(year) else NULL
    select_cols <- if (!is.null(vars)) unique(c("year", "pnadc_module", vars)) else NULL
    ds <- .lazy_return(cache_dir_resolved, ds_name, backend,
                       filters = if (!is.null(year_filter)) list(year = year_filter) else list(),
                       select_cols = select_cols)
    if (!is.null(ds)) return(ds)
  }

  # download and load data for each year
  dataset_name <- paste0("pnadc_", module, "_data")

  data_list <- .map_parallel(years, function(y) {
    target_year <- as.integer(y)

    # 1. check partitioned cache first (preferred path)
    if (!refresh && .has_arrow() &&
        .has_partitioned_cache(cache_dir, dataset_name)) {
      ds <- arrow::open_dataset(file.path(cache_dir, dataset_name))
      cached <- ds |>
        dplyr::filter(.data$year == target_year) |>
        dplyr::collect()
      if (nrow(cached) > 0) {
        cli::cli_inform("Loading PNADC {module} {y} from cache...")
        return(cached)
      }
    }

    # 2. fall back to flat cache (migration from old format)
    if (!refresh) {
      flat_base <- paste0("pnadc_", module, "_", y)
      flat_cached <- .cache_read(cache_dir, flat_base)
      if (!is.null(flat_cached)) {
        .warn_flat_cache("pnadc")
        cli::cli_inform("Loading PNADC {module} {y} from cache...")
        return(flat_cached)
      }
    }

    # 3. download and read
    # find the correct URL for this module and year
    url_info <- pnadc_find_data_url(module, y)
    zip_path <- file.path(cache_dir, url_info$data_filename)

    # download data file
    pnadc_download_file(url_info$data_url, zip_path, refresh)

    # download input file (required for reading fixed-width format)
    if (is.null(url_info$input_url)) {
      cli::cli_abort(c(
        "Could not find input specification file for {module} {y}",
        "i" = "Documentation URL: {.url {url_info$doc_dir_url}}"
      ))
    }
    input_path <- file.path(cache_dir, url_info$input_filename)
    pnadc_download_file(url_info$input_url, input_path, refresh)

    # read data
    data <- pnadc_read_zip(zip_path, input_path, module, y)

    # add module identifier and year partition column
    data <- data |>
      dplyr::mutate(year = target_year, pnadc_module = module, .before = 1)

    # 4. write to partitioned cache
    .cache_append_partitioned(data, cache_dir, dataset_name, c("year"))

    data
  })

  # combine all years
  combined_data <- dplyr::bind_rows(data_list)

  # if lazy was requested, return from cache after download
  if (isTRUE(lazy)) {
    backend <- match.arg(backend)
    cache_dir_resolved <- .module_cache_dir("pnadc", cache_dir)
    ds_name <- paste0("pnadc_", module, "_data")
    year_filter <- if (!is.null(year)) as.integer(year) else NULL
    select_cols <- if (!is.null(vars)) unique(c("year", "pnadc_module", vars)) else NULL
    ds <- .lazy_return(cache_dir_resolved, ds_name, backend,
                       filters = if (!is.null(year_filter)) list(year = year_filter) else list(),
                       select_cols = select_cols)
    if (!is.null(ds)) return(ds)
  }

  # select variables if specified
  if (!is.null(vars)) {
    vars <- toupper(vars)
    # always include required variables
    required <- pnadc_required_vars()
    vars_to_select <- unique(c("pnadc_module", required, vars))

    available_vars <- names(combined_data)
    missing_vars <- setdiff(vars_to_select, available_vars)

    if (length(missing_vars) > 0) {
      # only warn about user-requested vars, not required ones
      user_missing <- setdiff(missing_vars, c("pnadc_module", required))
      if (length(user_missing) > 0) {
        missing_str <- paste(user_missing, collapse = ", ")
        cli::cli_warn("Variables not found: {missing_str}")
      }
    }

    vars_to_select <- intersect(vars_to_select, available_vars)
    combined_data <- combined_data |>
      dplyr::select(dplyr::all_of(vars_to_select))
  }

  # report
  n_years <- length(years)
  cli::cli_alert_success(
    "Loaded {nrow(combined_data)} observations from PNADC {module} ({n_years} year(s))"
  )

  # apply survey design if requested
  if (as_survey) {
    return(pnadc_apply_survey_design(combined_data))
  }

  combined_data
}

# ============================================================================
# cache management functions
# ============================================================================

#' Clear PNADC cache
#'
#' Removes all cached PNADC data files.
#'
#' @param module Character. Optional module to clear cache for. If NULL (default),
#'   clears cache for all modules.
#' @param cache_dir Character. Optional custom cache directory. If NULL (default),
#'   uses the standard user cache directory.
#'
#' @return NULL (invisibly)
#'
#' @export
#'
#' @examples
#' pnadc_clear_cache()
pnadc_clear_cache <- function(module = NULL, cache_dir = NULL) {
  cache_dir <- pnadc_cache_dir(cache_dir)

  if (!is.null(module)) {
    module <- validate_pnadc_module(module)
    # remove only files for this module
    pattern <- paste0("pnadc_", module, "_")
    files <- list.files(cache_dir, pattern = pattern, full.names = TRUE)
  } else {
    # remove all files
    files <- list.files(cache_dir, full.names = TRUE, recursive = TRUE)
  }

  if (length(files) == 0) {
    cli::cli_alert_info("Cache is already empty")
    return(invisible(NULL))
  }

  # remove files
  unlink(files, recursive = TRUE)

  if (!is.null(module)) {
    cli::cli_alert_success("PNADC {module} cache cleared")
  } else {
    # recreate directory
    if (!dir.exists(cache_dir)) {
      dir.create(cache_dir, recursive = TRUE)
    }
    cli::cli_alert_success("PNADC cache cleared")
  }

  invisible(NULL)
}

#' Get PNADC cache status
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
#' @examples
#' pnadc_cache_status()
pnadc_cache_status <- function(cache_dir = NULL) {
  cache_dir <- pnadc_cache_dir(cache_dir)

  # list all files
  files <- list.files(cache_dir, full.names = TRUE, recursive = FALSE)

  if (length(files) == 0) {
    cli::cli_alert_info("Cache is empty")
    return(tibble::tibble(
      file = character(),
      module = character(),
      year = integer(),
      size_mb = numeric(),
      modified = as.POSIXct(character())
    ))
  }

  # get file info
  file_info <- file.info(files)

  # parse module and year from filename
  basenames <- basename(files)

  result <- tibble::tibble(
    file = basenames,
    size_mb = round(file_info$size / 1024^2, 1),
    modified = file_info$mtime
  )

  # try to extract module and year
  result <- result |>
    dplyr::mutate(
      module = stringr::str_extract(.data$file, "(?<=pnadc_)[a-z]+(?=_)"),
      year = as.integer(stringr::str_extract(.data$file, "\\d{4}"))
    ) |>
    dplyr::select("file", "module", "year", "size_mb", "modified")

  result
}
