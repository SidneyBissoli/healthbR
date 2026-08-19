# sipni internal data definitions for healthbR package
# constants, metadata, and dictionary data for the SI-PNI module

# ============================================================================
# available years
# ============================================================================

#' SI-PNI available years (aggregates 1994-2019 + microdata 2020+)
#'
#' Static fallback; when the R2 manifest has been read this session,
#' `.sipni_available_years()` extends this with the months actually
#' published on the mirror.
#' @noRd
sipni_available_years <- 1994L:2026L

#' SI-PNI year ranges by source
#' @noRd
sipni_ftp_years <- 1994L:2019L

#' @noRd
sipni_api_years <- 2020L:2026L

#' SI-PNI OpenDataSUS CSV base URL (CKAN S3 bucket of dadosabertos.saude.gov.br)
#'
#' The previous host (arquivosdadosabertos.saude.gov.br) was decommissioned
#' in 2026. Note: as of 2026-08 the Ministry only publishes the current
#' year's CSVs here; 2020-2025 files were removed from the source and are
#' available on the R2 mirror only.
#' @noRd
sipni_csv_base_url <- "https://s3.sa-east-1.amazonaws.com/ckan.saude.gov.br/PNI/csv"

#' SI-PNI month names in Portuguese (for CSV ZIP filenames)
#' @noRd
sipni_month_names <- c(
  "jan", "fev", "mar", "abr", "mai", "jun",
  "jul", "ago", "set", "out", "nov", "dez"
)

# ============================================================================
# UF codes
# ============================================================================

#' Brazilian state (UF) abbreviations
#' @noRd
sipni_uf_list <- c(
  "AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO", "MA",
  "MT", "MS", "MG", "PA", "PB", "PR", "PE", "PI", "RJ", "RN",
  "RS", "RO", "RR", "SC", "SP", "SE", "TO"
)

# ============================================================================
# valid types
# ============================================================================

#' SI-PNI valid file types
#' @noRd
sipni_valid_types <- tibble::tibble(
  code = c("DPNI", "CPNI", "API"),
  name = c("Doses Aplicadas", "Cobertura Vacinal", "Microdados"),
  description = c(
    "Doses de vacinas aplicadas por munic\u00edpio, faixa et\u00e1ria, imuno e dose (1994-2019)",
    "Cobertura vacinal por munic\u00edpio e imunobiol\u00f3gico (1994-2019)",
    "Microdados individuais de vacina\u00e7\u00e3o (2020+; R2 Parquet ou OpenDataSUS CSV)"
  )
)

# ============================================================================
# variables metadata (DPNI type)
# ============================================================================

#' SI-PNI variables metadata tibble (DPNI type)
#' @noRd
sipni_variables_dpni <- tibble::tibble(
  variable = c(
    # temporal
    "ANO", "ANOMES", "MES",
    # localizacao
    "UF", "MUNIC",
    # paciente
    "FX_ETARIA",
    # vacinacao
    "IMUNO", "DOSE", "QT_DOSE", "DOSE1", "DOSEN", "DIFER"
  ),
  description = c(
    # temporal
    "Ano de refer\u00eancia",
    "Ano e m\u00eas (AAAAMM)",
    "M\u00eas (01-12)",
    # localizacao
    "C\u00f3digo UF (IBGE 2 d\u00edgitos)",
    "C\u00f3digo munic\u00edpio (IBGE 6 d\u00edgitos)",
    # paciente
    "Faixa et\u00e1ria (codificada)",
    # vacinacao
    "C\u00f3digo do imunobiol\u00f3gico",
    "Tipo de dose",
    "Quantidade de doses aplicadas",
    "(Reservado)",
    "(Reservado)",
    "(Reservado)"
  ),
  type = c(
    # temporal
    "character", "character", "character",
    # localizacao
    "character", "character",
    # paciente
    "character",
    # vacinacao
    "character", "character", "integer", "character", "character", "character"
  ),
  section = c(
    # temporal
    rep("temporal", 3),
    # localizacao
    rep("localizacao", 2),
    # paciente
    "paciente",
    # vacinacao
    rep("vacinacao", 6)
  )
)

# ============================================================================
# variables metadata (CPNI type)
# ============================================================================

