"""
Gera amostras (~N linhas por arquivo) a partir dos arquivos REAIS da
Receita Federal já baixados em data/raw/, salvando o resultado em
data/samples/ -- pronto para versionar no Git (leve) e para o
load_raw.py consumir.


Uso:
    python data/generate_real_samples.py                # 10.000 linhas/arquivo (padrão)
    python data/generate_real_samples.py --linhas 5000   # customiza o tamanho da amostra
"""
import argparse
from pathlib import Path

DATA_DIR = Path(__file__).parent
RAW_DIR = DATA_DIR / "raw"
SAMPLES_DIR = DATA_DIR / "samples"

# Arquivos de domínio (CNAE, Natureza Jurídica, etc.) costumam ser
# pequenos -- copiamos por inteiro em vez de truncar.
COPIAR_INTEIRO_SE_MENOR_QUE = 2000  # linhas


def contar_e_amostrar(path: Path, destino: Path, n_linhas: int):
    linhas_escritas = 0
    with open(path, "rb") as fin, open(destino, "wb") as fout:
        for i, linha in enumerate(fin):
            if i >= n_linhas:
                break
            fout.write(linha)
            linhas_escritas += 1
    return linhas_escritas


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--linhas", type=int, default=10_000,
                         help="Quantidade de linhas a manter por arquivo (padrão: 10000)")
    args = parser.parse_args()

    if not RAW_DIR.exists():
        print(f"Pasta não encontrada: {RAW_DIR}")
        print("Coloque os arquivos baixados da Receita Federal em data/raw/ e rode novamente.")
        return

    arquivos = sorted(p for p in RAW_DIR.iterdir() if p.is_file())
    if not arquivos:
        print(f"Nenhum arquivo encontrado em {RAW_DIR}.")
        return

    SAMPLES_DIR.mkdir(parents=True, exist_ok=True)

    print(f"Gerando amostras de até {args.linhas} linhas em: {SAMPLES_DIR}\n")
    for path in arquivos:
        destino = SAMPLES_DIR / path.name
        tamanho_original_mb = path.stat().st_size / (1024 * 1024)

        linhas = contar_e_amostrar(path, destino, args.linhas)
        tamanho_amostra_mb = destino.stat().st_size / (1024 * 1024)

        print(f"{path.name}")
        print(f"  original: {tamanho_original_mb:,.1f} MB  ->  amostra: {tamanho_amostra_mb:,.2f} MB "
              f"({linhas:,} linhas)")

    print("\nConcluído. Os arquivos em data/samples/ já estão prontos para versionar no Git "
          "e para o flows/load_raw.py consumir.")


if __name__ == "__main__":
    main()
