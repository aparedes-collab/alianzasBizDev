-- Une API y tradicional (mismas columnas) y marca el origen.
-- UNION ALL BY NAME alinea por nombre: si una fuente trae una columna de más, queda NULL en la otra.
SELECT *, 'API' AS origen FROM raw_changan_api
UNION ALL BY NAME
SELECT *, 'Tradicional' AS origen FROM raw_changan_tradicional
