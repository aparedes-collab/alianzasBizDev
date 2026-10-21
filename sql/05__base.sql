-- Base tipada y con nombres limpios. Solo las columnas que usan los dashboards:
-- Poliza, Aseguradora, Prima_Total, Asesor_Venta, etc. NO pasan de aquí.
-- Las fechas se leen "como están escritas" (TRY_CAST ignora el offset): coinciden con lo que muestra Metabase.
SELECT
  origen,
  ID_Solicitud                                         AS id_solicitud,
  ID_BBVA                                              AS id_bbva,
  Folio_Persona                                        AS folio_persona,
  COALESCE(NULLIF(trim(Division), ''), 'Sin asignar')  AS division,
  COALESCE(NULLIF(trim(Grupo), ''), 'Sin grupo')       AS grupo,
  COALESCE(NULLIF(trim(Agencia_Origen), ''), 'Sin dato') AS agencia_origen,
  COALESCE(NULLIF(trim(Agencia_Cierre), ''), 'Sin dato') AS agencia_cierre,
  COALESCE(NULLIF(trim(Modelo), ''), 'Sin dato')       AS modelo,
  COALESCE(NULLIF(trim(Tipo_Producto), ''), 'Sin dato') AS tipo_producto,
  COALESCE(NULLIF(trim(T_Persona), ''), 'Sin dato')    AS t_persona,
  COALESCE(NULLIF(trim(Referenciador), ''), 'Sin dato') AS referenciador,
  Etapa_Funnel                                         AS etapa_funnel,

  TRY_CAST(F_Lead AS TIMESTAMP)                        AS f_lead,
  TRY_CAST("Fecha Preaprobado" AS TIMESTAMP)           AS f_preaprobado,
  TRY_CAST(F_Inicio_Captura AS TIMESTAMP)              AS f_inicio_captura,
  TRY_CAST(F_Analisis AS TIMESTAMP)                    AS f_analisis,
  TRY_CAST(F_Aprobacion AS TIMESTAMP)                  AS f_aprobacion,
  TRY_CAST(F_Rechazo AS TIMESTAMP)                     AS f_rechazo,
  TRY_CAST(F_Orden_Compra AS TIMESTAMP)                AS f_orden_compra,
  TRY_CAST(F_Contrato AS TIMESTAMP)                    AS f_contrato,
  TRY_CAST(F_Desembolso AS TIMESTAMP)                  AS f_desembolso,
  TRY_CAST(F_Expirada_O_Caida AS TIMESTAMP)            AS f_expirada_o_caida,

  TRY_CAST(F_Cotizacion_API AS TIMESTAMP)              AS f_cotizacion_api,
  TRY_CAST(F_Resultado_API AS TIMESTAMP)               AS f_resultado_api,
  TRY_CAST(F_Ultima_Modificacion_API AS TIMESTAMP)     AS f_ultima_modificacion_api,
  TRY_CAST(Num_Cotizaciones_API AS INTEGER)            AS num_cotizaciones_api,
  Estatus_API                                          AS estatus_api,
  Seg_Buro_API                                         AS seg_buro_api,

  TRY_CAST(Precio_Unidad AS DOUBLE)                    AS precio_unidad,
  TRY_CAST(Monto_Financiado_Neto AS DOUBLE)            AS monto_financiado_neto,
  TRY_CAST(Plazo AS INTEGER)                           AS plazo,
  TRY_CAST(Tasa_Final AS DOUBLE)                       AS tasa_final,

  -- métricas que ya calcula la fuente (solo para conciliar contra las nuestras en qa_sla_vs_fuente)
  TRY_CAST(Min_Captura_a_Analisis AS DOUBLE)           AS src_min_captura_analisis,
  TRY_CAST(Min_Analisis_a_Decision AS DOUBLE)          AS src_min_analisis_decision,
  TRY_CAST(Min_Lead_a_Decision AS DOUBLE)              AS src_min_lead_decision,
  TRY_CAST(Min_Preaprob_a_Captura AS DOUBLE)           AS src_min_preaprob_captura,
  TRY_CAST(Horas_Preaprob_Sin_Captura AS DOUBLE)       AS src_horas_preaprob_sin_captura
FROM _union
