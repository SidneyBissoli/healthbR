# tests for the SI-PNI R2 backend (utils-r2.R + sipni_r2.R)

# ============================================================================
# .resolve_sources
# ============================================================================

test_that(".resolve_sources keeps priority order and deduplicates", {
  expect_equal(.resolve_sources(c("r2", "datasus")), c("r2", "datasus"))
  expect_equal(.resolve_sources(c("datasus", "r2")), c("datasus", "r2"))
  expect_equal(.resolve_sources("datasus"), "datasus")
  expect_equal(.resolve_sources(c("r2", "r2", "datasus")), c("r2", "datasus"))
})

test_that(".resolve_sources rejects invalid values", {
  expect_error(.resolve_sources("ftp"), "Invalid")
  expect_error(.resolve_sources(character(0)), "Invalid")
  expect_error(.resolve_sources(c("r2", "s3")), "Invalid")
})


# ============================================================================
# .r2_credentials
# ============================================================================

test_that(".r2_credentials defaults to the public healthbr-data token", {
  creds <- .r2_credentials()
  expect_equal(creds$bucket, "healthbr-data")
  expect_match(creds$endpoint, "r2\\.cloudflarestorage\\.com")
  expect_true(nzchar(creds$access_key_id))
  expect_true(nzchar(creds$secret_access_key))
})

test_that(".r2_credentials accepts custom credentials", {
  creds <- .r2_credentials(list(
    access_key_id = "AK", secret_access_key = "SK",
    endpoint = "https://example.com", bucket = "meu-bucket"
  ))
  expect_equal(creds$access_key_id, "AK")
  expect_equal(creds$secret_access_key, "SK")
  expect_equal(creds$endpoint, "https://example.com")
  expect_equal(creds$bucket, "meu-bucket")
})

test_that(".r2_credentials fills endpoint/bucket defaults", {
  creds <- .r2_credentials(list(access_key_id = "AK",
                                secret_access_key = "SK"))
  expect_equal(creds$bucket, "healthbr-data")
  expect_match(creds$endpoint, "cloudflarestorage")
})

test_that(".r2_credentials rejects incomplete credentials", {
  expect_error(.r2_credentials(list(access_key_id = "AK")),
               "r2_credentials")
  expect_error(.r2_credentials(list()), "r2_credentials")
})


# ============================================================================
# sipni source validation in sipni_data
# ============================================================================

test_that("sipni_data rejects invalid source", {
  expect_error(sipni_data(year = 2024, source = "ftp"), "Invalid")
})


# ============================================================================
# sipni_variables_microdados metadata table
# ============================================================================

test_that("sipni_variables_microdados has 56 unique variables", {
  expect_equal(nrow(sipni_variables_microdados), 56)
  expect_equal(anyDuplicated(sipni_variables_microdados$variable), 0)
  expect_true(all(c("variable", "description", "type", "section") %in%
                    names(sipni_variables_microdados)))
})

test_that("sipni_variables_microdados has expected key variables and types", {
  v <- sipni_variables_microdados
  expect_true(all(c("dt_vacina", "ds_vacina", "co_vacina", "sg_uf_paciente",
                    "tp_sexo_paciente", "nu_idade_paciente",
                    "co_municipio_estabelecimento") %in% v$variable))
  expect_equal(v$type[v$variable == "dt_vacina"], "date")
  expect_equal(v$type[v$variable == "nu_idade_paciente"], "integer")
  expect_equal(v$type[v$variable == "ds_vacina"], "character")
})

test_that("sipni_variables selects the column set by source", {
  r2 <- sipni_variables(type = "API")
  csv <- sipni_variables(type = "API", source = "datasus")
  expect_equal(nrow(r2), 56)
  expect_true("dt_vacina" %in% r2$variable)
  expect_true("data_vacina" %in% csv$variable)
  expect_false("data_vacina" %in% r2$variable)
})


# ============================================================================
# .sipni_r2_shape_microdados
# ============================================================================

test_that(".sipni_r2_shape_microdados maps partition columns", {
  df <- tibble::tibble(
    dt_vacina = c("2024-01-15", "2024-01-16"),
    mes = c("01", "01"),
    uf = c("AC", "AC")
  )
  out <- .sipni_r2_shape_microdados(df, 2024)
  expect_equal(names(out)[1:3], c("year", "month", "uf_source"))
  expect_equal(out$year, c(2024L, 2024L))
  expect_equal(out$month, c(1L, 1L))
  expect_equal(out$uf_source, c("AC", "AC"))
  expect_false("mes" %in% names(out))
  expect_false("uf" %in% names(out))
  expect_true("dt_vacina" %in% names(out))
})