#' SI-PNI variables metadata tibble (CPNI type)
#' @noRd
sipni_variables_cpni <- tibble::tibble(
  variable = c(
    # temporal
    "ANO",
    # localizacao
    "UF", "MUNIC",
    # vacinacao
    "IMUNO", "QT_DOSE", "POP", "COBERT"
  ),
  description = c(
    # temporal
    "Ano de refer\u00eancia",
    # localizacao
    "C\u00f3digo UF (IBGE 2 d\u00edgitos)",
    "C\u00f3digo munic\u00edpio (IBGE 6 d\u00edgitos)",
    # vacinacao
    "C\u00f3digo do imunobiol\u00f3gico",
    "Quantidade de doses aplicadas",
    "Popula\u00e7\u00e3o alvo",
    "Cobertura vacinal (%)"
  ),
  type = c(
    # temporal
    "character",
    # localizacao
    "character", "character",
    # vacinacao
    "character", "integer", "integer", "double"
  ),
  section = c(
    "temporal",
    rep("localizacao", 2),
    rep("vacinacao", 4)
  )
)

# ============================================================================
# dictionary data
# ============================================================================

#' SI-PNI data dictionary tibble
#' @noRd
sipni_dictionary_data <- tibble::tibble(
  variable = c(
    # IMUNO (major vaccines)
    rep("IMUNO", 20),
    # DOSE
    rep("DOSE", 6),
    # FX_ETARIA
    rep("FX_ETARIA", 10)
  ),
  description = c(
    rep("C\u00f3digo do imunobiol\u00f3gico", 20),
    rep("Tipo de dose", 6),
    rep("Faixa et\u00e1ria", 10)
  ),
  code = c(
    # IMUNO
    "09", "21", "22", "23", "24", "28", "29", "39",
    "42", "46", "56", "63", "81", "82", "83", "84",
    "85", "86", "87", "99",
    # DOSE
    "1", "2", "3", "4", "R", "U",
    # FX_ETARIA
    "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"
  ),
  label = c(
    # IMUNO
    "BCG",
    "Hepatite B",
    "Tr\u00edplice bacteriana (DTP)",
    "Poliomielite oral (VOP)",
    "Sarampo",
    "Febre amarela",
    "Tr\u00edplice viral (SCR)",
    "Dupla adulto (dT)",
    "Tetravalente (DTP+Hib)",
    "Rotav\u00edrus humano",
    "Pneumoc\u00f3cica 10-valente",
    "Meningoc\u00f3cica C conjugada",
    "Pentavalente (DTP+HB+Hib)",
    "Poliomielite inativada (VIP)",
    "Hepatite A",
    "Pneumoc\u00f3cica 23-valente",
    "HPV quadrivalente",
    "dTpa (gestante)",
    "Varicela",
    "Outros imunobiol\u00f3gicos",
    # DOSE
    "1\u00aa dose",
    "2\u00aa dose",
    "3\u00aa dose",
    "4\u00aa dose",
    "Refor\u00e7o",
    "Dose \u00fanica",
    # FX_ETARIA
    "Menor de 1 ano",
    "1 ano",
    "2 anos",
    "3 anos",
    "4 anos",
    "5 a 9 anos",
    "10 a 14 anos",
    "15 a 19 anos",
    "20 anos e mais",
    "Ignorado"
  )
)

# ============================================================================
# label maps for categorical variables
# ============================================================================

# ============================================================================
# variables metadata (API type - individual-level microdata)
# ============================================================================

