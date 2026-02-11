# sinasc internal data definitions for healthbR package
# constants, metadata, and dictionary data for the SINASC module

# ============================================================================
# available years
# ============================================================================

#' SINASC available years by status
#' @noRd
sinasc_available_years <- list(
  final = 1996L:2022L,
  preliminary = 2023L:2024L
)

# ============================================================================
# UF codes
# ============================================================================

#' Brazilian state (UF) abbreviations
#' @noRd
sinasc_uf_list <- c(
  "AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO", "MA",
  "MT", "MS", "MG", "PA", "PB", "PR", "PE", "PI", "RJ", "RN",
  "RS", "RO", "RR", "SC", "SP", "SE", "TO"
)

# ============================================================================
# variables metadata
# ============================================================================

#' SINASC variables metadata tibble
#' @noRd
sinasc_variables_metadata <- tibble::tibble(
  variable = c(
    # recem_nascido
    "DTNASC", "HORANASC", "SEXO", "RACACOR", "PESO",
    "APGAR1", "APGAR5", "IDANOMAL", "CODANOMAL",
    # materna
    "IDADEMAE", "ESTCIVMAE", "ESCMAE", "ESCMAE2010",
    "RACACORMAE", "CODOCUPMAE", "QTDFILVIVO", "QTDFILMORT",
    "SERIESCMAE",
    # gestacao
    "GESTACAO", "SEMAGESTAC", "GRAVIDEZ", "CONSULTAS",
    "MESPRENAT", "TPNASCASSI",
    # parto
    "PARTO", "TPROBSON", "STCESPARTO", "STTRABPART",
    # localizacao
    "LOCNASC", "CODESTAB", "CODMUNNASC", "CODMUNRES",
    "CODMUNNATU",
    # administrativa
    "NUMERODO", "ORIGEM", "NUMEROLOTE", "DTCADASTRO",
    "DTRECEBIM", "DIFDATA", "KOTELCHUCK", "STDNEPIDEM",
    "STDNNOVA", "TPFUNCRESP", "TPDOCRESP"
  ),
  description = c(
    # recem_nascido
    "Data de nascimento (ddmmaaaa)",
    "Hora do nascimento",
    "Sexo (1=Masculino, 2=Feminino, 0/9=Ignorado)",
    "Ra\u00e7a/cor do rec\u00e9m-nascido",
    "Peso ao nascer (gramas)",
    "Apgar no 1\u00ba minuto",
    "Apgar no 5\u00ba minuto",
    "Anomalia cong\u00eanita detectada (1=Sim, 2=N\u00e3o, 9=Ignorado)",
    "C\u00f3digo da anomalia cong\u00eanita (CID-10)",
    # materna
    "Idade da m\u00e3e (anos)",
    "Estado civil da m\u00e3e",
    "Escolaridade da m\u00e3e (anos de estudo)",
    "Escolaridade da m\u00e3e (formato 2010+)",
    "Ra\u00e7a/cor da m\u00e3e",
    "Ocupa\u00e7\u00e3o da m\u00e3e (CBO-2002)",
    "Filhos vivos em gesta\u00e7\u00f5es anteriores",
    "Perdas fetais/abortos em gesta\u00e7\u00f5es anteriores",
    "S\u00e9rie escolar da m\u00e3e",
    # gestacao
    "Semanas de gesta\u00e7\u00e3o (categorias)",
    "Semanas de gesta\u00e7\u00e3o (n\u00famero)",
    "Tipo de gravidez (1=\u00danica, 2=Dupla, 3=Tripla+)",
    "Consultas pr\u00e9-natal (categorias)",
    "M\u00eas de in\u00edcio do pr\u00e9-natal",
    "Tipo de nascimento assistido por",
    # parto
    "Tipo de parto (1=Vaginal, 2=Ces\u00e1reo)",
    "Classifica\u00e7\u00e3o Grupo de Robson",
    "Ces\u00e1rea antes do in\u00edcio do trabalho de parto",
    "Trabalho de parto induzido",
    # localizacao
    "Local de nascimento (1=Hospital, 2=Outro estab., 3=Domic\u00edlio, 4=Outros)",
    "C\u00f3digo do estabelecimento de sa\u00fade",
    "Munic\u00edpio de nascimento (c\u00f3digo IBGE 6 d\u00edgitos)",
    "Munic\u00edpio de resid\u00eancia da m\u00e3e (c\u00f3digo IBGE 6 d\u00edgitos)",
    "Munic\u00edpio de naturalidade da m\u00e3e (c\u00f3digo IBGE)",
    # administrativa
    "N\u00famero da Declara\u00e7\u00e3o de Nascido Vivo",
    "Sistema de origem do registro",
    "N\u00famero do lote",
    "Data de cadastro no sistema",
    "Data de recebimento pelo n\u00edvel central",
    "Diferen\u00e7a entre nascimento e cadastro (dias)",
    "\u00cdndice de adequa\u00e7\u00e3o do pr\u00e9-natal (Kotelchuck)",
    "Status epidemiol\u00f3gico padr\u00e3o",
    "DN nova vers\u00e3o",
    "Tipo de fun\u00e7\u00e3o do respons\u00e1vel pelo preenchimento",
    "Tipo de documento do respons\u00e1vel"
  ),
  type = c(
    # recem_nascido
    "character", "character", "character", "character", "character",
    "character", "character", "character", "character",
    # materna
    "character", "character", "character", "character",
    "character", "character", "character", "character",
    "character",
    # gestacao
    "character", "character", "character", "character",
    "character", "character",
    # parto
    "character", "character", "character", "character",
    # localizacao
    "character", "character", "character", "character",
    "character",
    # administrativa
    "character", "character", "character", "character",
    "character", "character", "character", "character",
    "character", "character", "character"
  ),
  section = c(
    # recem_nascido
    rep("recem_nascido", 9),
    # materna
    rep("materna", 9),
    # gestacao
    rep("gestacao", 6),
    # parto
    rep("parto", 4),
    # localizacao
    rep("localizacao", 5),
    # administrativa
    rep("administrativa", 11)
  )
)

