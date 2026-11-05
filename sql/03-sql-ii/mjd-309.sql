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
count(*) FILTER (WHERE puesto_antiguo <> puesto_nuevo) AS no_coinciden
FROM comparacion;

-- RESULTADO: 1.074 clientes, 0 no coinciden.
--
-- Tiempos (05/11/2026, MacBook Air M2, DuckDB 2.0.0), mejor de tres ejecuciones,
-- envolviendo cada versión en SELECT count(*), sum(puesto) para no imprimir 1.074 filas:
--   Antigua (year() + subconsulta correlacionada): 0,035 s · 1.074 clientes, suma de control 226.819
--   Nueva   (fecha >= '2026-01-01' + rank()):      0,010 s · 1.074 clientes, suma de control 226.819
--
-- Respuesta a Elena Pérez: tenía dos problemas. year(p.fecha) obliga a calcular el año de
-- cada pedido antes de filtrar, y el puesto se calculaba comparando cada cliente con todos
-- los de su provincia (coste que crece con el cuadrado de los clientes). Con el filtro por
-- rango de fechas y rank() da exactamente lo mismo (1.074 clientes, 0 diferencias) y tarda
-- unas tres veces menos. Con diez veces más clientes, la antigua tardaría unas cien veces
-- más y la nueva unas diez.
