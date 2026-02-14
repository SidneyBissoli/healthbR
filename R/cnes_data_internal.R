# cnes internal data definitions for healthbR package
# constants, metadata, and dictionary data for the CNES module

# ============================================================================
# available years
# ============================================================================

#' CNES available years by status
#' @noRd
cnes_available_years <- list(
  final = 2005L:2023L,
  preliminary = 2024L
)

# ============================================================================
# UF codes
# ============================================================================

#' Brazilian state (UF) abbreviations
#' @noRd
cnes_uf_list <- c(
  "AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO", "MA",
  "MT", "MS", "MG", "PA", "PB", "PR", "PE", "PI", "RJ", "RN",
  "RS", "RO", "RR", "SC", "SP", "SE", "TO"
)

# ============================================================================
# valid types
# ============================================================================

#' CNES valid file types
#' @noRd
cnes_valid_types <- tibble::tibble(
  code = c(
    "ST", "LT", "PF", "DC", "EQ", "SR", "HB", "EP",
    "RC", "IN", "EE", "EF", "GM"
  ),
  name = c(
    "Estabelecimentos",
    "Leitos",
    "Profissional",
    "Dados Complementares",
    "Equipamentos",
    "Servi\u00e7o Especializado",
    "Habilita\u00e7\u00e3o",
    "Equipes",
    "Regra Contratual",
    "Incentivos",
    "Estab. de Ensino",
    "Estab. Filantr\u00f3pico",
    "Gest\u00e3o e Metas"
  ),
  description = c(
    "Cadastro de estabelecimentos de sa\u00fade",
    "Leitos hospitalares",
    "Profissionais de sa\u00fade",
    "Dados complementares do estabelecimento",
    "Equipamentos de sa\u00fade",
    "Servi\u00e7os especializados",
    "Habilita\u00e7\u00f5es",
    "Equipes de sa\u00fade",
    "Regras contratuais",
    "Incentivos financeiros",
    "Estabelecimentos de ensino em sa\u00fade",
    "Estabelecimentos filantr\u00f3picos",
    "Gest\u00e3o e metas"
  )
)

# ============================================================================
# variables metadata (ST type)
# ============================================================================

#' CNES variables metadata tibble (ST type)
#' @noRd
cnes_variables_metadata <- tibble::tibble(
  variable = c(
    # identificacao
    "CNES", "CODUFMUN", "COD_CEP", "CPF_CNPJ", "PF_PJ",
    "NIV_DEP", "CNPJ_MAN", "COD_IR",
    # classificacao
    "TP_UNID", "TURNO_AT", "NIV_HIER", "TP_PREST",
    # sus
    "VINC_SUS", "TP_GESTAO", "ESFERA_A", "ATIVIDAD",
    "RETESSION", "NAT_JUR",
    # atendimento
    "ATV_AMBUL", "ATV_HOSP", "ATV_URG", "ATV_SUR",
    "ATV_ENSN", "ATV_VIGIL",
    # temporal
    "COMPETEN", "DTCARGA", "DT_ATUAL"
  ),
  description = c(
    # identificacao
    "C\u00f3digo CNES do estabelecimento",
    "C\u00f3digo UF + Munic\u00edpio (IBGE 6 d\u00edgitos)",
    "CEP do estabelecimento",
    "CPF ou CNPJ do estabelecimento",
    "Pessoa F\u00edsica ou Jur\u00eddica (1=PF, 3=PJ)",
    "N\u00edvel de depend\u00eancia (1=Individual, 3=Mantido)",
    "CNPJ da mantenedora",
    "C\u00f3digo na Receita Federal",
    # classificacao
    "Tipo de unidade (hospital, UBS, cl\u00ednica, etc.)",
    "Turno de atendimento",
    "N\u00edvel de hierarquia",
    "Tipo de prestador",
    # sus
    "V\u00ednculo com o SUS (0=N\u00e3o, 1=Sim)",
    "Tipo de gest\u00e3o (M=Municipal, E=Estadual, D=Dupla, S=Sem gest\u00e3o)",
    "Esfera administrativa (1=Federal, 2=Estadual, 3=Municipal, 4=Privada)",
    "Atividade de ensino/pesquisa",
    "Reten\u00e7\u00e3o de tributos",
    "Natureza jur\u00eddica",
    # atendimento
    "Atendimento ambulatorial (1=Sim, 0=N\u00e3o)",
    "Atendimento hospitalar (1=Sim, 0=N\u00e3o)",
    "Atendimento de urg\u00eancia (1=Sim, 0=N\u00e3o)",
    "Atendimento de vigil\u00e2ncia em sa\u00fade (SADT)",
    "Atividade de ensino (1=Sim, 0=N\u00e3o)",
    "Atividade de vigil\u00e2ncia epidemiol\u00f3gica (1=Sim, 0=N\u00e3o)",
    # temporal
    "Compet\u00eancia (AAAAMM)",
    "Data de carga dos dados",
    "Data de atualiza\u00e7\u00e3o do cadastro"
  ),
  type = c(
    # identificacao
    "character", "character", "character", "character", "character",
    "character", "character", "character",
    # classificacao
    "character", "character", "character", "character",
    # sus
    "character", "character", "character", "character",
    "character", "character",
    # atendimento
    "character", "character", "character", "character",
    "character", "character",
    # temporal
    "date_ym", "character", "character"
  ),
  section = c(
    # identificacao
    rep("identificacao", 8),
    # classificacao
    rep("classificacao", 4),
    # sus
    rep("sus", 6),
    # atendimento
    rep("atendimento", 6),
    # temporal
    rep("temporal", 3)
  )
)

