# ans internal data definitions for healthbR package
# constants, metadata, and dictionary data for the ANS module

# ============================================================================
# base URL
# ============================================================================

#' ANS open data base URL
#' @noRd
ans_base_url <- "https://dadosabertos.ans.gov.br/FTP/PDA"

# ============================================================================
# available years by type
# ============================================================================

#' ANS available years by type
#' @noRd
ans_available_years <- list(
  beneficiaries = 2019L:2025L,
  complaints = 2011L:2026L,
  financial = 2007L:2025L
)

# ============================================================================
# valid types
# ============================================================================

#' ANS valid data types
#' @noRd
ans_valid_types <- tibble::tibble(
  code = c("beneficiaries", "complaints", "financial"),
  name = c(
    "Benefici\u00e1rios",
    "Demandas dos consumidores (NIP)",
    "Demonstra\u00e7\u00f5es cont\u00e1beis"
  ),
  description = c(
    "Informa\u00e7\u00f5es consolidadas de benefici\u00e1rios por operadora, UF, sexo, faixa et\u00e1ria",
    "Demandas e reclama\u00e7\u00f5es de consumidores via NIP",
    "Demonstra\u00e7\u00f5es cont\u00e1beis trimestrais das operadoras"
  )
)

# ============================================================================
# UF codes (standard 27 + XX for beneficiaries)
# ============================================================================

#' Brazilian state (UF) abbreviations for ANS
#' @noRd
ans_uf_list <- c(
  "AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO", "MA",
  "MT", "MS", "MG", "PA", "PB", "PR", "PE", "PI", "RJ", "RN",
  "RS", "RO", "RR", "SC", "SP", "SE", "TO"
)

#' UF list including XX (unidentified/foreign) for beneficiaries
#' @noRd
ans_uf_list_xx <- c(ans_uf_list, "XX")

# ============================================================================
# beneficiaries variable metadata (22 columns)
# ============================================================================

#' ANS beneficiaries variable metadata
#' @noRd
ans_beneficiaries_metadata <- tibble::tibble(
  variable = c(
    "ID_CMPT_MOVEL", "CD_OPERADORA", "NM_RAZAO_SOCIAL", "NR_CNPJ",
    "MODALIDADE_OPERADORA", "SG_UF", "CD_MUNICIPIO", "NM_MUNICIPIO",
    "TP_SEXO", "DE_FAIXA_ETARIA", "DE_FAIXA_ETARIA_REAJ",
    "CD_PLANO", "TP_VIGENCIA_PLANO", "DE_CONTRATACAO_PLANO",
    "DE_SEGMENTACAO_PLANO", "DE_ABRG_GEOGRAFICA_PLANO",
    "COBERTURA_ASSIST_PLAN", "TIPO_VINCULO",
    "QT_BENEFICIARIO_ATIVO", "QT_BENEFICIARIO_ADERIDO",
    "QT_BENEFICIARIO_CANCELADO", "DT_CARGA"
  ),
  description = c(
    "Compet\u00eancia (AAAA-MM)",
    "C\u00f3digo da operadora na ANS",
    "Raz\u00e3o social da operadora",
    "CNPJ da operadora",
    "Modalidade da operadora (Medicina de Grupo, Cooperativa, etc.)",
    "Sigla da UF",
    "C\u00f3digo do munic\u00edpio (IBGE)",
    "Nome do munic\u00edpio",
    "Sexo do benefici\u00e1rio (M/F)",
    "Faixa et\u00e1ria",
    "Faixa et\u00e1ria para reajuste",
    "C\u00f3digo do plano",
    "Tipo de vig\u00eancia do plano (A=Anterior, P=Posterior \u00e0 Lei 9656)",
    "Tipo de contrata\u00e7\u00e3o (Individual, Coletivo Empresarial, etc.)",
    "Segmenta\u00e7\u00e3o do plano (Ambulatorial, Hospitalar, etc.)",
    "Abrang\u00eancia geogr\u00e1fica (Nacional, Estadual, Municipal, etc.)",
    "Cobertura assistencial (M\u00e9dico-hospitalar, Odontol\u00f3gica)",
    "Tipo de v\u00ednculo (Titular, Dependente)",
    "Quantidade de benefici\u00e1rios ativos",
    "Quantidade de benefici\u00e1rios aderidos",
    "Quantidade de benefici\u00e1rios cancelados",
    "Data de carga dos dados"
  ),
  type = c(
    "character", "character", "character", "character",
    "character", "character", "character", "character",
    "character", "character", "character",
    "character", "character", "character",
    "character", "character",
    "character", "character",
    "integer", "integer",
    "integer", "date"
  ),
  section = c(
    rep("operadora", 5),
    rep("localidade", 3),
    rep("beneficiario", 3),
    rep("plano", 7),
    rep("quantitativo", 3),
    "temporal"
  )
)

# ============================================================================
# complaints variable metadata (27 columns)
# ============================================================================

