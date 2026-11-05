-- ============================================================
-- MJD-101 · Reconstruir la base de datos desde cero
-- Pide: Elena Pérez · Responsable de datos
-- ============================================================
-- ACTUALIZADO (05/11/2026): para reconstruir, usa ./scripts/reconstruir_bd.sh,
-- que crea la base en el formato que puede leer el Python del proyecto (DuckDB 1.5.6)
-- aunque la terminal sea DuckDB 2.0. Lo de abajo es cómo se hizo en el Vol 01.
--
-- La reconstrucción se lanza desde la terminal, en la raíz del repo
-- (cierra antes los notebooks y cualquier DuckDB abierto):
--
--   cd ~/master-data-ia
--   rm db/marejada.duckdb db/marejada.duckdb.wal   # el .wal puede no existir
--   time duckdb db/marejada.duckdb < sql/00_cargar_bronze.sql
--
-- Tiempo medido (26/10/2026, MacBook Air M2, DuckDB 1.5.6):
--   0,41 s en total (salida de `time`: 0.410 total), borrando
--   db/marejada.duckdb y reconstruyéndola con el script.
--
-- Comprobación: después de reconstruir, contar las filas y compararlas
-- con las de antes (entregables/01_inventario_datos.md).
--   duckdb -readonly db/marejada.duckdb < sql/01-puesta-a-punto/mjd-101_reconstruccion.sql
-- ============================================================

SELECT 'clientes' AS tabla, count(*) AS filas FROM bronze.clientes
UNION ALL SELECT 'comerciales',   count(*) FROM bronze.comerciales
UNION ALL SELECT 'inventario',    count(*) FROM bronze.inventario
UNION ALL SELECT 'lineas_pedido', count(*) FROM bronze.lineas_pedido
UNION ALL SELECT 'pedidos',       count(*) FROM bronze.pedidos
UNION ALL SELECT 'productos',     count(*) FROM bronze.productos
ORDER BY tabla;

-- Resultado de la base reconstruida: idéntico al de antes en las seis tablas
--   clientes 1.212 · comerciales 14 · inventario 381
--   lineas_pedido 381.158 · pedidos 77.448 · productos 235
