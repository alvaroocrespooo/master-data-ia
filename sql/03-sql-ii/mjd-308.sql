-- TICKET MJD-308
-- De: Elena Pérez · Responsable de datos
-- Íñigo quiere una "ficha" de cada cliente para el CRM nuevo. Una fila por cliente real, con su primer y su
-- último pedido, el canal y el comercial de ese último pedido, sus pedidos y ventas de los últimos doce
-- meses y su puesto dentro de su provincia.
-- ENTREGABLE: La consulta en sql/03-sql-ii/ y el resultado en entregables/mjd-308_ficha_clientes.xlsx.

WITH validos AS (
SELECT * FROM silver.pedidos
WHERE estado <> 'Cancelado' AND cliente_maestro_id IS NOT NULL
),
historia AS (
SELECT cliente_maestro_id,
min(fecha) AS primer_pedido,
max(fecha) AS ultimo_pedido,
arg_max(canal, fecha_pedido) AS canal_ultimo,
arg_max(comercial_id, fecha_pedido) AS comercial_ultimo,
count(*) FILTER (WHERE fecha > DATE '2026-09-30' - INTERVAL 1 YEAR) AS pedidos_12m
FROM validos
GROUP BY cliente_maestro_id
),
ventas_12m AS (
SELECT v.cliente_maestro_id, sum(l.importe_neto) AS ventas_12m
FROM validos AS v
JOIN silver.lineas_pedido AS l ON l.pedido_id = v.pedido_id
WHERE v.fecha > DATE '2026-09-30' - INTERVAL 1 YEAR
GROUP BY v.cliente_maestro_id
)
SELECT c.cliente_id, c.nombre_comercial, c.provincia,
h.primer_pedido, h.ultimo_pedido, h.canal_ultimo,
co.nombre_completo AS comercial_ultimo,
h.pedidos_12m,
round(coalesce(v.ventas_12m, 0), 2) AS ventas_12m,
rank() OVER (PARTITION BY c.provincia ORDER BY coalesce(v.ventas_12m, 0) DESC) AS
puesto_provincia
FROM silver.clientes AS c
JOIN historia AS h ON h.cliente_maestro_id = c.cliente_id
LEFT JOIN ventas_12m AS v ON v.cliente_maestro_id = c.cliente_id
LEFT JOIN silver.comerciales AS co ON co.comercial_id = h.comercial_ultimo
WHERE NOT c.es_ficha_duplicada
ORDER BY c.provincia, puesto_provincia;


-- 1.175 fichas, una por cliente real con pedidos. Son diez columnas; en el libro solo caben seis, en tu terminal
-- ancha las verás todas. Y para el Excel, el COPY del Volumen 02 con la consulta dentro ( INSTALL excel; LOAD
-- excel; si no la tienes cargada en la sesión):


COPY (WITH validos AS (
SELECT * FROM silver.pedidos
WHERE estado <> 'Cancelado' AND cliente_maestro_id IS NOT NULL
),
historia AS (
SELECT cliente_maestro_id,
min(fecha) AS primer_pedido,
max(fecha) AS ultimo_pedido,
arg_max(canal, fecha_pedido) AS canal_ultimo,
arg_max(comercial_id, fecha_pedido) AS comercial_ultimo,
count(*) FILTER (WHERE fecha > DATE '2026-09-30' - INTERVAL 1 YEAR) AS pedidos_12m
FROM validos
GROUP BY cliente_maestro_id
),
ventas_12m AS (
SELECT v.cliente_maestro_id, sum(l.importe_neto) AS ventas_12m
FROM validos AS v
JOIN silver.lineas_pedido AS l ON l.pedido_id = v.pedido_id
WHERE v.fecha > DATE '2026-09-30' - INTERVAL 1 YEAR
GROUP BY v.cliente_maestro_id
)
SELECT c.cliente_id, c.nombre_comercial, c.provincia,
h.primer_pedido, h.ultimo_pedido, h.canal_ultimo,
co.nombre_completo AS comercial_ultimo,
h.pedidos_12m,
round(coalesce(v.ventas_12m, 0), 2) AS ventas_12m,
rank() OVER (PARTITION BY c.provincia ORDER BY coalesce(v.ventas_12m, 0) DESC) AS
puesto_provincia
FROM silver.clientes AS c
JOIN historia AS h ON h.cliente_maestro_id = c.cliente_id
LEFT JOIN ventas_12m AS v ON v.cliente_maestro_id = c.cliente_id
LEFT JOIN silver.comerciales AS co ON co.comercial_id = h.comercial_ultimo
WHERE NOT c.es_ficha_duplicada
ORDER BY c.provincia, puesto_provincia) TO 'entregables/mjd-308_ficha_clientes.csv' WITH (FORMAT csv, HEADER true);

-- Esto último se copia y pega en el duckdb y genera el CSV con toda la info
-- Ruta: entregables/mjd-308_ficha_clientes.csv