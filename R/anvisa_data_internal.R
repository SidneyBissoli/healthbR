# ANVISA internal data definitions for healthbR package
# Constants, metadata, and URL helpers for the ANVISA module

# ============================================================================
# Base URL
# ============================================================================

#' ANVISA open data portal base URL
#' @noRd
anvisa_base_url <- "https://dados.anvisa.gov.br/dados"

# ============================================================================
# Type definitions
# ============================================================================

#' ANVISA valid data types (14 types)
#' @noRd
anvisa_valid_types <- tibble::tibble(
  code = c(
    "medicines", "medical_devices", "food", "cosmetics", "sanitizers",
    "tobacco", "pesticides", "hemovigilance", "technovigilance",
    "vigimed_notifications", "vigimed_medicines", "vigimed_reactions",
    "sngpc", "sngpc_compounded"
  ),
  name = c(
    "Medicamentos",
    "Produtos para Sa\u00fade",
    "Alimentos",
    "Cosm\u00e9ticos",
    "Saneantes",
    "Produtos Fum\u00edgenos",
    "Agrot\u00f3xicos",
    "Hemovigil\u00e2ncia",
    "Tecnovigil\u00e2ncia",
    "VigiMed - Notifica\u00e7\u00f5es",
    "VigiMed - Medicamentos",
    "VigiMed - Rea\u00e7\u00f5es",
    "SNGPC - Industrializados",
    "SNGPC - Manipulados"
  ),
  description = c(
    "Registro de medicamentos aprovados pela ANVISA",
    "Registro de produtos para sa\u00fade (dispositivos m\u00e9dicos)",
    "Registro de alimentos",
    "Registro de cosm\u00e9ticos",
    "Registro de saneantes",
    "Registro de produtos fum\u00edgenos (tabaco)",
    "Monografias de agrot\u00f3xicos (ingredientes ativos autorizados)",
    "Notifica\u00e7\u00f5es de eventos adversos em hemoterapia",
    "Notifica\u00e7\u00f5es de eventos adversos em dispositivos m\u00e9dicos",
    "Notifica\u00e7\u00f5es de farmacovigil\u00e2ncia (VigiMed)",
    "Medicamentos envolvidos em notifica\u00e7\u00f5es VigiMed",
    "Rea\u00e7\u00f5es adversas reportadas no VigiMed",
    "Venda de medicamentos controlados industrializados (SNGPC)",
    "Venda de medicamentos controlados manipulados (SNGPC)"
  ),
  category = c(
    rep("product_registration", 6),
    "reference",
    rep("surveillance", 5),
    rep("sngpc", 2)
  )
)

#' ANVISA snapshot types (no year/month parameter)
#' @noRd
anvisa_snapshot_types <- c(
  "medicines", "medical_devices", "food", "cosmetics", "sanitizers",
  "tobacco", "pesticides", "hemovigilance", "technovigilance",
  "vigimed_notifications", "vigimed_medicines", "vigimed_reactions"
)

#' ANVISA time-series types (require year/month)
#' @noRd
anvisa_sngpc_types <- c("sngpc", "sngpc_compounded")

# ============================================================================
# Type-to-filename mapping
# ============================================================================

#' ANVISA type-to-filename map for snapshot types
#' @noRd
anvisa_type_files <- c(
  medicines = "DADOS_ABERTOS_MEDICAMENTOS.csv",
  medical_devices = "TA_PRODUTO_SAUDE_SITE.csv",
  food = "DADOS_ABERTOS_ALIMENTO.csv",
  cosmetics = "DADOS_ABERTOS_COSMETICO.csv",
  sanitizers = "DADOS_ABERTOS_REGISTROS_SANEANTES.CSV",
  tobacco = "DADOS_ABERTOS_PRODUTO_FUMIGENO.csv",
  pesticides = "TA_MONOGRAFIA_AGROTOXICO.csv",
  hemovigilance = "DADOS_ABERTOS_HEMOVIGILANCIA.csv",
  technovigilance = "DADOS_ABERTOS_TECNOVIGILANCIA.csv",
  vigimed_notifications = "VigiMed_Notificacoes.csv",
  vigimed_medicines = "VigiMed_Medicamentos.csv",
  vigimed_reactions = "VigiMed_Reacoes.csv"
)

