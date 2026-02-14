# sih internal data definitions for healthbR package
# constants, metadata, and dictionary data for the SIH module

# ============================================================================
# available years
# ============================================================================

#' SIH available years by status
#' @noRd
sih_available_years <- list(
  final = 2008L:2023L,
  preliminary = 2024L
)

# ============================================================================
# UF codes
# ============================================================================

#' Brazilian state (UF) abbreviations
#' @noRd
sih_uf_list <- c(
  "AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO", "MA",
  "MT", "MS", "MG", "PA", "PB", "PR", "PE", "PI", "RJ", "RN",
  "RS", "RO", "RR", "SC", "SP", "SE", "TO"
)

# ============================================================================
# variables metadata
# ============================================================================

#' SIH variables metadata tibble
#' @noRd
sih_variables_metadata <- tibble::tibble(
  variable = c(
    # identificacao
    "N_AIH", "IDENT", "CEP", "MUNIC_RES", "MUNIC_MOV",
    # paciente
    "NASC", "SEXO", "IDADE", "COD_IDADE", "RACA_COR",
    "NACIONAL", "INSTRU",
    # clinica
    "DIAG_PRINC", "DIAG_SECUN", "DIAGSEC1", "CID_ASSO",
    "CID_MORTE",
    # procedimento
    "PROC_REA", "PROC_SOLIC", "QT_DIARIAS",
    # internacao
    "DT_INTER", "DT_SAIDA", "CAR_INT", "COMPLEX", "ESPEC",
    "DIAS_PERM",
    # hospital
    "CNES", "CNPJ_MANT", "NATUREZA", "GESTAO",
    # desfecho
    "MORTE", "COBRANCA", "CBOR",
    # financeiro
    "VAL_SH", "VAL_SP", "VAL_TOT", "VAL_UTI", "US_TOT",
    # uti
    "UTI_MES_TO", "MARCA_UTI", "UTI_INT_TO"
  ),
  description = c(
    # identificacao
    "N\u00famero da AIH",
    "Tipo de AIH (1=Normal, 5=Longa perman\u00eancia)",
    "CEP do paciente",
    "Munic\u00edpio de resid\u00eancia (c\u00f3digo IBGE 6 d\u00edgitos)",
    "Munic\u00edpio de atendimento (c\u00f3digo IBGE 6 d\u00edgitos)",
    # paciente
    "Data de nascimento (aaaammdd)",
    "Sexo (0=Ignorado, 1=Masculino, 3=Feminino)",
    "Idade (valor num\u00e9rico conforme COD_IDADE)",
    "C\u00f3digo da unidade de idade (2=dias, 3=meses, 4=anos)",
    "Ra\u00e7a/cor (01=Branca, 02=Preta, 03=Parda, 04=Amarela, 05=Ind\u00edgena, 99=Sem info)",
    "Nacionalidade do paciente",
    "Grau de instru\u00e7\u00e3o do paciente",
    # clinica
    "Diagn\u00f3stico principal (CID-10)",
    "Diagn\u00f3stico secund\u00e1rio (CID-10)",
    "Diagn\u00f3stico secund\u00e1rio 1 (CID-10)",
    "CID associado (causas externas)",
    "CID da causa da morte (se \u00f3bito)",
    # procedimento
    "Procedimento realizado (c\u00f3digo SUS)",
    "Procedimento solicitado (c\u00f3digo SUS)",
    "Quantidade de di\u00e1rias",
    # internacao
    "Data de interna\u00e7\u00e3o (aaaammdd)",
    "Data de sa\u00edda (aaaammdd)",
    "Car\u00e1ter de interna\u00e7\u00e3o (1=Eletiva, 2=Urg\u00eancia, 3-6=Outros)",
    "Complexidade (01=Aten\u00e7\u00e3o B\u00e1sica, 02=M\u00e9dia, 03=Alta)",
    "Especialidade do leito",
    "Dias de perman\u00eancia",
    # hospital
    "C\u00f3digo CNES do estabelecimento",
    "CNPJ do mantenedor",
    "Natureza jur\u00eddica do estabelecimento",
    "Tipo de gest\u00e3o (M=Municipal, E=Estadual)",
    # desfecho
    "\u00d3bito durante interna\u00e7\u00e3o (0=N\u00e3o, 1=Sim)",
    "Motivo de cobran\u00e7a",
    "CBO do m\u00e9dico respons\u00e1vel",
    # financeiro
    "Valor dos servi\u00e7os hospitalares",
    "Valor dos servi\u00e7os profissionais",
    "Valor total da AIH",
    "Valor de UTI",
    "Valor total dos procedimentos (US$)",
    # uti
    "Total de dias em UTI no m\u00eas",
    "Indica uso de UTI",
    "Total de dias em UTI na interna\u00e7\u00e3o"
  ),
  type = c(
    # identificacao
    "character", "character", "character", "character", "character",
    # paciente
    "date_ymd", "character", "integer", "character", "character",
    "character", "character",
    # clinica
    "character", "character", "character", "character",
    "character",
    # procedimento
    "character", "character", "integer",
    # internacao
    "date_ymd", "date_ymd", "character", "character", "character",
    "integer",
    # hospital
    "character", "character", "character", "character",
    # desfecho
    "character", "character", "character",
    # financeiro
    "double", "double", "double", "double", "double",
    # uti
    "integer", "character", "integer"
  ),
  section = c(
    # identificacao
    rep("identificacao", 5),
    # paciente
    rep("paciente", 7),
    # clinica
    rep("clinica", 5),
    # procedimento
    rep("procedimento", 3),
    # internacao
    rep("internacao", 6),
    # hospital
    rep("hospital", 4),
    # desfecho
    rep("desfecho", 3),
    # financeiro
    rep("financeiro", 5),
    # uti
    rep("uti", 3)
  )
)

