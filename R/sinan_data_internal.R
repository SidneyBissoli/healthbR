# sinan internal data definitions for healthbR package
# constants, metadata, and dictionary data for the SINAN module

# ============================================================================
# available years
# ============================================================================

#' SINAN available years by status
#' @noRd
sinan_available_years <- list(
  final = 2007L:2022L,
  preliminary = 2023L:2024L
)

# ============================================================================
# valid diseases (agravos)
# ============================================================================

#' SINAN valid disease (agravo) codes
#' @noRd
sinan_valid_diseases <- tibble::tibble(
  code = c(
    "ACBI", "ACGR", "ANIM", "BOTU", "CHAG", "CHIK", "COQU", "DENG",
    "DIFT", "ESQU", "FEAM", "FETI", "FMAC", "HANS", "HANT", "HEPA",
    "IEXO", "LEIV", "LEIT", "LEPT", "MALA", "MENI", "PEST", "RAIV",
    "SIFA", "SIFC", "SIFG", "TETA", "TUBE", "VIOL", "ZIKA"
  ),
  name = c(
    "Acidente Biologico", "Acidente Grave", "Animais Peconhentos",
    "Botulismo", "Chagas", "Chikungunya", "Coqueluche", "Dengue",
    "Difteria", "Esquistossomose", "Febre Amarela", "Febre Tifoide",
    "Febre Maculosa", "Hanseniase", "Hantavirose", "Hepatites Virais",
    "Intox. Exogena", "Leishmaniose Visceral", "Leishmaniose Tegumentar",
    "Leptospirose", "Malaria", "Meningite", "Peste", "Raiva",
    "Sifilis Adquirida", "Sifilis Congenita", "Sifilis Gestacional",
    "Tetano", "Tuberculose", "Violencia", "Zika"
  ),
  description = c(
    "Acidente de trabalho com material biologico",
    "Acidente de trabalho grave",
    "Acidentes por animais pe\u00e7onhentos",
    "Botulismo",
    "Doen\u00e7a de Chagas",
    "Febre de Chikungunya",
    "Coqueluche (pertussis)",
    "Dengue",
    "Difteria",
    "Esquistossomose",
    "Febre amarela",
    "Febre tifoide",
    "Febre maculosa e rickettsioses",
    "Hansen\u00edase (lepra)",
    "S\u00edndrome pulmonar por hantav\u00edrus",
    "Hepatites virais",
    "Intoxica\u00e7\u00e3o ex\u00f3gena",
    "Leishmaniose visceral",
    "Leishmaniose tegumentar",
    "Leptospirose",
    "Mal\u00e1ria",
    "Meningite",
    "Peste",
    "Atendimento antirr\u00e1bico",
    "S\u00edfilis adquirida",
    "S\u00edfilis cong\u00eanita",
    "S\u00edfilis em gestante",
    "T\u00e9tano acidental",
    "Tuberculose",
    "Viol\u00eancia dom\u00e9stica/sexual",
    "Zika v\u00edrus"
  )
)

# ============================================================================
# variables metadata
# ============================================================================