# ============================================================================
# .sipni_r2_cached_combos
# ============================================================================

test_that(".sipni_r2_cached_combos returns typed empty tibble without cache", {
  tmp <- withr::local_tempdir()
  out <- .sipni_r2_cached_combos(tmp, "sipni_r2_data",
                                 c("year", "month", "uf_source"))
  expect_equal(nrow(out), 0)
  expect_type(out$year, "integer")
  expect_type(out$month, "integer")
  expect_type(out$uf_source, "character")
})


# ============================================================================
# .r2_manifest local-cache behaviour (offline, mocked HEAD)
# ============================================================================

test_that(".r2_manifest uses the cached copy when offline", {
  tmp <- withr::local_tempdir()
  manifest_path <- "sipni/manifest.json"
  slug <- gsub("[^a-z0-9]+", "_", tolower(manifest_path))
  json_path <- file.path(tmp, paste0("r2_", slug))
  writeLines('{"dataset": "sipni-microdados", "partitions": {
    "2024-01": {"processing_timestamp": "2026-01-01 00:00:00",
                 "source_url": "https://example.com/x.zip",
                 "total_records": 10}}}', json_path)

  local_mocked_bindings(.r2_head_etag = function(url) NULL)
  # clear any session memo from other tests
  rm(list = ls(envir = .r2_env)[grepl("^manifest:", ls(envir = .r2_env))],
     envir = .r2_env)

  m <- .r2_manifest(manifest_path, tmp)
  expect_type(m, "list")
  expect_equal(m$dataset, "sipni-microdados")
  expect_true("2024-01" %in% names(m$partitions))
})

test_that(".r2_manifest returns NULL offline with no cached copy", {
  tmp <- withr::local_tempdir()
  local_mocked_bindings(.r2_head_etag = function(url) NULL)
  expect_null(.r2_manifest("nao/existe/manifest.json", tmp))
})


# ============================================================================
# .sipni_r2_manifest_summary (offline, from cached fixture)
# ============================================================================

test_that(".sipni_r2_manifest_summary parses microdados partition keys", {
  tmp <- withr::local_tempdir()
  slug <- gsub("[^a-z0-9]+", "_", "sipni/manifest.json")
  writeLines('{"partitions": {
    "2020-01": {"processing_timestamp": "2026-02-23 09:45:30",
                 "source_url": "https://example.com/jan.zip",
                 "total_records": 100},
    "2024-12": {"processing_timestamp": "2026-03-01 10:00:00",
                 "source_url": "https://example.com/dez.zip",
                 "total_records": 200}}}',
    file.path(tmp, paste0("r2_", slug)))

  local_mocked_bindings(.r2_head_etag = function(url) NULL)
  rm(list = ls(envir = .r2_env)[grepl("^manifest:", ls(envir = .r2_env))],
     envir = .r2_env)

  s <- .sipni_r2_manifest_summary("microdados", tmp)
  expect_s3_class(s, "tbl_df")
  expect_equal(nrow(s), 2)
  expect_equal(s$year, c(2020L, 2024L))
  expect_equal(s$month, c(1L, 12L))
  expect_true(all(is.na(s$uf)))
  expect_equal(s$records, c(100, 200))

  # microdata years get memoized for dynamic year validation
  expect_true(all(c(2020L, 2024L) %in% .sipni_r2_microdados_years()))
  expect_true(all(c(2020L, 2024L) %in% sipni_years()))
})

test_that(".sipni_r2_manifest_summary parses aggregate partition keys", {
  tmp <- withr::local_tempdir()
  slug <- gsub("[^a-z0-9]+", "_", "sipni/agregados/doses/manifest.json")
  writeLines('{"partitions": {
    "1994-AC": {"processing_timestamp": "2026-02-26 21:22:33",
                 "source_url": "ftp://ftp.datasus.gov.br/DPNIAC94.DBF",
                 "total_records": 1639}}}',
    file.path(tmp, paste0("r2_", slug)))

  local_mocked_bindings(.r2_head_etag = function(url) NULL)
  rm(list = ls(envir = .r2_env)[grepl("^manifest:", ls(envir = .r2_env))],
     envir = .r2_env)

  s <- .sipni_r2_manifest_summary("doses", tmp)
  expect_equal(s$year, 1994L)
  expect_equal(s$uf, "AC")
  expect_true(is.na(s$month))
})


