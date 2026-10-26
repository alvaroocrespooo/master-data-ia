-- ============================================================
-- MJD-210 · Comprobaciones de la capa SILVER
-- Las seis tienen que salir `true`. Si alguna sale `false`, algo ha
-- cambiado en los datos de origen: no se usa silver hasta revisarlo.
-- Uso: duckdb -readonly db/marejada.duckdb < sql/02_comprobar_silver.sql
-- ============================================================

SELECT 'Clientes: misma cantidad de fichas que en bronze' AS comprobacion,
       (SELECT count(*) FROM silver.clientes) = (SELECT count(*) FROM bronze.clientes) AS ok
UNION ALL
SELECT 'Clientes: ninguna provincia por revisar',
       (SELECT count(*) FROM silver.clientes WHERE provincia = 'REVISAR') = 0
UNION ALL
SELECT 'Productos: ninguna categoría por revisar',
       (SELECT count(*) FROM silver.productos WHERE categoria = 'REVISAR') = 0
UNION ALL
SELECT 'Líneas: ningún (pedido, línea) repetido',
       (SELECT count(*) FROM (SELECT pedido_id, num_linea FROM silver.lineas_pedido
                              GROUP BY ALL HAVING count(*) > 1)) = 0
UNION ALL
SELECT 'Pedidos: ninguna entrega anterior al pedido',
       (SELECT count(*) FROM silver.pedidos WHERE fecha_entrega < fecha) = 0
UNION ALL
SELECT 'Pedidos: 23 entregas marcadas como sospechosas',
       (SELECT count(*) FROM silver.pedidos WHERE entrega_sospechosa) = 23;