#' SI-PNI variables metadata tibble (API type - OpenDataSUS microdata)
#' @noRd
sipni_variables_api <- tibble::tibble(
  variable = c(
    # establishment
    "sigla_uf_estabelecimento", "nome_uf_estabelecimento",
    "codigo_municipio_estabelecimento", "nome_municipio_estabelecimento",
    "codigo_cnes_estabelecimento", "nome_razao_social_estabelecimento",
    "nome_fantasia_estalecimento", "codigo_tipo_estabelecimento",
    "descricao_tipo_estabelecimento", "codigo_natureza_estabelecimento",
    "descricao_natureza_estabelecimento",
    # patient
    "codigo_paciente", "tipo_sexo_paciente", "numero_idade_paciente",
    "codigo_raca_cor_paciente", "nome_raca_cor_paciente",
    "sigla_uf_paciente", "nome_uf_paciente",
    "codigo_municipio_paciente", "nome_municipio_paciente",
    "numero_cep_paciente", "codigo_etnia_indigena_paciente",
    "nome_etnia_indigena_paciente", "codigo_pais_paciente",
    "nome_pais_paciente", "descricao_nacionalidade_paciente",
    # vaccine
    "codigo_vacina", "sigla_vacina", "descricao_vacina",
    "codigo_dose_vacina", "descricao_dose_vacina",
    "codigo_lote_vacina", "codigo_vacina_fabricante",
    "descricao_vacina_fabricante", "data_vacina",
    # administration
    "codigo_via_administracao", "descricao_via_administracao",
    "codigo_local_aplicacao", "descricao_local_aplicacao",
    # strategy
    "codigo_estrategia_vacinacao", "descricao_estrategia_vacinacao",
    "codigo_vacina_grupo_atendimento", "descricao_vacina_grupo_atendimento",
    "codigo_vacina_categoria_atendimento", "descricao_vacina_categoria_atendimento",
    # maternal
    "codigo_condicao_maternal", "descricao_condicao_maternal"
  ),
  description = c(
    # establishment
    "Sigla UF do estabelecimento",
    "Nome UF do estabelecimento",
    "C\u00f3digo munic\u00edpio do estabelecimento (IBGE)",
    "Nome munic\u00edpio do estabelecimento",
    "C\u00f3digo CNES do estabelecimento",
    "Raz\u00e3o social do estabelecimento",
    "Nome fantasia do estabelecimento",
    "C\u00f3digo tipo do estabelecimento",
    "Descri\u00e7\u00e3o tipo do estabelecimento",
    "C\u00f3digo natureza jur\u00eddica do estabelecimento",
    "Descri\u00e7\u00e3o natureza jur\u00eddica do estabelecimento",
    # patient
    "C\u00f3digo anonimizado do paciente",
    "Sexo do paciente (M/F)",
    "Idade do paciente",
    "C\u00f3digo ra\u00e7a/cor do paciente",
    "Nome ra\u00e7a/cor do paciente",
    "Sigla UF do paciente",
    "Nome UF do paciente",
    "C\u00f3digo munic\u00edpio do paciente (IBGE)",
    "Nome munic\u00edpio do paciente",
    "CEP do paciente",
    "C\u00f3digo etnia ind\u00edgena do paciente",
    "Nome etnia ind\u00edgena do paciente",
    "C\u00f3digo pa\u00eds do paciente",
    "Nome pa\u00eds do paciente",
    "Descri\u00e7\u00e3o da nacionalidade do paciente",
    # vaccine
    "C\u00f3digo da vacina",
    "Sigla da vacina",
    "Descri\u00e7\u00e3o da vacina",
    "C\u00f3digo da dose",
    "Descri\u00e7\u00e3o da dose",
    "C\u00f3digo do lote da vacina",
    "C\u00f3digo do fabricante da vacina",
    "Descri\u00e7\u00e3o do fabricante da vacina",
    "Data da vacina\u00e7\u00e3o (AAAA-MM-DD)",
    # administration
    "C\u00f3digo via de administra\u00e7\u00e3o",
    "Descri\u00e7\u00e3o via de administra\u00e7\u00e3o",
    "C\u00f3digo local de aplica\u00e7\u00e3o",
    "Descri\u00e7\u00e3o local de aplica\u00e7\u00e3o",
    # strategy
    "C\u00f3digo estrat\u00e9gia de vacina\u00e7\u00e3o",
    "Descri\u00e7\u00e3o estrat\u00e9gia de vacina\u00e7\u00e3o",
    "C\u00f3digo grupo de atendimento",
    "Descri\u00e7\u00e3o grupo de atendimento",
    "C\u00f3digo categoria de atendimento",
    "Descri\u00e7\u00e3o categoria de atendimento",
    # maternal
    "C\u00f3digo condi\u00e7\u00e3o maternal",
    "Descri\u00e7\u00e3o condi\u00e7\u00e3o maternal"
  ),
  type = c(
    # establishment (11)
    "character", "character", "character", "character", "character",
    "character", "character", "character", "character", "character",
    "character",
    # patient (15)
    "character", "character", "integer", "character", "character",
    "character", "character", "character", "character", "character",
    "character", "character", "character", "character", "character",
    # vaccine (9)
    "character", "character", "character", "character", "character",
    "character", "character", "character", "date",
    # administration (4)
    "character", "character", "character", "character",
    # strategy (6)
    "character", "character", "character", "character",
    "character", "character",
    # maternal (2)
    "character", "character"
  ),
  section = c(
    rep("estabelecimento", 11),
    rep("paciente", 15),
    rep("vacina", 9),
    rep("administracao", 4),
    rep("estrategia", 6),
    rep("maternal", 2)
  )
)

