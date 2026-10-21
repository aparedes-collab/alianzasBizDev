-- Chequeos de integridad por origen. Ojo: ID_BBVA NO es único (se sabe); aquí se mide cuánto se repite
-- cada identificador para decidir cuál usar como llave. No detiene el build.
SELECT
  origen,
  count(*)                                              AS filas,
  count(*) FILTER (WHERE f_lead IS NULL)                AS sin_f_lead,
  count(DISTINCT id_solicitud)                          AS id_solicitud_distintos,
  count(id_solicitud)                                   AS id_solicitud_con_valor,
  count(DISTINCT id_bbva)                               AS id_bbva_distintos,
  count(DISTINCT folio_persona)                         AS folio_persona_distintos,
  count(*) FILTER (WHERE f_analisis IS NOT NULL AND f_preaprobado IS NULL) AS analisis_sin_preaprobado,
  count(*) FILTER (WHERE f_aprobacion IS NOT NULL AND f_analisis IS NULL)  AS aprobacion_sin_analisis,
  count(*) FILTER (WHERE f_aprobacion IS NOT NULL AND f_rechazo IS NOT NULL) AS aprobado_y_rechazado,
  min(f_lead)                                           AS primer_lead,
  max(f_lead)                                           AS ultimo_lead
FROM _base
GROUP BY origen
ORDER BY origen
