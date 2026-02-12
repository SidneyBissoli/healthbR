# sia internal data definitions for healthbR package
# constants, metadata, and dictionary data for the SIA module

# ============================================================================
# available years
# ============================================================================

#' SIA available years by status
#' @noRd
sia_available_years <- list(
  final = 2008L:2023L,
  preliminary = 2024L
)

# ============================================================================
# UF codes
# ============================================================================

#' Brazilian state (UF) abbreviations
#' @noRd
sia_uf_list <- c(
  "AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO", "MA",
  "MT", "MS", "MG", "PA", "PB", "PR", "PE", "PI", "RJ", "RN",
  "RS", "RO", "RR", "SC", "SP", "SE", "TO"
)

# ============================================================================
# valid types
# ============================================================================

#' SIA valid file types
#' @noRd
sia_valid_types <- tibble::tibble(
  code = c(
    "PA", "BI", "AD", "AM", "AN", "AQ", "AR", "AB",
    "ACF", "ATD", "AMP", "SAD", "PS"
  ),
  name = c(
    "Produ\u00e7\u00e3o Ambulatorial",
    "Boletim Individualizado",
    "APAC Laudos Diversos",
    "APAC Medicamentos",
    "APAC Nefrologia",
    "APAC Quimioterapia",
    "APAC Radioterapia",
    "APAC Cirurgia Bari\u00e1trica",
    "APAC Confec\u00e7\u00e3o de F\u00edstula",
    "APAC Tratamento Dial\u00edtico",
    "APAC Acompanhamento Multiprofissional",
    "RAAS Aten\u00e7\u00e3o Domiciliar",
    "RAAS Psicossocial"
  ),
  description = c(
    "BPA consolidado",
    "BPA individualizado",
    "Autoriza\u00e7\u00e3o de alta complexidade",
    "Medicamentos de alto custo",
    "Procedimentos nefrol\u00f3gicos",
    "Quimioterapia oncol\u00f3gica",
    "Radioterapia oncol\u00f3gica",
    "Cirurgia bari\u00e1trica",
    "Confec\u00e7\u00e3o de f\u00edstula arteriovenosa",
    "Di\u00e1lise",
    "Acompanhamento multiprofissional",
    "Servi\u00e7os de aten\u00e7\u00e3o domiciliar",
    "CAPS e servi\u00e7os psicossociais"
  )
)

# ============================================================================
# variables metadata (PA type)
# ============================================================================

#' SIA variables metadata tibble (PA type)
#' @noRd
sia_variables_metadata <- tibble::tibble(
  variable = c(
    # gestao
    "PA_CODUNI", "PA_GESTAO", "PA_CONDIC",
    # procedimento
    "PA_PROC_ID", "PA_TPFIN", "PA_SUBFIN", "PA_CODOCO",
    "PA_DOCORIG", "PA_CODESP", "PA_TIPATE", "PA_TIPPRO",
    # paciente
    "PA_SEXO", "PA_IDADE", "PA_RACACOR", "PA_ETNIA",
    # diagnostico
    "PA_CIDPRI", "PA_CIDSEC", "PA_CATEND",
    # financeiro
    "PA_QTDPRO", "PA_QTDAPR", "PA_VALPRO", "PA_VALAPR",
    # localizacao
    "PA_UFMUN", "PA_MUNRES", "PA_MUNPCN", "PA_REGCT",
    # temporal
    "PA_MVM", "PA_CMP"
  ),
  description = c(
    # gestao
    "C\u00f3digo CNES do estabelecimento",
    "C\u00f3digo de gest\u00e3o (UF + munic\u00edpio)",
    "Condi\u00e7\u00e3o de gest\u00e3o (EP, EC, etc.)",
    # procedimento
    "C\u00f3digo do procedimento (SIGTAP)",
    "Tipo de financiamento",
    "Subtipo de financiamento",
    "C\u00f3digo de ocorr\u00eancia",
    "Documento de origem",
    "C\u00f3digo da especialidade",
    "Tipo de atendimento",
    "Tipo de presta\u00e7\u00e3o de servi\u00e7o",
    # paciente
    "Sexo (1=Masculino, 2=Feminino)",
    "Idade do paciente",
    "Ra\u00e7a/cor (1=Branca, 2=Preta, 3=Amarela, 4=Parda, 5=Ind\u00edgena)",
    "C\u00f3digo de etnia ind\u00edgena",
    # diagnostico
    "Diagn\u00f3stico principal (CID-10)",
    "Diagn\u00f3stico secund\u00e1rio (CID-10)",
    "Categoria de atendimento",
    # financeiro
    "Quantidade produzida",
    "Quantidade aprovada",
    "Valor produzido (R$)",
    "Valor aprovado (R$)",
    # localizacao
    "Munic\u00edpio de atendimento (UF + IBGE 6 d\u00edgitos)",
    "Munic\u00edpio de resid\u00eancia (IBGE 6 d\u00edgitos)",
    "Munic\u00edpio do paciente",
    "Regi\u00e3o de sa\u00fade (CIR/RRAS)",
    # temporal
    "M\u00eas/ano de movimenta\u00e7\u00e3o (AAAAMM)",
    "M\u00eas/ano de compet\u00eancia (AAAAMM)"
  ),
  type = rep("character", 28),
  section = c(
    # gestao
    rep("gestao", 3),
    # procedimento
    rep("procedimento", 8),
    # paciente
    rep("paciente", 4),
    # diagnostico
    rep("diagnostico", 3),
    # financeiro
    rep("financeiro", 4),
    # localizacao
    rep("localizacao", 4),
    # temporal
    rep("temporal", 2)
  )
)

