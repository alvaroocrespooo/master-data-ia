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

--Respuesta a Lucía Gómez: La facturación de marzo de 2025 por provincia según nuestro modelo coincide con la hoja de contabilidad que me has pasado. Por lo tanto, puedes fiarte del modelo.