-- Análisis de external_quotes (solo origen API): agencia, fecha de creación y de última modificación.
--   f_creacion              = fecha de la cotización (si falta, la del lead)
--   ultima_etapa            = fecha más reciente entre las etapas del proceso
--   ultima_modificacion     = la más reciente entre ultima_etapa y F_Ultima_Modificacion_API
-- (GREATEST ignora los NULL.)
SELECT
  id_solicitud,
  agencia_origen                                   AS agencia,
  division,
  modelo,
  etapa_funnel,
  COALESCE(f_cotizacion_api, f_lead)               AS f_creacion,
  f_ultima_modificacion_api,
  GREATEST(f_lead, f_preaprobado, f_inicio_captura, f_analisis, f_aprobacion, f_rechazo,
           f_orden_compra, f_contrato, f_desembolso, f_expirada_o_caida) AS ultima_etapa,
  GREATEST(f_lead, f_preaprobado, f_inicio_captura, f_analisis, f_aprobacion, f_rechazo,
           f_orden_compra, f_contrato, f_desembolso, f_expirada_o_caida,
           f_ultima_modificacion_api)              AS ultima_modificacion,
  estatus_api,
  num_cotizaciones_api,
  seg_buro_api,
  f_resultado_api,
  f_analisis IS NOT NULL                           AS convirtio_solicitud,
  CASE WHEN f_analisis >= COALESCE(f_cotizacion_api, f_lead)
       THEN date_diff('minute', COALESCE(f_cotizacion_api, f_lead), f_analisis) / 1440.0 END AS dias_a_solicitud
FROM _base
WHERE origen = 'API' AND COALESCE(f_cotizacion_api, f_lead) IS NOT NULL
ORDER BY ultima_modificacion DESC
