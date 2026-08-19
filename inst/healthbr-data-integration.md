# Integração healthbR ↔ healthbr-data (R2)

> Documento de planejamento. Descreve a arquitetura proposta para integrar
> o backend Cloudflare R2 do projeto healthbr-data ao pacote healthbR,
> permitindo que o usuário escolha a fonte dos dados via parâmetro `source`.
>
> Status: **SI-PNI implementado (0.3.0, branch feature/r2-backend, ago/2026)**;
> SIM/SINASC/SIH (§7) pendentes. A implementação divergiu da seção 2 em
> pontos decididos com o mantenedor em 19/ago/2026 (issue #1: o Ministério
> removeu os microdados 2020–2025 da fonte oficial):
> - `source = c("r2", "datasus")` é **vetor de prioridade com fallback
>   automático** e o **R2 é o padrão** para o módulo inteiro (não mais
>   `datasus` padrão);
> - microdados 2020+ via R2 têm o **schema JSON de 56 campos**
>   (`dt_vacina`, ...), diferente do CSV (~47 campos) — cada fonte retorna
>   suas colunas como publicadas (tabela `sipni_variables_microdados`);
> - novos: `sipni_status()` (manifesto, cache local com ETag), atributos
>   `healthbr_source`/`healthbr_provenance`, `lazy = TRUE` retorna o
>   dataset remoto; infra genérica em `R/utils-r2.R` (`.r2_filesystem()`,
>   `.r2_open_dataset()`, `.r2_manifest()`) pronta para o SIM (§7.4.1).
> Criado em: 2026-03-07.

---

## 1. CONTEXTO

O pacote `healthbR` acessa dados do SI-PNI de duas formas atualmente:

- **FTP DATASUS (1994–2019):** arquivos `.dbf` baixados sob demanda por
  UF × ano.
- **OpenDATASUS CSV (2020+):** arquivos CSV mensais nacionais (~1.4 GB cada),
  lidos em chunks e filtrados por UF.

O projeto **healthbr-data** mantém os mesmos dados pré-processados e
publicados como Parquet no Cloudflare R2 (`healthbr-data` bucket), com
as seguintes vantagens:

| Propriedade | Backend atual (FTP/CSV) | Backend R2 (Parquet) |
|-------------|:-----------------------:|:--------------------:|
| Microdados 2020+ | CSV com artefatos (`.0`, zeros perdidos em 2020–2024) | JSON origin — sem artefatos |
| Agregados 1994–2019 | `.dbf` via FTP (lento, instável em BAs/MG/SP) | Parquet prontos — leitura instantânea |
| Acesso offline | Não | Sim (após cache local) |
| Leitura parcial (Arrow lazy) | Limitada | Nativa via `arrow::open_dataset()` |
| Volume para múltiplos anos/UFs | Download sequencial | Scan colunar filtrado |

---

## 2. DESIGN PROPOSTO

### 2.1 Mudança na assinatura de `sipni_data()`

Adicionar dois novos parâmetros ao fim da assinatura existente:

```r
sipni_data(
  year, type = "DPNI", uf = NULL, month = NULL,
  vars = NULL, parse = TRUE, col_types = NULL,
  cache = TRUE, cache_dir = NULL,
  lazy = FALSE, backend = c("arrow", "duckdb"),
  source = c("datasus", "r2"),   # NOVO
  r2_credentials = NULL          # NOVO
)
```

**`source`**  
- `"datasus"` (padrão): comportamento atual, sem quebra de compatibilidade.  
- `"r2"`: lê do Cloudflare R2 via Arrow S3 filesystem.

**`r2_credentials`**  
- Lista com `access_key_id` e `secret_access_key`.  
- Se `NULL`, usa o token read-only público do `healthbr-data` como padrão
  (o token é intencionalmente publicado; só permite leitura do bucket).  
- Permite que usuários com credenciais próprias apontem para buckets
  alternativos.

### 2.2 Comportamento por `source`

| `source` | Dados 1994–2019 | Dados 2020+ | Dicionários |
|----------|-----------------|-------------|-------------|
| `"datasus"` | `.dbf` via FTP | CSV via OpenDATASUS | internos (`sipni_data_internal.R`) |
| `"r2"` | `sipni/agregados/doses/` ou `sipni/agregados/cobertura/` | `sipni/microdados/` | `sipni/dicionarios/` |