# ============================================================================
# dictionary data
# ============================================================================

#' SIH data dictionary tibble
#' @noRd
sih_dictionary_data <- tibble::tibble(
  variable = c(
    # SEXO
    rep("SEXO", 3),
    # RACA_COR
    rep("RACA_COR", 6),
    # COD_IDADE
    rep("COD_IDADE", 3),
    # IDENT
    rep("IDENT", 2),
    # CAR_INT
    rep("CAR_INT", 6),
    # COMPLEX
    rep("COMPLEX", 3),
    # ESPEC
    rep("ESPEC", 10),
    # MORTE
    rep("MORTE", 2),
    # INSTRU
    rep("INSTRU", 5)
  ),
  description = c(
    rep("Sexo do paciente", 3),
    rep("Ra\u00e7a/cor do paciente", 6),
    rep("Unidade de medida da idade", 3),
    rep("Tipo de AIH", 2),
    rep("Car\u00e1ter da interna\u00e7\u00e3o", 6),
    rep("Complexidade", 3),
    rep("Especialidade do leito", 10),
    rep("\u00d3bito durante interna\u00e7\u00e3o", 2),
    rep("Grau de instru\u00e7\u00e3o", 5)
  ),
  code = c(
    # SEXO
    "0", "1", "3",
    # RACA_COR
    "01", "02", "03", "04", "05", "99",
    # COD_IDADE
    "2", "3", "4",
    # IDENT
    "1", "5",
    # CAR_INT
    "1", "2", "3", "4", "5", "6",
    # COMPLEX
    "01", "02", "03",
    # ESPEC
    "01", "02", "03", "04", "05", "06", "07", "08", "09", "10",
    # MORTE
    "0", "1",
    # INSTRU
    "0", "1", "2", "3", "4"
  ),
  label = c(
    # SEXO
    "Ignorado", "Masculino", "Feminino",
    # RACA_COR
    "Branca", "Preta", "Parda", "Amarela", "Ind\u00edgena", "Sem informa\u00e7\u00e3o",
    # COD_IDADE
    "Dias", "Meses", "Anos",
    # IDENT
    "Normal", "Longa perman\u00eancia",
    # CAR_INT
    "Eletiva", "Urg\u00eancia", "Acidente no local de trabalho",
    "Acidente no trajeto", "Outros acidentes de tr\u00e2nsito",
    "Outros tipos de les\u00f5es",
    # COMPLEX
    "Aten\u00e7\u00e3o B\u00e1sica", "M\u00e9dia complexidade", "Alta complexidade",
    # ESPEC
    "Cirurgia", "Obstetr\u00edcia", "Cl\u00ednica m\u00e9dica", "Cuidados prolongados",
    "Psiquiatria", "Tisiologia", "Pediatria", "Reabilita\u00e7\u00e3o",
    "Cl\u00ednica cir\u00fargica", "Hospital-dia",
    # MORTE
    "N\u00e3o", "Sim",
    # INSTRU
    "Sem instru\u00e7\u00e3o/analfabeto", "1\u00ba grau", "2\u00ba grau",
    "3\u00ba grau", "N\u00e3o informado"
  )
)

# ============================================================================
# label maps for categorical variables
# ============================================================================

#' Label maps for SIH categorical variables
#' @noRd
sih_label_maps <- list(
  SEXO = c("0" = "Ignorado", "1" = "Masculino", "3" = "Feminino"),
  RACA_COR = c(
    "01" = "Branca", "02" = "Preta", "03" = "Parda",
    "04" = "Amarela", "05" = "Ind\u00edgena", "99" = "Sem informa\u00e7\u00e3o"
  ),
  COD_IDADE = c("2" = "Dias", "3" = "Meses", "4" = "Anos"),
  IDENT = c("1" = "Normal", "5" = "Longa perman\u00eancia"),
  CAR_INT = c(
    "1" = "Eletiva", "2" = "Urg\u00eancia",
    "3" = "Acidente no local de trabalho",
    "4" = "Acidente no trajeto",
    "5" = "Outros acidentes de tr\u00e2nsito",
    "6" = "Outros tipos de les\u00f5es"
  ),
  COMPLEX = c(
    "01" = "Aten\u00e7\u00e3o B\u00e1sica",
    "02" = "M\u00e9dia complexidade",
    "03" = "Alta complexidade"
  ),
  MORTE = c("0" = "N\u00e3o", "1" = "Sim"),
  INSTRU = c(
    "0" = "Sem instru\u00e7\u00e3o/analfabeto", "1" = "1\u00ba grau",
    "2" = "2\u00ba grau", "3" = "3\u00ba grau", "4" = "N\u00e3o informado"
  )
)
