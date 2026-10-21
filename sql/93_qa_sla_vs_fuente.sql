-- Concilia las medianas que calculamos desde las fechas contra las columnas Min_* que ya trae la fuente.
-- Si difieren mucho, hay que revisar cuál definición es la correcta antes de mostrarlas al cliente.
SELECT * FROM (
  SELECT origen, 'Captura → análisis' AS metrica,
         median(mins(f_inicio_captura, f_analisis))               AS mediana_calculada_min,
         median(src_min_captura_analisis)                         AS mediana_fuente_min
  FROM _base GROUP BY origen
  UNION ALL
  SELECT origen, 'Análisis → decisión',
         median(mins(f_analisis, LEAST(f_aprobacion, f_rechazo))),
         median(src_min_analisis_decision)
  FROM _base GROUP BY origen
  UNION ALL
  SELECT origen, 'Lead → decisión',
         median(mins(f_lead, LEAST(f_aprobacion, f_rechazo))),
         median(src_min_lead_decision)
  FROM _base GROUP BY origen
  UNION ALL
  SELECT origen, 'Preaprobado → captura',
         median(mins(f_preaprobado, f_inicio_captura)),
         median(src_min_preaprob_captura)
  FROM _base GROUP BY origen
) ORDER BY origen, metrica
