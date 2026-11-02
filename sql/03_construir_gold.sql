-- ============================================================
-- Capa GOLD de Marejada Distribución: el modelo en estrella
-- Se construye a partir de silver. Volumen 04.
-- Uso: duckdb db/marejada.duckdb < sql/03_construir_gold.sql
-- duckdb db/marejada.duckdb < sql/04_comprobar_gold.sql
-- ============================================================
CREATE SCHEMA IF NOT EXISTS gold;
-- ------------------------------------------------------------
-- dim_fecha: un día por fila, años completos 2024-2026
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE gold.dim_fecha AS
SELECT CAST(strftime(d, '%Y%m%d') AS INTEGER) AS fecha_key,
d::DATE AS fecha,
year(d) AS anio,
quarter(d) AS trimestre,
'T' || quarter(d) AS nombre_trimestre,
month(d) AS mes,
['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'][month(d)] AS nombre_mes,
strftime(d, '%Y-%m') AS anio_mes,
date_trunc('month', d)::DATE AS inicio_mes,
weekofyear(d) AS semana_iso,
day(d) AS dia_mes,
isodow(d) AS dia_semana,
['lunes', 'martes', 'miércoles', 'jueves', 'viernes',
'sábado', 'domingo'][isodow(d)] AS nombre_dia,
isodow(d) >= 6 AS es_fin_de_semana
FROM generate_series(DATE '2024-01-01', DATE '2026-12-31', INTERVAL 1 DAY) AS t(d);
-- ------------------------------------------------------------
-- dim_producto: un producto por fila + el miembro desconocido
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE gold.dim_producto AS
SELECT row_number() OVER (ORDER BY producto_id)::INTEGER AS producto_key,
producto_id, sku, nombre, categoria, subcategoria, marca, formato,
precio_lista, coste_unitario, iva_pct, activo
FROM silver.productos
UNION ALL
SELECT -1, NULL, 'DESCONOCIDO', 'Producto desconocido', 'Desconocida', 'Desconocida',
'Desconocida', 'Desconocido', NULL, NULL, NULL, NULL;
-- ------------------------------------------------------------
-- dim_comercial: una persona por fila + el miembro desconocido
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE gold.dim_comercial AS
SELECT row_number() OVER (ORDER BY c.comercial_id)::INTEGER AS comercial_key,
c.comercial_id,
c.nombre_completo AS comercial,
coalesce(c.zona, 'Dirección') AS zona,
c.puesto,
j.nombre_completo AS jefe,
c.fecha_alta,
c.fecha_baja,
c.fecha_baja IS NULL AS en_activo
FROM silver.comerciales AS c
LEFT JOIN silver.comerciales AS j ON j.comercial_id = c.jefe_id
UNION ALL
SELECT -1, NULL, 'Desconocido', 'Desconocida', NULL, NULL, NULL, NULL, NULL;
-- ------------------------------------------------------------
-- dim_cliente: SCD tipo 2 sobre el comercial asignado.
-- Una fila por cliente real (ficha maestra) y por cada periodo
-- con un comercial asignado distinto.
-- Reasignaciones conocidas (RRHH):
-- Óscar Peña (14) se fue el 31/10/2024: sus clientes pasan a Rubén Martín (12).
-- Héctor Bustamante (7) se fue el 30/06/2025: sus clientes pasan a Celia Gómez (13).
-- Un cliente "era de" quien se fue si tiene algún pedido gestionado por esa persona.
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE gold.dim_cliente AS
WITH maestros AS (
SELECT * FROM silver.clientes WHERE NOT es_ficha_duplicada
),
reasignaciones AS (
SELECT * FROM (VALUES
(14, 12, DATE '2024-10-31'),
( 7, 13, DATE '2025-06-30')
) AS t(comercial_anterior, comercial_nuevo, ultimo_dia_anterior)
),
heredados AS (
SELECT DISTINCT m.cliente_id, r.comercial_anterior, r.ultimo_dia_anterior
FROM maestros AS m
JOIN reasignaciones AS r ON r.comercial_nuevo = m.comercial_id
JOIN silver.pedidos AS p
ON p.cliente_maestro_id = m.cliente_id
AND p.comercial_id = r.comercial_anterior
),
versiones AS (
-- versión anterior: solo para los clientes heredados
SELECT m.*, h.comercial_anterior AS comercial_asignado_id,
DATE '1900-01-01' AS valido_desde, h.ultimo_dia_anterior AS valido_hasta
FROM maestros AS m
JOIN heredados AS h USING (cliente_id)
UNION ALL
-- versión actual: todos los clientes
SELECT m.*, m.comercial_id AS comercial_asignado_id,
coalesce(h.ultimo_dia_anterior + 1, DATE '1900-01-01') AS valido_desde,
DATE '9999-12-31' AS valido_hasta
FROM maestros AS m
LEFT JOIN heredados AS h USING (cliente_id)
)
SELECT row_number() OVER (ORDER BY v.cliente_id, v.valido_desde)::INTEGER AS cliente_key,
v.cliente_id,
v.nombre_comercial,
v.razon_social,
v.tipo_cliente,
v.municipio,
v.provincia,
v.codigo_postal,
v.comercial_asignado_id,
co.nombre_completo AS comercial_asignado,
v.fecha_alta,
v.activo_en_erp,
v.valido_desde,
v.valido_hasta,
v.valido_hasta = DATE '9999-12-31' AS es_version_actual
FROM versiones AS v
LEFT JOIN silver.comerciales AS co ON co.comercial_id = v.comercial_asignado_id
UNION ALL
SELECT -1, NULL, 'Cliente desconocido', NULL, 'Desconocido', NULL, 'Desconocida', NULL,
NULL, NULL, NULL, NULL, DATE '1900-01-01', DATE '9999-12-31', true;
-- ------------------------------------------------------------
-- fact_ventas. Grano: una línea de un pedido no cancelado.
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE gold.fact_ventas AS
SELECT l.pedido_id,
l.num_linea,
CAST(strftime(p.fecha, '%Y%m%d') AS INTEGER) AS fecha_key,
coalesce(dc.cliente_key, -1) AS cliente_key,
coalesce(dp.producto_key, -1) AS producto_key,
coalesce(dco.comercial_key, -1) AS comercial_key,
p.canal,
p.almacen,
p.estado,
l.cantidad,
l.precio_unitario,
l.descuento_pct,
l.importe_neto,
l.cantidad * dp.coste_unitario AS coste_estimado
FROM silver.lineas_pedido AS l
JOIN silver.pedidos AS p ON p.pedido_id = l.pedido_id
LEFT JOIN gold.dim_cliente AS dc
ON dc.cliente_id = p.cliente_maestro_id
AND p.fecha BETWEEN dc.valido_desde AND dc.valido_hasta
LEFT JOIN gold.dim_producto AS dp ON dp.producto_id = l.producto_id
LEFT JOIN gold.dim_comercial AS dco ON dco.comercial_id = p.comercial_id
WHERE p.estado <> 'Cancelado';
-- ------------------------------------------------------------
-- fact_pedidos. Grano: un pedido, en cualquier estado.
-- Aquí viven los gastos de envío, que son del pedido, no de la línea.
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE gold.fact_pedidos AS
WITH lineas AS (
SELECT pedido_id, count(*) AS num_lineas, sum(importe_neto) AS importe_neto
FROM silver.lineas_pedido
GROUP BY pedido_id
)
SELECT p.pedido_id,
CAST(strftime(p.fecha, '%Y%m%d') AS INTEGER) AS fecha_key,
CAST(strftime(p.fecha_entrega, '%Y%m%d') AS INTEGER) AS fecha_entrega_key,
coalesce(dc.cliente_key, -1) AS cliente_key,
coalesce(dco.comercial_key, -1) AS comercial_key,
p.canal,
p.almacen,
p.estado,
p.entrega_sospechosa,
coalesce(l.num_lineas, 0) AS num_lineas,
coalesce(l.importe_neto, 0) AS importe_neto,
p.gastos_envio,
p.fecha_entrega - p.fecha AS dias_entrega
FROM silver.pedidos AS p
LEFT JOIN lineas AS l ON l.pedido_id = p.pedido_id
LEFT JOIN gold.dim_cliente AS dc
ON dc.cliente_id = p.cliente_maestro_id
AND p.fecha BETWEEN dc.valido_desde AND dc.valido_hasta
LEFT JOIN gold.dim_comercial AS dco ON dco.comercial_id = p.comercial_id;