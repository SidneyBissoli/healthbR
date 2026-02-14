# Tests for shared search helpers in utils-search.R

# ============================================================================
# .strip_accents
# ============================================================================

test_that(".strip_accents strips lowercase Portuguese accents", {
  expect_equal(.strip_accents("\u00e0\u00e1\u00e2\u00e3\u00e4"), "aaaaa")
  expect_equal(.strip_accents("\u00e8\u00e9\u00ea\u00eb"), "eeee")
  expect_equal(.strip_accents("\u00ec\u00ed\u00ee\u00ef"), "iiii")
  expect_equal(.strip_accents("\u00f2\u00f3\u00f4\u00f5\u00f6"), "ooooo")
  expect_equal(.strip_accents("\u00f9\u00fa\u00fb\u00fc"), "uuuu")
  expect_equal(.strip_accents("\u00e7"), "c")
})

test_that(".strip_accents strips uppercase accents", {
  expect_equal(.strip_accents("\u00c0\u00c1\u00c2\u00c3\u00c4"), "AAAAA")
  expect_equal(.strip_accents("\u00c7"), "C")
  expect_equal(.strip_accents("\u00d2\u00d3\u00d4\u00d5\u00d6"), "OOOOO")
})

test_that(".strip_accents strips Spanish characters", {
  expect_equal(.strip_accents("\u00f1"), "n")
  expect_equal(.strip_accents("\u00d1"), "N")
})

test_that(".strip_accents leaves ASCII unchanged", {
  expect_equal(.strip_accents("hello world"), "hello world")
  expect_equal(.strip_accents("ABC123"), "ABC123")
})

test_that(".strip_accents handles full Portuguese words", {
  expect_equal(.strip_accents("sa\u00fade"), "saude")
  expect_equal(.strip_accents("popula\u00e7\u00e3o"), "populacao")
  expect_equal(.strip_accents("m\u00e3e"), "mae")
  expect_equal(.strip_accents("domic\u00edlio"), "domicilio")
})

test_that(".strip_accents handles empty and vector input", {
  expect_equal(.strip_accents(""), "")
  expect_equal(.strip_accents(c("caf\u00e9", "ma\u00e7\u00e3")), c("cafe", "maca"))
})


# ============================================================================
# .search_metadata
# ============================================================================

test_that(".search_metadata returns data unchanged when search is NULL", {
  df <- data.frame(variable = c("A", "B"), description = c("x", "y"),
                   stringsAsFactors = FALSE)
  expect_identical(.search_metadata(df, NULL, c("variable", "description")), df)
})

test_that(".search_metadata filters by exact match", {
  df <- data.frame(variable = c("IDADE", "SEXO", "RACA"),
                   description = c("Idade", "Sexo", "Raca"),
                   stringsAsFactors = FALSE)
  result <- .search_metadata(df, "sexo", c("variable", "description"))
  expect_equal(nrow(result), 1)
  expect_equal(result$variable, "SEXO")
})

test_that(".search_metadata is case-insensitive", {
  df <- data.frame(variable = c("IDADE", "SEXO"),
                   description = c("Idade do paciente", "Sexo do paciente"),
                   stringsAsFactors = FALSE)
  result <- .search_metadata(df, "IDADE", c("variable", "description"))
  expect_equal(nrow(result), 1)
  expect_equal(result$variable, "IDADE")
})

test_that(".search_metadata is accent-insensitive", {
  df <- data.frame(variable = c("IDADE", "NOME_MAE"),
                   description = c("Idade", "Nome da m\u00e3e"),
                   stringsAsFactors = FALSE)
  # search "mae" should match "mãe" in description

  result <- .search_metadata(df, "mae", c("variable", "description"))
  expect_equal(nrow(result), 1)
  expect_equal(result$variable, "NOME_MAE")
})

test_that(".search_metadata matches accented search against ASCII data", {
  df <- data.frame(variable = c("SAUDE", "OUTRO"),
                   description = c("Saude publica", "Outro campo"),
                   stringsAsFactors = FALSE)
  # search with accent should match ASCII description
  result <- .search_metadata(df, "sa\u00fade", c("variable", "description"))
  expect_equal(nrow(result), 1)
  expect_equal(result$variable, "SAUDE")
})

test_that(".search_metadata searches multiple columns", {
  df <- data.frame(
    code = c("DENG", "TUBE", "CHIK"),
    name = c("Dengue", "Tuberculose", "Chikungunya"),
    description = c("Febre", "Pulmonar", "Viral"),
    stringsAsFactors = FALSE
  )
  # match in code column
  result <- .search_metadata(df, "DENG", c("code", "name", "description"))
  expect_equal(nrow(result), 1)
  expect_equal(result$code, "DENG")

  # match in name column
  result2 <- .search_metadata(df, "tuberculose", c("code", "name", "description"))
  expect_equal(nrow(result2), 1)
  expect_equal(result2$code, "TUBE")

  # match in description column
  result3 <- .search_metadata(df, "pulmonar", c("code", "name", "description"))
  expect_equal(nrow(result3), 1)
  expect_equal(result3$code, "TUBE")
})

test_that(".search_metadata returns empty data.frame when no match", {
  df <- data.frame(variable = c("A", "B"),
                   description = c("x", "y"),
                   stringsAsFactors = FALSE)
  result <- .search_metadata(df, "zzz", c("variable", "description"))
  expect_equal(nrow(result), 0)
})

test_that(".search_metadata handles partial matches", {
  df <- data.frame(variable = c("CAUSABAS", "CAUSA_EXTERNA", "SEXO"),
                   description = c("Causa basica", "Causa externa", "Sexo"),
                   stringsAsFactors = FALSE)
  result <- .search_metadata(df, "causa", c("variable", "description"))
  expect_equal(nrow(result), 2)
})

test_that(".search_metadata handles accented data with accent search", {
  df <- data.frame(variable = c("POP"),
                   description = c("Popula\u00e7\u00e3o residente"),
                   stringsAsFactors = FALSE)
  result <- .search_metadata(df, "popula\u00e7\u00e3o", c("variable", "description"))
  expect_equal(nrow(result), 1)
})
