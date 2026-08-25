"""
Carrega os CSVs brutos para o schema `raw` no DuckDB.
Uso:
    python load_raw.py [--limit N]
"""
import argparse
import duckdb
from pathlib import Path

BASE_DIR = Path(__file__).parent.parent
SAMPLES_DIR = BASE_DIR / "data" / "samples"
SANITIZED_DIR = BASE_DIR / "data" / "_sanitized"
DB_PATH = BASE_DIR / "data" / "warehouse.duckdb"

CHUNK_SIZE = 8 * 1024 * 1024  # 8MB por chunk


def sanitize_to_utf8(path: Path) -> Path:
    """
    Alguns arquivos da Receita trazem bytes que fazem o próprio validador
    de encoding do DuckDB rejeitar até o 'latin-1' (mesmo latin-1 mapeando
    todo byte 0-255 para um char válido). Para contornar isso de forma
    robusta, decodifiquei o arquivo em streaming como latin-1 (nunca
    falha) e regravei como UTF-8 limpo, que o DuckDB sempre aceita.

    A cópia sanitizada é temporária: fica em data/_sanitized/ apenas
    durante o load e é apagada logo em seguida (ver load()), para não
    duplicar em disco os arquivos originais.
    """
    SANITIZED_DIR.mkdir(parents=True, exist_ok=True)
    out_path = SANITIZED_DIR / (path.name + ".utf8.csv")

    print(f"  sanitizando encoding: {path.name} -> {out_path.name}")
    with open(path, "rb") as fin, open(out_path, "w", encoding="utf-8", newline="") as fout:
        while True:
            chunk = fin.read(CHUNK_SIZE)
            if not chunk:
                break
            fout.write(chunk.decode("latin-1"))

    return out_path

# (nome_tabela_raw, arquivo, colunas na ordem oficial do layout RFB)
TABLES = {
    "raw_empresas": {
        "file": "K3241.K03200Y1.D60808.EMPRECSV",
        "columns": [
            "cnpj_basico", "razao_social", "natureza_juridica",
            "qualificacao_responsavel", "capital_social", "porte_empresa",
            "ente_federativo_responsavel",
        ],
    },
    "raw_estabelecimentos": {
        "file": "K3241.K03200Y1.D60808.ESTABELE",
        "columns": [
            "cnpj_basico", "cnpj_ordem", "cnpj_dv", "identificador_matriz_filial",
            "nome_fantasia", "situacao_cadastral", "data_situacao_cadastral",
            "motivo_situacao_cadastral", "nome_cidade_exterior", "pais",
            "data_inicio_atividade", "cnae_fiscal_principal", "cnae_fiscal_secundaria",
            "tipo_logradouro", "logradouro", "numero", "complemento", "bairro",
            "cep", "uf", "municipio", "ddd1", "telefone1", "ddd2", "telefone2",
            "ddd_fax", "fax", "correio_eletronico", "situacao_especial",
            "data_situacao_especial",
        ],
    },
    "raw_socios": {
        "file": "K3241.K03200Y0.D60808.SOCIOCSV",
        "columns": [
            "cnpj_basico", "identificador_socio", "nome_socio", "cnpj_cpf_socio",
            "qualificacao_socio", "data_entrada_sociedade", "pais",
            "representante_legal", "nome_representante",
            "qualificacao_representante", "faixa_etaria",
        ],
    },
    "raw_simples": {
        "file": "F.K03200$W.SIMPLES.CSV.D60808",
        "columns": [
            "cnpj_basico", "opcao_simples", "data_opcao_simples",
            "data_exclusao_simples", "opcao_mei", "data_opcao_mei",
            "data_exclusao_mei",
        ],
    },
    "raw_cnae": {
        "file": "F.K03200$Z.D60808.CNAECSV",
        "columns": ["codigo", "descricao"],
    },
}


def load(limit: int | None = None):
    con = duckdb.connect(str(DB_PATH))
    con.execute("CREATE SCHEMA IF NOT EXISTS raw")

    for table, cfg in TABLES.items():
        raw_path = SAMPLES_DIR / cfg["file"]
        if not raw_path.exists():
            print(f"  aviso: arquivo não encontrado, pulando: {raw_path.name}")
            continue

        path = sanitize_to_utf8(raw_path)
        cols = cfg["columns"]
        col_defs = ", ".join(f"{c} VARCHAR" for c in cols)
        con.execute(f"DROP TABLE IF EXISTS raw.{table}")
        con.execute(f"CREATE TABLE raw.{table} ({col_defs})")

        limit_clause = f"LIMIT {limit}" if limit else ""
        con.execute(f"""
            INSERT INTO raw.{table}
            SELECT * FROM read_csv(
                '{path.as_posix()}',
                delim=';',
                header=false,
                columns={{{', '.join(f"'{c}': 'VARCHAR'" for c in cols)}}},
                encoding='utf-8',
                quote='"',
                null_padding=true,
                ignore_errors=true
            ) {limit_clause}
        """)
        count = con.execute(f"SELECT COUNT(*) FROM raw.{table}").fetchone()[0]
        print(f"raw.{table}: {count} linhas carregadas")

        # Remove a cópia sanitizada após o load: prioriza economia de disco
        # em vez de cache entre execuções (arquivos reais da RFB podem
        # passar de 1GB cada, então evitamos manter as duas cópias).
        path.unlink(missing_ok=True)

    if SANITIZED_DIR.exists() and not any(SANITIZED_DIR.iterdir()):
        SANITIZED_DIR.rmdir()

    con.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=None)
    args = parser.parse_args()
    load(limit=args.limit)