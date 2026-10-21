"""Capas 2 y 3: ejecuta las vistas SQL (carpeta sql/) con DuckDB sobre los raw
y exporta cada vista a site/data/<vista>.csv y .json.

Convención: cada archivo sql/NN_nombre.sql contiene UN SELECT (sin punto y coma
obligatorio). La vista resultante se llama "nombre" (sin el prefijo numérico)
y puede ser usada por los archivos siguientes.
"""
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parent.parent
SQL_DIR = ROOT / "sql"
OUT_DIR = ROOT / "site" / "data"


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect()  # en memoria

    # Raw: una vista por fuente, apuntando a su latest.csv
    raw_root = ROOT / "data" / "raw"
    sources = sorted(p.name for p in raw_root.iterdir() if (p / "latest.csv").exists())
    if not sources:
        print("No hay datos raw. Corre primero pipeline/extract.py", file=sys.stderr)
        return 1
    for name in sources:
        path = (raw_root / name / "latest.csv").as_posix()
        con.execute(
            f"CREATE VIEW raw_{name} AS SELECT * FROM read_csv_auto('{path}', header=true, sample_size=-1)"
        )
        print(f"raw_{name}: {con.execute(f'SELECT count(*) FROM raw_{name}').fetchone()[0]:,} filas")

    # Vistas intermedias, en orden
    views = []
    for f in sorted(SQL_DIR.glob("*.sql")):
        view = re.sub(r"^\d+_", "", f.stem)
        query = f.read_text().strip().rstrip(";")
        con.execute(f"CREATE OR REPLACE TABLE {view} AS {query}")
        n = con.execute(f"SELECT count(*) FROM {view}").fetchone()[0]
        print(f"{view}: {n:,} filas")
        views.append(view)

        # CSV descargable + JSON para el dashboard
        con.execute(f"COPY {view} TO '{(OUT_DIR / (view + '.csv')).as_posix()}' (HEADER, DELIMITER ',')")
        rows = con.execute(f"SELECT * FROM {view}").fetchall()
        cols = [d[0] for d in con.description]
        records = [dict(zip(cols, r)) for r in rows]
        (OUT_DIR / f"{view}.json").write_text(
            json.dumps(records, default=str, ensure_ascii=False), encoding="utf-8"
        )

    meta = {
        "actualizado_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "vistas": views,
    }
    (OUT_DIR / "meta.json").write_text(json.dumps(meta, ensure_ascii=False), encoding="utf-8")
    print("Listo:", ", ".join(views))
    return 0


if __name__ == "__main__":
    sys.exit(main())