# ============================================================================
# dictionary data
# ============================================================================

#' SINASC data dictionary tibble
#' @noRd
sinasc_dictionary_data <- tibble::tibble(
  variable = c(
    # SEXO
    rep("SEXO", 3),
    # RACACOR
    rep("RACACOR", 5),
    # RACACORMAE
    rep("RACACORMAE", 5),
    # LOCNASC
    rep("LOCNASC", 5),
    # ESTCIVMAE
    rep("ESTCIVMAE", 6),
    # ESCMAE
    rep("ESCMAE", 6),
    # GESTACAO
    rep("GESTACAO", 7),
    # GRAVIDEZ
    rep("GRAVIDEZ", 4),
    # PARTO
    rep("PARTO", 3),
    # CONSULTAS
    rep("CONSULTAS", 5),
    # IDANOMAL
    rep("IDANOMAL", 3),
    # STCESPARTO
    rep("STCESPARTO", 4),
    # STTRABPART
    rep("STTRABPART", 4),
    # TPNASCASSI
    rep("TPNASCASSI", 4),
    # KOTELCHUCK
    rep("KOTELCHUCK", 5)
  ),
  description = c(
    rep("Sexo do rec\u00e9m-nascido", 3),
    rep("Ra\u00e7a/cor do rec\u00e9m-nascido", 5),
    rep("Ra\u00e7a/cor da m\u00e3e", 5),
    rep("Local de nascimento", 5),
    rep("Estado civil da m\u00e3e", 6),
    rep("Escolaridade da m\u00e3e (anos de estudo)", 6),
    rep("Semanas de gesta\u00e7\u00e3o", 7),
    rep("Tipo de gravidez", 4),
    rep("Tipo de parto", 3),
    rep("Consultas pr\u00e9-natal", 5),
    rep("Anomalia cong\u00eanita", 3),
    rep("Ces\u00e1rea antes do trabalho de parto", 4),
    rep("Trabalho de parto induzido", 4),
    rep("Nascimento assistido por", 4),
    rep("\u00cdndice de Kotelchuck", 5)
  ),
  code = c(
    # SEXO
    "1", "2", "0",
    # RACACOR
    "1", "2", "3", "4", "5",
    # RACACORMAE
    "1", "2", "3", "4", "5",
    # LOCNASC
    "1", "2", "3", "4", "9",
    # ESTCIVMAE
    "1", "2", "3", "4", "5", "9",
    # ESCMAE
    "1", "2", "3", "4", "5", "9",
    # GESTACAO
    "1", "2", "3", "4", "5", "6", "9",
    # GRAVIDEZ
    "1", "2", "3", "9",
    # PARTO
    "1", "2", "9",
    # CONSULTAS
    "1", "2", "3", "4", "9",
    # IDANOMAL
    "1", "2", "9",
    # STCESPARTO
    "1", "2", "3", "9",
    # STTRABPART
    "1", "2", "3", "9",
    # TPNASCASSI
    "1", "2", "3", "9",
    # KOTELCHUCK
    "1", "2", "3", "4", "9"
  ),
  label = c(
    # SEXO
    "Masculino", "Feminino", "Ignorado",
    # RACACOR
    "Branca", "Preta", "Amarela", "Parda", "Ind\u00edgena",
    # RACACORMAE
    "Branca", "Preta", "Amarela", "Parda", "Ind\u00edgena",
    # LOCNASC
    "Hospital", "Outro estab. sa\u00fade", "Domic\u00edlio", "Outros", "Ignorado",
    # ESTCIVMAE
    "Solteira", "Casada", "Vi\u00fava",
    "Separada judicialmente", "Uni\u00e3o est\u00e1vel", "Ignorado",
    # ESCMAE
    "Nenhuma", "1 a 3 anos", "4 a 7 anos",
    "8 a 11 anos", "12 e mais", "Ignorado",
    # GESTACAO
    "Menos de 22 semanas", "22 a 27 semanas", "28 a 31 semanas",
    "32 a 36 semanas", "37 a 41 semanas", "42 e mais semanas", "Ignorado",
    # GRAVIDEZ
    "\u00danica", "Dupla", "Tripla e mais", "Ignorada",
    # PARTO
    "Vaginal", "Ces\u00e1reo", "Ignorado",
    # CONSULTAS
    "Nenhuma", "1 a 3", "4 a 6", "7 e mais", "Ignorado",
    # IDANOMAL
    "Sim", "N\u00e3o", "Ignorado",
    # STCESPARTO
    "Sim, antes", "Sim, durante/ap\u00f3s", "N\u00e3o", "Ignorado",
    # STTRABPART
    "Sim, espont\u00e2neo", "Sim, induzido", "N\u00e3o", "Ignorado",
    # TPNASCASSI
    "M\u00e9dico", "Enfermeira/obstetriz", "Parteira", "Outros/Ignorado",
    # KOTELCHUCK
    "Inadequado", "Intermedi\u00e1rio", "Adequado", "Mais que adequado", "N\u00e3o classificado"
  )
)

