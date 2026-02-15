# pns functions for healthbR package
# functions to download and process PNS (Pesquisa Nacional de Saude) data
# includes microdata access via FTP and tabulated data via SIDRA API

# ============================================================================
# internal constants and data
# ============================================================================

#' PNS URL patterns for FTP access
#' @noRd
pns_url_patterns <- list(
  base_url = "https://ftp.ibge.gov.br/PNS",
  "2013" = list(
    data = "https://ftp.ibge.gov.br/PNS/2013/Microdados/Dados/PNS_2013.zip",
    dict = "https://ftp.ibge.gov.br/PNS/2013/Microdados/Documentacao/Dicionario_e_input_20200930.zip"
  ),
  "2019" = list(
    data = "https://ftp.ibge.gov.br/PNS/2019/Microdados/Dados/PNS_2019_20220525.zip",
    dict = "https://ftp.ibge.gov.br/PNS/2019/Microdados/Documentacao/Dicionario_e_input_20220530.zip"
  )
)

#' SIDRA theme labels (Portuguese)
#' @noRd
sidra_theme_labels <- c(
  "health_perception" = "Percep\u00e7\u00e3o do estado de sa\u00fade",
  "chronic_diseases" = "Doen\u00e7as cr\u00f4nicas",
  "mental_health" = "Sa\u00fade mental",
  "tobacco" = "Tabagismo",
  "alcohol" = "Consumo de \u00e1lcool",
  "physical_activity" = "Atividade f\u00edsica",
  "nutrition" = "Alimenta\u00e7\u00e3o e nutri\u00e7\u00e3o",
  "health_services" = "Acesso a servi\u00e7os de sa\u00fade",
  "health_insurance" = "Plano de sa\u00fade",
  "medications" = "Medicamentos",
  "womens_health" = "Sa\u00fade da mulher",
  "oral_health" = "Sa\u00fade bucal",
  "accidents_violence" = "Acidentes e viol\u00eancias",
  "disability" = "Defici\u00eancia",
  "elderly" = "Sa\u00fade do idoso",
  "anthropometry" = "Antropometria e medidas",
  "child_health" = "Sa\u00fade da crian\u00e7a",
  "work_health" = "Sa\u00fade do trabalhador",
  "social_capital" = "Capital social",
  "housing" = "Domic\u00edlio e saneamento"
)