### 2.3 Mapeamento de parâmetros existentes para o R2

| Parâmetro `sipni_data()` | Comportamento no R2 |
|--------------------------|---------------------|
| `year` | Filtro na partição `ano=` |
| `type = "DPNI"` | Prefixo `sipni/agregados/doses/` |
| `type = "CPNI"` | Prefixo `sipni/agregados/cobertura/` |
| `type = "API"` (2020+) | Prefixo `sipni/microdados/` |
| `uf` | Filtro na partição `uf=` |
| `month` | Filtro na partição `mes=` (apenas 2020+) |
| `vars` | `select()` antes do `collect()` |
| `lazy = TRUE` | Retorna `arrow::open_dataset()` diretamente |
| `cache` | Cache local do dataset Arrow (mesmo mecanismo atual) |

---

## 3. ARQUIVOS A CRIAR/MODIFICAR

### Novos arquivos

**`R/sipni_r2.R`** — Funções internas de acesso ao R2:

```
.sipni_r2_credentials()      # resolve credenciais (padrão ou usuário)
.sipni_r2_filesystem()       # cria arrow::S3FileSystem com as credenciais
.sipni_r2_open_dataset()     # abre o dataset Arrow no prefixo correto
.sipni_r2_fetch()            # aplica filtros e collect()
.sipni_r2_dictionary()       # lê sipni/dicionarios/ do R2
```

### Arquivos a modificar

**`R/sipni_data_internal.R`** — Adicionar constantes R2:

```r
# R2 backend constants
sipni_r2_endpoint   <- "https://<account-id>.r2.cloudflarestorage.com"
sipni_r2_bucket     <- "healthbr-data"
sipni_r2_access_key <- "<token-read-only-publico>"      # Object Read only
sipni_r2_secret_key <- "<token-read-only-publico-secret>"

# R2 prefixes
sipni_r2_prefix_microdados  <- "sipni/microdados"
sipni_r2_prefix_doses       <- "sipni/agregados/doses"
sipni_r2_prefix_cobertura   <- "sipni/agregados/cobertura"
sipni_r2_prefix_dicionarios <- "sipni/dicionarios"
```

**`R/sipni.R`** — Modificações em funções exportadas:

```
sipni_data()        # ramificação source == "r2" no início do fluxo
sipni_dictionary()  # ramificação source == "r2" → lê do R2
sipni_info()        # mencionar fonte R2 na saída
```

**`DESCRIPTION`** — Adicionar `arrow` e `paws.storage` (ou `aws.s3`) a
`Imports` ou `Suggests`:

```
Suggests:
    arrow,
    paws.storage   # alternativa mais leve para S3/R2
```

---

## 4. DEPENDÊNCIAS

O backend R2 requer:

- **`arrow`** (já em `Suggests`) — para `open_dataset()` com S3FileSystem.
- **`paws.storage`** ou configuração direta do `arrow::S3FileSystem` — para
  autenticação no R2 (endpoint customizado, sem região AWS).

O backend atual (FTP/CSV) não é afetado. `source = "datasus"` continua
funcionando sem `arrow`.

---

## 5. NOTAS DE IMPLEMENTAÇÃO

### Autenticação no R2 via Arrow

O Cloudflare R2 expõe endpoint S3-compatível mas sem região AWS. A
configuração do `arrow::S3FileSystem` precisa de:

```r
fs <- arrow::S3FileSystem$create(
  endpoint_override = "https://<account-id>.r2.cloudflarestorage.com",
  access_key        = sipni_r2_access_key,
  secret_key        = sipni_r2_secret_key,
  region            = "auto"
)
```

### Particionamento no R2

Os Parquets estão particionados no estilo Hive:

```
sipni/microdados/ano=2024/mes=01/uf=AC/part-00000.parquet
sipni/agregados/doses/ano=2019/uf=SP/part-00000.parquet
sipni/dicionarios/imuno.parquet
sipni/dicionarios/imunocob.parquet
...
```

O Arrow detecta automaticamente as partições ao abrir o dataset,
permitindo filtros pushdown sem `collect()`.