#' ANVISA SNGPC subdirectory names
#' @noRd
anvisa_sngpc_subdirs <- c(
  sngpc = "Industrializados",
  sngpc_compounded = "Manipulados"
)

#' ANVISA SNGPC file prefixes
#' @noRd
anvisa_sngpc_prefixes <- c(
  sngpc = "EDA_Industrializados_",
  sngpc_compounded = "EDA_Manipulados_"
)

# ============================================================================
# CSV format specs per type
# ============================================================================

#' ANVISA CSV delimiter per type (most are semicolon; sanitizers uses comma)
#' @noRd
anvisa_csv_delim <- c(
  medicines = ";",
  medical_devices = ";",
  food = ";",
  cosmetics = ";",
  sanitizers = ",",
  tobacco = ";",
  pesticides = ";",
  hemovigilance = ";",
  technovigilance = ";",
  vigimed_notifications = ";",
  vigimed_medicines = ";",
  vigimed_reactions = ";",
  sngpc = ";",
  sngpc_compounded = ";"
)

# All files use ISO-8859-1 (latin1) encoding

# ============================================================================
# SNGPC date range
# ============================================================================

#' ANVISA SNGPC available years
#' @noRd
anvisa_sngpc_years <- 2014L:2026L

# ============================================================================
# Variable metadata per type
# ============================================================================

#' ANVISA medicines variable metadata (11 columns)
#' @noRd
anvisa_medicines_metadata <- tibble::tibble(
  variable = c(
    "TIPO_PRODUTO", "NOME_PRODUTO", "DATA_FINALIZACAO_PROCESSO",
    "CATEGORIA_REGULATORIA", "NUMERO_REGISTRO_PRODUTO",
    "DATA_VENCIMENTO_REGISTRO", "NUMERO_PROCESSO",
    "CLASSE_TERAPEUTICA", "EMPRESA_DETENTORA_REGISTRO",
    "SITUACAO_REGISTRO", "PRINCIPIO_ATIVO"
  ),
  description = c(
    "Tipo de produto (Medicamento)",
    "Nome do produto",
    "Data de finaliza\u00e7\u00e3o do processo",
    "Categoria regulat\u00f3ria (Similar, Gen\u00e9rico, Novo, etc.)",
    "N\u00famero de registro do produto",
    "Data de vencimento do registro",
    "N\u00famero do processo",
    "Classe terap\u00eautica",
    "CNPJ e nome da empresa detentora do registro",
    "Situa\u00e7\u00e3o do registro (Ativo, Caduco/Cancelado, etc.)",
    "Princ\u00edpio ativo"
  )
)

#' ANVISA medical devices variable metadata (12 columns)
#' @noRd
anvisa_medical_devices_metadata <- tibble::tibble(
  variable = c(
    "NUMERO_REGISTRO_CADASTRO", "NUMERO_PROCESSO", "NOME_TECNICO",
    "CLASSE_RISCO", "NOME_COMERCIAL",
    "CNPJ_DETENTOR_REGISTRO_CADASTRO", "DETENTOR_REGISTRO_CADASTRO",
    "NOME_FABRICANTE", "NOME_PAIS_FABRIC",
    "DT_PUB_REGISTRO_CADASTRO", "VALIDADE_REGISTRO_CADASTRO",
    "DT_ATUALIZACAO_DADO"
  ),
  description = c(
    "N\u00famero do registro/cadastro",
    "N\u00famero do processo",
    "Nome t\u00e9cnico do produto",
    "Classe de risco (I, II, III, IV)",
    "Nome comercial",
    "CNPJ do detentor do registro",
    "Nome do detentor do registro",
    "Nome do fabricante",
    "Pa\u00eds do fabricante",
    "Data de publica\u00e7\u00e3o do registro",
    "Validade do registro (Vigente/Caduco)",
    "Data de atualiza\u00e7\u00e3o do dado"
  )
)