#' SINAN variables metadata tibble
#' @noRd
sinan_variables_metadata <- tibble::tibble(
  variable = c(
    # notificacao
    "NU_NOTIFIC", "TP_NOT", "ID_AGRAVO", "DT_NOTIFIC", "SEM_NOT",
    "NU_ANO", "DT_SIN_PRI", "SEM_PRI",
    # paciente
    "NM_PACIENT", "DT_NASC", "NU_IDADE_N", "CS_SEXO", "CS_GESTANT",
    "CS_RACA", "CS_ESCOL_N",
    # residencia
    "SG_UF_NOT", "ID_MUNICIP", "ID_REGIONA", "ID_UNIDADE",
    "SG_UF", "ID_MN_RESI", "ID_RG_RESI",
    # investigacao
    "CLASSI_FIN", "CRITERIO", "EVOLUCAO", "DT_OBITO",
    "DT_ENCERRA", "DT_INVEST",
    # temporal
    "DT_DIGITA", "CS_FLXRET", "FLXRECEBI", "TPUNINOT"
  ),
  description = c(
    # notificacao
    "N\u00famero da notifica\u00e7\u00e3o",
    "Tipo de notifica\u00e7\u00e3o (1=Negativa, 2=Individual, 3=Surto, 4=Agregado)",
    "C\u00f3digo do agravo notificado (CID-10)",
    "Data da notifica\u00e7\u00e3o (dd/mm/aaaa)",
    "Semana epidemiol\u00f3gica da notifica\u00e7\u00e3o",
    "Ano da notifica\u00e7\u00e3o",
    "Data dos primeiros sintomas",
    "Semana epidemiol\u00f3gica dos primeiros sintomas",
    # paciente
    "Nome do paciente",
    "Data de nascimento",
    "Idade (codificada: 1=hora, 2=dia, 3=m\u00eas, 4=ano)",
    "Sexo (M=Masculino, F=Feminino, I=Ignorado)",
    "Gesta\u00e7\u00e3o (1=1\u00ba tri, 2=2\u00ba tri, 3=3\u00ba tri, 4=IG desconhecida, 5=N\u00e3o, 6=N/A, 9=Ignorado)",
    "Ra\u00e7a/cor (1=Branca, 2=Preta, 3=Amarela, 4=Parda, 5=Ind\u00edgena, 9=Ignorado)",
    "Escolaridade (0=Analfabeto, 1=1\u00aa-4\u00aa, 2=5\u00aa-8\u00aa, 3=EM incompleto, 4=EM completo, 5=ES incompleta, 6=ES completa, 7=N/A, 8=Ignorado, 9=Ignorado, 10=1\u00aa-4\u00aa incompleta, 11=4\u00aa completa, 12=5\u00aa-8\u00aa incompleta, 13=Fundamental completo)",
    # residencia
    "UF de notifica\u00e7\u00e3o (sigla)",
    "Munic\u00edpio de notifica\u00e7\u00e3o (c\u00f3digo IBGE 6 d\u00edgitos)",
    "Regional de notifica\u00e7\u00e3o",
    "Unidade notificadora (CNES)",
    "UF de resid\u00eancia (sigla)",
    "Munic\u00edpio de resid\u00eancia (c\u00f3digo IBGE 6 d\u00edgitos)",
    "Regional de resid\u00eancia",
    # investigacao
    "Classifica\u00e7\u00e3o final",
    "Crit\u00e9rio de confirma\u00e7\u00e3o/descarte",
    "Evolu\u00e7\u00e3o (1=Cura, 2=\u00d3bito pelo agravo, 3=\u00d3bito por outras causas, 9=Ignorado)",
    "Data do \u00f3bito",
    "Data de encerramento da investiga\u00e7\u00e3o",
    "Data da investiga\u00e7\u00e3o",
    # temporal
    "Data de digita\u00e7\u00e3o",
    "Fluxo de retorno",
    "Fluxo recebimento",
    "Tipo da unidade notificadora"
  ),
  type = c(
    # notificacao
    "character", "character", "character", "date_dmy", "character",
    "integer", "date_dmy", "character",
    # paciente
    "character", "date_dmy", "character", "character", "character",
    "character", "character",
    # residencia
    "character", "character", "character", "character",
    "character", "character", "character",
    # investigacao
    "character", "character", "character", "date_dmy",
    "date_dmy", "date_dmy",
    # temporal
    "date_dmy", "character", "character", "character"
  ),
  section = c(
    # notificacao
    rep("notificacao", 8),
    # paciente
    rep("paciente", 7),
    # residencia
    rep("residencia", 7),
    # investigacao
    rep("investigacao", 6),
    # temporal
    rep("temporal", 4)
  )
)

# ============================================================================
# dictionary data
# ============================================================================