#' ANS complaints (NIP) variable metadata
#' @noRd
ans_complaints_metadata <- tibble::tibble(
  variable = c(
    "NUMERO_DA_DEMANDA", "ABERTURA_DA_DEMANDA", "ANO_DE_REFERENCIA",
    "MES_DE_REFERENCIA", "SITUACAO_DA_DEMANDA", "FORMA_DE_CONTATO_COM_A_ANS",
    "ASSUNTO", "REGISTRO_OPERADORA", "NOME_OPERADORA",
    "MODALIDADE_DA_OPERADORA", "TIPO_DE_PLANO_CONTRATADO",
    "EPOCA_DE_ADESAO_AO_PLANO", "TIPOS_DE_COBER_CONTRATADAS",
    "IDADE_BENEFICIARIO", "SEXO", "ESTADO_DO_BENEFICIARIO",
    "MUNICIPIO_DO_BENEFICIARIO", "UF_ONDE_CONSUMIDOR",
    "MUNIC_CONSUMIDOR_ATEND", "CD_MUNICIPIO_ATEND",
    "CLASSIFICACAO_DA_NIP", "NATUREZA_DA_NIP", "SITUACAO_DA_NIP",
    "DATA_DO_AUTO", "STATUS_AUTO", "NUMERO_PROCESSO",
    "RESPOSTA_BENEFICIARIO"
  ),
  description = c(
    "N\u00famero da demanda",
    "Data de abertura da demanda",
    "Ano de refer\u00eancia",
    "M\u00eas de refer\u00eancia",
    "Situa\u00e7\u00e3o da demanda (Finalizado, Em andamento, etc.)",
    "Forma de contato (Telefone, Internet, etc.)",
    "Assunto da demanda",
    "Registro da operadora na ANS",
    "Nome da operadora",
    "Modalidade da operadora",
    "Tipo de plano contratado",
    "\u00c9poca de ades\u00e3o ao plano",
    "Tipos de coberturas contratadas",
    "Idade do benefici\u00e1rio",
    "Sexo (M/F)",
    "Estado do benefici\u00e1rio",
    "Munic\u00edpio do benefici\u00e1rio",
    "UF onde o consumidor foi atendido",
    "Munic\u00edpio onde o consumidor foi atendido",
    "C\u00f3digo do munic\u00edpio de atendimento",
    "Classifica\u00e7\u00e3o da NIP",
    "Natureza da NIP",
    "Situa\u00e7\u00e3o da NIP",
    "Data do auto de infra\u00e7\u00e3o",
    "Status do auto",
    "N\u00famero do processo",
    "Resposta do benefici\u00e1rio"
  ),
  type = c(
    "character", "date", "integer",
    "integer", "character", "character",
    "character", "character", "character",
    "character", "character",
    "character", "character",
    "integer", "character", "character",
    "character", "character",
    "character", "character",
    "character", "character", "character",
    "date", "character", "character",
    "character"
  ),
  section = c(
    rep("demanda", 6),
    "assunto",
    rep("operadora", 3),
    rep("plano", 3),
    rep("beneficiario", 4),
    rep("atendimento", 3),
    rep("nip", 3),
    rep("processo", 4)
  )
)

# ============================================================================
# financial variable metadata (6 columns)
# ============================================================================

#' ANS financial statements variable metadata
#' @noRd
ans_financial_metadata <- tibble::tibble(
  variable = c(
    "DATA", "REG_ANS", "CD_CONTA_CONTABIL",
    "DESCRICAO", "VL_SALDO_INICIAL", "VL_SALDO_FINAL"
  ),
  description = c(
    "Data de refer\u00eancia",
    "Registro da operadora na ANS",
    "C\u00f3digo da conta cont\u00e1bil",
    "Descri\u00e7\u00e3o da conta cont\u00e1bil",
    "Valor do saldo inicial",
    "Valor do saldo final"
  ),
  type = c(
    "date", "character", "character",
    "character", "double", "double"
  ),
  section = c(
    "temporal", "operadora", "conta",
    "conta", "valor", "valor"
  )
)

# ============================================================================
# operators variable metadata (20 columns)
# ============================================================================

#' ANS operators variable metadata
#' @noRd
ans_operators_metadata <- tibble::tibble(
  variable = c(
    "REGISTRO_OPERADORA", "CNPJ", "Razao_Social", "Nome_Fantasia",
    "Modalidade", "Logradouro", "Numero", "Complemento", "Bairro",
    "Cidade", "UF", "CEP", "DDD", "Telefone", "Fax",
    "Endereco_eletronico", "Representante", "Cargo_Representante",
    "Regiao_de_Comercializacao", "Data_Registro_ANS"
  ),
  description = c(
    "Registro da operadora na ANS",
    "CNPJ da operadora",
    "Raz\u00e3o social",
    "Nome fantasia",
    "Modalidade (Medicina de Grupo, Cooperativa, Autogest\u00e3o, etc.)",
    "Logradouro",
    "N\u00famero",
    "Complemento",
    "Bairro",
    "Cidade",
    "Unidade federativa",
    "CEP",
    "DDD",
    "Telefone",
    "Fax",
    "Endere\u00e7o eletr\u00f4nico (e-mail)",
    "Representante legal",
    "Cargo do representante",
    "Regi\u00e3o de comercializa\u00e7\u00e3o",
    "Data de registro na ANS"
  ),
  type = c(
    "character", "character", "character", "character",
    "character", "character", "character", "character", "character",
    "character", "character", "character", "character", "character",
    "character",
    "character", "character", "character",
    "character", "date"
  ),
  section = c(
    rep("identificacao", 5),
    rep("endereco", 7),
    rep("contato", 3),
    rep("contato", 1),
    rep("representante", 2),
    "comercializacao",
    "temporal"
  )
)