#' Internal SIDRA catalog with representative tables
#' @noRd
pns_sidra_catalog_internal <- tibble::tibble(
  table_code = c(
    # health perception
    "4751", "7666", "7667",
    # chronic diseases
    "4416", "4418", "4420", "4487", "4489", "4491",
    "4450", "4452", "4454", "4432", "4434", "4436",
    # mental health
    "4667", "4669", "4671", "7891", "7893", "7895",
    # tobacco
    "4162", "4164", "4173", "4175", "7765", "7767",
    # alcohol
    "4352", "4354", "4356", "7720", "7722",
    # physical activity
    "4250", "4252", "4254", "7735", "7737",
    # nutrition
    "4304", "4306", "4308", "7668", "7670",
    # health services
    "5031", "5033", "5035", "7585", "7587",
    # health insurance
    "4938", "4940", "4942", "7565", "7567",
    # womens health
    "5471", "5473", "5475", "8252", "8254",
    # oral health
    "5141", "5143", "5145",
    # accidents/violence
    "5133", "5135", "5137",
    # elderly
    "5549", "5551", "5553",
    # anthropometry
    "8167", "8169", "8171"
  ),
  table_name = c(
    # health perception
    "Autoavalia\u00e7\u00e3o de estado de sa\u00fade das pessoas de 18 anos ou mais - boa ou muito boa",
    "Autoavalia\u00e7\u00e3o de sa\u00fade por sexo",
    "Autoavalia\u00e7\u00e3o de sa\u00fade por faixa et\u00e1ria",
    # chronic diseases - hypertension
    "Diagn\u00f3stico de hipertens\u00e3o arterial - Total",
    "Diagn\u00f3stico de hipertens\u00e3o arterial por sexo",
    "Diagn\u00f3stico de hipertens\u00e3o arterial por faixa et\u00e1ria",
    # chronic diseases - diabetes
    "Diagn\u00f3stico de diabetes - Total",
    "Diagn\u00f3stico de diabetes por sexo",
    "Diagn\u00f3stico de diabetes por faixa et\u00e1ria",
    # chronic diseases - cholesterol
    "Diagn\u00f3stico de colesterol alto - Total",
    "Diagn\u00f3stico de colesterol alto por sexo",
    "Diagn\u00f3stico de colesterol alto por faixa et\u00e1ria",
    # chronic diseases - heart disease
    "Diagn\u00f3stico de doen\u00e7a do cora\u00e7\u00e3o - Total",
    "Diagn\u00f3stico de doen\u00e7a do cora\u00e7\u00e3o por sexo",
    "Diagn\u00f3stico de doen\u00e7a do cora\u00e7\u00e3o por faixa et\u00e1ria",
    # mental health
    "Diagn\u00f3stico de depress\u00e3o - Total",
    "Diagn\u00f3stico de depress\u00e3o por sexo",
    "Diagn\u00f3stico de depress\u00e3o por faixa et\u00e1ria",
    "Indicadores de sa\u00fade mental - Total",
    "Indicadores de sa\u00fade mental por sexo",
    "Indicadores de sa\u00fade mental por faixa et\u00e1ria",
    # tobacco
    "Uso de produtos de tabaco - Total",
    "Uso de produtos de tabaco por sexo",
    "Fumantes atuais de tabaco - Total",
    "Fumantes atuais de tabaco por sexo",
    "Uso de tabaco - Total 2019",
    "Uso de tabaco por sexo 2019",
    # alcohol
    "Consumo de bebida alco\u00f3lica - Total",
    "Consumo de bebida alco\u00f3lica por sexo",
    "Consumo abusivo de \u00e1lcool",
    "Consumo de \u00e1lcool - Total 2019",
    "Consumo de \u00e1lcool por sexo 2019",
    # physical activity
    "Pr\u00e1tica de atividade f\u00edsica no lazer - Total",
    "Pr\u00e1tica de atividade f\u00edsica por sexo",
    "Atividade f\u00edsica suficiente no lazer",
    "Atividade f\u00edsica - Total 2019",
    "Atividade f\u00edsica por sexo 2019",
    # nutrition
    "Consumo de frutas e hortali\u00e7as - Total",
    "Consumo de frutas e hortali\u00e7as por sexo",
    "Consumo regular de frutas",
    "Consumo de alimentos - Total 2019",
    "Consumo de alimentos por sexo 2019",
    # health services
    "Acesso a servi\u00e7os de sa\u00fade - Total",
    "Acesso a servi\u00e7os de sa\u00fade por sexo",
    "Consulta m\u00e9dica nos \u00faltimos 12 meses",
    "Acesso a servi\u00e7os - Total 2019",
    "Acesso a servi\u00e7os por sexo 2019",
    # health insurance
    "Plano de sa\u00fade - Total",
    "Plano de sa\u00fade por sexo",
    "Cobertura de plano de sa\u00fade",
    "Plano de sa\u00fade - Total 2019",
    "Plano de sa\u00fade por sexo 2019",
    # womens health
    "Exame de mamografia - Total",
    "Exame de mamografia por faixa et\u00e1ria",
    "Exame de Papanicolau",
    "Sa\u00fade da mulher - Total 2019",
    "Sa\u00fade da mulher por faixa et\u00e1ria 2019",
    # oral health
    "Sa\u00fade bucal - Total",
    "Sa\u00fade bucal por sexo",
    "Consulta ao dentista",
    # accidents/violence
    "Acidentes de tr\u00e2nsito - Total",
    "Acidentes de tr\u00e2nsito por sexo",
    "Viol\u00eancia f\u00edsica",
    # elderly
    "Sa\u00fade do idoso - Total",
    "Sa\u00fade do idoso por sexo",
    "Capacidade funcional do idoso",
    # anthropometry
    "Antropometria - Total",
    "Antropometria por sexo",
    "Medidas de peso e altura"
  ),
  theme = c(
    rep("health_perception", 3),
    rep("chronic_diseases", 12),
    rep("mental_health", 6),
    rep("tobacco", 6),
    rep("alcohol", 5),
    rep("physical_activity", 5),
    rep("nutrition", 5),
    rep("health_services", 5),
    rep("health_insurance", 5),
    rep("womens_health", 5),
    rep("oral_health", 3),
    rep("accidents_violence", 3),
    rep("elderly", 3),
    rep("anthropometry", 3)
  ),
  years = c(
    # health perception
    list(c("2013", "2019")), list(c("2013", "2019")), list(c("2013", "2019")),
    # chronic diseases
    list(c("2013", "2019")), list(c("2013", "2019")), list(c("2013", "2019")),
    list(c("2013", "2019")), list(c("2013", "2019")), list(c("2013", "2019")),
    list(c("2013", "2019")), list(c("2013", "2019")), list(c("2013", "2019")),
    list(c("2013", "2019")), list(c("2013", "2019")), list(c("2013", "2019")),
    # mental health
    list(c("2013", "2019")), list(c("2013", "2019")), list(c("2013", "2019")),
    list(c("2019")), list(c("2019")), list(c("2019")),
    # tobacco
    list(c("2013")), list(c("2013")), list(c("2013", "2019")), list(c("2013", "2019")),
    list(c("2019")), list(c("2019")),
    # alcohol
    list(c("2013", "2019")), list(c("2013", "2019")), list(c("2013", "2019")),
    list(c("2019")), list(c("2019")),
    # physical activity
    list(c("2013", "2019")), list(c("2013", "2019")), list(c("2013", "2019")),
    list(c("2019")), list(c("2019")),
    # nutrition
    list(c("2013", "2019")), list(c("2013", "2019")), list(c("2013", "2019")),
    list(c("2019")), list(c("2019")),
    # health services
    list(c("2013", "2019")), list(c("2013", "2019")), list(c("2013", "2019")),
    list(c("2019")), list(c("2019")),
    # health insurance
    list(c("2013", "2019")), list(c("2013", "2019")), list(c("2013", "2019")),
    list(c("2019")), list(c("2019")),
    # womens health
    list(c("2013", "2019")), list(c("2013", "2019")), list(c("2013", "2019")),
    list(c("2019")), list(c("2019")),
    # oral health
    list(c("2013", "2019")), list(c("2013", "2019")), list(c("2013", "2019")),
    # accidents/violence
    list(c("2013", "2019")), list(c("2013", "2019")), list(c("2013", "2019")),
    # elderly
    list(c("2013", "2019")), list(c("2013", "2019")), list(c("2013", "2019")),
    # anthropometry
    list(c("2019")), list(c("2019")), list(c("2019"))
  ),
  territorial_levels = c(
    rep(list(c("1", "2", "3")), 69)
  )
)

# add theme labels
pns_sidra_catalog_internal$theme_label <- sidra_theme_labels[pns_sidra_catalog_internal$theme]

# ============================================================================
# internal helper functions
# ============================================================================

#' Get PNS cache directory
#' @noRd
pns_cache_dir <- function(cache_dir = NULL) {
  .module_cache_dir("pns", cache_dir)
}

#' Validate PNS year parameter
#' @noRd
validate_pns_year <- function(year) {
  available <- c(2013L, 2019L)

  if (is.null(year)) {
    return(available)
  }

  year <- as.integer(year)
  invalid <- year[!year %in% available]

  if (length(invalid) > 0) {
    cli::cli_abort(c(
      "Invalid year{?s}: {.val {invalid}}",
      "i" = "Available years: {.val {available}}"
    ))
  }

  year
}