#' ANVISA food variable metadata (10 columns)
#' @noRd
anvisa_food_metadata <- tibble::tibble(
  variable = c(
    "NU_CNPJ_EMPRESA", "NO_RAZAO_SOCIAL_EMPRESA", "NO_PRODUTO",
    "NU_PROCESSO", "DS_TIPO_PRODUTO", "DS_CATEGORIA_PRODUTO",
    "DT_FINALIZACAO_PROCESSO", "NU_REGISTRO_PRODUTO",
    "DT_VENCIMENTO_REGISTRO", "ST_SITUACAO_REGISTRO"
  ),
  description = c(
    "CNPJ da empresa",
    "Raz\u00e3o social da empresa",
    "Nome do produto",
    "N\u00famero do processo",
    "Tipo de produto (Alimento)",
    "Categoria do produto",
    "Data de finaliza\u00e7\u00e3o do processo",
    "N\u00famero de registro do produto",
    "Data de vencimento do registro",
    "Situa\u00e7\u00e3o do registro (Ativo, Inativo)"
  )
)

#' ANVISA cosmetics variable metadata (10 columns, same schema as food)
#' @noRd
anvisa_cosmetics_metadata <- tibble::tibble(
  variable = c(
    "NU_CNPJ_EMPRESA", "NO_RAZAO_SOCIAL_EMPRESA", "NO_PRODUTO",
    "NU_PROCESSO", "DS_TIPO_PRODUTO", "DS_CATEGORIA_PRODUTO",
    "DT_FINALIZACAO_PROCESSO", "NU_REGISTRO_PRODUTO",
    "DT_VENCIMENTO_REGISTRO", "ST_SITUACAO_REGISTRO"
  ),
  description = c(
    "CNPJ da empresa",
    "Raz\u00e3o social da empresa",
    "Nome do produto",
    "N\u00famero do processo",
    "Tipo de produto (Cosm\u00e9tico)",
    "Categoria do produto",
    "Data de finaliza\u00e7\u00e3o do processo",
    "N\u00famero de registro do produto",
    "Data de vencimento do registro",
    "Situa\u00e7\u00e3o do registro (Ativo, Inativo)"
  )
)

#' ANVISA sanitizers variable metadata (6 columns)
#' @noRd
anvisa_sanitizers_metadata <- tibble::tibble(
  variable = c(
    "NOME_PRODUTO", "NUMERO_PROCESSO", "RAZAO_SOCIAL_EMPRESA",
    "NUMERO_REGISTRO", "DATA_VENCIMENTO_REGISTRO",
    "ST_SITUACAO_REGISTRO"
  ),
  description = c(
    "Nome do produto",
    "N\u00famero do processo",
    "Raz\u00e3o social da empresa",
    "N\u00famero de registro",
    "Data de vencimento do registro",
    "Situa\u00e7\u00e3o do registro (Ativo, Inativo)"
  )
)

#' ANVISA tobacco variable metadata (9 columns)
#' @noRd
anvisa_tobacco_metadata <- tibble::tibble(
  variable = c(
    "NU_CNPJ_EMPRESA", "NO_RAZAO_SOCIAL_EMPRESA", "NO_PRODUTO",
    "NU_PROCESSO", "DS_TIPO_PRODUTO", "DS_CATEGORIA_PRODUTO",
    "DT_FINALIZACAO_PROCESSO", "DT_VENCIMENTO_REGISTRO",
    "ST_SITUACAO_REGISTRO"
  ),
  description = c(
    "CNPJ da empresa",
    "Raz\u00e3o social da empresa",
    "Nome do produto",
    "N\u00famero do processo",
    "Tipo de produto (Derivados do Tabaco)",
    "Categoria do produto (Cigarro com Filtro, etc.)",
    "Data de finaliza\u00e7\u00e3o do processo",
    "Data de vencimento do registro",
    "Situa\u00e7\u00e3o do registro (Ativo, Inativo)"
  )
)