# ============================================================================
# dictionary data
# ============================================================================

#' SIA data dictionary tibble
#' @noRd
sia_dictionary_data <- tibble::tibble(
  variable = c(
    # PA_SEXO
    rep("PA_SEXO", 2),
    # PA_RACACOR
    rep("PA_RACACOR", 5),
    # PA_CONDIC
    rep("PA_CONDIC", 4),
    # PA_TIPATE
    rep("PA_TIPATE", 4),
    # PA_TPFIN
    rep("PA_TPFIN", 5),
    # PA_CATEND
    rep("PA_CATEND", 2)
  ),
  description = c(
    rep("Sexo do paciente", 2),
    rep("Ra\u00e7a/cor do paciente", 5),
    rep("Condi\u00e7\u00e3o de gest\u00e3o", 4),
    rep("Tipo de atendimento", 4),
    rep("Tipo de financiamento", 5),
    rep("Categoria de atendimento", 2)
  ),
  code = c(
    # PA_SEXO
    "1", "2",
    # PA_RACACOR
    "01", "02", "03", "04", "05",
    # PA_CONDIC
    "EP", "EC", "MP", "MC",
    # PA_TIPATE
    "01", "02", "03", "04",
    # PA_TPFIN
    "01", "04", "05", "06", "07",
    # PA_CATEND
    "01", "02"
  ),
  label = c(
    # PA_SEXO
    "Masculino", "Feminino",
    # PA_RACACOR
    "Branca", "Preta", "Amarela", "Parda", "Ind\u00edgena",
    # PA_CONDIC
    "Estado plena", "Estado convencional",
    "Municipal plena", "Municipal convencional",
    # PA_TIPATE
    "Eletivo", "Urg\u00eancia",
    "Acidente de trabalho", "Outros",
    # PA_TPFIN
    "Fundo de A\u00e7\u00f5es Estrat\u00e9gicas", "FAEC",
    "Incentivo MAC", "MAC", "Incentivo FAEC",
    # PA_CATEND
    "Eletivo", "Urg\u00eancia"
  )
)

# ============================================================================
# label maps for categorical variables
# ============================================================================

#' Label maps for SIA categorical variables
#' @noRd
sia_label_maps <- list(
  PA_SEXO = c("1" = "Masculino", "2" = "Feminino"),
  PA_RACACOR = c(
    "01" = "Branca", "02" = "Preta", "03" = "Amarela",
    "04" = "Parda", "05" = "Ind\u00edgena"
  ),
  PA_CONDIC = c(
    "EP" = "Estado plena", "EC" = "Estado convencional",
    "MP" = "Municipal plena", "MC" = "Municipal convencional"
  ),
  PA_TIPATE = c(
    "01" = "Eletivo", "02" = "Urg\u00eancia",
    "03" = "Acidente de trabalho", "04" = "Outros"
  ),
  PA_TPFIN = c(
    "01" = "Fundo de A\u00e7\u00f5es Estrat\u00e9gicas", "04" = "FAEC",
    "05" = "Incentivo MAC", "06" = "MAC", "07" = "Incentivo FAEC"
  ),
  PA_CATEND = c("01" = "Eletivo", "02" = "Urg\u00eancia")
)