#' Download PNS microdata file
#' @noRd
pns_download_data <- function(year, cache_dir, refresh = FALSE) {
  year_char <- as.character(year)
  url_info <- pns_url_patterns[[year_char]]

  if (is.null(url_info)) {
    cli::cli_abort("No URL pattern found for year {year}")
  }

  # define file paths
  zip_filename <- basename(url_info$data)
  zip_path <- file.path(cache_dir, zip_filename)

  # check if already downloaded

  if (file.exists(zip_path) && !refresh) {
    cli::cli_alert_info("Using cached file: {.file {zip_path}}")
    return(zip_path)
  }

  # download
  cli::cli_inform("Downloading PNS {year} data from IBGE...")
  cli::cli_inform("URL: {.url {url_info$data}}")
  cli::cli_inform("This may take a few minutes...")

  tryCatch(
    {
      curl::curl_download(url_info$data, zip_path, quiet = FALSE)
      cli::cli_alert_success("Download complete: {.file {zip_path}}")
    },
    error = function(e) {
      if (file.exists(zip_path)) file.remove(zip_path)
      cli::cli_abort("Download failed: {e$message}")
    }
  )

  zip_path
}

#' Read PNS microdata from ZIP file
#' @noRd
pns_read_microdata <- function(zip_path, year) {
  cli::cli_inform("Extracting and reading PNS {year} data...")

  # create temp directory for extraction
  temp_dir <- file.path(tempdir(), paste0("pns_", year))
  if (dir.exists(temp_dir)) {
    unlink(temp_dir, recursive = TRUE)
  }
  dir.create(temp_dir)

  # extract ZIP
  utils::unzip(zip_path, exdir = temp_dir)

  # find data files
  extracted_files <- list.files(temp_dir, recursive = TRUE, full.names = TRUE)

  # look for txt data file
  txt_files <- extracted_files[grepl("\\.txt$", extracted_files, ignore.case = TRUE)]
  # exclude input files
  txt_files <- txt_files[!grepl("input", txt_files, ignore.case = TRUE)]

  # look for csv file
  csv_files <- extracted_files[grepl("\\.csv$", extracted_files, ignore.case = TRUE)]

  if (length(csv_files) > 0) {
    # read CSV format
    cli::cli_inform("Reading CSV format...")
    data <- readr::read_csv(csv_files[1], show_col_types = FALSE)
  } else if (length(txt_files) > 0) {
    # for fixed-width format, we need the input file
    # try to find input specification
    input_files <- extracted_files[grepl("input", extracted_files, ignore.case = TRUE)]

    if (length(input_files) > 0) {
      cli::cli_inform("Reading fixed-width format with input file...")
      data <- pns_read_fwf(txt_files[1], input_files[1])
    } else {
      # try reading as delimited
      cli::cli_inform("Attempting to read as delimited text...")
      data <- readr::read_delim(txt_files[1], delim = ";", show_col_types = FALSE)
    }
  } else {
    # cleanup and abort
    unlink(temp_dir, recursive = TRUE)
    cli::cli_abort(c(
      "Could not find data files in PNS {year} archive",
      "i" = "Files found: {.val {basename(extracted_files)}}"
    ))
  }

  # cleanup temp directory
  unlink(temp_dir, recursive = TRUE)

  # add year column
  data <- data |>
    dplyr::mutate(year = as.character(year), .before = 1)

  tibble::as_tibble(data)
}

#' Read PNS fixed-width format data
#' @noRd
pns_read_fwf <- function(data_file, input_file) {
  # parse input file to get column specifications
  input_lines <- readr::read_lines(input_file)

  # typical IBGE input file format:
  # @position variable $format.
  # or @position variable format.

  # extract position and variable info
  spec_lines <- input_lines[grepl("^@", input_lines)]

  if (length(spec_lines) == 0) {
    # alternative: try reading as SAS input format
    cli::cli_warn("Could not parse input file format, attempting delimited read")
    return(readr::read_delim(data_file, delim = ";", show_col_types = FALSE))
  }

  # parse specifications
  col_specs <- purrr::map(spec_lines, function(line) {
    # extract @position variable format
    parts <- stringr::str_match(line, "@(\\d+)\\s+(\\S+)\\s+\\$?(\\d+)")
    if (is.na(parts[1, 1])) {
      return(NULL)
    }
    list(
      start = as.integer(parts[1, 2]),
      name = parts[1, 3],
      width = as.integer(parts[1, 4])
    )
  })

  col_specs <- purrr::compact(col_specs)

  if (length(col_specs) == 0) {
    cli::cli_warn("Could not parse column specifications, attempting delimited read")
    return(readr::read_delim(data_file, delim = ";", show_col_types = FALSE))
  }

  # create fwf_positions
  positions <- readr::fwf_positions(
    start = purrr::map_int(col_specs, "start"),
    end = purrr::map_int(col_specs, ~ .x$start + .x$width - 1),
    col_names = purrr::map_chr(col_specs, "name")
  )

  readr::read_fwf(data_file, col_positions = positions, show_col_types = FALSE)
}

# ============================================================================
# public api functions - basic info
# ============================================================================

#' List available PNS survey years
#'
#' Returns a character vector with available PNS survey years.
#'
#' @return A character vector of available years.
#'
#' @export
#'
#' @examples
#' pns_years()
pns_years <- function() {
  c("2013", "2019")
}