# ============================================================================
# variables metadata (microdata via R2 mirror - JSON origin, 56 fields)
# ============================================================================

#' SI-PNI microdata variables (R2 backend, 2020+)
#'
#' The R2 mirror publishes the Ministry's JSON exports (56 fields, prefixes
#' co_/no_/ds_/sg_/nu_/dt_/tp_/st_), which differ from the CSV export
#' column names in `sipni_variables_api`. Reference: the Ministry's
#' Dicionario_tb_ria_rotina.pdf.
#' @noRd
sipni_variables_microdados <- tibble::tribble(
  ~variable, ~description, ~type, ~section,
  "co_documento", "C\u00f3digo \u00fanico do registro de vacina\u00e7\u00e3o (RNDS)", "character", "registro",
  "co_paciente", "C\u00f3digo anonimizado do paciente", "character", "paciente",
  "tp_sexo_paciente", "Sexo do paciente (M/F)", "character", "paciente",
  "co_raca_cor_paciente", "C\u00f3digo ra\u00e7a/cor do paciente", "character", "paciente",
  "no_raca_cor_paciente", "Nome ra\u00e7a/cor do paciente", "character", "paciente",
  "co_municipio_paciente", "C\u00f3digo munic\u00edpio de resid\u00eancia do paciente (IBGE)", "character", "paciente",
  "co_pais_paciente", "C\u00f3digo pa\u00eds de resid\u00eancia do paciente", "character", "paciente",
  "no_municipio_paciente", "Nome munic\u00edpio de resid\u00eancia do paciente", "character", "paciente",
  "no_pais_paciente", "Nome pa\u00eds de resid\u00eancia do paciente", "character", "paciente",
  "sg_uf_paciente", "Sigla UF de resid\u00eancia do paciente", "character", "paciente",
  "nu_cep_paciente", "CEP do paciente", "character", "paciente",
  "ds_nacionalidade_paciente", "Nacionalidade do paciente", "character", "paciente",
  "no_etnia_indigena_paciente", "Nome etnia ind\u00edgena do paciente", "character", "paciente",
  "co_etnia_indigena_paciente", "C\u00f3digo etnia ind\u00edgena do paciente", "character", "paciente",
  "co_cnes_estabelecimento", "C\u00f3digo CNES do estabelecimento", "character", "estabelecimento",
  "no_razao_social_estabelecimento", "Raz\u00e3o social do estabelecimento", "character", "estabelecimento",
  "no_fantasia_estalecimento", "Nome fantasia do estabelecimento (grafia da fonte)", "character", "estabelecimento",
  "co_municipio_estabelecimento", "C\u00f3digo munic\u00edpio do estabelecimento (IBGE)", "character", "estabelecimento",
  "no_municipio_estabelecimento", "Nome munic\u00edpio do estabelecimento", "character", "estabelecimento",
  "sg_uf_estabelecimento", "Sigla UF do estabelecimento", "character", "estabelecimento",
  "co_troca_documento", "C\u00f3digo de troca do documento", "character", "registro",
  "co_vacina", "C\u00f3digo da vacina", "character", "vacina",
  "sg_vacina", "Sigla da vacina", "character", "vacina",
  "dt_vacina", "Data da vacina\u00e7\u00e3o (AAAA-MM-DD)", "date", "vacina",
  "co_dose_vacina", "C\u00f3digo da dose", "character", "vacina",
  "ds_dose_vacina", "Descri\u00e7\u00e3o da dose", "character", "vacina",
  "co_local_aplicacao", "C\u00f3digo local de aplica\u00e7\u00e3o", "character", "administracao",
  "ds_local_aplicacao", "Descri\u00e7\u00e3o local de aplica\u00e7\u00e3o", "character", "administracao",
  "co_via_administracao", "C\u00f3digo via de administra\u00e7\u00e3o", "character", "administracao",
  "ds_via_administracao", "Descri\u00e7\u00e3o via de administra\u00e7\u00e3o", "character", "administracao",
  "co_lote_vacina", "C\u00f3digo do lote da vacina", "character", "vacina",
  "ds_vacina_fabricante", "Nome do fabricante da vacina", "character", "vacina",
  "dt_entrada_rnds", "Data/hora de entrada do registro na RNDS", "character", "registro",
  "co_sistema_origem", "C\u00f3digo do sistema de origem", "character", "registro",
  "ds_sistema_origem", "Descri\u00e7\u00e3o do sistema de origem", "character", "registro",
  "st_documento", "Situa\u00e7\u00e3o do documento", "character", "registro",
  "co_estrategia_vacinacao", "C\u00f3digo estrat\u00e9gia de vacina\u00e7\u00e3o", "character", "estrategia",
  "ds_estrategia_vacinacao", "Descri\u00e7\u00e3o estrat\u00e9gia de vacina\u00e7\u00e3o", "character", "estrategia",
  "co_origem_registro", "C\u00f3digo origem do registro", "character", "registro",
  "ds_origem_registro", "Descri\u00e7\u00e3o origem do registro", "character", "registro",
  "co_vacina_grupo_atendimento", "C\u00f3digo grupo de atendimento", "character", "estrategia",
  "ds_vacina_grupo_atendimento", "Descri\u00e7\u00e3o grupo de atendimento", "character", "estrategia",
  "co_vacina_categoria_atendimento", "C\u00f3digo categoria de atendimento", "character", "estrategia",
  "ds_vacina_categoria_atendimento", "Descri\u00e7\u00e3o categoria de atendimento", "character", "estrategia",
  "co_vacina_fabricante", "C\u00f3digo do fabricante da vacina", "character", "vacina",
  "ds_vacina", "Descri\u00e7\u00e3o da vacina", "character", "vacina",
  "ds_condicao_maternal", "Descri\u00e7\u00e3o condi\u00e7\u00e3o maternal", "character", "maternal",
  "co_tipo_estabelecimento", "C\u00f3digo tipo do estabelecimento", "character", "estabelecimento",
  "ds_tipo_estabelecimento", "Descri\u00e7\u00e3o tipo do estabelecimento", "character", "estabelecimento",
  "co_natureza_estabelecimento", "C\u00f3digo natureza jur\u00eddica do estabelecimento", "character", "estabelecimento",
  "ds_natureza_estabelecimento", "Descri\u00e7\u00e3o natureza jur\u00eddica do estabelecimento", "character", "estabelecimento",
  "nu_idade_paciente", "Idade do paciente", "integer", "paciente",
  "co_condicao_maternal", "C\u00f3digo condi\u00e7\u00e3o maternal", "character", "maternal",
  "no_uf_paciente", "Nome UF de resid\u00eancia do paciente", "character", "paciente",
  "no_uf_estabelecimento", "Nome UF do estabelecimento", "character", "estabelecimento",
  "dt_deletado_rnds", "Data/hora de exclus\u00e3o do registro na RNDS", "character", "registro"
)

