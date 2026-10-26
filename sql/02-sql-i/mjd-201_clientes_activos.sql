-- ============================================================
-- MJD-201 · Clientes activos por provincia
-- Pide: Íñigo Sainz · Director comercial · Prioridad alta
-- Fecha de corte: 2026-09-30
-- Uso: duckdb -readonly db/marejada.duckdb < sql/02-sql-i/mjd-201_clientes_activos.sql
-- ============================================================
-- "Activo" significa dos cosas en estos datos:
--   1. Marcado como activo en el ERP (columna activo = 'S').
--   2. Ha comprado (pedido no cancelado) en los últimos 90 días.

-- Definición 1: la bandera del ERP, con la provincia normalizada.
-- El alias NO se llama "provincia": si se llamara igual que la columna,
-- GROUP BY agruparía por la columna original y saldrían las 15 grafías.
SELECT CASE
           WHEN lower(trim(provincia)) IN ('cantabria', 'santander')            THEN 'Cantabria'
           WHEN lower(trim(provincia)) IN ('asturias', 'principado de asturias') THEN 'Asturias'
           WHEN lower(trim(provincia)) IN ('bizkaia', 'vizcaya')                THEN 'Bizkaia'
           WHEN lower(trim(provincia)) = 'burgos'                              THEN 'Burgos'
           WHEN lower(trim(provincia)) = 'palencia'                            THEN 'Palencia'
           ELSE 'REVISAR'
       END AS provincia_limpia,
       count(*) AS marcados_activos
FROM bronze.clientes
WHERE activo = 'S'
GROUP BY provincia_limpia
ORDER BY marcados_activos DESC;

-- Definición 2 frente a la 1, en la misma tabla.
WITH ultima_compra AS (
    SELECT cliente_id, max(fecha_pedido) AS ultimo_pedido
    FROM bronze.pedidos
    WHERE estado <> 'Cancelado'
    GROUP BY cliente_id
)
SELECT CASE
           WHEN lower(trim(c.provincia)) IN ('cantabria', 'santander')            THEN 'Cantabria'
           WHEN lower(trim(c.provincia)) IN ('asturias', 'principado de asturias') THEN 'Asturias'
           WHEN lower(trim(c.provincia)) IN ('bizkaia', 'vizcaya')                THEN 'Bizkaia'
           WHEN lower(trim(c.provincia)) = 'burgos'                              THEN 'Burgos'
           WHEN lower(trim(c.provincia)) = 'palencia'                            THEN 'Palencia'
           ELSE 'REVISAR'
       END AS provincia_limpia,
       count(*) FILTER (WHERE c.activo = 'S') AS marcados_activos,
       count(*) FILTER (WHERE u.ultimo_pedido >= DATE '2026-09-30' - INTERVAL 90 DAY) AS compran_ult_90_dias,
       count(*) FILTER (WHERE c.activo = 'S'
                          AND (u.ultimo_pedido IS NULL
                               OR u.ultimo_pedido < DATE '2026-09-30' - INTERVAL 90 DAY)) AS marcados_pero_sin_compras
FROM bronze.clientes AS c
LEFT JOIN ultima_compra AS u ON u.cliente_id = c.cliente_id
GROUP BY provincia_limpia
ORDER BY marcados_activos DESC;

-- Segunda vía (silver): clientes reales (fichas maestras) con compras en 90 días.
SELECT c.provincia,
       count(DISTINCT p.cliente_maestro_id) AS clientes_con_compras_90d
FROM silver.pedidos AS p
JOIN silver.clientes AS c ON c.cliente_id = p.cliente_maestro_id
WHERE p.estado <> 'Cancelado'
  AND p.fecha >= DATE '2026-09-30' - INTERVAL 90 DAY
GROUP BY c.provincia
ORDER BY clientes_con_compras_90d DESC;

-- ============================================================
-- RESULTADO (26/10/2026, DuckDB 1.5.6)
--   Provincia   Marcados activos  Compran 90 d  Marcados sin compras  Clientes reales 90 d (silver)
--   Cantabria          663             620              43                    602
--   Asturias           176             166              10                    162
--   Bizkaia            142             135               7                    135
--   Burgos              84              79               5                     76
--   Palencia            60              55               5                     52
--   TOTAL            1.125           1.055              70                  1.027
--
-- Respuesta a Íñigo: en el ERP hay 1.125 fichas marcadas como activas,
-- pero 70 no han comprado nada en los últimos tres meses. Han comprado
-- en los últimos 90 días 1.055 fichas, y es la cifra recomendada.
-- Nota al pie: son fichas, no clientes. Quitando las fichas duplicadas
-- (MJD-205) son 1.027 clientes reales.
-- ============================================================
