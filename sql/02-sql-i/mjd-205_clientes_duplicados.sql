-- ============================================================
-- MJD-205 · Fichas de cliente duplicadas
-- Pide: Elena Pérez · Responsable de datos
-- Duplicado = mismo NIF una vez normalizado (sin espacios ni guiones,
-- en mayúsculas). Propuesta: conservar la ficha más antigua (cliente_id
-- más bajo) y traspasarle los pedidos de las demás. La fusión se hace
-- en el ERP (administración), no en nuestra base.
-- Entregable: entregables/mjd-205_fichas_duplicadas.xlsx
-- Uso (escribe el Excel, así que sin -readonly):
--   duckdb db/marejada.duckdb < sql/02-sql-i/mjd-205_clientes_duplicados.sql
-- ============================================================

INSTALL excel;
LOAD excel;

-- Lista completa: cada ficha de un NIF repetido, con sus pedidos
-- y la propuesta de cuál conservar.
CREATE OR REPLACE TEMP VIEW mjd205 AS
WITH fichas AS (
    SELECT *, upper(replace(trim(nif), '-', '')) AS nif_norm
    FROM bronze.clientes
),
nif_duplicados AS (
    SELECT nif_norm, min(cliente_id) AS ficha_a_conservar
    FROM fichas GROUP BY nif_norm HAVING count(*) > 1
),
pedidos_por_cliente AS (
    SELECT cliente_id, count(*) AS pedidos, min(fecha_pedido)::DATE AS primer_pedido
    FROM bronze.pedidos GROUP BY cliente_id
)
SELECT f.nif_norm, f.cliente_id, f.nombre_comercial, f.municipio, f.fecha_alta,
       coalesce(pc.pedidos, 0) AS pedidos,
       pc.primer_pedido,
       CASE WHEN f.cliente_id = d.ficha_a_conservar THEN 'Conservar'
            ELSE 'Fusionar en ' || d.ficha_a_conservar END AS propuesta
FROM fichas AS f
JOIN nif_duplicados AS d USING (nif_norm)
LEFT JOIN pedidos_por_cliente AS pc ON pc.cliente_id = f.cliente_id
ORDER BY f.nif_norm, f.cliente_id;

SELECT * FROM mjd205;

COPY (SELECT * FROM mjd205)
TO 'entregables/mjd-205_fichas_duplicadas.xlsx' WITH (FORMAT xlsx, HEADER true);

-- Resumen
WITH fichas AS (
    SELECT *, upper(replace(trim(nif), '-', '')) AS nif_norm FROM bronze.clientes
),
dup AS (
    SELECT nif_norm, min(cliente_id) AS ficha_a_conservar
    FROM fichas GROUP BY nif_norm HAVING count(*) > 1
),
fichas_sobrantes AS (
    SELECT f.cliente_id
    FROM fichas AS f
    JOIN dup AS d ON d.nif_norm = f.nif_norm
    WHERE f.cliente_id <> d.ficha_a_conservar
)
SELECT (SELECT count(*) FROM dup)              AS nif_duplicados,
       (SELECT count(*) FROM fichas_sobrantes) AS fichas_sobrantes,
       (SELECT count(*) FROM bronze.pedidos
        WHERE cliente_id IN (SELECT cliente_id FROM fichas_sobrantes)) AS pedidos_a_traspasar;

-- Segunda vía (silver): la columna es_ficha_duplicada debe dar las mismas fichas sobrantes.
SELECT count(*) FILTER (WHERE es_ficha_duplicada) AS fichas_sobrantes_silver,
       count(DISTINCT cliente_maestro_id) AS clientes_reales
FROM silver.clientes;

-- ============================================================
-- RESULTADO (26/10/2026)
--   37 NIF duplicados → 74 fichas, 37 sobrantes, 1.007 pedidos a traspasar.
--   Silver: 37 fichas con es_ficha_duplicada = true; 1.175 clientes reales.
--   Lista para administración: entregables/mjd-205_fichas_duplicadas.xlsx
-- Criterio: se conserva la ficha más antigua (cliente_id más bajo), que
--   tiene el historial completo. La fusión la hace administración en el ERP.
-- ============================================================
