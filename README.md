# reportes-data

Pipeline: **Metabase (CSV público) → raw → vistas intermedias (DuckDB/SQL) → dashboard estático en Cloudflare Pages**.
Hoy cubre Changan/BBVA (API + tradicional en un solo dashboard).

```
config/sources.yml          # fuentes de Metabase (las URLs van en secrets, no aquí)
pipeline/extract.py         # capa 1: descarga raw sin transformar        -> data/raw/<fuente>/
pipeline/build.py           # capas 2 y 3: corre sql/*.sql y exporta       -> site/data/*.csv|json
sql/                        # una vista por archivo (un SELECT) — ver abajo
site/index.html             # dashboard (lee site/data/*.json)
.github/workflows/refresh.yml   # cron diario + botón manual
internal/                   # controles de calidad (NO se publican)
```

## Vistas (carpeta `sql/`)

| Archivo | Qué es | ¿Se publica? |
|---|---|---|
| `00__union.sql`, `05__base.sql` | Une API + tradicional (`origen`) y tipa columnas | No (prefijo `_`) |
| `10_solicitudes.sql` | Detalle por lead — la tabla descargable | Sí |
| `20_funnel_diario.sql` | Funnel por cosecha: día × división × agencia × modelo × referenciador | Sí |
| `30_sla_leads.sql` | Tiempos entre etapas por lead (minutos) | Sí |
| `40_cotizaciones_api.sql` | external_quotes: agencia, creación, última modificación | Sí |
| `90_qa_*.sql` … `93_qa_*.sql` | Controles de calidad | No (van a `internal/`) |

Convención: prefijo numérico = orden; `_nombre` = interna; `qa_nombre` = control de calidad (si trae una columna
`falla` y alguna fila es verdadera, el build **falla y no se publica nada**).

Columnas sensibles que el dashboard no necesita (póliza, aseguradora, prima, asesor, etc.) no pasan de `05__base.sql`.

## Controles de calidad

- `qa_parseo_fechas`: si Metabase cambia el formato de fecha y más del 2 % de los valores de una columna no se
  puede leer, el build se detiene (en vez de mostrar ceros).
- `qa_resumen`: filas, duplicados de `id_solicitud` / `id_bbva` / `folio_persona`, etapas inconsistentes
  (p. ej. aprobado y rechazado a la vez). **Úsalo para decidir la llave única** (ID_BBVA no lo es).
- `qa_etapas`: valores reales de `Etapa_Funnel` contra las fechas de cada etapa.
- `qa_sla_vs_fuente`: medianas calculadas desde fechas contra las columnas `Min_*` de la fuente.
- En GitHub Actions se guardan como artefacto `qa-<run>` (14 días). En local quedan en `internal/`.

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

Crea `sql/50_mi_vista.sql` con un solo `SELECT` sobre `_base` (o sobre vistas anteriores). Se exporta sola a
`site/data/mi_vista.csv` y `.json`; para mostrarla hay que agregar una sección en `site/index.html`.

## Agregar otro cliente

1. Fuentes en `config/sources.yml` y sus secrets en GitHub.
2. Vistas propias en `sql/` (o una carpeta por cliente si crece).
3. Otro sitio (carpeta y proyecto de Pages) con su propia política de Cloudflare Access.

## Configuración única

**GitHub (repo privado) → Settings → Secrets and variables → Actions:**
`METABASE_URL_CHANGAN_API`, `METABASE_URL_CHANGAN_TRAD`, `CLOUDFLARE_API_TOKEN`
(permiso *Cloudflare Pages: Edit*), `CLOUDFLARE_ACCOUNT_ID`.

**Cloudflare:**
1. Crea el proyecto de Pages `bbva-dashboard` (puede ser vacío; el primer deploy lo llena).
2. Zero Trust → Access → Applications: protege el dominio del proyecto con una política que
   permita solo los correos o el dominio de BBVA. **Hazlo antes del primer deploy**: sin esa
   política, el sitio y los CSV de `data/` (que incluyen detalle por lead) serían públicos.

## Supuestos a validar contra el Looker actual

1. **Etapas por fecha, no por texto:** un lead "alcanzó" una etapa si su fecha no está vacía. `Etapa_Funnel` solo se muestra.
2. **Ingresos = leads con `F_Lead`**; preaprobado = `Fecha Preaprobado`; análisis = `F_Analisis`; aprobaciones = `F_Aprobacion`; etc.
3. **Cierre = desembolso** (constante `ETAPA_CIERRE` al inicio del script de `site/index.html`).
4. **Todo es por cosecha** (fecha de ingreso). El MoM del Looker puede contar por fecha del evento; si es así hay que cambiarlo.
5. **Decisión = aprobación o rechazo**, el primero que ocurra.
6. **Promedios (precio, financiamiento, tasa)** sobre unidades desembolsadas.
7. **Última modificación** de una cotización = la fecha más reciente entre las etapas y `F_Ultima_Modificacion_API`.

Prueba de aceptación sugerida: con el mismo periodo, comparar Ingresos / Preaprobado / Análisis / Aprobaciones del dashboard
nuevo contra el Looker (en el de API, hoy: 229 / 201 / 4 / 0 del 1 ago al 21 oct).

## Pendiente

- Los raw históricos (`data/raw/*/<fecha>.csv`) no persisten entre ejecuciones de GitHub Actions.
  Para conservar historial hay que sincronizarlos a un bucket (p. ej. Cloudflare R2) en el workflow.
- Definir la llave única de lead (ver `qa_resumen`).
- Si cualquier descarga de Metabase falla, o se rompe el formato de fechas, el workflow falla y no se publica nada.
