-- ============================================================
-- MJD-301 · ¿Los clientes de la web son nuevos?
-- Pide: Paula Herrero · Marketing y tienda online
-- Criterio: ventas del 1.4 (silver, sin cancelados, cliente_maestro_id)
-- ============================================================

WITH validos AS (
SELECT * FROM silver.pedidos
WHERE estado <> 'Cancelado' AND cliente_maestro_id IS NOT NULL
),
primer_web AS (
SELECT cliente_maestro_id, min(fecha_pedido) AS primer_pedido_web
FROM validos
WHERE canal = 'Web B2B'
GROUP BY cliente_maestro_id
),
historial_previo AS (
SELECT w.cliente_maestro_id,
count(v.pedido_id) AS pedidos_antes,
count(v.pedido_id) FILTER (WHERE v.canal = 'Teléfono') AS por_telefono,
count(v.pedido_id) FILTER (WHERE v.canal = 'Comercial') AS por_comercial
FROM primer_web AS w
LEFT JOIN validos AS v
ON v.cliente_maestro_id = w.cliente_maestro_id
AND v.fecha_pedido < w.primer_pedido_web
GROUP BY w.cliente_maestro_id
),
clasificados AS (
SELECT cliente_maestro_id,
CASE WHEN pedidos_antes = 0 THEN '1. Nuevo'
WHEN por_telefono > por_comercial THEN '2. Venía del teléfono'
ELSE '3. Venía del comercial'
END AS origen
FROM historial_previo
),
ventas_web AS (
SELECT v.cliente_maestro_id, sum(l.importe_neto) AS ventas
FROM validos AS v
JOIN silver.lineas_pedido AS l ON l.pedido_id = v.pedido_id
WHERE v.canal = 'Web B2B'
GROUP BY v.cliente_maestro_id
)
SELECT c.origen,
count(*) AS clientes,
round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct_clientes,
round(sum(w.ventas)) AS ventas_web,
round(100 * sum(w.ventas) / sum(sum(w.ventas)) OVER (), 1) AS pct_ventas_web
FROM clasificados AS c
JOIN ventas_web AS w USING (cliente_maestro_id)
GROUP BY c.origen
ORDER BY c.origen;
-- Segunda vía: clientes distintos con algún pedido web válido.
-- Tiene que coincidir con la suma de los tres grupos de arriba.
SELECT count(DISTINCT cliente_maestro_id) AS clientes_web
FROM silver.pedidos
WHERE canal = 'Web B2B'
  AND estado <> 'Cancelado'
  AND cliente_maestro_id IS NOT NULL;

-- ============================================================
-- RESULTADO (27/10/2026, DuckDB 2.0.0)
--   Origen                  Clientes   %     Ventas web (€)   %
--   1. Nuevo                     49   4,5 %       240.896    5,5 %
--   2. Venía del teléfono        37   3,4 %        97.297    2,2 %
--   3. Venía del comercial    1.000  92,1 %     4.068.986   92,3 %
--   Segunda vía: 1.086 clientes web = 49 + 37 + 1.000.
-- Respuesta a Paula: la web casi no trae clientes nuevos. El 95 % de
--   lo que vende es a clientes que ya compraban por otro canal.
-- Notas: los empates teléfono = comercial (32) caen en "comercial"
--   por el ELSE; "venía del comercial" es mayoría de pedidos, no
--   exclusividad (casi todos usaban los dos canales).
-- ============================================================