#' ANVISA pesticides variable metadata (15 columns)
#' @noRd
anvisa_pesticides_metadata <- tibble::tibble(
  variable = c(
    "NO_SUBSTANCIA", "TP_SUBSTANCIA", "NU_LMR", "CO_MONOGRAFIA",
    "DS_INGREDIENTE_ATIVO", "NU_CAS", "ST_AUTORIZADO", "NO_CULTURA",
    "TIPO_LIMITE", "NO_VALOR_REFERENCIA", "NO_UNIDADE_MEDIDA",
    "DS_ATO_LEGAL", "DT_INICIO_VIGENCIA", "DT_FIM_VIGENCIA",
    "DT_ATUALIZACAO"
  ),
  description = c(
    "Nome da subst\u00e2ncia",
    "Tipo da subst\u00e2ncia (Qu\u00edmico, Biol\u00f3gico, etc.)",
    "Limite m\u00e1ximo de res\u00edduo (LMR)",
    "C\u00f3digo da monografia",
    "Descri\u00e7\u00e3o do ingrediente ativo",
    "N\u00famero CAS",
    "Autorizado (SIM/N\u00c3O)",
    "Nome da cultura",
    "Tipo de limite",
    "Valor de refer\u00eancia",
    "Unidade de medida",
    "Ato legal (norma)",
    "Data de in\u00edcio da vig\u00eancia",
    "Data de fim da vig\u00eancia",
    "Data de atualiza\u00e7\u00e3o"
  )
)

#' ANVISA hemovigilance variable metadata (16 columns)
#' @noRd
anvisa_hemovigilance_metadata <- tibble::tibble(
  variable = c(
    "NU_NOTIFICACAO", "DATA_OCORRENCIA_EVENTO",
    "DATA_NOTIFICACAO_EVENTO", "STATUS_ANALISE",
    "PRODUTO_MOTIVO", "TIPO_REACAO_TRANSFUSIONAL", "GRAU_RISCO",
    "CATEGORIA_NOTIFICADOR", "TIPO_HEMOCOMPONENTE",
    "FAIXA_ETARIA_PACIENTE", "CIDADE_NOTIFICACAO",
    "UF_NOTIFICACAO", "DS_TEMPORALIDADE_REACAO",
    "TIPO_EVENTO_ADVERSO", "ETAPA_CICLO_SANGUE",
    "DS_ESPECIFICACAO_EVENTO"
  ),
  description = c(
    "N\u00famero da notifica\u00e7\u00e3o",
    "Data de ocorr\u00eancia do evento",
    "Data da notifica\u00e7\u00e3o",
    "Status da an\u00e1lise (Conclu\u00edda, N\u00e3o Conclu\u00edda)",
    "Produto motivo do evento",
    "Tipo de rea\u00e7\u00e3o transfusional",
    "Grau de risco (Grau I, II, III, IV)",
    "Categoria do notificador (Rede Sentinela, etc.)",
    "Tipo de hemocomponente",
    "Faixa et\u00e1ria do paciente",
    "Cidade da notifica\u00e7\u00e3o",
    "UF da notifica\u00e7\u00e3o",
    "Temporalidade da rea\u00e7\u00e3o (Imediata, Tardia)",
    "Tipo de evento adverso",
    "Etapa do ciclo do sangue",
    "Especifica\u00e7\u00e3o do evento"
  )
)