# ============================================================================
# label maps for categorical variables
# ============================================================================

#' Label maps for SI-PNI categorical variables
#' @noRd
sipni_label_maps <- list(
  IMUNO = c(
    "09" = "BCG",
    "21" = "Hepatite B",
    "22" = "Tr\u00edplice bacteriana (DTP)",
    "23" = "Poliomielite oral (VOP)",
    "24" = "Sarampo",
    "28" = "Febre amarela",
    "29" = "Tr\u00edplice viral (SCR)",
    "39" = "Dupla adulto (dT)",
    "42" = "Tetravalente (DTP+Hib)",
    "46" = "Rotav\u00edrus humano",
    "56" = "Pneumoc\u00f3cica 10-valente",
    "63" = "Meningoc\u00f3cica C conjugada",
    "81" = "Pentavalente (DTP+HB+Hib)",
    "82" = "Poliomielite inativada (VIP)",
    "83" = "Hepatite A",
    "84" = "Pneumoc\u00f3cica 23-valente",
    "85" = "HPV quadrivalente",
    "86" = "dTpa (gestante)",
    "87" = "Varicela",
    "99" = "Outros imunobiol\u00f3gicos"
  ),
  DOSE = c(
    "1" = "1\u00aa dose",
    "2" = "2\u00aa dose",
    "3" = "3\u00aa dose",
    "4" = "4\u00aa dose",
    "R" = "Refor\u00e7o",
    "U" = "Dose \u00fanica"
  ),
  FX_ETARIA = c(
    "1" = "Menor de 1 ano",
    "2" = "1 ano",
    "3" = "2 anos",
    "4" = "3 anos",
    "5" = "4 anos",
    "6" = "5 a 9 anos",
    "7" = "10 a 14 anos",
    "8" = "15 a 19 anos",
    "9" = "20 anos e mais",
    "10" = "Ignorado"
  )
)
