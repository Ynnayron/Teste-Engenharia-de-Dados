"""
Prefect Flow: pipeline CNPJ (Franq - teste técnico).

Orquestra:
  1. extract_and_load_sample -> baixa/gera amostra (~10k linhas/arquivo) e
     carrega no schema `raw` do DuckDB (camada Bronze).
  2. run_dbt_transformations -> executa `dbt run` (staging -> intermediate
     -> marts) e `dbt snapshot` (SCD2 de capital_social).
  3. run_dbt_tests -> executa `dbt test` para validar qualidade de dados.

Cada Task tem retries configurados para tolerar falhas transitórias
(rede instável no download, lock momentâneo do DuckDB, etc.), simulando
resiliência de um ambiente de produção real.

"""
import subprocess
import sys
from pathlib import Path

from prefect import flow, task, get_run_logger

BASE_DIR = Path(__file__).parent.parent
DBT_DIR = BASE_DIR / "dbt"


@task(retries=2, retry_delay_seconds=10, log_prints=True)
def extract_and_load_sample(limit: int = 10_000):
    """
    Extrai e carrega uma amostra dos dados brutos (~10k linhas por arquivo)
    para o schema `raw` do DuckDB. Em produção, esta task chamaria a API/
    download dos arquivos oficiais da RFB.
    """
    logger = get_run_logger()
    sys.path.insert(0, str(BASE_DIR / "flows"))
    import load_raw  # noqa: E402

    logger.info(f"Carregando amostra (limit={limit}) para o schema raw...")
    load_raw.load(limit=limit)
    logger.info("Extração e carga concluídas.")


def _run_dbt_command(args: list[str], logger) -> None:
    cmd = ["dbt", *args, "--profiles-dir", str(DBT_DIR), "--project-dir", str(DBT_DIR)]
    logger.info("Executando: %s", " ".join(cmd))
    result = subprocess.run(cmd, capture_output=True, text=True, cwd=str(DBT_DIR))
    logger.info(result.stdout)
    if result.returncode != 0:
        logger.error(result.stderr)
        raise RuntimeError(f"Comando dbt falhou: {' '.join(cmd)}")


@task(retries=1, retry_delay_seconds=15, log_prints=True)
def run_dbt_transformations():
    """Executa o pipeline de transformação: dbt run + dbt snapshot."""
    logger = get_run_logger()
    _run_dbt_command(["run"], logger)
    _run_dbt_command(["snapshot"], logger)


@task(retries=0, log_prints=True)
def run_dbt_tests():
    """Executa a validação de qualidade de dados: dbt test."""
    logger = get_run_logger()
    _run_dbt_command(["test"], logger)


@flow(name="cnpj-pipeline-franq", log_prints=True)
def pipeline_flow(sample_limit: int = 10_000):
    logger = get_run_logger()
    logger.info("Iniciando pipeline CNPJ (extração -> transformação -> qualidade)")

    extract_and_load_sample(limit=sample_limit)
    run_dbt_transformations()
    run_dbt_tests()

    logger.info("Pipeline concluído com sucesso.")


if __name__ == "__main__":
    pipeline_flow()
