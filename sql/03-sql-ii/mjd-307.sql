-- TICKET MJD-307
-- De: Íñigo Sainz · Director comercial
-- Siempre se dice que el 20 % de los clientes hace el 80 % de las ventas. ¿Es verdad en Marejada?
-- ¿Cuántos clientes necesito para llegar al 80 % de lo vendido en los últimos doce meses?

WITH ventas_cliente AS (
           SELECT p.cliente_maestro_id, sum(l.importe_neto) AS ventas
           FROM silver.pedidos AS p
           JOIN silver.lineas_pedido AS l ON l.pedido_id = p.pedido_id
           WHERE p.estado <> 'Cancelado'
           AND p.fecha > DATE '2026-09-30' - INTERVAL 1 YEAR
           AND p.cliente_maestro_id IS NOT NULL
           GROUP BY p.cliente_maestro_id
           ),
           acumulado AS (
           SELECT cliente_maestro_id, ventas,
           row_number() OVER (ORDER BY ventas DESC, cliente_maestro_id) AS puesto,
           count(*) OVER () AS total_clientes,
           sum(ventas) OVER (ORDER BY ventas DESC, cliente_maestro_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
           / sum(ventas) OVER () AS pct_acumulado
           FROM ventas_cliente
           )
           SELECT puesto AS clientes_necesarios,
           total_clientes,
           round(100.0 * puesto / total_clientes, 1) AS pct_clientes,
           round(100 * pct_acumulado, 1) AS pct_ventas_acumulado
           FROM acumulado
           WHERE pct_acumulado >= 0.80
           ORDER BY puesto
           LIMIT 1;


-- Hacen falta 487 de los 1.092 clientes, el 44,6 %, para llegar al 80 % de las ventas. No es un 80/20, sino más
-- bien un 80/45: las ventas de Marejada están concentradas, pero bastante menos de lo que dice el tópico. El
-- primer quintil del 5.4 lo confirma desde el otro lado: el 20 % de los clientes hace el 59,6 %, no el 80 %.