#' ANVISA technovigilance variable metadata (18 columns)
#' @noRd
anvisa_technovigilance_metadata <- tibble::tibble(
  variable = c(
    "ANO_NOTIFICACAO", "DATA_NOTIFICACAO", "NU_NOTIFICACAO",
    "TIPO_NOTIFICACAO", "SUBTIPO_QUEIXA",
    "CATEGORIA_DISPOSITIVO", "CODIFICACAO_EVENTO_ADVERSO",
    "UF_EMPRESA_NOTIFICANTE", "MUNICIPIO_EMP_NOTIFICANTE",
    "TIPO_NOTIFICANTE", "UF_OCORRENCIA", "MUNICIPIO_OCORRENCIA",
    "CLASSE_RISCO", "NOME_TECNICO_PRODUTO",
    "OCORRENCIA_NIVEL_1", "OCORRENCIA_NIVEL_2",
    "UF_EMPRESA_REGISTRO", "MUNICIPIO_EMPRESA_REGISTRO"
  ),
  description = c(
    "Ano da notifica\u00e7\u00e3o",
    "Data da notifica\u00e7\u00e3o",
    "N\u00famero da notifica\u00e7\u00e3o",
    "Tipo (Queixa T\u00e9cnica, Evento Adverso)",
    "Subtipo de queixa",
    "Categoria do dispositivo (Artigo M\u00e9dico-Hospitalar, etc.)",
    "Codifica\u00e7\u00e3o do evento adverso",
    "UF da empresa notificante",
    "Munic\u00edpio da empresa notificante",
    "Tipo de notificante",
    "UF da ocorr\u00eancia",
    "Munic\u00edpio da ocorr\u00eancia",
    "Classe de risco (I, II, III, IV)",
    "Nome t\u00e9cnico do produto",
    "Ocorr\u00eancia n\u00edvel 1 (Mec\u00e2nico, El\u00e9trica, etc.)",
    "Ocorr\u00eancia n\u00edvel 2 (detalhe)",
    "UF da empresa de registro",
    "Munic\u00edpio da empresa de registro"
  )
)

#' ANVISA VigiMed notifications variable metadata (29 columns)
#' @noRd
anvisa_vigimed_notifications_metadata <- tibble::tibble(
  variable = c(
    "UF", "TIPO_ENTRADA_VIGIMED", "RECEBIDO_DE",
    "IDENTIFICACAO_NOTIFICACAO", "DATA_INCLUSAO_SISTEMA",
    "DATA_ULTIMA_ATUALIZACAO", "DATA_NOTIFICACAO",
    "TIPO_NOTIFICACAO", "NOTIFICACAO_PARENT_CHILD",
    "DATA_NASCIMENTO", "IDADE_MOMENTO_REACAO", "GRUPO_IDADE",
    "IDADE_GESTACIONAL_MOMENTO_REACAO", "SEXO", "GESTANTE",
    "LACTANTE", "PESO_KG", "ALTURA_CM",
    "REACAO_EVENTO_ADVERSO_MEDDRA", "GRAVE", "GRAVIDADE",
    "DESFECHO", "DATA_INICIO_HORA", "DATA_FINAL_HORA", "DURACAO",
    "RELACAO_MEDICAMENTO_EVENTO", "NOME_MEDICAMENTO_WHODRUG",
    "ACAO_ADOTADA", "NOTIFICADOR"
  ),
  description = c(
    "UF",
    "Tipo de entrada no VigiMed",
    "Recebido de (Empresa Farmac\u00eautica, etc.)",
    "Identifica\u00e7\u00e3o da notifica\u00e7\u00e3o (BR-ANVISA-...)",
    "Data de inclus\u00e3o no sistema",
    "Data da \u00faltima atualiza\u00e7\u00e3o",
    "Data da notifica\u00e7\u00e3o",
    "Tipo de notifica\u00e7\u00e3o (espont\u00e2nea, etc.)",
    "Notifica\u00e7\u00e3o parent/child",
    "Data de nascimento",
    "Idade no momento da rea\u00e7\u00e3o",
    "Grupo de idade",
    "Idade gestacional no momento da rea\u00e7\u00e3o",
    "Sexo",
    "Gestante (Sim/N\u00e3o)",
    "Lactante (Sim/N\u00e3o)",
    "Peso em kg",
    "Altura em cm",
    "Rea\u00e7\u00e3o/evento adverso (MedDRA)",
    "Grave (Sim/N\u00e3o)",
    "Tipo de gravidade",
    "Desfecho",
    "Data de in\u00edcio",
    "Data final",
    "Dura\u00e7\u00e3o",
    "Rela\u00e7\u00e3o medicamento-evento (Suspeito, Concomitante)",
    "Nome do medicamento (WHODrug)",
    "A\u00e7\u00e3o adotada",
    "Tipo de notificador (M\u00e9dico, Farmac\u00eautico, etc.)"
  )
)

