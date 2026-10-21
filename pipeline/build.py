"""Capas 2 y 3: ejecuta las vistas SQL (carpeta sql/) con DuckDB sobre los raw
y exporta cada vista.

Convención de nombres (sql/NN_nombre.sql, un SELECT por archivo):
  _nombre   -> tabla intermedia interna: NO se exporta (staging)
  qa_nombre -> control de calidad: se exporta a internal/ (NO se publica en el sitio).
               Si trae una columna booleana `falla` y alguna fila es true, el build
               termina con error y el workflow no publica nada.
  nombre    -> vista pública: site/data/<nombre>.csv y .json

El prefijo numérico solo define el orden de ejecución.
"""
import json
import re
import sys
from datetime import datetime, timezone
from decimal import Decimal
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parent.parent
SQL_DIR = ROOT / "sql"
OUT_DIR = ROOT / "site" / "data"
INT_DIR = ROOT / "internal"

MACROS = [
    # minutos entre dos timestamps; NULL si falta alguno o si el orden es negativo
    "CREATE MACRO mins(a, b) AS CASE WHEN a IS NULL OR b IS NULL OR b < a "
    "THEN NULL ELSE date_diff('second', a, b) / 60.0 END",
]


def ser(o):
    if hasattr(o, "isoformat"):
        return o.isoformat()
    if isinstance(o, Decimal):
        return float(o)
    return str(o)


def export(con, view, folder, with_json):
    folder.mkdir(parents=True, exist_ok=True)
    con.execute(f"COPY {view} TO '{(folder / (view + '.csv')).as_posix()}' (HEADER, DELIMITER ',')")
    if with_json:
        cur = con.execute(f"SELECT * FROM {view}")
        cols = [d[0] for d in cur.description]
        records = [dict(zip(cols, r)) for r in cur.fetchall()]
        (folder / f"{view}.json").write_text(
            json.dumps(records, default=ser, ensure_ascii=False, allow_nan=False), encoding="utf-8"
        )


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect()  # en memoria
    for m in MACROS:
        con.execute(m)

    # Raw: una vista por fuente. Todo se lee como texto (all_varchar) para que dos fuentes con
    # tipos inferidos distintos no choquen; los tipos se fijan en sql/05__base.sql.
    raw_root = ROOT / "data" / "raw"
    sources = sorted(p.name for p in raw_root.iterdir() if (p / "latest.csv").exists())
    if not sources:
        print("No hay datos raw. Corre primero pipeline/extract.py", file=sys.stderr)
        return 1
    for name in sources:
        path = (raw_root / name / "latest.csv").as_posix()
        con.execute(
            f"CREATE VIEW raw_{name} AS SELECT * FROM read_csv('{path}', header=true, "
            f"all_varchar=true, nullstr=['', 'null', 'NULL', 'None'], sample_size=-1)"
        )
        n = con.execute(f"SELECT count(*) FROM raw_{name}").fetchone()[0]
        print(f"raw_{name}: {n:,} filas")

    views, fallas = [], []
    for f in sorted(SQL_DIR.glob("*.sql")):
        view = re.sub(r"^\d+_", "", f.stem)
        query = f.read_text().strip().rstrip(";")
        con.execute(f"CREATE OR REPLACE TABLE {view} AS {query}")
        n = con.execute(f"SELECT count(*) FROM {view}").fetchone()[0]

        if view.startswith("_"):
            print(f"{view}: {n:,} filas (interna)")
            continue
        if view.startswith("qa_"):
            export(con, view, INT_DIR, with_json=False)
            cols = [d[0] for d in con.execute(f"SELECT * FROM {view} LIMIT 0").description]
            if "falla" in cols:
                bad = con.execute(f"SELECT * FROM {view} WHERE falla").fetchall()
                if bad:
                    fallas.append((view, cols, bad))
            print(f"{view}: {n:,} filas (control de calidad -> internal/)")
            continue

        print(f"{view}: {n:,} filas")
        export(con, view, OUT_DIR, with_json=True)
        views.append(view)

    meta = {
        "actualizado_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "vistas": views,
    }
    (OUT_DIR / "meta.json").write_text(json.dumps(meta, ensure_ascii=False), encoding="utf-8")

    if fallas:
        for view, cols, bad in fallas:
            print(f"\nFALLA en {view}:", file=sys.stderr)
            print("  " + " | ".join(cols), file=sys.stderr)
            for r in bad:
                print("  " + " | ".join(str(x) for x in r), file=sys.stderr)
        print("\nSe detiene el build: no se publica nada.", file=sys.stderr)
        return 1

    print("Listo:", ", ".join(views))
    return 0


if __name__ == "__main__":
    sys.exit(main())
