-- Vista unificada del funnel Changan/BBVA: API + tradicional con la columna "origen".
-- UNION ALL BY NAME alinea las columnas por nombre; si una fuente trae una columna
-- que la otra no, queda en NULL en lugar de romper.
SELECT *, 'API' AS origen FROM raw_changan_api
UNION ALL BY NAME
SELECT *, 'Tradicional' AS origen FROM raw_changan_tradicional