#' ANVISA VigiMed medicines variable metadata (22 columns)
#' @noRd
anvisa_vigimed_medicines_metadata <- tibble::tibble(
  variable = c(
    "IDENTIFICACAO_NOTIFICACAO", "RELACAO_MEDICAMENTO_EVENTO",
    "NOME_MEDICAMENTO_WHODRUG", "PRINCIPIOS_ATIVOS_WHODRUG",
    "CODIGO_ATC", "DETENTOR_REGISTRO", "CONCENTRACAO",
    "COMPONENTE_SUSPEITO", "ACAO_ADOTADA",
    "PROBLEMAS_ADICIONAIS_RELCIONADOS_MEDICAMENTO",
    "INDICACAO_MEDDRA", "INDICACAO_RELATADA_NOTIFICADOR_INICIAL",
    "DOSE", "FREQUENCIA_DOSE", "POSOLOGIA", "DURACAO",
    "INICIO_ADMINISTRACAO", "FIM_ADMINISTRACAO",
    "FORMA_FARMACEUTICA", "VIA_ADMINISTRACAO",
    "VIA_ADMINISTRACAO_MAE_PAI", "NUMELO_LOTE"
  ),
  description = c(
    "Identifica\u00e7\u00e3o da notifica\u00e7\u00e3o (chave de liga\u00e7\u00e3o)",
    "Rela\u00e7\u00e3o medicamento-evento (Suspeito, Concomitante)",
    "Nome do medicamento (WHODrug)",
    "Princ\u00edpios ativos (WHODrug)",
    "C\u00f3digo ATC",
    "Detentor do registro",
    "Concentra\u00e7\u00e3o",
    "Componente suspeito",
    "A\u00e7\u00e3o adotada",
    "Problemas adicionais relacionados ao medicamento",
    "Indica\u00e7\u00e3o (MedDRA)",
    "Indica\u00e7\u00e3o relatada pelo notificador",
    "Dose",
    "Frequ\u00eancia da dose",
    "Posologia",
    "Dura\u00e7\u00e3o do uso",
    "In\u00edcio da administra\u00e7\u00e3o",
    "Fim da administra\u00e7\u00e3o",
    "Forma farmac\u00eautica",
    "Via de administra\u00e7\u00e3o",
    "Via de administra\u00e7\u00e3o (m\u00e3e/pai)",
    "N\u00famero do lote"
  )
)

#' ANVISA VigiMed reactions variable metadata (12 columns)
#' @noRd
anvisa_vigimed_reactions_metadata <- tibble::tibble(
  variable = c(
    "IDENTIFICACAO_NOTIFICACAO", "REACAO_EVTO_ADVERSO_MEDDRA_LLT",
    "PT", "HLT", "HLGT", "SOC",
    "DATA_INICIO_HORA", "DATA_FINAL_HORA", "DURACAO",
    "GRAVE", "GRAVIDADE", "DESFECHO"
  ),
  description = c(
    "Identifica\u00e7\u00e3o da notifica\u00e7\u00e3o (chave de liga\u00e7\u00e3o)",
    "Rea\u00e7\u00e3o/evento adverso (MedDRA LLT)",
    "Preferred Term (MedDRA PT)",
    "High Level Term (MedDRA HLT)",
    "High Level Group Term (MedDRA HLGT)",
    "System Organ Class (MedDRA SOC)",
    "Data de in\u00edcio",
    "Data final",
    "Dura\u00e7\u00e3o",
    "Grave (Sim/N\u00e3o)",
    "Tipo de gravidade",
    "Desfecho"
  )
)

