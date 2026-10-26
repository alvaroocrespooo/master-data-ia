-- ============================================================
-- MJD-202 · Top 10 de productos por facturación de 2025
-- Pide: Íñigo Sainz · Director comercial
-- Criterios: neto de descuentos, sin cancelados, devoluciones restadas,
--            sin líneas duplicadas. Fecha: fecha de pedido.
-- Uso: duckdb -readonly db/marejada.duckdb < sql/02-sql-i/mjd-202_top10_productos.sql
-- ============================================================

-- Desde bronze, quitando a mano los duplicados (DISTINCT sin linea_id).
-- Se agrupa por SKU además de por nombre: hay productos con el mismo
-- nombre en formatos distintos (barril de 20 L y de 30 L).
WITH lineas AS (
    SELECT DISTINCT pedido_id, num_linea, producto_id, cantidad, precio_unitario, descuento_pct
    FROM bronze.lineas_pedido
)
SELECT pr.sku,
       pr.nombre,
       pr.formato,
       round(sum(l.cantidad * l.precio_unitario * (1 - l.descuento_pct / 100)), 2) AS ventas_netas_2025
FROM lineas AS l
JOIN bronze.pedidos   AS p  ON p.pedido_id    = l.pedido_id
JOIN bronze.productos AS pr ON pr.producto_id = l.producto_id
WHERE p.estado <> 'Cancelado'
  AND p.fecha_pedido >= '2025-01-01'
  AND p.fecha_pedido <  '2026-01-01'
GROUP BY pr.sku, pr.nombre, pr.formato
ORDER BY ventas_netas_2025 DESC
LIMIT 10;

-- Segunda vía (silver): mismo ranking con importe_neto ya calculado.
SELECT pr.sku,
       pr.nombre,
       pr.formato,
       round(sum(l.importe_neto), 2) AS ventas_netas_2025
FROM silver.lineas_pedido AS l
JOIN silver.pedidos   AS p  ON p.pedido_id    = l.pedido_id
JOIN silver.productos AS pr ON pr.producto_id = l.producto_id
WHERE p.estado <> 'Cancelado'
  AND p.fecha >= DATE '2025-01-01'
  AND p.fecha <  DATE '2026-01-01'
GROUP BY pr.sku, pr.nombre, pr.formato
ORDER BY ventas_netas_2025 DESC
LIMIT 10;

-- ============================================================
-- RESULTADO (26/10/2026) · las dos vías dan el mismo top 10
--    1 ALI-0001 Anchoas de Santoña en aceite (Bandeja 12 latas)       1.065.599,02
--    2 VIN-0025 Valle del Nansa Blanco IGP Costa de Cantabria (6x75)    917.337,46
--    3 VIN-0023 Valle del Nansa Crianza DO Ribera del Duero (6x75)      586.205,99
--    4 VIN-0015 Hacienda Ruesga Reserva DOCa Rioja (6x75)               426.057,45
--    5 REF-0003 Cola Bahía (Bag-in-box 18 L)                            421.423,14
--    6 DES-0001 Vasos de cartón 25 cl (Caja 1000 uds)                   385.835,42
--    7 CER-0066 Ola Fría Sin alcohol (Caja 24x33 cl lata)               355.647,02
--    8 CER-0020 Brisa Cantábrica Lager (Barril 30 L)                    349.934,30
--    9 DES-0006 Envases take away cartón (Caja 300 uds)                 297.448,77
--   10 REF-0016 Tónica Brava (Bag-in-box 18 L)                          291.850,06
-- Ventas netas por fecha de pedido (no facturación contable: ver MJD-204).
-- ============================================================
