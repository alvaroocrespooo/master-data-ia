-- ============================================================
-- MJD-204 · Marzo de 2025: ventas comerciales frente a contabilidad
-- Pide: Lucía Gómez · Administración y finanzas · Prioridad alta
-- Criterios de contabilidad (hoja Notas del Excel): mes de ENTREGA,
-- sin cancelados, devoluciones restadas, base CON gastos de envío.
-- Uso: duckdb -readonly db/marejada.duckdb < sql/02-sql-i/mjd-204_cuadre_marzo_2025.sql
-- ============================================================

-- Paso 1. La cifra de Íñigo: todo lo pedido en marzo, tal cual.
SELECT round(sum(l.cantidad * l.precio_unitario * (1 - l.descuento_pct / 100)), 2) AS cifra_comercial
FROM bronze.pedidos AS p
JOIN bronze.lineas_pedido AS l ON l.pedido_id = p.pedido_id
WHERE p.fecha_pedido >= '2025-03-01' AND p.fecha_pedido < '2025-04-01';

-- Paso 2. La hoja de contabilidad (la tabla empieza en la fila 4).
SELECT *
FROM read_xlsx('datos/contabilidad/facturacion_mensual_2024-2026.xlsx', range = 'A4:E1000')
WHERE "Año" = 2025 AND "Mes" = 'marzo';

SELECT round(sum("Base imponible (€)"), 2) AS cifra_contabilidad
FROM read_xlsx('datos/contabilidad/facturacion_mensual_2024-2026.xlsx', range = 'A4:E1000')
WHERE "Año" = 2025 AND "Mes" = 'marzo';

-- Paso 3. El puente, criterio a criterio.
-- Los portes se suman con el importe ya agregado por pedido
-- (una fila por pedido), para no caer en el abanico (fan-out).
WITH lineas_unicas AS (
    SELECT DISTINCT pedido_id, num_linea, producto_id, cantidad, precio_unitario, descuento_pct
    FROM bronze.lineas_pedido
),
importe_todas AS (
    SELECT pedido_id, sum(cantidad * precio_unitario * (1 - descuento_pct / 100)) AS importe
    FROM bronze.lineas_pedido GROUP BY pedido_id
),
importe_unicas AS (
    SELECT pedido_id, sum(cantidad * precio_unitario * (1 - descuento_pct / 100)) AS importe
    FROM lineas_unicas GROUP BY pedido_id
)
SELECT '1. Pedido en marzo, todo' AS paso,
       round(sum(i.importe), 2) AS importe
FROM bronze.pedidos p JOIN importe_todas i USING (pedido_id)
WHERE p.fecha_pedido >= '2025-03-01' AND p.fecha_pedido < '2025-04-01'
UNION ALL
SELECT '2. Sin cancelados',
       round(sum(i.importe), 2)
FROM bronze.pedidos p JOIN importe_todas i USING (pedido_id)
WHERE p.fecha_pedido >= '2025-03-01' AND p.fecha_pedido < '2025-04-01'
  AND p.estado <> 'Cancelado'
UNION ALL
SELECT '3. Sin líneas duplicadas',
       round(sum(i.importe), 2)
FROM bronze.pedidos p JOIN importe_unicas i USING (pedido_id)
WHERE p.fecha_pedido >= '2025-03-01' AND p.fecha_pedido < '2025-04-01'
  AND p.estado <> 'Cancelado'
UNION ALL
SELECT '4. Por mes de entrega, no de pedido',
       round(sum(i.importe), 2)
FROM bronze.pedidos p JOIN importe_unicas i USING (pedido_id)
WHERE p.fecha_entrega >= '2025-03-01' AND p.fecha_entrega < '2025-04-01'
  AND p.estado IN ('Entregado', 'Devuelto parcial')
UNION ALL
SELECT '5. Más gastos de envío',
       round(sum(i.importe + p.gastos_envio), 2)
FROM bronze.pedidos p JOIN importe_unicas i USING (pedido_id)
WHERE p.fecha_entrega >= '2025-03-01' AND p.fecha_entrega < '2025-04-01'
  AND p.estado IN ('Entregado', 'Devuelto parcial')
