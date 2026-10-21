-- Control crítico: si una columna de fecha trae valores pero no se pueden leer (p. ej. Metabase cambió
-- el formato a "October 7, 2026, 2:10 PM"), TRY_CAST los dejaría en NULL y el dashboard mostraría ceros
-- sin avisar. Aquí falla el build si se pierde más del 2 % de los valores de alguna columna.
SELECT
  origen,
  columna,
  count(valor)                         AS con_valor,
  count(TRY_CAST(valor AS TIMESTAMP))  AS leidos,
  count(valor) - count(TRY_CAST(valor AS TIMESTAMP)) AS no_leidos,
  min(valor)                           AS ejemplo,
  count(TRY_CAST(valor AS TIMESTAMP)) < 0.98 * count(valor) AS falla
FROM (
  UNPIVOT (
    SELECT origen, F_Lead, "Fecha Preaprobado", F_Inicio_Captura, F_Analisis, F_Aprobacion, F_Rechazo,
           F_Orden_Compra, F_Contrato, F_Desembolso, F_Expirada_O_Caida,
           F_Cotizacion_API, F_Resultado_API, F_Ultima_Modificacion_API
    FROM _union
  ) ON COLUMNS(* EXCLUDE origen) INTO NAME columna VALUE valor
)
GROUP BY origen, columna
ORDER BY origen, columna