### Dicionários no R2

Os 6 Parquets de dicionário (`imuno`, `imunocob`, `dose`, `fxet`, `ano`,
`mes`) são arquivos planos (sem particionamento). Lidos com
`arrow::read_parquet()` diretamente. `sipni_dictionary(source = "r2")`
lerá esses arquivos em vez dos dados internos de `sipni_data_internal.R`.

### Sem quebra de compatibilidade

- `source = "datasus"` é o padrão → comportamento atual inalterado.
- Todos os parâmetros existentes continuam funcionando normalmente.
- O R2 é um backend opcional: se `arrow` não estiver instalado e
  `source = "r2"` for solicitado, a função emite erro claro pedindo
  para instalar `arrow`.

---

## 6. REFERÊNCIA: ESTRUTURA DO R2

```
s3://healthbr-data/sipni/
  microdados/                      ← SI-PNI rotina 2020+
    manifest.json
    ano=2024/mes=01/uf=AC/
      part-00000.parquet
  covid/microdados/                ← SI-PNI COVID 2021+
    manifest.json
    ano=2024/mes=01/uf=AC/
      part-00000.parquet
  agregados/
    doses/                         ← DPNI 1994-2019
      manifest.json
      ano=2019/uf=SP/
        part-00000.parquet
    cobertura/                     ← CPNI 1994-2019
      manifest.json
      ano=2019/uf=SP/
        part-00000.parquet
  dicionarios/
    imuno.parquet
    imunocob.parquet
    dose.parquet
    fxet.parquet
    ano.parquet
    mes.parquet
    originais/                     ← arquivos .cnv e .dbf originais do MS
```

**Acesso público:** token read-only (Account API token, Object Read only)
publicado intencionalmente nos dataset cards do Hugging Face. O token só
permite leitura do bucket `healthbr-data`.

**Dataset cards (Hugging Face):**
- Microdados: `https://huggingface.co/datasets/SidneyBissoli/sipni-microdados`
- COVID: `https://huggingface.co/datasets/SidneyBissoli/sipni-covid`
- Agregados Doses: `https://huggingface.co/datasets/SidneyBissoli/sipni-agregados-doses`
- Agregados Cobertura: `https://huggingface.co/datasets/SidneyBissoli/sipni-agregados-cobertura`
- Dicionários: `https://huggingface.co/datasets/SidneyBissoli/sipni-dicionarios`

---

## 7. SIM, SINASC e SIH via R2 — contrato e backlog (18/ago/2026)

> Decisões tomadas no projeto healthbr-data em 18/ago/2026 (ver lá
> `docs/contract-consumers-pt.md` — **fonte da verdade** do que o bucket garante —
> e `docs/sim/exploration-pt.md` §9). Esta seção traduz o contrato para o
> pacote. O módulo `sim` hoje lê o FTP direto e mantém uma lista fixa de anos
> (`sim_available_years`: final 1996–2022, preliminar 2023–2024), já defasada
> (FTP em ago/2026: final até 2024, preliminar 2025–2026). Com `source = "r2"`
> essa informação passa a vir do `manifest.json`.

### 7.1 Prefixos e partições no R2

| Módulo | Prefixo R2 | Partição | Chave no manifesto | Observações |
|---|---|---|---|---|
| `sim` (não fetais) | `sim/dores/` | `ano=YYYY/uf=XX/` | `YYYY-XX` | 1979–presente; UF de **residência**; preliminares no mesmo prefixo |
| `sim` (fetais) | `sim/dofet/` | `ano=YYYY/` | `YYYY` | arquivo nacional; sem `uf=` |
| `sinasc` | `sinasc/` | `ano=YYYY/uf=XX/` | `YYYY-XX` | 1994–2022+ |
| `sih` | `sih/rd/`, `sih/sp/` | `ano=YYYY/mes=MM/uf=XX/` | `YYYY-MM-XX` | RD 1992+, SP 1997+ |

Todas as colunas são string; nenhum valor é transformado; **schema por
arquivo-fonte** (abrir com `unify_schemas = TRUE`; colunas ausentes num ano
vêm `NA`). Cada Parquet carrega metadado `healthbr` (JSON no schema metadata:
`source_url`, `source_hash_md5`, `download_date`, `pipeline_version`,
`git_commit`, `source_status`).

