-- TICKET MJD-402
-- De: Lucía Gómez · Administración y finanzas
-- He oído que ya tenéis un "modelo" nuevo. Antes de fiarme: sácame con él la facturación de marzo de
-- 2025 por provincia, con nuestro criterio, y la comparo con mi hoja.
----------------------------------

SELECT c.provincia,
round(sum(f.importe_neto + f.gastos_envio), 2) AS base_imponible
FROM gold.fact_pedidos AS f
JOIN gold.dim_cliente AS c ON c.cliente_key = f.cliente_key
JOIN gold.dim_fecha AS d ON d.fecha_key = f.fecha_entrega_key
WHERE d.anio_mes = '2025-03'
AND f.estado IN ('Entregado', 'Devuelto parcial')
GROUP BY c.provincia
ORDER BY c.provincia;

-- hoja de Lucía Gómez (para comparar):

SELECT "Provincia" AS provincia, "Base imponible (€)" AS contabilidad
FROM read_xlsx('datos/contabilidad/facturacion_mensual_2024-2026.xlsx', range = 'A4:E1000')
WHERE "Año" = 2025 AND "Mes" = 'marzo'
ORDER BY provincia;

-- ============================================================
-- RESULTADO (05/11/2026)
--   Asturias 205.455,25 · Bizkaia 9.992,87 · Burgos 116.563,83 · Palencia 65.337,74:
--   iguales al céntimo en el modelo y en la hoja de contabilidad.
--   Cantabria: 678.588,45 en el modelo frente a 684.893,81 en la hoja (−6.305,36),
--   y el modelo tiene una fila "Desconocida" de 6.305,36.
-- Respuesta a Lucía Gómez: con el modelo, marzo de 2025 cuadra con tu hoja al céntimo en
--   cuatro provincias. En Cantabria faltan 6.305,36 €, que son exactamente la fila
--   "Desconocida": los pedidos de los seis clientes borrados del maestro, que tú tienes
--   asignados a Cantabria. Sumados, el total es 1.082.243,50, igual que tu hoja. Esta
--   comprobación ya se hace sola cada vez que se reconstruye gold (sql/04_comprobar_gold.sql).
-- ============================================================
