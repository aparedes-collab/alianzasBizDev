"""Capa 1 (raw): descarga cada CSV de Metabase tal cual y lo guarda sin transformar.

Salida: data/raw/<fuente>/<YYYY-MM-DD_HHMMSS>.csv  +  data/raw/<fuente>/latest.csv
"""
import os
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

import requests
import yaml

ROOT = Path(__file__).resolve().parent.parent


def main() -> int:
    cfg = yaml.safe_load((ROOT / "config" / "sources.yml").read_text())
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d_%H%M%S")
    failed = []

    for name, src in cfg["sources"].items():
        url = os.environ.get(src["url_env"])
        if not url:
            print(f"[{name}] falta la variable {src['url_env']}", file=sys.stderr)
            failed.append(name)
            continue

        out_dir = ROOT / "data" / "raw" / name
        out_dir.mkdir(parents=True, exist_ok=True)
        tmp = out_dir / f"{stamp}.csv.part"
        try:
            with requests.get(url, stream=True, timeout=300) as r:
                r.raise_for_status()
                with open(tmp, "wb") as f:
                    for chunk in r.iter_content(chunk_size=1 << 20):
                        f.write(chunk)
            if tmp.stat().st_size == 0:
                raise RuntimeError("la descarga llegó vacía")
        except Exception as e:  # no mostramos la URL: es sensible
            print(f"[{name}] error al descargar: {type(e).__name__}: {e}", file=sys.stderr)
            tmp.unlink(missing_ok=True)
            failed.append(name)
            continue

        final = out_dir / f"{stamp}.csv"
        tmp.rename(final)
        shutil.copyfile(final, out_dir / "latest.csv")
        print(f"[{name}] ok -> {final.relative_to(ROOT)} ({final.stat().st_size:,} bytes)")

    # Si algo falló, el workflow falla y NO se publica un dashboard con datos viejos mezclados.
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
