-- TICKET MJD-306
-- De: Marcos Diego · Logística y almacén
-- Con el inventario del 30 de septiembre, ¿para cuántas semanas tengo stock de cada producto al ritmo al
-- que se está vendiendo? Quiero ver lo que se me va a acabar y lo que me sobra.
-- Por producto activo: unidades en stock (los dos almacenes juntos), venta media semanal de las últi‐
-- mas ocho semanas completas y semanas de cobertura.
-- Ojo con las semanas en las que un producto no se ha vendido: cuentan como cero.

WITH semanas AS (
SELECT s::DATE AS semana
FROM generate_series(DATE '2026-08-03', DATE '2026-09-21', INTERVAL 7 DAY) AS t(s)
),
productos_activos AS (
SELECT producto_id, sku, nombre, formato FROM silver.productos WHERE activo
),
venta_semanal AS (
SELECT date_trunc('week', p.fecha)::DATE AS semana, l.producto_id, sum(l.cantidad) AS unidades
FROM silver.pedidos AS p
JOIN silver.lineas_pedido AS l ON l.pedido_id = p.pedido_id
WHERE p.estado <> 'Cancelado'
AND p.fecha >= '2026-08-03' AND p.fecha < '2026-09-28'
GROUP BY ALL
),
media AS (
SELECT pa.producto_id, avg(coalesce(v.unidades, 0)) AS media_semanal
FROM productos_activos AS pa
CROSS JOIN semanas AS s
LEFT JOIN venta_semanal AS v ON v.producto_id = pa.producto_id AND v.semana = s.semana
GROUP BY pa.producto_id
),
stock AS (
SELECT producto_id, sum(unidades) AS unidades_stock
FROM silver.inventario
WHERE producto_id IS NOT NULL
GROUP BY producto_id
)
SELECT pa.sku, pa.nombre,
coalesce(st.unidades_stock, 0) AS stock,
round(m.media_semanal, 1) AS venta_semanal,
round(coalesce(st.unidades_stock, 0) / nullif(m.media_semanal, 0), 1) AS semanas_cobertura
FROM productos_activos AS pa
JOIN media AS m USING (producto_id)
LEFT JOIN stock AS st USING (producto_id)
ORDER BY semanas_cobertura
LIMIT 12;

-- Y el resumen para Marcos, con la misma lógica en tramos:
WITH semanas AS (
SELECT s::DATE AS semana
FROM generate_series(DATE '2026-08-03', DATE '2026-09-21', INTERVAL 7 DAY) AS t(s)
),
venta_semanal AS (
SELECT date_trunc('week', p.fecha)::DATE AS semana, l.producto_id, sum(l.cantidad) AS unidades
FROM silver.pedidos AS p
JOIN silver.lineas_pedido AS l ON l.pedido_id = p.pedido_id
WHERE p.estado <> 'Cancelado' AND p.fecha >= '2026-08-03' AND p.fecha < '2026-09-28'
GROUP BY ALL
),
cobertura AS (
SELECT pa.producto_id,
coalesce(any_value(st.unidades_stock), 0) / nullif(avg(coalesce(v.unidades, 0)), 0) AS
semanas
FROM silver.productos AS pa
CROSS JOIN semanas AS s
LEFT JOIN venta_semanal AS v ON v.producto_id = pa.producto_id AND v.semana = s.semana
LEFT JOIN (SELECT producto_id, sum(unidades) AS unidades_stock
FROM silver.inventario WHERE producto_id IS NOT NULL
GROUP BY producto_id) AS st ON st.producto_id = pa.producto_id
WHERE pa.activo
GROUP BY pa.producto_id
)
SELECT CASE WHEN semanas < 1 THEN '1. Menos de 1 semana'
WHEN semanas < 4 THEN '2. De 1 a 4 semanas'
WHEN semanas <= 26 THEN '3. De 4 a 26 semanas'
ELSE '4. Más de 26 semanas'
END AS cobertura,
count(*) AS productos
FROM cobertura
GROUP BY ALL
ORDER BY cobertura;

-- Los doce primeros de la lista no tienen ni una unidad en ninguno de los dos almacenes: son roturas de stock
-- ya, no riesgos.
-- La respuesta a Marcos: de los 211 productos activos, 72 tienen stock para menos de una semana al ritmo ac‐
-- tual (12 de ellos, con el stock a cero) y 7 para más de medio año.