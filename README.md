# Pipeline de dados de CNPJ

Pipeline de dados de CNPJ (Receita Federal) construído com **dbt Core** +
**Prefect** + **DuckDB**, seguindo arquitetura em camadas (staging →
intermediate → marts), com testes de qualidade, macros customizadas e
snapshot SCD2.

Documentação de arquitetura cloud (FinOps/BigQuery): [`docs/proposta_finops_bigquery.pdf`](docs/proposta_finops_bigquery.pdf)

## Arquitetura

```
data/raw/            # arquivos completos baixados da RFB (NÃO versionado)
data/samples/         # amostra (~10k linhas/arquivo) dos dados reais, versionada
data/warehouse.duckdb # banco DuckDB local (gerado, NÃO versionado)

dbt/
  models/
    staging/cnpj/      # padronização básica dos dados brutos (views)
    intermediate/       # regras de negócio intermediárias (views)
    marts/core/          # dimensões + fato incremental (tables)
  macros/                # macros Jinja reutilizáveis (parsing, formatação, teste customizado)
  snapshots/             # snapshot SCD2 (histórico de capital_social)
  tests/                 # testes singulares

flows/
  load_raw.py            # extração/carga da camada raw (equivalente a um Airbyte)
  pipeline_flow.py   # Prefect Flow: extração -> dbt run/snapshot -> dbt test
```

## Pré-requisitos

- Python 3.11+
- pip

## Setup

```bash
# 1. Crie e ative um ambiente virtual
python -m venv .venv
.venv\Scripts\activate        # Windows
# source .venv/bin/activate   # Linux/Mac

# 2. Instale as dependências
pip install -r requirements.txt
```

## Dados

Este repositório já inclui uma **amostra real** dos dados da Receita Federal
(`data/samples/`, ~10.000 linhas por arquivo) — suficiente para rodar o
pipeline completo sem precisar baixar nada.

Se quiser rodar contra os dados completos:

1. Baixe os arquivos em <https://dadosabertos.rfb.gov.br/CNPJ/>
2. Coloque-os em `data/raw/`
3. Gere uma nova amostra (opcional) com:
   ```bash
   python data/generate_real_samples.py --linhas 10000
   ```
4. Ou ajuste `flows/load_raw.py` para apontar direto para `data/raw/`

## Executando o pipeline

### Opção A — via Prefect Flow (recomendado, ponta a ponta)

```bash
python flows/pipeline_flow.py
```

Isso executa, em sequência: extração/carga da amostra → `dbt run` → `dbt
snapshot` → `dbt test`.

### Opção B — passo a passo manual

```bash
# 1. Carregue os dados brutos no DuckDB
python flows/load_raw.py --limit 10000

# 2. Entre na pasta do dbt e configure o profiles dir
cd dbt
$env:DBT_PROFILES_DIR = (Get-Location).Path      # PowerShell
# export DBT_PROFILES_DIR=$(pwd)                  # Linux/Mac/Git Bash

# 3. Teste a conexão
dbt debug

# 4. Rode os modelos
dbt run

# 5. Rode os testes
dbt test

# 6. Rode o snapshot (SCD2)
dbt snapshot
```

### Rodando um modelo específico

```bash
dbt run --select stg_empresas
dbt run --select +fct_empresas_ativas   # roda o modelo e tudo que ele depende
dbt test --select stg_empresas          # roda só os testes daquele modelo
```

## O que foi implementado

| Requisito do teste | Onde está |
|---|---|
| Arquitetura em camadas | `dbt/models/{staging,intermediate,marts}` |
| Materialização incremental | `marts/core/fct_empresas_ativas.sql` (`materialized='incremental'`, merge por `cnpj_basico`) |
| Snapshot SCD2 | `dbt/snapshots/snap_empresas_capital_social.sql` |
| 4 macros Jinja | `dbt/macros/` (`parse_br_decimal`, `parse_rfb_date`, `format_cnpj`, `decode_dominio`) |
| 35 testes dbt (genéricos + customizado) | `dbt/models/**/*.yml` + `dbt/macros/test_valor_positivo.sql` + `dbt/tests/assert_uma_matriz_por_empresa.sql` |
| Prefect Flow (extração + dbt run + dbt test) | `flows/pipeline_flow.py` |
| Documentação FinOps / proposta BigQuery | `docs/proposta_finops_bigquery.docx` |

## Notas de qualidade de dados

Alguns testes de `relationships` estão configurados com `severity: warn`
em vez de `error` — isso é intencional e está documentado inline nos
respectivos `.yml`. A causa é a amostragem via `--limit`, que carrega as
primeiras N linhas de cada arquivo de forma independente, sem garantir
que os mesmos `cnpj_basico` apareçam em Empresas, Estabelecimentos e
Sócios simultaneamente. Ao rodar contra os arquivos completos (sem
`--limit`), esse comportamento tende a desaparecer.

O teste `valor_positivo` em `capital_social` também é `warn`: capital
social igual a zero é um valor legítimo e comum em dados reais da RFB
(MEIs, empresas recém-abertas), não um erro de qualidade de dado.