### 7.2 Dados preliminares (SIM) — o que o pacote deve fazer

O DATASUS publica o ano N fechado só em dez/N+1; até lá, N e N+1 estão em
`PRELIM/` e são regravados sem aviso. O healthbr-data publica esses anos **no
mesmo prefixo**, marcados `source_status = "preliminar"` no manifesto e no
metadado de cada Parquet (ausente = final). Quando o ano fecha, a partição é
substituída (sem histórico). Cabe ao pacote dar visibilidade — itens acordados:

1. **`preliminary = FALSE`** em `sim_data()` (e nos demais módulos quando a
   fonte tiver preliminares): com o default, anos marcados como preliminares
   no manifesto são **excluídos** (e, se o usuário pediu explicitamente um ano
   preliminar, erro/aviso claro sugerindo `preliminary = TRUE`). Nome do
   argumento decidido: `preliminary` (adjetivo, como `lazy`, `verbose`).
2. **Aviso** (`cli::cli_warn`/`cli_inform`) sempre que o retorno contiver
   dados preliminares: anos, data de processamento (`processing_timestamp`)
   e a frase "podem ser regravados pelo Ministério".
3. **Marcação no resultado**: coluna `healthbr_status` (`"final"`/
   `"preliminar"`) ou atributo `attr(x, "healthbr_source_status")` — decidir
   na implementação; a coluna facilita `group_by`.
4. **`sim_status()`** (padrão para os outros módulos): tabela ano × UF ×
   status × `processing_timestamp` × `source_hash_md5` lida do manifesto —
   substitui a lista fixa `sim_available_years`; `sim_years(status=)` e
   `sim_info()` passam a consultá-la quando `source = "r2"`.
5. **Vinheta/README**: calendário do SIM (final em dez/N+1; preliminares N e
   N+1), o que muda entre preliminar e final, e como o cache local deve ser
   invalidado (por `source_hash_md5`/`processing_timestamp`, não por nome).

### 7.3 Notas de série histórica que o pacote deve absorver

- **`contador`/`CONTADOR`** (SIM: minúsculo 1979–2005 e 2009–2010; maiúsculo
  2006–2008 e 2011+): o R2 publica como na fonte (decisão A). O pacote
  coalesce as duas caixas em `CONTADOR` ao retornar (conveniência mora aqui).
  O SINASC hoje já vem unificado pelo pipeline, mas **será revertido** para a
  caixa da fonte — coalescer desde já evita quebra.
- SIM: `NUMERODO` não existe nos arquivos públicos; `CODMUNRES` 7 dígitos até
  2005 e 6 a partir de 2006; CID-9 (1979–95) com nomes `DATAOBITO` (AAMMDD, dia
  `00` até 1990), `MUNIRES`, `OCUPACAO`, `INSTRUCAO`, `ESTCIVIL`; `decode_age`
  continua válido (`IDADE` é estável desde 1979).
- Óbitos fetais só em `sim/dofet/` (`TIPOBITO = 1`); `sim/dores/` só tem
  `TIPOBITO = 2`. Sugestão de API: `sim_data(type = c("dores", "dofet"))`.
- SIH: transição 1998 (CID-9→10, datas), SIGTAP 2008; SP com 3 schemas.

### 7.4 Ordem sugerida de implementação

1. Infra comum: `.r2_filesystem()`, `.r2_manifest(prefix)` (cache curto),
   `source = c("datasus", "r2")` nos `*_data()`.
2. `sim`: `preliminary`, `sim_status()`, aviso, coalescência de `CONTADOR`,
   `type = "dofet"`.
3. `sinasc`, `sih`, `sipni` (seção 2 acima).
4. Testes de integração com `HEALTHBR_INTEGRATION=true` contra o bucket
   público; `NEWS.md`; anunciar a mudança de API no thread rOpenSci (#751).

Rastreio: uma issue por item de 7.2 e 7.4 (milestone "backend R2"), quando o
mantenedor aprovar o texto.

---

*Documento criado em 2026-03-07; seção 7 adicionada em 2026-08-18. Atualizar ao iniciar a implementação.*
