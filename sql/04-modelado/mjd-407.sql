-- TICKET MJD-407
-- De: Elena Pérez · Responsable de datos
-- Un compañero de otro equipo ha hecho esta consulta para un informe de marzo de 2025 y los portes le
-- salen el doble de lo que dice contabilidad. ¿Qué le pasa y cómo se arregla? Explícaselo de forma que no
-- vuelva a pasar.

----------------

--SELECT round(sum(v.importe_neto), 2) AS ventas,
--sum(p.gastos_envio) AS portes
--FROM gold.fact_ventas AS v
--JOIN gold.fact_pedidos AS p USING (pedido_id)
--WHERE v.fecha_key BETWEEN 20250301 AND 20250331;

----------------


SELECT round(sum(v.importe_neto), 2) AS ventas,
sum(p.gastos_envio) AS portes
FROM gold.fact_ventas AS v
JOIN gold.fact_pedidos AS p USING (pedido_id)
WHERE v.fecha_key BETWEEN 20250301 AND 20250331;

--Las ventas están bien (vienen del grano de las líneas), pero los portes salen 10.752 € en lugar de 4.920. Lo
--correcto es el drill-across del 11.4: cada cosa agregada en su tabla de hechos, y unidas después:

SELECT (SELECT round(sum(importe_neto), 2) FROM gold.fact_ventas
WHERE fecha_key BETWEEN 20250301 AND 20250331) AS ventas,
(SELECT sum(gastos_envio) FROM gold.fact_pedidos
WHERE fecha_key BETWEEN 20250301 AND 20250331
AND estado <> 'Cancelado') AS portes;

--Respuesta a Elena Pérez: El problema es que la consulta original hace un JOIN entre las tablas de ventas y pedidos, lo que provoca que los portes se dupliquen si un pedido tiene varias líneas de venta. Para evitar esto, debemos calcular las ventas y los portes por separado y luego unir los resultados, como se muestra en la segunda consulta. De esta manera, obtenemos el total correcto de ventas y portes sin duplicaciones.