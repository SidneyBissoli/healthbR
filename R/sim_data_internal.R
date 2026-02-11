# sim internal data definitions for healthbR package
# constants, metadata, and dictionary data for the SIM module

# ============================================================================
# available years
# ============================================================================

#' SIM available years by status
#' @noRd
sim_available_years <- list(
  final = 1996L:2022L,
  preliminary = 2023L:2024L
)

# ============================================================================
# UF codes
# ============================================================================

#' Brazilian state (UF) abbreviations
#' @noRd
sim_uf_list <- c(
  "AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO", "MA",
  "MT", "MS", "MG", "PA", "PB", "PR", "PE", "PI", "RJ", "RN",
  "RS", "RO", "RR", "SC", "SP", "SE", "TO"
)

#' UF abbreviation to IBGE code mapping
#' @noRd
sim_uf_codes <- c(
  "AC" = "12", "AL" = "27", "AP" = "16", "AM" = "13",
  "BA" = "29", "CE" = "23", "DF" = "53", "ES" = "32",
  "GO" = "52", "MA" = "21", "MT" = "51", "MS" = "50",
  "MG" = "31", "PA" = "15", "PB" = "25", "PR" = "41",
  "PE" = "26", "PI" = "22", "RJ" = "33", "RN" = "24",
  "RS" = "43", "RO" = "11", "RR" = "14", "SC" = "42",
  "SP" = "35", "SE" = "28", "TO" = "17"
)

# ============================================================================
# variables metadata
# ============================================================================

#' SIM variables metadata tibble
#' @noRd
sim_variables_metadata <- tibble::tibble(
  variable = c(
    # identification
    "TIPOBITO", "DTOBITO", "HORAOBITO", "NATURAL", "DTNASC",
    # location
    "CODMUNRES", "CODMUNOCOR", "LOCOCOR",
    # demographics
    "SEXO", "IDADE", "RACACOR", "ESTCIV", "ESC", "ESC2010", "OCUP",
    # cause of death
    "CAUSABAS", "CAUSABAS_O", "LINHAA", "LINHAB", "LINHAC", "LINHAD",
    "LINHAII", "CIRCOBITO",
    # maternal/perinatal
    "IDADEMAE", "ESCMAE", "GESTACAO", "GRAVIDEZ", "PARTO",
    "OBITOGRAV", "OBITOPUERP", "PESO",
    # investigation
    "ASSISTMED", "EXAME", "CIRURGIA", "NECROPSIA",
    "ACIDTRAB", "FONTE", "FONTEINV", "TPPOS"
  ),
  description = c(
    # identification
    "Tipo do \u00f3bito (1=fetal, 2=n\u00e3o fetal)",
    "Data do \u00f3bito (ddmmaaaa)",
    "Hora do \u00f3bito",
    "Naturalidade (c\u00f3digo IBGE)",
    "Data de nascimento (ddmmaaaa)",
    # location
    "Munic\u00edpio de resid\u00eancia (c\u00f3digo IBGE 6 d\u00edgitos)",
    "Munic\u00edpio de ocorr\u00eancia do \u00f3bito (c\u00f3digo IBGE)",
    "Local de ocorr\u00eancia (1=Hospital, 2=Outro estab., 3=Domic\u00edlio, 4=Via p\u00fablica, 5=Outros, 9=Ignorado)",
    # demographics
    "Sexo (M=Masculino, F=Feminino, I=Ignorado)",
    "Idade codificada (ver sim_dictionary('IDADE'))",
    "Ra\u00e7a/cor (1=Branca, 2=Preta, 3=Amarela, 4=Parda, 5=Ind\u00edgena)",
    "Estado civil",
    "Escolaridade em anos de estudo",
    "Escolaridade em s\u00e9ries (formato 2010+)",
    "Ocupa\u00e7\u00e3o (CBO-2002, a partir de 2006)",
    # cause of death
    "Causa b\u00e1sica do \u00f3bito (CID-10)",
    "Causa b\u00e1sica original (antes de recodifica\u00e7\u00e3o)",
    "CIDs informados na Linha A da DO",
    "CIDs informados na Linha B da DO",
    "CIDs informados na Linha C da DO",
    "CIDs informados na Linha D da DO",
    "CIDs informados na Parte II da DO",
    "Circunst\u00e2ncia do \u00f3bito (causas externas)",
    # maternal/perinatal
    "Idade da m\u00e3e",
    "Escolaridade da m\u00e3e",
    "Semanas de gesta\u00e7\u00e3o",
    "Tipo de gravidez (1=\u00danica, 2=Dupla, 3=Tripla+)",
    "Tipo de parto (1=Vaginal, 2=Ces\u00e1reo)",
    "\u00d3bito na gravidez (1=Sim, 2=N\u00e3o, 9=Ignorado)",
    "\u00d3bito no puerp\u00e9rio",
    "Peso ao nascer (gramas)",
    # investigation
    "Recebeu assist\u00eancia m\u00e9dica (1=Sim, 2=N\u00e3o, 9=Ignorado)",
    "Realiza\u00e7\u00e3o de exame complementar",
    "Realiza\u00e7\u00e3o de cirurgia",
    "Realiza\u00e7\u00e3o de necr\u00f3psia",
    "Acidente de trabalho",
    "Fonte da informa\u00e7\u00e3o",
    "Fonte de investiga\u00e7\u00e3o",
    "Tipo de posi\u00e7\u00e3o (investiga\u00e7\u00e3o)"
  ),
  type = c(
    # identification
    "character", "character", "character", "character", "character",
    # location
    "character", "character", "character",
    # demographics
    "character", "character", "character", "character", "character",
    "character", "character",
    # cause of death
    "character", "character", "character", "character", "character",
    "character", "character", "character",
    # maternal/perinatal
    "character", "character", "character", "character", "character",
    "character", "character", "character",
    # investigation
    "character", "character", "character", "character",
    "character", "character", "character", "character"
  ),
  section = c(
    # identification
    rep("identificacao", 5),
    # location
    rep("localizacao", 3),
    # demographics
    rep("demografica", 7),
    # cause of death
    rep("causa", 8),
    # maternal/perinatal
    rep("materna", 8),
    # investigation
    rep("investigacao", 8)
  )
)