ORDER BY paso;

-- Paso 4. Provincia por provincia, con FULL JOIN para no perder
-- filas que estén solo en un lado.
WITH lineas_unicas AS (
    SELECT DISTINCT pedido_id, num_linea, producto_id, cantidad, precio_unitario, descuento_pct
    FROM bronze.lineas_pedido
),
importe AS (
    SELECT pedido_id, sum(cantidad * precio_unitario * (1 - descuento_pct / 100)) AS importe
    FROM lineas_unicas GROUP BY pedido_id
),
nuestro AS (
    SELECT CASE
               WHEN lower(trim(c.provincia)) IN ('cantabria', 'santander')            THEN 'Cantabria'
               WHEN lower(trim(c.provincia)) IN ('asturias', 'principado de asturias') THEN 'Asturias'
               WHEN lower(trim(c.provincia)) IN ('bizkaia', 'vizcaya')                THEN 'Bizkaia'
               WHEN lower(trim(c.provincia)) = 'burgos'                              THEN 'Burgos'
               WHEN lower(trim(c.provincia)) = 'palencia'                            THEN 'Palencia'
               ELSE 'Sin asignar'
           END AS provincia,
           round(sum(i.importe + p.gastos_envio), 2) AS calculado
    FROM bronze.pedidos AS p
    JOIN importe AS i ON i.pedido_id = p.pedido_id
    LEFT JOIN bronze.clientes AS c ON c.cliente_id = p.cliente_id
    WHERE p.fecha_entrega >= '2025-03-01' AND p.fecha_entrega < '2025-04-01'
      AND p.estado IN ('Entregado', 'Devuelto parcial')
    GROUP BY 1
),
contabilidad AS (
    SELECT "Provincia" AS provincia, "Base imponible (€)" AS contabilidad
    FROM read_xlsx('datos/contabilidad/facturacion_mensual_2024-2026.xlsx', range = 'A4:E1000')
    WHERE "Año" = 2025 AND "Mes" = 'marzo'
)
SELECT provincia, n.calculado, k.contabilidad,
       round(n.calculado - k.contabilidad, 2) AS diferencia
FROM nuestro AS n
FULL JOIN contabilidad AS k USING (provincia)
ORDER BY provincia;

-- Segunda vía (silver): la cifra contable directamente.
WITH portes AS (
    SELECT sum(gastos_envio) AS gastos_envio
    FROM silver.pedidos
    WHERE fecha_entrega >= '2025-03-01' AND fecha_entrega < '2025-04-01'
      AND estado IN ('Entregado', 'Devuelto parcial')
)
SELECT round(sum(l.importe_neto) + any_value(portes.gastos_envio), 2) AS facturacion_contable_silver
FROM silver.pedidos AS p
JOIN silver.lineas_pedido AS l ON l.pedido_id = p.pedido_id
CROSS JOIN portes
WHERE p.fecha_entrega >= '2025-03-01' AND p.fecha_entrega < '2025-04-01'
  AND p.estado IN ('Entregado', 'Devuelto parcial');

-- ============================================================
-- RESULTADO (26/10/2026) · el puente
--   1. Pedido en marzo, todo                 1.104.552,29  (cifra de Íñigo)
--   2. Sin cancelados                        1.066.085,78  (−38.466,51)
--   3. Sin líneas duplicadas                 1.063.694,42  (−2.391,36)  ← error del ERP
--   4. Por mes de entrega, no de pedido      1.077.305,50  (+13.611,08)
--   5. Más gastos de envío                   1.082.243,50  (+4.938,00)  = contabilidad
-- Por provincia: Asturias, Bizkaia, Burgos y Palencia cuadran al céntimo.
-- Cantabria −6.305,36 y "Sin asignar" +6.305,36: son los pedidos de los
-- clientes borrados del maestro, que eran de Cantabria.
-- Segunda vía (silver): 1.082.243,50.
-- Respuesta a Lucía: las dos cifras están bien, miden cosas distintas.
-- Además, los informes comerciales incluyen cancelados y duplicados.
-- ============================================================
