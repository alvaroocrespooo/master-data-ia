-- ============================================================
-- MJD-102 · Referencias distintas y unidades por almacén
-- Pide: Marcos Diego · Logística y almacén
-- Uso: duckdb -readonly db/marejada.duckdb < sql/01-puesta-a-punto/mjd-102_almacenes.sql
-- ============================================================

SELECT almacen,
       count(DISTINCT sku) AS referencias,
       sum(unidades)       AS unidades
FROM bronze.inventario
GROUP BY almacen
ORDER BY almacen;

-- Resultado (26/10/2026):
--   Guarnizo: 235 referencias, 13.319 unidades
--   Llanera:  146 referencias,  8.130 unidades

-- AVISO para Marcos (revisión de Elena): los SKU del inventario vienen
-- sucios (minúsculas, espacios, sin guion), así que estas cifras salen
-- de datos sin revisar. Comprobación:
SELECT count(*) AS skus_que_no_cruzan_con_productos
FROM bronze.inventario
WHERE sku NOT IN (SELECT sku FROM bronze.productos);
-- Resultado: 45 de 381 filas no cruzan con el maestro de productos.
-- Se arregla en silver (Volumen 02). Hasta entonces, la cifra se
-- entrega con esta advertencia.