# ============================================================================
# .sipni_expand_dict_lookup / sipni_dictionary(lookup = TRUE)
# ============================================================================

test_that(".sipni_expand_dict_lookup expands commas, ranges and reuse", {
  d <- tibble::tibble(
    variable = c("IMUNO", "IMUNO", "DOSE", "IMUNO", "IMUNO"),
    description = "x",
    code = c("01", "02", "03", "04", "05"),
    label = c("A", "B", "Tratamento", "C", "D"),
    source_codes = c("08,82", "11-13", NA, "99", "99")
  )
  lk <- .sipni_expand_dict_lookup(d)

  # comma-separated codes -> one row each
  expect_setequal(lk$code[lk$label == "A"], c("08", "82"))
  # ranges expand with zero padding
  expect_true(all(c("11", "12", "13") %in% lk$code[lk$label == "B"]))
  # NA source_codes -> code passes through unchanged
  expect_true("03" %in% lk$code[lk$variable == "DOSE"])
  # a data code claimed twice resolves to the FIRST entry (TabWin order)
  expect_equal(lk$label[lk$code == "99"], "C")
  expect_equal(names(lk), c("variable", "description", "code", "label"))
})

test_that(".sipni_expand_dict_lookup: catch-all ranges do not override", {
  # mimics FX_ETARIA: the "Idade ignorada" 00-99 catch-all comes FIRST in
  # the published file — explicit codes must still win (specificity rule)
  d <- tibble::tibble(
    variable = "FX_ETARIA",
    description = "x",
    code = c("99", "10", "36"),
    label = c("Idade ignorada", "Menor de 1 ano", "5 a 9 anos"),
    source_codes = c("00-99", "50", "67")
  )
  lk <- .sipni_expand_dict_lookup(d)
  expect_equal(lk$label[lk$code == "50"], "Menor de 1 ano")
  expect_equal(lk$label[lk$code == "67"], "5 a 9 anos")
  # unclaimed codes fall through to the catch-all
  expect_equal(lk$label[lk$code == "07"], "Idade ignorada")
  expect_false(any(grepl(" | ", lk$label, fixed = TRUE)))
})

test_that("local partitioned cache reads unify schemas across years", {
  skip_if_not_installed("arrow")

  # years with different column sets (schema per source file, like DPNI
  # 1994 = 7 cols vs 2019 = 12 cols); without unify_schemas the read
  # projected everything to the first file's schema, dropping columns
  tmp <- withr::local_tempdir()
  old <- tibble::tibble(year = 1994L, uf_source = "AC",
                        ANO = "1994", QT_DOSE = "1")
  new <- tibble::tibble(year = 2019L, uf_source = "AC",
                        ANO = "2019", QT_DOSE = "2", ANOMES = "201901")
  .cache_append_partitioned(old, tmp, "sipni_dpni_data",
                            c("uf_source", "year"))
  .cache_append_partitioned(new, tmp, "sipni_dpni_data",
                            c("uf_source", "year"))

  got <- .sipni_ftp_check_cache("AC", 2019, "DPNI", cache = TRUE,
                                cache_dir = tmp)
  expect_true("ANOMES" %in% names(got))
  expect_equal(got$ANOMES, "201901")

  res <- .sipni_r2_fetch_agregados("DPNI", years = c(1994L, 2019L),
                                   ufs = "AC", cache = TRUE,
                                   cache_dir = tmp, creds = NULL)
  combined <- dplyr::bind_rows(res$results)
  expect_equal(nrow(combined), 2)
  expect_true("ANOMES" %in% names(combined))
})

test_that("sipni_dictionary(lookup = TRUE) is a no-op on the built-in dict", {
  expect_identical(sipni_dictionary(source = "datasus"),
                   sipni_dictionary(source = "datasus", lookup = TRUE))
})

test_that("built-in dictionary follows the official .cnv data codes", {
  d <- sipni_dictionary(source = "datasus")
  # regenerated from the Ministry's .cnv files: data code 02 = BCG,
  # 09 = Hib (the 0.2.0 hand-written table mislabeled these)
  expect_match(d$label[d$variable == "IMUNO" & d$code == "02"][1], "BCG")
  expect_match(d$label[d$variable == "IMUNO" & d$code == "09"][1], "Hib")
  # range-encoded DOSE codes (11-31 = Tratamento) are expanded
  expect_equal(unique(d$label[d$variable == "DOSE" & d$code == "11"]),
               "Tratamento")
  expect_true(all(c("IMUNO", "DOSE", "FX_ETARIA", "ANO", "MES") %in%
                    d$variable))
})


