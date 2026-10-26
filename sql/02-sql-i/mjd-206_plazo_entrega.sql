-- ============================================================
-- MJD-206 · Plazo de entrega por almacén y mes (2026)
-- Pide: Marcos Diego · Logística y almacén
-- Plazo = fecha_entrega − fecha de pedido, en días. Solo pedidos
-- entregados (o devueltos en parte). Se excluyen las 23 fechas
-- imposibles (entrega anterior al pedido).
-- Uso: duckdb -readonly db/marejada.duckdb < sql/02-sql-i/mjd-206_plazo_entrega.sql
-- ============================================================

SELECT almacen,
       date_trunc('month', fecha_pedido)::DATE AS mes,
       count(*) AS pedidos,
       round(avg(fecha_entrega - fecha_pedido::DATE), 2) AS dias_medios,
       round(100.0 * count(*) FILTER (WHERE fecha_entrega - fecha_pedido::DATE <= 1) / count(*), 1) AS pct_en_24h
FROM bronze.pedidos
WHERE estado IN ('Entregado', 'Devuelto parcial')
  AND fecha_pedido >= '2026-01-01'
  AND fecha_entrega >= fecha_pedido::DATE
GROUP BY almacen, mes
ORDER BY almacen, mes;

-- Por qué hace falta el filtro: abril de 2026 sin él.
SELECT almacen,
       date_trunc('month', fecha_pedido)::DATE AS mes,
       round(avg(fecha_entrega - fecha_pedido::DATE), 2) AS dias_medios_sin_filtrar
FROM bronze.pedidos
WHERE estado IN ('Entregado', 'Devuelto parcial')
  AND fecha_pedido >= '2026-04-01' AND fecha_pedido < '2026-05-01'
GROUP BY almacen, mes
ORDER BY almacen;

-- Resumen del año por almacén, y segunda vía con silver
-- (allí las fechas imposibles ya son NULL y avg las ignora).
SELECT almacen,
       count(*) AS pedidos,
       round(avg(fecha_entrega - fecha), 2) AS dias_medios_2026,
       round(100.0 * count(*) FILTER (WHERE fecha_entrega - fecha <= 1) / count(*), 1) AS pct_en_24h
FROM silver.pedidos
WHERE estado IN ('Entregado', 'Devuelto parcial')
  AND fecha >= DATE '2026-01-01'
  AND fecha_entrega IS NOT NULL
GROUP BY almacen
ORDER BY almacen;

-- ============================================================
-- RESULTADO (26/10/2026)
--   2026, sin fechas imposibles:
--     Guarnizo  20.111 pedidos  2,15 días de media  38,5 % en 24 h
--     Llanera    3.891 pedidos  2,16 días de media  38,1 % en 24 h
--   Mes a mes, los dos almacenes están entre 2,06 y 2,27 días.
--   Sin el filtro, abril en Guarnizo daría −40,81 días por las fechas 1900.
-- Respuesta a Marcos: algo más de dos días de media, estable todo el año,
--   y Llanera no es más lento que Guarnizo. La queja de Asturias hay que
--   mirarla pedido a pedido (dime el cliente).
-- ============================================================
