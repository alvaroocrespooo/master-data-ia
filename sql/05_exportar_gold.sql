-- ============================================================
-- Exporta la capa GOLD a ficheros Parquet para Power BI. Volumen 07 (MJD-701).
-- Power BI Desktop no lee una base de DuckDB, pero sí Parquet: columnas con su tipo,
-- comprimidas, y una sola fuente de verdad (gold) para todo el Bloque 1.
-- Uso, desde la carpeta del proyecto:
--   mkdir -p exportar/gold
--   duckdb db/marejada.duckdb < sql/05_exportar_gold.sql
-- ============================================================
COPY (SELECT * FROM gold.dim_fecha     ORDER BY fecha_key)     TO 'exportar/gold/dim_fecha.parquet'     (FORMAT parquet);
COPY (SELECT * FROM gold.dim_producto  ORDER BY producto_key)  TO 'exportar/gold/dim_producto.parquet'  (FORMAT parquet);
COPY (SELECT * FROM gold.dim_comercial ORDER BY comercial_key) TO 'exportar/gold/dim_comercial.parquet' (FORMAT parquet);
COPY (SELECT * FROM gold.dim_cliente   ORDER BY cliente_key)   TO 'exportar/gold/dim_cliente.parquet'   (FORMAT parquet);

-- En los hechos, el coste estimado pasa de DECIMAL(29,2) a DECIMAL(18,2): Power BI no admite más de 28 cifras
COPY (
    SELECT pedido_id, num_linea, fecha_key, cliente_key, producto_key, comercial_key,
           canal, almacen, estado, cantidad, precio_unitario, descuento_pct,
           importe_neto,
           CAST(coste_estimado AS DECIMAL(18, 2)) AS coste_estimado
    FROM gold.fact_ventas
    ORDER BY pedido_id, num_linea
) TO 'exportar/gold/fact_ventas.parquet' (FORMAT parquet);

COPY (
    SELECT pedido_id, fecha_key, fecha_entrega_key, cliente_key, comercial_key,
           canal, almacen, estado, entrega_sospechosa, num_lineas,
           importe_neto, gastos_envio, dias_entrega
    FROM gold.fact_pedidos
    ORDER BY pedido_id
) TO 'exportar/gold/fact_pedidos.parquet' (FORMAT parquet);