# ============================================================================
# dictionary data
# ============================================================================

#' SIM data dictionary tibble
#' @noRd
sim_dictionary_data <- tibble::tibble(
  variable = c(
    # TIPOBITO
    rep("TIPOBITO", 2),
    # SEXO
    rep("SEXO", 3),
    # RACACOR
    rep("RACACOR", 5),
    # ESTCIV
    rep("ESTCIV", 6),
    # ESC
    rep("ESC", 6),
    # LOCOCOR
    rep("LOCOCOR", 6),
    # CIRCOBITO
    rep("CIRCOBITO", 5),
    # ASSISTMED
    rep("ASSISTMED", 3),
    # GRAVIDEZ
    rep("GRAVIDEZ", 4),
    # PARTO
    rep("PARTO", 3),
    # OBITOGRAV
    rep("OBITOGRAV", 3),
    # OBITOPUERP
    rep("OBITOPUERP", 4),
    # IDADE (unit codes)
    rep("IDADE", 6)
  ),
  description = c(
    rep("Tipo do \u00f3bito", 2),
    rep("Sexo", 3),
    rep("Ra\u00e7a/cor", 5),
    rep("Estado civil", 6),
    rep("Escolaridade (anos de estudo)", 6),
    rep("Local de ocorr\u00eancia", 6),
    rep("Circunst\u00e2ncia do \u00f3bito", 5),
    rep("Assist\u00eancia m\u00e9dica", 3),
    rep("Tipo de gravidez", 4),
    rep("Tipo de parto", 3),
    rep("\u00d3bito na gravidez", 3),
    rep("\u00d3bito no puerp\u00e9rio", 4),
    rep("Idade (1\u00ba d\u00edgito = unidade)", 6)
  ),
  code = c(
    # TIPOBITO
    "1", "2",
    # SEXO
    "M", "F", "I",
    # RACACOR
    "1", "2", "3", "4", "5",
    # ESTCIV
    "1", "2", "3", "4", "5", "9",
    # ESC
    "1", "2", "3", "4", "5", "9",
    # LOCOCOR
    "1", "2", "3", "4", "5", "9",
    # CIRCOBITO
    "1", "2", "3", "4", "9",
    # ASSISTMED
    "1", "2", "9",
    # GRAVIDEZ
    "1", "2", "3", "9",
    # PARTO
    "1", "2", "9",
    # OBITOGRAV
    "1", "2", "9",
    # OBITOPUERP
    "1", "2", "3", "9",
    # IDADE
    "0", "1", "2", "3", "4", "5"
  ),
  label = c(
    # TIPOBITO
    "Fetal", "N\u00e3o fetal",
    # SEXO
    "Masculino", "Feminino", "Ignorado",
    # RACACOR
    "Branca", "Preta", "Amarela", "Parda", "Ind\u00edgena",
    # ESTCIV
    "Solteiro", "Casado", "Vi\u00favo",
    "Separado judicialmente", "Uni\u00e3o est\u00e1vel", "Ignorado",
    # ESC
    "Nenhuma", "1 a 3 anos", "4 a 7 anos",
    "8 a 11 anos", "12 e mais", "Ignorado",
    # LOCOCOR
    "Hospital", "Outro estab. sa\u00fade", "Domic\u00edlio",
    "Via p\u00fablica", "Outros", "Ignorado",
    # CIRCOBITO
    "Acidente", "Suic\u00eddio", "Homic\u00eddio", "Outros", "Ignorado",
    # ASSISTMED
    "Sim", "N\u00e3o", "Ignorado",
    # GRAVIDEZ
    "\u00danica", "Dupla", "Tripla e mais", "Ignorada",
    # PARTO
    "Vaginal", "Ces\u00e1reo", "Ignorado",
    # OBITOGRAV
    "Sim", "N\u00e3o", "Ignorado",
    # OBITOPUERP
    "De 0 a 42 dias", "De 43 dias a 1 ano", "N\u00e3o", "Ignorado",
    # IDADE
    "Minutos (< 1 hora)", "Horas", "Dias", "Meses", "Anos (0-99)", "Anos (100+)"
  )
)