#' PNS survey information
#'
#' Displays information about the PNS survey and returns metadata.
#'
#' @param year Numeric. Year to get specific information about.
#'   NULL shows general info.
#'
#' @return Invisibly returns a list with survey metadata.
#'
#' @export
#'
#' @examples
#' pns_info()
#' pns_info(2019)
pns_info <- function(year = NULL) {

  info <- list(
    name = "Pesquisa Nacional de Sa\u00fade (PNS)",
    name_en = "National Health Survey",
    institution = "IBGE - Instituto Brasileiro de Geografia e Estat\u00edstica",
    partner = "Minist\u00e9rio da Sa\u00fade",
    available_years = pns_years(),
    description = paste0(
      "A PNS \u00e9 uma pesquisa domiciliar que investiga as condi\u00e7\u00f5es de ",
      "sa\u00fade da popula\u00e7\u00e3o brasileira, incluindo estilo de vida, ",
      "preval\u00eancia de doen\u00e7as cr\u00f4nicas, acesso a servi\u00e7os de sa\u00fade, ",
      "entre outros temas."
    ),
    url = "https://www.ibge.gov.br/estatisticas/sociais/saude/9160-pesquisa-nacional-de-saude.html",
    ftp_url = "https://ftp.ibge.gov.br/PNS/",
    sidra_url = "https://sidra.ibge.gov.br/pesquisa/pns",
    sidra_tables = 2222,
    citation = paste0(
      "IBGE - Instituto Brasileiro de Geografia e Estat\u00edstica. ",
      "Pesquisa Nacional de Sa\u00fade. Rio de Janeiro: IBGE."
    )
  )

  # year-specific information
  year_info <- list(
    "2013" = list(
      sample_size = "approximately 80,000 households",
      reference_period = "August 2013 - February 2014",
      modules = c("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K",
                  "L", "M", "N", "O", "P", "Q", "R", "S", "U", "W", "X"),
      notes = "First edition of PNS"
    ),
    "2019" = list(
      sample_size = "approximately 100,000 households",
      reference_period = "August 2019 - December 2019",
      modules = c("A", "C", "E", "F", "G", "J", "K", "L", "M", "N", "O",
                  "P", "Q", "R", "S", "U", "W", "X", "Y", "Z"),
      notes = "Second edition with expanded sample"
    )
  )

  # display information
  cli::cli_h1("Pesquisa Nacional de Sa\u00fade (PNS)")
  cli::cli_text("")
  cli::cli_text(info$description)
  cli::cli_text("")
  cli::cli_alert_info("Institution: {info$institution}")
  cli::cli_alert_info("Partner: {info$partner}")
  cli::cli_alert_info("Available years: {stringr::str_c(info$available_years, collapse = ', ')}")
  cli::cli_alert_info("SIDRA tables: {info$sidra_tables}")
  cli::cli_text("")
  cli::cli_h2("Data access")
  cli::cli_alert("Microdata (individual records): {.fn pns_data}")
  cli::cli_alert("Tabulated indicators (SIDRA API): {.fn pns_sidra_data}")
  cli::cli_text("")
  cli::cli_text("URL: {.url {info$url}}")
  cli::cli_text("FTP: {.url {info$ftp_url}}")
  cli::cli_text("SIDRA: {.url {info$sidra_url}}")

  if (!is.null(year)) {
    year_char <- as.character(year)
    if (year_char %in% names(year_info)) {
      yi <- year_info[[year_char]]
      cli::cli_text("")
      cli::cli_h2("PNS {year}")
      cli::cli_alert_info("Sample size: {yi$sample_size}")
      cli::cli_alert_info("Reference period: {yi$reference_period}")
      cli::cli_alert_info("Modules: {stringr::str_c(yi$modules, collapse = ', ')}")
      if (!is.null(yi$notes)) {
        cli::cli_alert_info("Notes: {yi$notes}")
      }
      info$year_details <- yi
    }
  }

  invisible(info)
}

#' List PNS survey modules
#'
#' Returns information about the questionnaire modules available in the PNS.
#'
#' @param year Numeric. Year to get modules for (2013 or 2019).
#'   NULL returns modules for all years. Default is NULL.
#'
#' @return A tibble with module codes, names, and descriptions.
#'
#' @export
#'
#' @examples
#' pns_modules()
#' pns_modules(year = 2019)
pns_modules <- function(year = NULL) {

  # module definitions
  modules <- tibble::tibble(
    module = c("A", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
               "N", "O", "P", "Q", "R", "S", "U", "W", "X", "Y", "Z"),
    name = c(
      "Informa\u00e7\u00f5es do domic\u00edlio",
      "Caracter\u00edsticas gerais dos moradores",
      "Educa\u00e7\u00e3o",
      "Trabalho e rendimento",
      "Pessoas com defici\u00eancia",
      "Cobertura de plano de sa\u00fade",
      "Utiliza\u00e7\u00e3o de servi\u00e7os de sa\u00fade",
      "Sa\u00fade dos moradores do domic\u00edlio",
      "Percep\u00e7\u00e3o do estado de sa\u00fade",
      "Acidentes e viol\u00eancias",
      "Estilos de vida",
      "Atendimento m\u00e9dico",
      "Doen\u00e7as cr\u00f4nicas",
      "Sa\u00fade da mulher",
      "Atendimento pr\u00e9-natal",
      "Interna\u00e7\u00f5es",
      "Urg\u00eancias",
      "Sa\u00fade bucal",
      "Acidentes de trabalho",
      "Antropometria e press\u00e3o arterial",
      "Exames laboratoriais",
      "Atividade f\u00edsica de crian\u00e7as",
      "Consumo alimentar de crian\u00e7as"
    ),
    name_en = c(
      "Household information",
      "General characteristics of residents",
      "Education",
      "Work and income",
      "Persons with disabilities",
      "Health insurance coverage",
      "Health services utilization",
      "Health of household residents",
      "Health status perception",
      "Accidents and violence",
      "Lifestyles",
      "Medical care",
      "Chronic diseases",
      "Women's health",
      "Prenatal care",
      "Hospitalizations",
      "Emergencies",
      "Oral health",
      "Work accidents",
      "Anthropometry and blood pressure",
      "Laboratory tests",
      "Physical activity of children",
      "Food consumption of children"
    ),
    year_2013 = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE,
                  TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE),
    year_2019 = c(TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE,
                  TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE)
  )

  # filter by year if specified

  if (!is.null(year)) {
    year <- validate_pns_year(year)
    if (2013 %in% year && 2019 %in% year) {
      # keep all
    } else if (2013 %in% year) {
      modules <- modules |>
        dplyr::filter(.data$year_2013 == TRUE)
    } else if (2019 %in% year) {
      modules <- modules |>
        dplyr::filter(.data$year_2019 == TRUE)
    }
  }

  modules |>
    dplyr::select("module", "name", "name_en")
}

