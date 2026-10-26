-- ============================================================
-- MJD-203 · Clientes dormidos de Cantabria
-- Pide: Raquel Fernández · Jefa de ventas Cantabria · Plazo: mañana
-- Dormido = ha comprado alguna vez y su último pedido (no cancelado)
--           es anterior al 2026-07-02 (fecha de corte − 90 días).
-- Entregable: entregables/mjd-203_clientes_dormidos.xlsx
-- Uso (escribe el Excel, así que sin -readonly):
--   duckdb db/marejada.duckdb < sql/02-sql-i/mjd-203_clientes_dormidos.sql
-- ============================================================

INSTALL excel;
LOAD excel;

CREATE OR REPLACE TEMP VIEW mjd203 AS
WITH lineas AS (
    SELECT DISTINCT pedido_id, num_linea, producto_id, cantidad, precio_unitario, descuento_pct
    FROM bronze.lineas_pedido
),
pedidos_validos AS (
    SELECT * FROM bronze.pedidos WHERE estado <> 'Cancelado'
),
ultima_compra AS (
    SELECT cliente_id, max(fecha_pedido)::DATE AS ultimo_pedido
    FROM pedidos_validos
    GROUP BY cliente_id
),
ventas_ultimo_anio AS (
    SELECT p.cliente_id,
           sum(l.cantidad * l.precio_unitario * (1 - l.descuento_pct / 100)) AS ventas
    FROM pedidos_validos AS p
    JOIN lineas AS l ON l.pedido_id = p.pedido_id
    WHERE p.fecha_pedido >= DATE '2026-09-30' - INTERVAL 1 YEAR
    GROUP BY p.cliente_id
)
SELECT c.cliente_id,
       c.nombre_comercial,
       c.municipio,
       right(regexp_replace(c.telefono, '[^0-9]', '', 'g'), 9) AS telefono,
       co.nombre || ' ' || co.apellidos AS comercial,
       u.ultimo_pedido,
       date_diff('month', u.ultimo_pedido, DATE '2026-09-30') AS meses_sin_pedir,
       CASE WHEN u.ultimo_pedido >= DATE '2025-09-30' THEN 'Dormido'
            ELSE 'Perdido (más de un año)' END AS situacion,
       c.activo AS activo_en_erp,
       round(coalesce(v.ventas, 0), 2) AS ventas_ultimo_anio
FROM bronze.clientes AS c
JOIN ultima_compra AS u ON u.cliente_id = c.cliente_id
LEFT JOIN ventas_ultimo_anio AS v ON v.cliente_id = c.cliente_id
LEFT JOIN bronze.comerciales AS co ON co.comercial_id = c.comercial_id
WHERE lower(trim(c.provincia)) IN ('cantabria', 'santander')
  AND u.ultimo_pedido < DATE '2026-09-30' - INTERVAL 90 DAY
ORDER BY ventas_ultimo_anio DESC;

-- Vista previa y resumen
SELECT * FROM mjd203 LIMIT 10;

SELECT count(*) AS clientes_dormidos,
       count(*) FILTER (WHERE situacion = 'Dormido') AS dormidos_este_anio,
       count(*) FILTER (WHERE situacion <> 'Dormido') AS perdidos,
       count(*) FILTER (WHERE activo_en_erp = 'S') AS siguen_activos_en_erp
FROM mjd203;

-- El Excel para Raquel
COPY (SELECT * FROM mjd203)
TO 'entregables/mjd-203_clientes_dormidos.xlsx' WITH (FORMAT xlsx, HEADER true);

-- ============================================================
-- RESULTADO (26/10/2026)
--   86 clientes de Cantabria sin pedir desde antes del 2026-07-02:
--   33 dormidos (último pedido en el último año) y 53 perdidos (más de un año).
--   42 de los 86 siguen marcados como activos en el ERP.
--   Excel: entregables/mjd-203_clientes_dormidos.xlsx (86 filas).
-- AVISO para Raquel: los dos primeros de la lista son el mismo cliente
--   (10637 y 11193, Supermercado La Fuente, mismo teléfono): ficha
--   duplicada (MJD-205). Que lo llame una sola persona.
-- ============================================================
