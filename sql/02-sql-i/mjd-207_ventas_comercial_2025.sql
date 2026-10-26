-- ============================================================
-- MJD-207 · Ventas de 2025 por comercial y trimestre
-- Pide: Íñigo Sainz · Director comercial
-- El comercial que cuenta es el del PEDIDO (quien hizo la venta),
-- no el asignado hoy al cliente. Ventas netas, sin cancelados.
-- Uso: duckdb -readonly db/marejada.duckdb < sql/02-sql-i/mjd-207_ventas_comercial_2025.sql
-- ============================================================

-- Dos pasos: primero una fila por pedido, después por comercial.
-- Así count(*) cuenta pedidos (no líneas) y el ticket medio es por pedido.
WITH lineas AS (
    SELECT DISTINCT pedido_id, num_linea, producto_id, cantidad, precio_unitario, descuento_pct
    FROM bronze.lineas_pedido
),
ventas_pedido AS (
    SELECT p.pedido_id, p.comercial_id, quarter(p.fecha_pedido) AS trimestre,
           sum(l.cantidad * l.precio_unitario * (1 - l.descuento_pct / 100)) AS ventas
    FROM bronze.pedidos AS p
    JOIN lineas AS l ON l.pedido_id = p.pedido_id
    WHERE p.estado <> 'Cancelado'
      AND p.fecha_pedido >= '2025-01-01' AND p.fecha_pedido < '2026-01-01'
    GROUP BY p.pedido_id, p.comercial_id, trimestre
)
SELECT co.nombre || ' ' || co.apellidos AS comercial,
       round(sum(v.ventas) FILTER (WHERE trimestre = 1)) AS t1,
       round(sum(v.ventas) FILTER (WHERE trimestre = 2)) AS t2,
       round(sum(v.ventas) FILTER (WHERE trimestre = 3)) AS t3,
       round(sum(v.ventas) FILTER (WHERE trimestre = 4)) AS t4,
       round(sum(v.ventas)) AS total_2025,
       count(*) AS pedidos,
       round(sum(v.ventas) / count(*)) AS ticket_medio
FROM ventas_pedido AS v
JOIN bronze.comerciales AS co ON co.comercial_id = v.comercial_id
GROUP BY comercial
ORDER BY total_2025 DESC;

-- Contexto para las notas: altas y bajas del equipo.
SELECT nombre || ' ' || apellidos AS comercial, zona, fecha_alta, fecha_baja
FROM bronze.comerciales
WHERE fecha_alta >= '2025-01-01' OR fecha_baja IS NOT NULL
ORDER BY fecha_alta;

-- Segunda vía (silver): el total del año debe coincidir.
SELECT round(sum(l.importe_neto)) AS total_2025_silver,
       count(DISTINCT p.pedido_id) AS pedidos
FROM silver.pedidos AS p
JOIN silver.lineas_pedido AS l ON l.pedido_id = p.pedido_id
WHERE p.estado <> 'Cancelado'
  AND p.fecha >= DATE '2025-01-01' AND p.fecha < DATE '2026-01-01';

-- ============================================================
-- RESULTADO (26/10/2026) · ventas netas 2025, euros redondeados
--   Rubén Martín Calvo        2.349.289  3.851 pedidos  ticket 610
--   Raquel Fernández Cobo     2.187.256  3.649          599
--   Pablo Revuelta Gómez      2.141.292  4.040          530
--   Daniel Gutiérrez Pérez    1.848.675  3.168          584
--   Adrián Suárez Fernández   1.611.782  2.167          744
--   Nuria Álvarez Menéndez    1.398.780  2.550          549
--   Sara Ceballos Ortiz       1.208.264  2.328          519
--   Lorena Arce Díaz            864.615  1.795          482
--   Celia Gómez Sáiz            712.589  1.374          519  (alta 16/06/2025)
--   Héctor Bustamante Lavín     605.161  1.157          523  (baja 30/06/2025)
--   Mikel Goikoetxea Arana      386.225    618          625  (alta 03/03/2025)
--   Ane Etxeberria Zubiri       305.448    523          584  (alta 17/02/2025)
--   Suma 15.619.376 en 27.220 pedidos = silver (segunda vía).
-- Notas para Íñigo: se usa el comercial del pedido; la zona condiciona
--   la cifra; Héctor y Celia comparten cartera en 2025.
-- ============================================================
