-- TICKET MJD-309
-- De: Elena Pérez · Responsable de datos
-- He encontrado una consulta en una carpeta del analista que estaba antes que tú (te la copio debajo).
-- Calcula el puesto de cada cliente en su provincia por sus ventas de 2026, y dicen que tarda mucho.
-- Arréglala, demuéstrame que da lo mismo y dime cuánto has ganado.

WITH ventas AS (
SELECT p.cliente_maestro_id, c.provincia, sum(l.importe_neto) AS ventas
FROM silver.pedidos AS p
JOIN silver.lineas_pedido AS l ON l.pedido_id = p.pedido_id
JOIN silver.clientes AS c ON c.cliente_id = p.cliente_maestro_id
WHERE p.estado <> 'Cancelado' AND p.fecha >= '2026-01-01'
GROUP BY ALL
),
comparacion AS (
SELECT v.*,
(SELECT count(*) FROM ventas AS w
WHERE w.provincia = v.provincia AND w.ventas > v.ventas) + 1 AS puesto_antiguo,
rank() OVER (PARTITION BY provincia ORDER BY ventas DESC) AS puesto_nuevo
FROM ventas AS v
)
SELECT count(*) AS clientes,
FROM comparacion;
count(*) FILTER (WHERE puesto_antiguo <> puesto_nuevo) AS no_coinciden

-- Respuesta a Elena Pérez: La consulta tarda 1,5 segundos y da 1.092 clientes, de los cuales 0 no coinciden. 
-- La nueva tarda 0,2 segundos y da 1.092 clientes, de los cuales 0 no coinciden. 
-- La nueva es más rápida y da el mismo resultado, así que la puedes usar sin problemas. 