# ============================================================================
# integration tests (require internet + HEALTHBR_INTEGRATION=true)
# ============================================================================

test_that("sipni_dictionary lookup decodes real aggregate data codes", {
  skip_if_no_integration()

  lk <- sipni_dictionary("IMUNO", lookup = TRUE,
                         cache_dir = tempfile("sipni_lk_test"))
  agg <- sipni_data(year = 2019, uf = "AC", parse = FALSE,
                    cache_dir = tempfile("sipni_lk_data"))
  expect_true(all(unique(agg$IMUNO) %in% lk$code))
})

test_that("sipni_status reads the live manifests", {
  skip_if_no_integration()

  status <- sipni_status(cache_dir = tempfile("sipni_status_test"))
  expect_s3_class(status, "tbl_df")
  expect_true(all(c("microdados", "doses", "cobertura") %in% status$dataset))
  micro <- status[status$dataset == "microdados", ]
  expect_true(all(c(2020L, 2024L) %in% micro$year))
  expect_true(all(micro$records > 0, na.rm = TRUE))
})

test_that("sipni_data reads microdata from R2 (default source)", {
  skip_if_no_integration()

  cache_dir <- tempfile("sipni_r2_micro_test")
  dir.create(cache_dir, recursive = TRUE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  data <- sipni_data(year = 2024, uf = "AC", month = 1,
                     cache_dir = cache_dir, parse = FALSE)
  expect_s3_class(data, "tbl_df")
  expect_gt(nrow(data), 0)
  expect_equal(names(data)[1:3], c("year", "month", "uf_source"))
  expect_true("dt_vacina" %in% names(data))
  expect_equal(unname(attr(data, "healthbr_source")["microdata"]), "r2")
  prov <- attr(data, "healthbr_provenance")
  expect_s3_class(prov, "tbl_df")
  expect_true(all(!is.na(prov$processing_timestamp)))
})

test_that("sipni_data reads aggregates from R2 (default source)", {
  skip_if_no_integration()

  cache_dir <- tempfile("sipni_r2_aggr_test")
  dir.create(cache_dir, recursive = TRUE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  data <- sipni_data(year = 2019, uf = "AC", cache_dir = cache_dir,
                     parse = FALSE)
  expect_gt(nrow(data), 0)
  expect_true(all(c("year", "uf_source", "IMUNO", "QT_DOSE") %in%
                    names(data)))
  expect_equal(unname(attr(data, "healthbr_source")["aggregated"]), "r2")

  # CPNI with the decimal comma fix
  cob <- sipni_data(year = 2019, type = "CPNI", uf = "AC",
                    cache_dir = cache_dir, parse = TRUE)
  expect_true("COBERT" %in% names(cob))
  expect_type(cob$COBERT, "double")
})

test_that("sipni_data R2 local cache serves the second call", {
  skip_if_no_integration()

  cache_dir <- tempfile("sipni_r2_cache_test")
  dir.create(cache_dir, recursive = TRUE)
  on.exit(unlink(cache_dir, recursive = TRUE))

  d1 <- sipni_data(year = 2019, uf = "AC", cache_dir = cache_dir,
                   parse = FALSE)
  d2 <- sipni_data(year = 2019, uf = "AC", cache_dir = cache_dir,
                   parse = FALSE)
  expect_equal(nrow(d1), nrow(d2))
})

test_that("sipni_data lazy = TRUE returns the remote dataset", {
  skip_if_no_integration()
  skip_if_not_installed("arrow")

  ds <- sipni_data(year = 2019, uf = "AC", lazy = TRUE, parse = FALSE)
  expect_true(inherits(ds, c("Dataset", "arrow_dplyr_query")))
  df <- ds |> dplyr::collect()
  expect_gt(nrow(df), 0)
  expect_true("ano" %in% names(df) || "uf" %in% names(df))
})

test_that("sipni_dictionary reads the R2 dictionaries", {
  skip_if_no_integration()

  dict <- sipni_dictionary(cache_dir = tempfile("sipni_dict_test"))
  expect_s3_class(dict, "tbl_df")
  expect_true(all(c("variable", "description", "code", "label",
                    "source_codes") %in% names(dict)))
  expect_true(all(c("IMUNO", "DOSE", "FX_ETARIA", "ANO", "MES") %in%
                    dict$variable))
  expect_gt(nrow(dict), 200)
})
