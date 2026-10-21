-- Valores reales de Etapa_Funnel y cuántos leads tienen cada fecha. Sirve para confirmar que las fechas y
-- la etapa cuentan la misma historia (el dashboard cuenta etapas por fecha, no por el texto de Etapa_Funnel).
SELECT
  origen,
  etapa_funnel,
  count(*)               AS leads,
  count(f_preaprobado)   AS con_preaprobado,
  count(f_analisis)      AS con_analisis,
  count(f_aprobacion)    AS con_aprobacion,
  count(f_rechazo)       AS con_rechazo,
  count(f_orden_compra)  AS con_orden_compra,
  count(f_contrato)      AS con_contrato,
  count(f_desembolso)    AS con_desembolso
FROM _base
GROUP BY origen, etapa_funnel
ORDER BY origen, leads DESC