# ============================================================================
# label maps for categorical variables
# ============================================================================

#' Label maps for SIM categorical variables
#' @noRd
sim_label_maps <- list(
  SEXO = c("M" = "Masculino", "F" = "Feminino", "I" = "Ignorado"),
  RACACOR = c(
    "1" = "Branca", "2" = "Preta", "3" = "Amarela",
    "4" = "Parda", "5" = "Ind\u00edgena"
  ),
  ESTCIV = c(
    "1" = "Solteiro", "2" = "Casado", "3" = "Vi\u00favo",
    "4" = "Separado judicialmente", "5" = "Uni\u00e3o est\u00e1vel",
    "9" = "Ignorado"
  ),
  LOCOCOR = c(
    "1" = "Hospital", "2" = "Outro estab. sa\u00fade",
    "3" = "Domic\u00edlio", "4" = "Via p\u00fablica",
    "5" = "Outros", "9" = "Ignorado"
  ),
  TIPOBITO = c("1" = "Fetal", "2" = "N\u00e3o fetal"),
  ESC = c(
    "1" = "Nenhuma", "2" = "1 a 3 anos", "3" = "4 a 7 anos",
    "4" = "8 a 11 anos", "5" = "12 e mais", "9" = "Ignorado"
  ),
  CIRCOBITO = c(
    "1" = "Acidente", "2" = "Suic\u00eddio",
    "3" = "Homic\u00eddio", "4" = "Outros", "9" = "Ignorado"
  ),
  ASSISTMED = c("1" = "Sim", "2" = "N\u00e3o", "9" = "Ignorado")
)
