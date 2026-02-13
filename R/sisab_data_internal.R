# sisab internal data definitions for healthbR package
# constants, metadata, and reference data for the SISAB module
# (Sistema de Informacao em Saude para a Atencao Basica)

# ============================================================================
# API base URL
# ============================================================================

#' SISAB API base URL (relatorioaps backend)
#' @noRd
sisab_api_url <- "https://relatorioaps-prd.saude.gov.br"

# ============================================================================
# valid report types
# ============================================================================

#' SISAB report types with API endpoint paths
#' @noRd
sisab_valid_types <- tibble::tibble(
  code = c("aps", "sb", "acs", "pns"),
  name = c(
    "Cobertura da Aten\u00e7\u00e3o Prim\u00e1ria",
    "Cobertura de Sa\u00fade Bucal",
    "Cobertura de Agentes Comunit\u00e1rios de Sa\u00fade",
    "Cobertura PNS (Pesquisa Nacional de Sa\u00fade)"
  ),
  endpoint = c(
    "/cobertura/aps",
    "/cobertura/sb/v2",
    "/cobertura/acs",
    "/cobertura/pns"
  ),
  description = c(
    "Cobertura potencial da APS por equipes eSF, eAP, eSFR, eCR, eAPP (2019-atual)",
    "Cobertura de sa\u00fade bucal por equipes eSB e outras (2024-atual)",
    "Cobertura de agentes comunit\u00e1rios de sa\u00fade (2007-atual)",
    "Cobertura da Aten\u00e7\u00e3o Prim\u00e1ria via PNS (2020-2023)"
  )
)

# ============================================================================
# valid geographic levels
# ============================================================================

#' SISAB valid geographic levels (mapped to API parameter values)
#' @noRd
sisab_valid_levels <- c(
  "brazil" = "BRASIL",
  "region" = "REGIAO",
  "uf" = "UF",
  "municipality" = "MUNICIPIO"
)

# ============================================================================
# UF code map (abbreviation -> IBGE code)
# ============================================================================

#' Brazilian UF abbreviations to IBGE codes
#' @noRd
sisab_uf_map <- c(
  "AC" = "12", "AL" = "27", "AP" = "16", "AM" = "13",
  "BA" = "29", "CE" = "23", "DF" = "53", "ES" = "32",
  "GO" = "52", "MA" = "21", "MT" = "51", "MS" = "50",
  "MG" = "31", "PA" = "15", "PB" = "25", "PR" = "41",
  "PE" = "26", "PI" = "22", "RJ" = "33", "RN" = "24",
  "RS" = "43", "RO" = "11", "RR" = "14", "SC" = "42",
  "SP" = "35", "SE" = "28", "TO" = "17"
)

# ============================================================================
# variables metadata per report type
# ============================================================================