# ============================================================================
# label maps for categorical variables
# ============================================================================

#' Label maps for SINASC categorical variables
#' @noRd
sinasc_label_maps <- list(
  SEXO = c("1" = "Masculino", "2" = "Feminino", "0" = "Ignorado"),
  RACACOR = c(
    "1" = "Branca", "2" = "Preta", "3" = "Amarela",
    "4" = "Parda", "5" = "Ind\u00edgena"
  ),
  RACACORMAE = c(
    "1" = "Branca", "2" = "Preta", "3" = "Amarela",
    "4" = "Parda", "5" = "Ind\u00edgena"
  ),
  LOCNASC = c(
    "1" = "Hospital", "2" = "Outro estab. sa\u00fade",
    "3" = "Domic\u00edlio", "4" = "Outros", "9" = "Ignorado"
  ),
  ESTCIVMAE = c(
    "1" = "Solteira", "2" = "Casada", "3" = "Vi\u00fava",
    "4" = "Separada judicialmente", "5" = "Uni\u00e3o est\u00e1vel",
    "9" = "Ignorado"
  ),
  ESCMAE = c(
    "1" = "Nenhuma", "2" = "1 a 3 anos", "3" = "4 a 7 anos",
    "4" = "8 a 11 anos", "5" = "12 e mais", "9" = "Ignorado"
  ),
  GESTACAO = c(
    "1" = "Menos de 22 semanas", "2" = "22 a 27 semanas",
    "3" = "28 a 31 semanas", "4" = "32 a 36 semanas",
    "5" = "37 a 41 semanas", "6" = "42 e mais semanas",
    "9" = "Ignorado"
  ),
  GRAVIDEZ = c(
    "1" = "\u00danica", "2" = "Dupla",
    "3" = "Tripla e mais", "9" = "Ignorada"
  ),
  PARTO = c("1" = "Vaginal", "2" = "Ces\u00e1reo", "9" = "Ignorado"),
  CONSULTAS = c(
    "1" = "Nenhuma", "2" = "1 a 3", "3" = "4 a 6",
    "4" = "7 e mais", "9" = "Ignorado"
  ),
  IDANOMAL = c("1" = "Sim", "2" = "N\u00e3o", "9" = "Ignorado")
)
