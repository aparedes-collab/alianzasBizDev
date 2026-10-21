# reportes-data

Pipeline: **Metabase (CSV público) → raw → vistas intermedias (DuckDB/SQL) → dashboard estático en Cloudflare Pages**.

```
config/sources.yml        # fuentes de Metabase (las URLs van en secrets, no aquí)
pipeline/extract.py       # capa 1: descarga raw sin transformar  -> data/raw/<fuente>/
pipeline/build.py         # capas 2 y 3: corre sql/*.sql y exporta -> site/data/*.csv|json
sql/NN_nombre.sql         # una vista intermedia por archivo (un SELECT)
site/index.html           # dashboard (lee site/data/*.json)
.github/workflows/refresh.yml   # cron diario + botón manual
```

## Correr en local

```bash
pip install -r requirements.txt
export METABASE_URL_CHANGAN_API="https://.../public/question/....csv"
export METABASE_URL_CHANGAN_TRAD="https://.../public/question/....csv"
python pipeline/extract.py
python pipeline/build.py
python -m http.server -d site 8000   # abre http://localhost:8000
```

## Agregar una vista nueva

Crea `sql/20_mi_vista.sql` con un solo `SELECT`. Puede usar `raw_<fuente>` o vistas anteriores
(por ejemplo `changan_funnel`). Se exporta sola a `site/data/mi_vista.csv` y `.json`.

## Agregar otro cliente

1. Añade sus fuentes en `config/sources.yml` y sus secrets en GitHub.
2. Añade sus vistas en `sql/`.
3. Crea otro sitio (carpeta y proyecto de Pages) con su propia política de Cloudflare Access.

## Configuración única

**GitHub (repo privado) -> Settings -> Secrets and variables -> Actions:**
`METABASE_URL_CHANGAN_API`, `METABASE_URL_CHANGAN_TRAD`, `CLOUDFLARE_API_TOKEN`
(permiso *Cloudflare Pages: Edit*), `CLOUDFLARE_ACCOUNT_ID`.

**Cloudflare:**
1. Crea el proyecto de Pages `bbva-dashboard` (puede ser vacío; el primer deploy lo llena).
2. Zero Trust -> Access -> Applications: protege el dominio del proyecto con una política que
   permita solo los correos o el dominio de BBVA. **Hazlo antes del primer deploy**: sin esa
   política, el sitio y los CSV de `data/` serían públicos.

## Pendiente / notas

- Los raw históricos (`data/raw/*/<fecha>.csv`) no persisten entre ejecuciones de GitHub Actions.
  Para conservar historial hay que sincronizarlos a un bucket (p. ej. Cloudflare R2) en el workflow.
- El dashboard es un esqueleto (filtro por origen, conteos, tabla). Falta el funnel por etapas
  y el tablero de SLAs: dependen de los nombres de columnas reales.
- Si cualquier descarga de Metabase falla, el workflow falla y no se publica nada.