#' SISAB APS coverage variables metadata
#' @noRd
sisab_variables_aps <- tibble::tibble(
  variable = c(
    "nuComp",
    "coRegiao", "noRegiao", "sgRegiao",
    "coUfIbge", "noUf", "noUfAcentuado", "sgUf",
    "coMunicipioIbge", "noMunicipioIbge", "noMunicipioAcentuado",
    "coClassificacaoTipologia", "nuAnoReferencia", "tpOrigemBasePopulacao",
    "qtPopulacao",
    "qtEsf", "qtEap30", "qtEap20",
    "qtEsfr", "qtCadastroEsfr",
    "qtEcr", "qtCadastroEcr",
    "qtEapp20", "qtCadastroEapp20",
    "qtEapp30", "qtCadastroEapp30",
    "qtCadastroEquipeEsfrEcrEapp",
    "qtCapacidadeEquipe",
    "qtCobertura"
  ),
  description = c(
    "Compet\u00eancia CNES (MM/YYYY)",
    "C\u00f3digo da regi\u00e3o", "Nome da regi\u00e3o", "Sigla da regi\u00e3o",
    "C\u00f3digo UF IBGE", "Nome da UF", "Nome da UF (com acentos)", "Sigla da UF",
    "C\u00f3digo munic\u00edpio IBGE", "Nome do munic\u00edpio", "Nome do munic\u00edpio (com acentos)",
    "Classifica\u00e7\u00e3o tipologia", "Ano refer\u00eancia popula\u00e7\u00e3o", "Origem base popula\u00e7\u00e3o",
    "Popula\u00e7\u00e3o",
    "Quantidade equipes eSF", "Quantidade equipes eAP 30h", "Quantidade equipes eAP 20h",
    "Quantidade equipes eSFR", "Cadastros equipes eSFR",
    "Quantidade equipes eCR", "Cadastros equipes eCR",
    "Quantidade equipes eAPP 20h", "Cadastros equipes eAPP 20h",
    "Quantidade equipes eAPP 30h", "Cadastros equipes eAPP 30h",
    "Cadastros equipes eSFR+eCR+eAPP",
    "Capacidade estimada equipe",
    "Cobertura (%)"
  ),
  type = c(
    "character",
    rep("character", 3),
    rep("character", 4),
    rep("character", 3),
    rep("character", 3),
    "numeric",
    rep("numeric", 3),
    rep("numeric", 2),
    rep("numeric", 2),
    rep("numeric", 2),
    rep("numeric", 2),
    "numeric",
    "numeric",
    "numeric"
  ),
  section = c(
    "temporal",
    rep("geografia", 3),
    rep("geografia", 4),
    rep("geografia", 3),
    rep("classificacao", 3),
    "populacao",
    rep("equipes", 3),
    rep("equipes", 2),
    rep("equipes", 2),
    rep("equipes", 2),
    rep("equipes", 2),
    "equipes",
    "cobertura",
    "cobertura"
  )
)

#' SISAB SB (Saude Bucal) coverage variables metadata
#' @noRd
sisab_variables_sb <- tibble::tibble(
  variable = c(
    "nuCompetencia",
    "coRegiao", "noRegiao", "sgRegiao",
    "coUfIbge", "noUf", "noUfAcentuado", "sgUf",
    "coMunicipioIbge", "noMunicipioIbge", "noMunicipioAcentuado",
    "qtPopulacao", "nuAnoReferencia",
    "qtEquipeSb40h", "qtEquipeSb30h", "qtEquipeSb20h",
    "qtParametroCadastroEquipeSb", "pcCoberturaSbSf",
    "qtEquipeEsfr", "qtEquipeEcr", "qtEquipeEapp",
    "qtSisabCadastroEquipeEsfrEcrEapp",
    "qtParametroCadastroEquipeSbAps", "pcCoberturaSbAps"
  ),
  description = c(
    "Compet\u00eancia CNES (YYYYMM)",
    "C\u00f3digo da regi\u00e3o", "Nome da regi\u00e3o", "Sigla da regi\u00e3o",
    "C\u00f3digo UF IBGE", "Nome da UF", "Nome da UF (com acentos)", "Sigla da UF",
    "C\u00f3digo munic\u00edpio IBGE", "Nome do munic\u00edpio", "Nome do munic\u00edpio (com acentos)",
    "Popula\u00e7\u00e3o", "Ano refer\u00eancia popula\u00e7\u00e3o",
    "Equipes Sa\u00fade Bucal 40h", "Equipes Sa\u00fade Bucal 30h", "Equipes Sa\u00fade Bucal 20h",
    "Par\u00e2metro cadastro equipe SB", "Cobertura Sa\u00fade Bucal SF (%)",
    "Equipes eSFR", "Equipes eCR", "Equipes eAPP",
    "Cadastros equipes eSFR+eCR+eAPP (SISAB)",
    "Par\u00e2metro cadastro equipe SB APS", "Cobertura Sa\u00fade Bucal APS (%)"
  ),
  type = c(
    "character",
    rep("character", 3),
    rep("character", 4),
    rep("character", 3),
    "numeric", "character",
    rep("numeric", 3),
    "numeric", "numeric",
    rep("numeric", 3),
    "numeric",
    "numeric", "numeric"
  ),
  section = c(
    "temporal",
    rep("geografia", 3),
    rep("geografia", 4),
    rep("geografia", 3),
    "populacao", "classificacao",
    rep("equipes", 3),
    "cobertura", "cobertura",
    rep("equipes", 3),
    "equipes",
    "cobertura", "cobertura"
  )
)

