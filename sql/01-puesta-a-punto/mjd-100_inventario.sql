-- ============================================================
-- MJD-100 · Inventario de datos de la capa bronze
-- Pide: Elena Pérez · Responsable de datos
-- Entregable: entregables/01_inventario_datos.md
-- Uso: duckdb -readonly db/marejada.duckdb < sql/01-puesta-a-punto/mjd-100_inventario.sql
--      (desde la raíz del repo)
-- ============================================================

-- 1. Filas de cada tabla. Con count(*), no con estimated_size,
--    que es una estimación.
SELECT 'clientes' AS tabla, count(*) AS filas FROM bronze.clientes
UNION ALL SELECT 'comerciales',   count(*) FROM bronze.comerciales
UNION ALL SELECT 'inventario',    count(*) FROM bronze.inventario
UNION ALL SELECT 'lineas_pedido', count(*) FROM bronze.lineas_pedido
UNION ALL SELECT 'pedidos',       count(*) FROM bronze.pedidos
UNION ALL SELECT 'productos',     count(*) FROM bronze.productos
ORDER BY tabla;

-- 2. Columnas de cada tabla (este dato de los metadatos sí es exacto).
SELECT table_name AS tabla, column_count AS columnas
FROM duckdb_tables()
WHERE schema_name = 'bronze'
ORDER BY table_name;

-- 3. Rango de fechas de los pedidos del ERP.
SELECT min(fecha_pedido) AS primer_pedido,
       max(fecha_pedido) AS ultimo_pedido
FROM bronze.pedidos;

-- 4. Tienda web: se lee directamente del JSON, sin cargarlo.
--    Los pedidos están en el array "orders"; las horas vienen en UTC.
SELECT count(*)          AS pedidos_web,
       min(o.created_at) AS primero_utc,
       max(o.created_at) AS ultimo_utc
FROM (SELECT unnest(orders) AS o
      FROM read_json('datos/web/pedidos_web.json'));

-- Resultado (26/10/2026, DuckDB 1.5.6):
--   clientes 1.212 filas, 15 columnas · comerciales 14, 9
--   inventario 381, 6 · lineas_pedido 381.158, 7
--   pedidos 77.448, 10 · productos 235, 13
--   Pedidos ERP: 2024-01-01 08:03 → 2026-09-30 23:32
--   Tienda web: 7.956 pedidos, 2025-04-07 04:04 → 2026-09-30 21:32 (UTC)
