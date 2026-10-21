-- Funnel por cosecha (fecha de ingreso del lead), agregado por día x división x agencia x modelo x referenciador.
-- El dashboard suma estas filas según los filtros, así que los números siempre cuadran entre secciones.
-- "Solicitud" = lead que ya pasó a análisis (los borradores siguen siendo leads).
SELECT
  origen,
  CAST(f_lead AS DATE)  AS dia,
  division,
  agencia_origen        AS agencia,
  modelo,
  referenciador,
  count(*)              AS ingresos,
  count(f_preaprobado)  AS preaprobados,
  count(f_analisis)     AS analisis,
  count(f_aprobacion)   AS aprobaciones,
  count(f_rechazo)      AS rechazos,
  count(f_orden_compra) AS ordenes_compra,
  count(f_contrato)     AS contratos,
  count(f_desembolso)   AS desembolsos,
  -- promedios de unidades desembolsadas (suma y n para poder re-agregar con filtros)
  count(precio_unidad)          FILTER (WHERE f_desembolso IS NOT NULL) AS desemb_n_precio,
  coalesce(sum(precio_unidad)   FILTER (WHERE f_desembolso IS NOT NULL), 0) AS desemb_suma_precio,
  count(monto_financiado_neto)  FILTER (WHERE f_desembolso IS NOT NULL) AS desemb_n_monto,
  coalesce(sum(monto_financiado_neto) FILTER (WHERE f_desembolso IS NOT NULL), 0) AS desemb_suma_monto,
  count(tasa_final)             FILTER (WHERE f_desembolso IS NOT NULL) AS desemb_n_tasa,
  coalesce(sum(tasa_final)      FILTER (WHERE f_desembolso IS NOT NULL), 0) AS desemb_suma_tasa
FROM _base
WHERE f_lead IS NOT NULL
GROUP BY ALL
ORDER BY dia, origen