# ============================================================================
# dictionary data
# ============================================================================

#' CNES data dictionary tibble
#' @noRd
cnes_dictionary_data <- tibble::tibble(
  variable = c(
    # TP_UNID (22 types)
    rep("TP_UNID", 22),
    # ESFERA_A
    rep("ESFERA_A", 4),
    # VINC_SUS
    rep("VINC_SUS", 2),
    # TP_GESTAO
    rep("TP_GESTAO", 4),
    # PF_PJ
    rep("PF_PJ", 2)
  ),
  description = c(
    rep("Tipo de unidade/estabelecimento", 22),
    rep("Esfera administrativa", 4),
    rep("V\u00ednculo com o SUS", 2),
    rep("Tipo de gest\u00e3o", 4),
    rep("Pessoa F\u00edsica ou Jur\u00eddica", 2)
  ),
  code = c(
    # TP_UNID
    "01", "02", "04", "05", "07", "09", "15", "20",
    "21", "22", "32", "36", "39", "40", "42", "43",
    "50", "60", "61", "62", "64", "70",
    # ESFERA_A
    "1", "2", "3", "4",
    # VINC_SUS
    "0", "1",
    # TP_GESTAO
    "M", "E", "D", "S",
    # PF_PJ
    "1", "3"
  ),
  label = c(
    # TP_UNID
    "Posto de sa\u00fade",
    "Centro de sa\u00fade/unidade b\u00e1sica",
    "Policl\u00ednica",
    "Hospital geral",
    "Hospital especializado",
    "Pronto socorro geral",
    "Unidade mista",
    "Pronto socorro especializado",
    "Consultoria m\u00e9dica",
    "Unidade de apoio diagn\u00f3stico",
    "Unidade m\u00f3vel fluvial",
    "Cl\u00ednica/centro de especialidade",
    "Unidade de sa\u00fade da fam\u00edlia",
    "Unidade m\u00f3vel terrestre",
    "Unidade m\u00f3vel de n\u00edvel pr\u00e9-hospitalar (SAMU)",
    "Farmac\u00eda",
    "Unidade de vigil\u00e2ncia em sa\u00fade",
    "Cooperativa ou empresa de cess\u00e3o de trabalhadores",
    "Centro de parto normal",
    "Hospital/dia (isolado)",
    "Central de regula\u00e7\u00e3o de servi\u00e7os de sa\u00fade",
    "Centro de aten\u00e7\u00e3o hemoter\u00e1pica/hematol\u00f3gica",
    # ESFERA_A
    "Federal",
    "Estadual",
    "Municipal",
    "Privada",
    # VINC_SUS
    "N\u00e3o",
    "Sim",
    # TP_GESTAO
    "Municipal",
    "Estadual",
    "Dupla",
    "Sem gest\u00e3o",
    # PF_PJ
    "Pessoa F\u00edsica",
    "Pessoa Jur\u00eddica"
  )
)

# ============================================================================
# label maps for categorical variables
# ============================================================================

#' Label maps for CNES categorical variables
#' @noRd
cnes_label_maps <- list(
  TP_UNID = c(
    "01" = "Posto de sa\u00fade",
    "02" = "Centro de sa\u00fade/unidade b\u00e1sica",
    "04" = "Policl\u00ednica",
    "05" = "Hospital geral",
    "07" = "Hospital especializado",
    "09" = "Pronto socorro geral",
    "15" = "Unidade mista",
    "20" = "Pronto socorro especializado",
    "21" = "Consultoria m\u00e9dica",
    "22" = "Unidade de apoio diagn\u00f3stico",
    "32" = "Unidade m\u00f3vel fluvial",
    "36" = "Cl\u00ednica/centro de especialidade",
    "39" = "Unidade de sa\u00fade da fam\u00edlia",
    "40" = "Unidade m\u00f3vel terrestre",
    "42" = "Unidade m\u00f3vel de n\u00edvel pr\u00e9-hospitalar (SAMU)",
    "43" = "Farmac\u00eda",
    "50" = "Unidade de vigil\u00e2ncia em sa\u00fade",
    "60" = "Cooperativa ou empresa de cess\u00e3o de trabalhadores",
    "61" = "Centro de parto normal",
    "62" = "Hospital/dia (isolado)",
    "64" = "Central de regula\u00e7\u00e3o de servi\u00e7os de sa\u00fade",
    "70" = "Centro de aten\u00e7\u00e3o hemoter\u00e1pica/hematol\u00f3gica"
  ),
  ESFERA_A = c(
    "1" = "Federal", "2" = "Estadual", "3" = "Municipal", "4" = "Privada"
  ),
  VINC_SUS = c("0" = "N\u00e3o", "1" = "Sim"),
  TP_GESTAO = c(
    "M" = "Municipal", "E" = "Estadual", "D" = "Dupla",
    "S" = "Sem gest\u00e3o"
  ),
  PF_PJ = c("1" = "Pessoa F\u00edsica", "3" = "Pessoa Jur\u00eddica")
)