#' Download PNS variable dictionary
#'
#' Downloads and returns the variable dictionary for PNS microdata.
#' The dictionary is cached locally to avoid repeated downloads.
#'
#' @param year Numeric. Year to get dictionary for (2013 or 2019).
#'   Default is 2019.
#' @param cache_dir Character. Directory for caching downloaded files.
#'   Default uses `tools::R_user_dir("healthbR", "cache")`.
#' @param refresh Logical. If TRUE, re-download even if file exists in cache.
#'   Default is FALSE.
#'
#' @return A tibble with variable definitions.
#'
#' @details
#' The dictionary includes variable names, labels, and response categories
#' for the PNS microdata. This is useful for understanding the structure

#' of the data returned by \code{\link{pns_data}}.
#'
#' @section Data source:
#' Dictionaries are downloaded from the IBGE FTP server:
#' \url{https://ftp.ibge.gov.br/PNS/}
#'
#' @export
#'
#' @examplesIf interactive()
#' # get dictionary for 2019
#' dict <- pns_dictionary(year = 2019, cache_dir = tempdir())
#'
#' # get dictionary for 2013
#' dict_2013 <- pns_dictionary(year = 2013, cache_dir = tempdir())
pns_dictionary <- function(year = 2019,
                           cache_dir = NULL,
                           refresh = FALSE) {

  # validate year
  year <- validate_pns_year(year)
  if (length(year) > 1) {
    year <- year[1]
    cli::cli_inform("Using year {year} for dictionary (only one year at a time).")
  }

  # set cache directory
  cache_dir <- pns_cache_dir(cache_dir)

  # get dictionary URL
  year_char <- as.character(year)
  url_info <- pns_url_patterns[[year_char]]

  if (is.null(url_info) || is.null(url_info$dict)) {
    cli::cli_abort("No dictionary URL found for year {year}")
  }

  # define file paths
  zip_filename <- basename(url_info$dict)
  zip_path <- file.path(cache_dir, zip_filename)
  dict_cache_file <- file.path(cache_dir, paste0("pns_dictionary_", year, ".rds"))

  # check if already processed
  if (file.exists(dict_cache_file) && !refresh) {
    cli::cli_inform("Loading PNS {year} dictionary from cache...")
    return(readRDS(dict_cache_file))
  }

  # download if needed
  if (!file.exists(zip_path) || refresh) {
    cli::cli_inform("Downloading PNS {year} dictionary from IBGE...")
    cli::cli_inform("URL: {.url {url_info$dict}}")

    tryCatch(
      {
        curl::curl_download(url_info$dict, zip_path, quiet = FALSE)
        cli::cli_alert_success("Download complete: {.file {zip_path}}")
      },
      error = function(e) {
        if (file.exists(zip_path)) file.remove(zip_path)
        cli::cli_abort("Download failed: {e$message}")
      }
    )
  }

  # extract and read dictionary
  cli::cli_inform("Extracting dictionary...")

  temp_dir <- file.path(tempdir(), paste0("pns_dict_", year))
  if (dir.exists(temp_dir)) {
    unlink(temp_dir, recursive = TRUE)
  }
  dir.create(temp_dir)

  utils::unzip(zip_path, exdir = temp_dir)

  # find dictionary file (usually Excel or TXT)
  extracted_files <- list.files(temp_dir, recursive = TRUE, full.names = TRUE)

  xlsx_files <- extracted_files[grepl("\\.xlsx?$", extracted_files, ignore.case = TRUE)]
  txt_files <- extracted_files[grepl("dicionario.*\\.txt$|dicion.*\\.txt$",
                                      extracted_files, ignore.case = TRUE)]

  dict_df <- NULL

  if (length(xlsx_files) > 0) {
    # read Excel dictionary
    rlang::check_installed("readxl", reason = "to read PNS dictionary Excel files")
    cli::cli_inform("Reading Excel dictionary...")
    dict_file <- xlsx_files[1]
    dict_df <- tryCatch(
      {
        readxl::read_excel(dict_file)
      },
      error = function(e) {
        cli::cli_warn("Could not read Excel file: {e$message}")
        NULL
      }
    )
  }

  if (is.null(dict_df) && length(txt_files) > 0) {
    # try reading TXT dictionary
    cli::cli_inform("Reading TXT dictionary...")
    dict_file <- txt_files[1]
    dict_df <- tryCatch(
      {
        readr::read_delim(dict_file, delim = ";", show_col_types = FALSE)
      },
      error = function(e) {
        cli::cli_warn("Could not read TXT file: {e$message}")
        NULL
      }
    )
  }

  # cleanup temp directory
  unlink(temp_dir, recursive = TRUE)

  if (is.null(dict_df)) {
    cli::cli_abort(c(
      "Could not find or read dictionary file for PNS {year}",
      "i" = "Files found: {.val {basename(extracted_files)}}"
    ))
  }

  # clean and standardize
  names(dict_df) <- .clean_names(names(dict_df))
  dict_df <- dict_df |>
    dplyr::mutate(year = as.character(year), .before = 1)

  dict_df <- tibble::as_tibble(dict_df)

  # save to cache
  saveRDS(dict_df, dict_cache_file)
  cli::cli_alert_success("Dictionary cached: {.file {dict_cache_file}}")

  dict_df
}

