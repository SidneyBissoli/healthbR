# Integração healthbR ↔ healthbr-data (R2)

> Documento de planejamento. Descreve a arquitetura proposta para integrar
> o backend Cloudflare R2 do projeto healthbr-data ao pacote healthbR,
> permitindo que o usuário escolha a fonte dos dados via parâmetro `source`.
>
> Status: **planejado** — nenhuma linha de código foi alterada ainda.
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

*Documento criado em 2026-03-07. Atualizar ao iniciar a implementação.*
