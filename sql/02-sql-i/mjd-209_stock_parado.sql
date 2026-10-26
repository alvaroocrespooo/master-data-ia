-- ============================================================
-- MJD-209 · Stock sin ventas en los últimos 90 días
-- Pide: Marcos Diego · Logística y almacén
-- Inventario a 30/09/2026. "Sin ventas" = ninguna línea en pedidos no
-- cancelados desde el 2026-07-02. Valor a coste unitario.
-- El SKU se normaliza en LOS DOS lados del JOIN.
-- Uso: duckdb -readonly db/marejada.duckdb < sql/02-sql-i/mjd-209_stock_parado.sql
-- ============================================================

WITH inventario AS (
    SELECT almacen, unidades, upper(replace(trim(sku), '-', '')) AS sku_norm
    FROM bronze.inventario
),
productos AS (
    SELECT producto_id, sku, nombre, formato, coste_unitario, activo,
           upper(replace(trim(sku), '-', '')) AS sku_norm
    FROM bronze.productos
),
ultima_venta AS (
    SELECT l.producto_id, max(p.fecha_pedido)::DATE AS ultima_venta
    FROM bronze.lineas_pedido AS l
    JOIN bronze.pedidos AS p ON p.pedido_id = l.pedido_id
    WHERE p.estado <> 'Cancelado'
    GROUP BY l.producto_id
)
SELECT i.almacen, pr.sku, pr.nombre, pr.formato, pr.activo,
       uv.ultima_venta,
       i.unidades,
       round(i.unidades * pr.coste_unitario, 2) AS valor_coste
FROM inventario AS i
JOIN productos AS pr ON pr.sku_norm = i.sku_norm
LEFT JOIN ultima_venta AS uv ON uv.producto_id = pr.producto_id
WHERE i.unidades > 0
  AND (uv.ultima_venta IS NULL OR uv.ultima_venta < DATE '2026-09-30' - INTERVAL 90 DAY)
ORDER BY valor_coste DESC;

-- Resumen para Marcos
WITH inventario AS (
    SELECT almacen, unidades, upper(replace(trim(sku), '-', '')) AS sku_norm
    FROM bronze.inventario
),
productos AS (
    SELECT producto_id, coste_unitario, activo, upper(replace(trim(sku), '-', '')) AS sku_norm
    FROM bronze.productos
),
ultima_venta AS (
    SELECT l.producto_id, max(p.fecha_pedido)::DATE AS ultima_venta
    FROM bronze.lineas_pedido AS l
    JOIN bronze.pedidos AS p ON p.pedido_id = l.pedido_id
    WHERE p.estado <> 'Cancelado'
    GROUP BY l.producto_id
)
SELECT count(*) AS articulos_parados,
       count(*) FILTER (WHERE pr.activo = 'N') AS descatalogados,
       sum(i.unidades) AS unidades,
       round(sum(i.unidades * pr.coste_unitario), 2) AS valor_coste_total
FROM inventario AS i
JOIN productos AS pr ON pr.sku_norm = i.sku_norm
LEFT JOIN ultima_venta AS uv ON uv.producto_id = pr.producto_id
WHERE i.unidades > 0
  AND (uv.ultima_venta IS NULL OR uv.ultima_venta < DATE '2026-09-30' - INTERVAL 90 DAY);

-- Referencias en almacén sin ficha en el maestro de productos
SELECT i.almacen, i.sku, i.descripcion, i.unidades
FROM bronze.inventario AS i
LEFT JOIN bronze.productos AS pr
       ON upper(replace(trim(pr.sku), '-', '')) = upper(replace(trim(i.sku), '-', ''))
WHERE pr.producto_id IS NULL
ORDER BY i.sku;

-- Segunda vía (silver): en silver.inventario las mismas 9 filas quedan sin producto_id.
SELECT count(*) AS sin_producto_en_silver
FROM silver.inventario
WHERE producto_id IS NULL;

-- ============================================================
-- RESULTADO (26/10/2026)
--   22 artículos con stock y sin ventas en 90 días, todos descatalogados
--   (activo = 'N'): 482 unidades, 10.648,52 € a coste.
--   9 referencias OBS-0001 a OBS-0009 en Guarnizo (115 unidades) sin
--   ficha en el ERP. Silver: las mismas 9 filas sin producto_id.
-- Respuesta a Marcos (copia a Íñigo): liquidar o devolver los
--   descatalogados es decisión comercial; las OBS se dan de alta en el
--   ERP o de baja en el almacén.
-- ============================================================
