-- ============================================================
-- MJD-208 · Peso de la tienda online en las ventas, mes a mes
-- Pide: Paula Herrero · Marketing y tienda online
-- Desde abril de 2025 (lanzamiento de la web). Ventas netas por fecha
-- de pedido, sin cancelados, sin líneas duplicadas. Fuente: ERP.
-- Uso: duckdb -readonly db/marejada.duckdb < sql/02-sql-i/mjd-208_peso_web.sql
-- ============================================================

WITH lineas AS (
    SELECT DISTINCT pedido_id, num_linea, producto_id, cantidad, precio_unitario, descuento_pct
    FROM bronze.lineas_pedido
),
ventas_pedido AS (
    SELECT p.pedido_id, p.canal, date_trunc('month', p.fecha_pedido)::DATE AS mes,
           sum(l.cantidad * l.precio_unitario * (1 - l.descuento_pct / 100)) AS ventas
    FROM bronze.pedidos AS p
    JOIN lineas AS l ON l.pedido_id = p.pedido_id
    WHERE p.estado <> 'Cancelado'
      AND p.fecha_pedido >= '2025-04-01'
    GROUP BY p.pedido_id, p.canal, mes
)
SELECT mes,
       round(sum(ventas)) AS ventas_totales,
       round(100 * sum(ventas) FILTER (WHERE canal = 'Web B2B')   / sum(ventas), 1) AS pct_web,
       round(100 * sum(ventas) FILTER (WHERE canal = 'Comercial') / sum(ventas), 1) AS pct_comercial,
       round(100 * sum(ventas) FILTER (WHERE canal = 'Teléfono')  / sum(ventas), 1) AS pct_telefono
FROM ventas_pedido
GROUP BY mes
ORDER BY mes;

-- Segunda vía (silver): los porcentajes de septiembre de 2026 deben coincidir.
SELECT round(100 * sum(l.importe_neto) FILTER (WHERE p.canal = 'Web B2B')   / sum(l.importe_neto), 1) AS pct_web_sep26,
       round(100 * sum(l.importe_neto) FILTER (WHERE p.canal = 'Comercial') / sum(l.importe_neto), 1) AS pct_comercial_sep26
FROM silver.pedidos AS p
JOIN silver.lineas_pedido AS l ON l.pedido_id = p.pedido_id
WHERE p.estado <> 'Cancelado'
  AND p.fecha >= DATE '2026-09-01' AND p.fecha < DATE '2026-10-01';

-- ============================================================
-- RESULTADO (26/10/2026)
--   Web B2B: 5,4 % en abril de 2025 → 27,6 % en septiembre de 2026.
--   Comercial: 65,0 % → 49,4 %. Teléfono: 29,6 % → 23,0 %.
--   Segunda vía (silver), septiembre de 2026: 27,6 % web, 49,4 % comercial.
-- Siguiente pregunta para Paula (Vol 03): ¿los clientes de la web son
--   nuevos o vienen del teléfono y del comercial?
-- ============================================================
