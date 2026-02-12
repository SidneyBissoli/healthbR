# sipni internal data definitions for healthbR package
# constants, metadata, and dictionary data for the SI-PNI module

# ============================================================================
# available years
# ============================================================================

#' SI-PNI available years (all data is final, frozen at 2019)
#' @noRd
sipni_available_years <- 1994L:2019L

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
  code = c("DPNI", "CPNI"),
  name = c("Doses Aplicadas", "Cobertura Vacinal"),
  description = c(
    "Doses de vacinas aplicadas por munic\u00edpio, faixa et\u00e1ria, imuno e dose",
    "Cobertura vacinal por munic\u00edpio e imunobiol\u00f3gico"
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
  type = rep("character", 12),
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
  type = rep("character", 7),
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
