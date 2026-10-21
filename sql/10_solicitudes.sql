-- Detalle por lead (reemplaza la tabla del Looker). Es la tabla descargable para editar en Excel.
-- Una etapa "se alcanzó" cuando su fecha no es NULL; Etapa_Funnel se conserva tal cual para ver el estado actual.
SELECT
  origen, id_solicitud, id_bbva, division, grupo,
  agencia_origen, agencia_cierre, modelo, tipo_producto, t_persona, referenciador, etapa_funnel,
  f_lead, f_preaprobado, f_inicio_captura, f_analisis, f_aprobacion, f_rechazo,
  f_orden_compra, f_contrato, f_desembolso,
  precio_unidad, monto_financiado_neto, plazo, tasa_final
FROM _base
WHERE f_lead IS NOT NULL
ORDER BY f_lead DESC