#' List PNS variables
#'
#' Returns a list of available variables in the PNS microdata with their labels.
#' This is a convenience wrapper around \code{\link{pns_dictionary}} that
#' returns only unique variable names and labels.
#'
#' @param year Numeric. Year to get variables for (2013 or 2019).
#'   Default is 2019.
#' @param module Character. Filter by module code (e.g., "J", "K", "L").
#'   NULL returns all modules. Default is NULL.
#' @param cache_dir Character. Directory for caching downloaded files.
#'   Default uses `tools::R_user_dir("healthbR", "cache")`.
#' @param refresh Logical. If TRUE, re-download even if file exists in cache.
#'   Default is FALSE.
#'
#' @return A tibble with variable names and labels.
#'
#' @export
#'
#' @examplesIf interactive()
#' # list all variables for 2019
#' pns_variables(year = 2019, cache_dir = tempdir())
#'
#' # list variables for a specific module
#' pns_variables(year = 2019, module = "J", cache_dir = tempdir())
pns_variables <- function(year = 2019,
                          module = NULL,
                          cache_dir = NULL,
                          refresh = FALSE) {

  # get dictionary
  dict <- pns_dictionary(
    year = year,
    cache_dir = cache_dir,
    refresh = refresh
  )

  # try to identify variable and label columns
  # common patterns in IBGE dictionaries
  possible_var_cols <- c("variavel", "variable", "var", "codigo", "code", "nome")
  possible_label_cols <- c("descricao", "description", "label", "rotulo", "desc")

  var_col <- NULL
  label_col <- NULL

  for (col in possible_var_cols) {
    if (col %in% names(dict)) {
      var_col <- col
      break
    }
  }

  for (col in possible_label_cols) {
    if (col %in% names(dict)) {
      label_col <- col
      break
    }
  }

  if (is.null(var_col)) {
    # return first two columns as fallback
    cli::cli_inform("Dictionary structure not recognized, returning raw structure.")
    return(dict)
  }

  # extract unique variables
  result <- dict |>
    dplyr::select(dplyr::all_of(c("year", var_col, if (!is.null(label_col)) label_col))) |>
    dplyr::distinct()

  # rename columns for consistency
  if (!is.null(label_col)) {
    names(result) <- c("year", "variable", "label")
  } else {
    names(result) <- c("year", "variable")
  }

  # filter by module if specified
  if (!is.null(module)) {
    module <- toupper(module)
    # variable names typically start with module letter
    result <- result |>
      dplyr::filter(stringr::str_detect(.data$variable, paste0("^", module)))
  }

  result
}

# ============================================================================
# public api functions - microdata
# ============================================================================

#' Download PNS microdata
#'
#' Downloads and returns PNS microdata for specified years from the IBGE FTP.
#' Data is cached locally to avoid repeated downloads. When the `arrow` package
#' is installed, data is cached in parquet format for faster subsequent reads.
#'
#' @param year Numeric or vector. Year(s) to download (2013, 2019).
#'   Use NULL to download all available years. Default is NULL.
#' @param vars Character vector. Variables to select. Use NULL for all variables.
#'   Default is NULL.
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
#' @return A tibble with PNS microdata.
#'
#' @details
#' The PNS (Pesquisa Nacional de Saude) is a household survey conducted by IBGE
#' in partnership with the Ministry of Health. It provides comprehensive data on
#' health conditions, lifestyle, and healthcare access of the Brazilian population.
#'
#' ## Survey design variables
#'
#' For proper statistical analysis with complex survey design, use the following
#' weight variables with the `srvyr` or `survey` packages:
#' - `V0028`: household weight
#' - `V0029`: selected person weight
#' - `V0030`: person weight with non-response adjustment
#' - `UPA_PNS`: primary sampling unit
#' - `V0024`: stratum
#'
#' @section Data source:
#' Data is downloaded from the IBGE FTP server:
#' \url{https://ftp.ibge.gov.br/PNS/}
#'
#' @export
#'
#' @examplesIf interactive()
#' # download PNS 2019 data
#' df <- pns_data(year = 2019, cache_dir = tempdir())
#'
#' # download all years
#' df_all <- pns_data(cache_dir = tempdir())
#'
#' # select specific variables
#' df_subset <- pns_data(
#'   year = 2019,
#'   vars = c("V0001", "C006", "C008", "V0028"),
#'   cache_dir = tempdir()
#' )
pns_data <- function(year = NULL,
                     vars = NULL,
                     cache_dir = NULL,
                     refresh = FALSE,
                     lazy = FALSE, backend = c("arrow", "duckdb")) {

  # validate year
  year <- validate_pns_year(year)

  # set cache directory
  cache_dir <- pns_cache_dir(cache_dir)

  # lazy evaluation: return from partitioned cache if available
  if (isTRUE(lazy)) {
    backend <- match.arg(backend)
    cache_dir_resolved <- .module_cache_dir("pns", cache_dir)
    year_filter <- if (!is.null(year)) as.character(year) else NULL
    select_cols <- if (!is.null(vars)) unique(c("year", vars)) else NULL
    ds <- .lazy_return(cache_dir_resolved, "pns_data", backend,
                       filters = if (!is.null(year_filter)) list(year = year_filter) else list(),
                       select_cols = select_cols)
    if (!is.null(ds)) return(ds)
  }

  # download and load data for each year
  dataset_name <- "pns_data"

  data_list <- .map_parallel(year, function(y) {
    target_year <- as.character(y)

    # 1. check partitioned cache first (preferred path)
    if (!refresh && .has_arrow() &&
        .has_partitioned_cache(cache_dir, dataset_name)) {
      ds <- arrow::open_dataset(file.path(cache_dir, dataset_name))
      cached <- ds |>
        dplyr::filter(.data$year == target_year) |>
        dplyr::collect()
      if (nrow(cached) > 0) {
        cli::cli_inform("Loading PNS {y} from cache...")
        return(cached)
      }
    }

    # 2. download and read
    zip_path <- pns_download_data(y, cache_dir, refresh)
    data <- pns_read_microdata(zip_path, y)

    # 4. write to partitioned cache
    .cache_append_partitioned(data, cache_dir, dataset_name, c("year"))

    data
  })

  # combine all years
  combined_data <- dplyr::bind_rows(data_list)

  # if lazy was requested, return from cache after download
  if (isTRUE(lazy)) {
    backend <- match.arg(backend)
    cache_dir_resolved <- .module_cache_dir("pns", cache_dir)
    year_filter <- if (!is.null(year)) as.character(year) else NULL
    select_cols <- if (!is.null(vars)) unique(c("year", vars)) else NULL
    ds <- .lazy_return(cache_dir_resolved, "pns_data", backend,
                       filters = if (!is.null(year_filter)) list(year = year_filter) else list(),
                       select_cols = select_cols)
    if (!is.null(ds)) return(ds)
  }

  # select variables if specified
  if (!is.null(vars)) {
    vars <- toupper(vars)
    # always keep year column
    vars_to_select <- unique(c("year", vars))
    available_vars <- names(combined_data)
    missing_vars <- setdiff(vars_to_select, available_vars)
    if (length(missing_vars) > 0) {
      cli::cli_warn("Variable{?s} not found: {.val {missing_vars}}")
    }
    vars_to_select <- intersect(vars_to_select, available_vars)
    combined_data <- combined_data |>
      dplyr::select(dplyr::all_of(vars_to_select))
  }

  # report
  years_in_data <- unique(combined_data$year)
  cli::cli_alert_success(
    "Loaded {.val {nrow(combined_data)}} observations from {.val {length(years_in_data)}} year{?s}: {.val {years_in_data}}"
  )

  combined_data
}