#' SISAB ACS coverage variables metadata
#' @noRd
sisab_variables_acs <- tibble::tibble(
  variable = c(
    "nuComp",
    "coRegiao", "noRegiao", "sgRegiao",
    "coUfIbge", "noUf", "noUfAcentuado", "sgUf",
    "coMunicipioIbge", "noMunicipioIbge", "noMunicipioAcentuado",
    "qtAcsAtivoAb", "qtAcsCoberturaAb",
    "qtPopulacao", "qtCoberturaAcsAb", "pcCoberturaAcsAb"
  ),
  description = c(
    "Compet\u00eancia CNES (YYYYMM)",
    "C\u00f3digo da regi\u00e3o", "Nome da regi\u00e3o", "Sigla da regi\u00e3o",
    "C\u00f3digo UF IBGE", "Nome da UF", "Nome da UF (com acentos)", "Sigla da UF",
    "C\u00f3digo munic\u00edpio IBGE", "Nome do munic\u00edpio", "Nome do munic\u00edpio (com acentos)",
    "ACS ativos na Aten\u00e7\u00e3o B\u00e1sica", "ACS com cobertura na AB",
    "Popula\u00e7\u00e3o", "Popula\u00e7\u00e3o coberta por ACS", "Cobertura ACS AB (%)"
  ),
  type = c(
    "character",
    rep("character", 3),
    rep("character", 4),
    rep("character", 3),
    "character", "character",
    "character", "character", "character"
  ),
  section = c(
    "temporal",
    rep("geografia", 3),
    rep("geografia", 4),
    rep("geografia", 3),
    rep("agentes", 2),
    "populacao", "cobertura", "cobertura"
  )
)

#' SISAB PNS coverage variables metadata
#' @noRd
sisab_variables_pns <- tibble::tibble(
  variable = c(
    "nuComp",
    "coRegiao", "noRegiao", "sgRegiao",
    "coUfIbge", "noUf", "noUfAcentuado", "sgUf",
    "coMunicipioIbge", "noMunicipioIbge", "noMunicipioAcentuado",
    "qtPopulacao",
    "qtEapPaga", "qtEsfPaga",
    "qtCadastroEapPaga", "qtCadastroEsfPaga",
    "qtTotalCadastroApsPaga",
    "vlCobertura"
  ),
  description = c(
    "Compet\u00eancia (MMM/YYYY)",
    "C\u00f3digo da regi\u00e3o", "Nome da regi\u00e3o", "Sigla da regi\u00e3o",
    "C\u00f3digo UF IBGE", "Nome da UF", "Nome da UF (com acentos)", "Sigla da UF",
    "C\u00f3digo munic\u00edpio IBGE", "Nome do munic\u00edpio", "Nome do munic\u00edpio (com acentos)",
    "Popula\u00e7\u00e3o",
    "Quantidade eAP pagas", "Quantidade eSF pagas",
    "Cadastros eAP pagas", "Cadastros eSF pagas",
    "Total cadastros APS pagas",
    "Cobertura (%)"
  ),
  type = c(
    "character",
    rep("character", 3),
    rep("character", 4),
    rep("character", 3),
    "numeric",
    rep("numeric", 2),
    rep("numeric", 2),
    "numeric",
    "numeric"
  ),
  section = c(
    "temporal",
    rep("geografia", 3),
    rep("geografia", 4),
    rep("geografia", 3),
    "populacao",
    rep("equipes", 2),
    rep("equipes", 2),
    "equipes",
    "cobertura"
  )
)