#' ANVISA SNGPC industrialized variable metadata (15 columns)
#' @noRd
anvisa_sngpc_metadata <- tibble::tibble(
  variable = c(
    "NU_ANO_VENDA", "NU_MES_VENDA", "SG_UF_VENDA",
    "NO_MUNICIPIO_VENDA", "DS_PRINCIPIO_ATIVO",
    "DS_DESCRICAO_APRESENTACAO", "QT_VENDIDA", "DS_UNIDADE_MEDIDA",
    "NO_CONSELHO_PRESCRITOR", "SG_UF_CONSELHO_PRESCRITOR",
    "TP_RECEITUARIO", "CO_CID10", "SG_SEXO", "NU_IDADE",
    "NU_UNIDADE_IDADE"
  ),
  description = c(
    "Ano da venda",
    "M\u00eas da venda",
    "UF da venda",
    "Munic\u00edpio da venda",
    "Princ\u00edpio ativo",
    "Descri\u00e7\u00e3o da apresenta\u00e7\u00e3o",
    "Quantidade vendida",
    "Unidade de medida",
    "Conselho do prescritor (CRM, CRO, etc.)",
    "UF do conselho do prescritor",
    "Tipo de receitu\u00e1rio",
    "C\u00f3digo CID-10",
    "Sexo",
    "Idade",
    "Unidade de idade"
  )
)

#' ANVISA SNGPC compounded variable metadata (17 columns)
#' @noRd
anvisa_sngpc_compounded_metadata <- tibble::tibble(
  variable = c(
    "NU_ANO_VENDA", "NU_MES_VENDA", "SG_UF_VENDA",
    "NO_MUNICIPIO_VENDA", "DS_DCB", "NO_PRINCIPIO_ATIVO",
    "QT_ATIVO_POR_UNID_FARMACOTEC",
    "DS_UNIDADE_MEDIDA_PRINCIPIO_ATIVO",
    "QT_UNIDADE_FARMACOTECNICA", "DS_TIPO_UNIDADE_FARMACOTECNICA",
    "NO_CONSELHO_PRESCRITOR", "SG_UF_CONSELHO_PRESCRITOR",
    "TP_RECEITUARIO", "CO_CID10", "SG_SEXO", "NU_IDADE",
    "NU_UNIDADE_IDADE"
  ),
  description = c(
    "Ano da venda",
    "M\u00eas da venda",
    "UF da venda",
    "Munic\u00edpio da venda",
    "C\u00f3digo DCB (Denomina\u00e7\u00e3o Comum Brasileira)",
    "Nome do princ\u00edpio ativo",
    "Quantidade de ativo por unidade farmacot\u00e9cnica",
    "Unidade de medida do princ\u00edpio ativo",
    "Quantidade de unidades farmacot\u00e9cnicas",
    "Tipo de unidade farmacot\u00e9cnica (C\u00e1psula, Comprimido, etc.)",
    "Conselho do prescritor (CRM, CRO, etc.)",
    "UF do conselho do prescritor",
    "Tipo de receitu\u00e1rio",
    "C\u00f3digo CID-10",
    "Sexo",
    "Idade",
    "Unidade de idade"
  )
)

# ============================================================================
# Metadata lookup helper
# ============================================================================

#' Get variable metadata for a given ANVISA type
#' @param type Character. ANVISA data type code.
#' @return A tibble with variable metadata.
#' @noRd
.anvisa_get_metadata <- function(type) {
  switch(type,
    medicines = anvisa_medicines_metadata,
    medical_devices = anvisa_medical_devices_metadata,
    food = anvisa_food_metadata,
    cosmetics = anvisa_cosmetics_metadata,
    sanitizers = anvisa_sanitizers_metadata,
    tobacco = anvisa_tobacco_metadata,
    pesticides = anvisa_pesticides_metadata,
    hemovigilance = anvisa_hemovigilance_metadata,
    technovigilance = anvisa_technovigilance_metadata,
    vigimed_notifications = anvisa_vigimed_notifications_metadata,
    vigimed_medicines = anvisa_vigimed_medicines_metadata,
    vigimed_reactions = anvisa_vigimed_reactions_metadata,
    sngpc = anvisa_sngpc_metadata,
    sngpc_compounded = anvisa_sngpc_compounded_metadata
  )
}