# ============================================================================
# public api functions - SIDRA
# ============================================================================

#' List PNS SIDRA tables
#'
#' Returns a catalog of available SIDRA tables for the PNS, organized by
#' health theme.
#'
#' @param theme Character. Filter by theme. NULL returns all themes.
#'   Available themes: "chronic_diseases", "lifestyle", "health_services",
#'   "health_perception", "womens_health", "accidents_violence",
#'   "oral_health", "anthropometry", "health_insurance", "disability",
#'   "elderly", "tobacco", "alcohol", "physical_activity", "nutrition",
#'   "medications", "mental_health", "work_health", "child_health".
#' @param year Numeric. Filter tables that contain data for this year.
#'   NULL returns tables for all years.
#'
#' @return A tibble with columns: table_code, table_name, theme,
#'   theme_label, years, territorial_levels.
#'
#' @export
#'
#' @examples
#' # list all tables
#' pns_sidra_tables()
#'
#' # filter by theme
#' pns_sidra_tables(theme = "chronic_diseases")
#'
#' # tables with 2013 data
#' pns_sidra_tables(year = 2013)
pns_sidra_tables <- function(theme = NULL, year = NULL) {

  catalog <- pns_sidra_catalog_internal

  # validate and filter by theme
  if (!is.null(theme)) {
    available_themes <- unique(catalog$theme)
    theme <- tolower(theme)
    invalid <- theme[!theme %in% available_themes]
    if (length(invalid) > 0) {
      cli::cli_abort(c(
        "Invalid theme{?s}: {.val {invalid}}",
        "i" = "Available themes: {.val {sort(available_themes)}}"
      ))
    }
    catalog <- catalog |>
      dplyr::filter(.data$theme %in% !!theme)
  }

  # filter by year
  if (!is.null(year)) {
    year_char <- as.character(year)
    catalog <- catalog |>
      dplyr::filter(purrr::map_lgl(.data$years, ~ any(year_char %in% .x)))
  }

  catalog |>
    dplyr::select(
      "table_code", "table_name", "theme", "theme_label", "years", "territorial_levels"
    ) |>
    dplyr::arrange(.data$theme, .data$table_code)
}

#' Search PNS SIDRA tables
#'
#' Searches PNS SIDRA tables by keyword in the table name/description.
#' Supports partial matching, case-insensitive, and accent-insensitive search.
#'
#' @param keyword Character. Search term (minimum 2 characters).
#' @param year Numeric. Filter tables containing data for this year.
#'   NULL returns all.
#'
#' @return A tibble with matching tables (same structure as pns_sidra_tables()).
#'
#' @export
#'
#' @examples
#' pns_sidra_search("diabetes")
#' pns_sidra_search("hipertensao")
#' pns_sidra_search("fumante")
pns_sidra_search <- function(keyword, year = NULL) {

  # validate keyword
  if (missing(keyword) || is.null(keyword) || nchar(keyword) < 2) {
    cli::cli_abort("Please provide a keyword with at least 2 characters.")
  }

  catalog <- pns_sidra_catalog_internal

  keyword_norm <- .strip_accents(tolower(keyword))

  # search in table names
  table_names_norm <- .strip_accents(tolower(catalog$table_name))
  matches <- grepl(keyword_norm, table_names_norm, fixed = TRUE)
  catalog <- catalog[matches, ]

  # filter by year
  if (!is.null(year)) {
    year_char <- as.character(year)
    catalog <- catalog |>
      dplyr::filter(purrr::map_lgl(.data$years, ~ any(year_char %in% .x)))
  }

  # inform results
  if (nrow(catalog) == 0) {
    cli::cli_alert_warning("No tables found for keyword: '{keyword}'")
  } else {
    cli::cli_alert_info("Found {nrow(catalog)} table(s) matching '{keyword}'")
  }

  catalog |>
    dplyr::select(
      "table_code", "table_name", "theme", "theme_label", "years", "territorial_levels"
    ) |>
    dplyr::arrange(.data$table_code)
}