#' SINAN data dictionary tibble
#' @noRd
sinan_dictionary_data <- tibble::tibble(
  variable = c(
    # TP_NOT
    rep("TP_NOT", 4),
    # CS_SEXO
    rep("CS_SEXO", 3),
    # CS_RACA
    rep("CS_RACA", 6),
    # CS_GESTANT
    rep("CS_GESTANT", 7),
    # CS_ESCOL_N
    rep("CS_ESCOL_N", 14),
    # CLASSI_FIN
    rep("CLASSI_FIN", 5),
    # EVOLUCAO
    rep("EVOLUCAO", 4),
    # CRITERIO
    rep("CRITERIO", 4),
    # NU_IDADE_N
    rep("NU_IDADE_N", 4)
  ),
  description = c(
    rep("Tipo de notifica\u00e7\u00e3o", 4),
    rep("Sexo", 3),
    rep("Ra\u00e7a/cor", 6),
    rep("Gesta\u00e7\u00e3o", 7),
    rep("Escolaridade", 14),
    rep("Classifica\u00e7\u00e3o final", 5),
    rep("Evolu\u00e7\u00e3o do caso", 4),
    rep("Crit\u00e9rio de confirma\u00e7\u00e3o/descarte", 4),
    rep("Idade (1\u00ba d\u00edgito = unidade)", 4)
  ),
  code = c(
    # TP_NOT
    "1", "2", "3", "4",
    # CS_SEXO
    "M", "F", "I",
    # CS_RACA
    "1", "2", "3", "4", "5", "9",
    # CS_GESTANT
    "1", "2", "3", "4", "5", "6", "9",
    # CS_ESCOL_N
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    "10", "11", "12", "13",
    # CLASSI_FIN
    "1", "2", "3", "5", "8",
    # EVOLUCAO
    "1", "2", "3", "9",
    # CRITERIO
    "1", "2", "3", "4",
    # NU_IDADE_N
    "1", "2", "3", "4"
  ),
  label = c(
    # TP_NOT
    "Negativa", "Individual", "Surto", "Agregado",
    # CS_SEXO
    "Masculino", "Feminino", "Ignorado",
    # CS_RACA
    "Branca", "Preta", "Amarela", "Parda", "Ind\u00edgena", "Ignorado",
    # CS_GESTANT
    "1\u00ba trimestre", "2\u00ba trimestre", "3\u00ba trimestre",
    "Idade gestacional desconhecida", "N\u00e3o", "N\u00e3o se aplica", "Ignorado",
    # CS_ESCOL_N
    "Analfabeto", "1\u00aa a 4\u00aa s\u00e9rie incompleta do EF",
    "4\u00aa s\u00e9rie completa do EF",
    "5\u00aa a 8\u00aa s\u00e9rie incompleta do EF",
    "Ensino fundamental completo",
    "Ensino m\u00e9dio incompleto", "Ensino m\u00e9dio completo",
    "Educa\u00e7\u00e3o superior incompleta", "Educa\u00e7\u00e3o superior completa",
    "Ignorado",
    "1\u00aa a 4\u00aa s\u00e9rie incompleta do EF (antigo)",
    "4\u00aa s\u00e9rie completa do EF (antigo)",
    "5\u00aa a 8\u00aa s\u00e9rie incompleta do EF (antigo)",
    "Ensino fundamental completo (antigo)",
    # CLASSI_FIN
    "Confirmado", "Descartado", "Inconclusivo",
    "Confirmado por crit\u00e9rio cl\u00ednico-epidemiol\u00f3gico",
    "Inconclusivo",
    # EVOLUCAO
    "Cura", "\u00d3bito pelo agravo notificado",
    "\u00d3bito por outras causas", "Ignorado",
    # CRITERIO
    "Laboratorial", "Cl\u00ednico-epidemiol\u00f3gico",
    "Cl\u00ednico", "Em investiga\u00e7\u00e3o",
    # NU_IDADE_N
    "Hora", "Dia", "M\u00eas", "Ano"
  )
)

# ============================================================================
# label maps for categorical variables
# ============================================================================

#' Label maps for SINAN categorical variables
#' @noRd
sinan_label_maps <- list(
  CS_SEXO = c("M" = "Masculino", "F" = "Feminino", "I" = "Ignorado"),
  CS_RACA = c(
    "1" = "Branca", "2" = "Preta", "3" = "Amarela",
    "4" = "Parda", "5" = "Ind\u00edgena", "9" = "Ignorado"
  ),
  TP_NOT = c(
    "1" = "Negativa", "2" = "Individual",
    "3" = "Surto", "4" = "Agregado"
  ),
  CS_GESTANT = c(
    "1" = "1\u00ba trimestre", "2" = "2\u00ba trimestre",
    "3" = "3\u00ba trimestre",
    "4" = "Idade gestacional desconhecida",
    "5" = "N\u00e3o", "6" = "N\u00e3o se aplica", "9" = "Ignorado"
  ),
  CLASSI_FIN = c(
    "1" = "Confirmado", "2" = "Descartado",
    "3" = "Inconclusivo",
    "5" = "Confirmado por crit\u00e9rio cl\u00ednico-epidemiol\u00f3gico",
    "8" = "Inconclusivo"
  ),
  EVOLUCAO = c(
    "1" = "Cura", "2" = "\u00d3bito pelo agravo notificado",
    "3" = "\u00d3bito por outras causas", "9" = "Ignorado"
  ),
  CRITERIO = c(
    "1" = "Laboratorial", "2" = "Cl\u00ednico-epidemiol\u00f3gico",
    "3" = "Cl\u00ednico", "4" = "Em investiga\u00e7\u00e3o"
  )
)
