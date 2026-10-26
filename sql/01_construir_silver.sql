-- ============================================================
-- MJD-210 · Construcción de la capa SILVER de Marejada Distribución
-- Pide: Elena Pérez · Responsable de datos
-- Las reglas de limpieza, escritas una sola vez. Bronze no se toca.
-- Uso (desde la raíz del repo, después de cargar bronze):
--   duckdb db/marejada.duckdb < sql/00_cargar_bronze.sql
--   duckdb db/marejada.duckdb < sql/01_construir_silver.sql
--   duckdb -readonly db/marejada.duckdb < sql/02_comprobar_silver.sql
-- El orden de las tablas importa: silver.pedidos usa silver.clientes.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS silver;

-- ------------------------------------------------------------
-- Tablas de correspondencias (cómo viene escrito → cómo debe quedar)
-- Una grafía nueva se arregla añadiendo una fila, sin tocar consultas.
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE silver.map_provincias AS
SELECT * FROM (VALUES
    ('cantabria',              'Cantabria'),
    ('santander',              'Cantabria'),   -- decisión: Santander es la capital, se trata como Cantabria
    ('asturias',               'Asturias'),
    ('principado de asturias', 'Asturias'),
    ('bizkaia',                'Bizkaia'),
    ('vizcaya',                'Bizkaia'),
    ('burgos',                 'Burgos'),
    ('palencia',               'Palencia')
) AS t(texto_normalizado, provincia);

CREATE OR REPLACE TABLE silver.map_categorias AS
SELECT * FROM (VALUES
    ('cervezas',             'Cervezas'),
    ('cerveza',              'Cervezas'),
    ('refrescos',            'Refrescos'),
    ('aguas',                'Aguas'),
    ('agua',                 'Aguas'),
    ('vinos',                'Vinos'),
    ('licores y destilados', 'Licores y destilados'),
    ('cafe e infusiones',    'Café e infusiones'),
    ('alimentacion',         'Alimentación'),
    ('limpieza e higiene',   'Limpieza e higiene'),
    ('desechables',          'Desechables')
) AS t(texto_normalizado, categoria);

-- ------------------------------------------------------------
-- Clientes: todas las fichas, con su ficha maestra (la más antigua del NIF)
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE silver.clientes AS
WITH fichas AS (
    SELECT *, upper(replace(trim(nif), '-', '')) AS nif_norm
    FROM bronze.clientes
),
maestras AS (
    SELECT nif_norm, min(cliente_id) AS cliente_maestro_id
    FROM fichas
    GROUP BY nif_norm
),
municipios AS (
    -- de las formas en que aparece cada municipio, la que no está toda en mayúsculas
    SELECT lower(municipio) AS clave,
           max(municipio) FILTER (WHERE municipio <> upper(municipio)) AS municipio
    FROM bronze.clientes
    GROUP BY clave
)
SELECT f.cliente_id,
       m.cliente_maestro_id,
       f.cliente_id <> m.cliente_maestro_id                     AS es_ficha_duplicada,
       f.nif_norm                                                AS nif,
       trim(f.nombre_comercial)                                  AS nombre_comercial,
       trim(f.razon_social)                                      AS razon_social,
       f.tipo_cliente,
       coalesce(mu.municipio, f.municipio)                       AS municipio,
       coalesce(mp.provincia, 'REVISAR')                         AS provincia,
       lpad(f.codigo_postal::VARCHAR, 5, '0')                    AS codigo_postal,
       right(regexp_replace(f.telefono, '[^0-9]', '', 'g'), 9)   AS telefono,
       CASE WHEN lower(trim(f.email)) LIKE '%_@_%._%'
            THEN lower(trim(f.email)) END                        AS email,
       f.comercial_id,
       f.fecha_alta,
       f.activo = 'S'                                            AS activo_en_erp,
       f.limite_credito,
       f.descuento_habitual
FROM fichas AS f
JOIN maestras AS m ON m.nif_norm = f.nif_norm
LEFT JOIN municipios AS mu ON mu.clave = lower(f.municipio)
LEFT JOIN silver.map_provincias AS mp ON mp.texto_normalizado = lower(trim(f.provincia));

-- ------------------------------------------------------------
-- Productos, comerciales e inventario
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE silver.productos AS
SELECT p.producto_id,
       p.sku,
       p.nombre,
       coalesce(mc.categoria, 'REVISAR')        AS categoria,
       p.subcategoria,
       p.marca,
       p.formato,
       CAST(p.precio_lista   AS DECIMAL(10, 2)) AS precio_lista,
       CAST(p.coste_unitario AS DECIMAL(10, 2)) AS coste_unitario,
       p.iva_pct,
       p.activo = 'S'                           AS activo,
       p.fecha_alta,
       p.fecha_baja
FROM bronze.productos AS p
LEFT JOIN silver.map_categorias AS mc
       ON mc.texto_normalizado = strip_accents(lower(trim(p.categoria)));

CREATE OR REPLACE TABLE silver.comerciales AS
SELECT comercial_id,
       nombre || ' ' || apellidos AS nombre_completo,
       nombre, apellidos, email, zona, puesto, jefe_id, fecha_alta, fecha_baja
FROM bronze.comerciales;

CREATE OR REPLACE TABLE silver.inventario AS
WITH normalizado AS (
    SELECT *, upper(replace(trim(sku), '-', '')) AS sku_norm
    FROM bronze.inventario
)
SELECT n.almacen,
       left(n.sku_norm, 3) || '-' || substr(n.sku_norm, 4) AS sku,
       p.producto_id,
       n.descripcion,
       n.unidades,
       n.ubicacion,
       n.fecha_inventario
FROM normalizado AS n
LEFT JOIN bronze.productos AS p ON p.sku = left(n.sku_norm, 3) || '-' || substr(n.sku_norm, 4);

-- ------------------------------------------------------------
-- Pedidos y líneas
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE silver.pedidos AS
SELECT p.pedido_id,
       p.fecha_pedido,
       CAST(p.fecha_pedido AS DATE)                           AS fecha,
       p.cliente_id,
       c.cliente_maestro_id,
       p.comercial_id,
       p.canal,
       p.estado,
       CASE WHEN p.fecha_entrega >= CAST(p.fecha_pedido AS DATE)
            THEN p.fecha_entrega END                          AS fecha_entrega,
       coalesce(p.fecha_entrega < CAST(p.fecha_pedido AS DATE), false) AS entrega_sospechosa,
       p.almacen,
       CAST(p.gastos_envio AS DECIMAL(10, 2))                 AS gastos_envio,
       p.observaciones
FROM bronze.pedidos AS p
LEFT JOIN silver.clientes AS c ON c.cliente_id = p.cliente_id;

CREATE OR REPLACE TABLE silver.lineas_pedido AS
WITH sin_duplicar AS (
    SELECT DISTINCT pedido_id, num_linea, producto_id, cantidad, precio_unitario, descuento_pct
    FROM bronze.lineas_pedido
)
SELECT l.pedido_id,
       l.num_linea,
       l.producto_id,
       l.cantidad,
       CAST(l.precio_unitario AS DECIMAL(10, 2))            AS precio_unitario,
       l.descuento_pct,
       l.cantidad * CAST(l.precio_unitario AS DECIMAL(10, 2)) * (100 - l.descuento_pct) / 100 AS importe_neto
FROM sin_duplicar AS l
WHERE l.pedido_id IN (SELECT pedido_id FROM bronze.pedidos);
