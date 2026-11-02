-- ============================================================
-- Comprobaciones de la capa GOLD. Todas deben salir true.
-- Uso: duckdb db/marejada.duckdb < sql/04_comprobar_gold.sql
-- ============================================================
SELECT 'fact_ventas: mismas líneas que silver sin cancelados' AS comprobacion,
       (SELECT count(*) FROM gold.fact_ventas)
     = (SELECT count(*) FROM silver.lineas_pedido AS l
        JOIN silver.pedidos AS p ON p.pedido_id = l.pedido_id
        WHERE p.estado <> 'Cancelado') AS ok
UNION ALL
SELECT 'fact_ventas: mismo importe que silver sin cancelados',
       abs((SELECT sum(importe_neto) FROM gold.fact_ventas)
          - (SELECT sum(l.importe_neto) FROM silver.lineas_pedido AS l
             JOIN silver.pedidos AS p ON p.pedido_id = l.pedido_id
             WHERE p.estado <> 'Cancelado')) < 0.01
UNION ALL
SELECT 'fact_pedidos: un pedido por fila, todos los de silver',
       (SELECT count(*) FROM gold.fact_pedidos) = (SELECT count(*) FROM silver.pedidos)
   AND (SELECT count(DISTINCT pedido_id) FROM gold.fact_pedidos) = (SELECT count(*) FROM silver.pedidos)
UNION ALL
SELECT 'Hechos: ninguna clave de dimensión vacía',
       (SELECT count(*) FROM gold.fact_ventas
        WHERE fecha_key IS NULL OR cliente_key IS NULL OR producto_key IS NULL OR comercial_key IS NULL) = 0
UNION ALL
SELECT 'Hechos: todas las fechas existen en dim_fecha',
       (SELECT count(*) FROM gold.fact_pedidos AS f
        LEFT JOIN gold.dim_fecha AS d ON d.fecha_key = f.fecha_key
        WHERE d.fecha_key IS NULL) = 0
UNION ALL
SELECT 'dim_cliente: una sola versión válida por cliente y día',
       (SELECT count(*) FROM gold.dim_cliente AS a
        JOIN gold.dim_cliente AS b
           ON a.cliente_id = b.cliente_id AND a.cliente_key < b.cliente_key
          AND a.valido_desde <= b.valido_hasta AND b.valido_desde <= a.valido_hasta) = 0
UNION ALL
SELECT 'Puente de marzo de 2025: 1.082.243,50 como contabilidad',
       (SELECT round(sum(importe_neto + gastos_envio), 2)
        FROM gold.fact_pedidos
        WHERE estado IN ('Entregado', 'Devuelto parcial')
          AND fecha_entrega_key BETWEEN 20250301 AND 20250331) = 1082243.50;