#' Get PNS tabulated data from SIDRA API
#'
#' Queries the IBGE SIDRA API to retrieve tabulated PNS indicators.
#' Returns pre-aggregated data (prevalences, means, proportions) with
#' confidence intervals and coefficients of variation.
#'
#' @param table Numeric or character. SIDRA table code.
#'   Use \code{pns_sidra_tables()} or \code{pns_sidra_search()} to find codes.
#' @param territorial_level Character. Geographic level:
#'   "brazil" (N1), "region" (N2), "state" (N3), "municipality" (N6).
#'   Default "brazil".
#' @param geo_code Character. IBGE code(s) for specific localities.
#'   "all" returns all localities at the chosen level. Default "all".
#' @param year Numeric. Year(s) to query. NULL returns all available periods.
#' @param variable Numeric or character. SIDRA variable ID(s).
#'   NULL returns all variables excluding metadata. Default NULL.
#' @param classifications Named list. SIDRA classification filters.
#'   Example: list("2" = "6794") for sex = total.
#'   NULL returns default aggregation. Default NULL.
#' @param raw Logical. If TRUE, returns raw API output without cleaning.
#'   Default FALSE.
#'
#' @return A tibble with queried indicators.
#'
#' @export
#'
#' @examplesIf interactive()
#' # self-rated health by state, 2019
#' pns_sidra_data(
#'   table = 4751,
#'   territorial_level = "state",
#'   year = 2019
#' )
#'
#' # same table, Brazil-level, both years
#' pns_sidra_data(
#'   table = 4751,
#'   territorial_level = "brazil",
#'   year = c(2013, 2019)
#' )
#'
#' # hypertension data
#' pns_sidra_data(
#'   table = 4416,
#'   territorial_level = "brazil"
#' )
pns_sidra_data <- function(table,
                           territorial_level = "brazil",
                           geo_code = "all",
                           year = NULL,
                           variable = NULL,
                           classifications = NULL,
                           raw = FALSE) {

  # validate table
  table <- as.character(table)

  # check if table exists in catalog (soft warning)
  if (!table %in% pns_sidra_catalog_internal$table_code) {
    cli::cli_alert_warning(
      "Table {.val {table}} not found in internal catalog. Proceeding with API call."
    )
  }

  # validate territorial level
  if (!territorial_level %in% names(sidra_level_map)) {
    cli::cli_abort(c(
      "Invalid territorial_level: {.val {territorial_level}}",
      "i" = "Available: {.val {names(sidra_level_map)}}"
    ))
  }
  level_code <- sidra_level_map[[territorial_level]]

  # build SIDRA API URL
  base_url <- "https://apisidra.ibge.gov.br/values"

  url <- stringr::str_c(base_url, "/t/", table)
  url <- stringr::str_c(url, "/n", level_code, "/", geo_code)

  if (!is.null(variable)) {
    url <- stringr::str_c(url, "/v/", stringr::str_c(variable, collapse = ","))
  } else {
    url <- stringr::str_c(url, "/v/allxp")
  }

  if (!is.null(year)) {
    url <- stringr::str_c(url, "/p/", stringr::str_c(year, collapse = ","))
  } else {
    url <- stringr::str_c(url, "/p/all")
  }

  if (!is.null(classifications)) {
    for (class_id in names(classifications)) {
      class_values <- classifications[[class_id]]
      url <- stringr::str_c(
        url, "/c", class_id, "/",
        stringr::str_c(class_values, collapse = ",")
      )
    }
  }

  # make API request
  cli::cli_alert_info("Querying SIDRA API for table {.val {table}}...")

  response <- tryCatch(
    {
      curl::curl_fetch_memory(url, handle = curl::new_handle(timeout = 60))
    },
    error = function(e) {
      cli::cli_abort(c(
        "SIDRA API request failed",
        "i" = "Error: {e$message}",
        "i" = "Check your internet connection and try again."
      ))
    }
  )

  if (response$status_code != 200) {
    cli::cli_abort(c(
      "SIDRA API request failed with status {.val {response$status_code}}",
      "i" = "URL: {.url {url}}",
      "i" = "Check table code and parameters with {.fn pns_sidra_tables}"
    ))
  }

  # parse JSON response
  content <- rawToChar(response$content)
  Encoding(content) <- "UTF-8"
  data_raw <- jsonlite::fromJSON(content)

  if (is.null(data_raw) || length(data_raw) == 0) {
    cli::cli_alert_warning("No data returned for the specified parameters.")
    return(tibble::tibble())
  }

  data_raw <- tibble::as_tibble(data_raw)

  if (raw) {
    return(data_raw)
  }

  # clean and format
  result <- clean_sidra_response(data_raw, table)

  cli::cli_alert_success("Retrieved {.val {nrow(result)}} rows from SIDRA table {.val {table}}")

  result
}

# ============================================================================
# cache management functions
# ============================================================================

#' Clear PNS cache
#'
#' Removes all cached PNS data files.
#'
#' @param cache_dir Character. Optional custom cache directory. If NULL (default),
#'   uses the standard user cache directory.
#'
#' @return NULL (invisibly)
#'
#' @export
#'
#' @examples
#' pns_clear_cache()
pns_clear_cache <- function(cache_dir = NULL) {
  cache_dir <- pns_cache_dir(cache_dir)

  # list all files
  files <- list.files(cache_dir, full.names = TRUE, recursive = TRUE)

  if (length(files) == 0) {
    cli::cli_alert_info("Cache is already empty")
    return(invisible(NULL))
  }

  # remove all files
  unlink(cache_dir, recursive = TRUE)
  dir.create(cache_dir, recursive = TRUE)

  cli::cli_alert_success("PNS cache cleared")

  invisible(NULL)
}

#' Get PNS cache status
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
#' pns_cache_status()
pns_cache_status <- function(cache_dir = NULL) {
  cache_dir <- pns_cache_dir(cache_dir)

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

  tibble::tibble(
    file = basename(files),
    size_mb = round(file_info$size / 1024^2, 1),
    modified = file_info$mtime
  )
}
