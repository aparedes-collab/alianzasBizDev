-- Tiempos entre etapas (en minutos) por lead. Las medianas se calculan en el dashboard con los filtros activos
-- (la mediana no se puede sumar, por eso aquí queda el detalle y no un agregado).
-- Decisión = aprobación o rechazo, lo que ocurra primero. Si el orden de dos fechas es negativo, el tiempo queda NULL.
SELECT
  origen,
  CAST(f_lead AS DATE)  AS dia,
  division,
  agencia_origen        AS agencia,
  modelo,
  mins(f_lead, f_preaprobado)                       AS m_lead_preaprobado,
  mins(f_preaprobado, f_inicio_captura)             AS m_preaprobado_captura,
  mins(f_inicio_captura, f_analisis)                AS m_captura_analisis,
  mins(f_analisis, LEAST(f_aprobacion, f_rechazo))  AS m_analisis_decision,
  mins(f_lead, LEAST(f_aprobacion, f_rechazo))      AS m_lead_decision,
  mins(LEAST(f_aprobacion, f_rechazo), f_orden_compra) AS m_decision_orden,
  mins(f_orden_compra, f_contrato)                  AS m_orden_contrato,
  mins(f_contrato, f_desembolso)                    AS m_contrato_desembolso,
  src_horas_preaprob_sin_captura * 60.0             AS m_preaprob_sin_captura
FROM _base
WHERE f_lead IS NOT NULL
  AND (f_preaprobado IS NOT NULL OR f_analisis IS NOT NULL OR f_aprobacion IS NOT NULL
       OR f_rechazo IS NOT NULL OR src_horas_preaprob_sin_captura IS NOT NULL)
