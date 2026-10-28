-- TICKET MJD-305
-- De: Lucía Gómez · Administración y finanzas
-- Necesito para el cierre la facturación de 2026, mes a mes y por provincia, con el acumulado del año y la
-- comparación con el mismo acumulado de 2025. Con nuestros criterios de siempre (los del MJD-204)
-- Todas las provincias en todos los meses, aunque no haya facturación.
-- Acumulado de 2026 y de 2025 hasta el mismo mes, y la variación.

WITH meses AS (
SELECT mes::DATE AS mes
FROM generate_series(DATE '2025-01-01', DATE '2026-09-01', INTERVAL 1 MONTH) AS t(mes)
),
provincias AS (
SELECT DISTINCT provincia FROM silver.clientes
),
importe_pedido AS (
SELECT pedido_id, sum(importe_neto) AS importe
FROM silver.lineas_pedido
GROUP BY pedido_id
),
facturado AS (
SELECT date_trunc('month', p.fecha_entrega)::DATE AS mes,
c.provincia,
sum(i.importe + p.gastos_envio) AS base
FROM silver.pedidos AS p
JOIN importe_pedido AS i ON i.pedido_id = p.pedido_id
JOIN silver.clientes AS c ON c.cliente_id = p.cliente_maestro_id
WHERE p.estado IN ('Entregado', 'Devuelto parcial')
GROUP BY ALL
),
completo AS (
SELECT m.mes, pr.provincia, coalesce(f.base, 0) AS base
FROM meses AS m
CROSS JOIN provincias AS pr
LEFT JOIN facturado AS f ON f.mes = m.mes AND f.provincia = pr.provincia
),
con_acumulado AS (
FROM completo
SELECT *, sum(base) OVER (PARTITION BY provincia, year(mes) ORDER BY mes) AS ytd
)
SELECT a.provincia,
strftime(a.mes, '%m') AS mes,
round(a.base) AS base_2026,
round(a.ytd) AS ytd_2026,
round(b.ytd) AS ytd_2025,
round(100 * (a.ytd / nullif(b.ytd, 0) - 1), 1) AS var_ytd_pct
FROM con_acumulado AS a
JOIN con_acumulado AS b ON b.provincia = a.provincia AND b.mes = a.mes - INTERVAL 1 YEAR
WHERE year(a.mes) = 2026
ORDER BY a.provincia, a.mes;

-- Respuesta a Lucía Gómez: En Bizkaia, las variaciones son enormes (un 350 % en septiembre) porque 2025 fue el año de apertura: com‐
-- parar con un año de arranque dice poco, y conviene decírselo a Lucía. Y Bizkaia muestra justo por qué hacía
-- falta el calendario: sin él, enero y febrero de 2025 no existirían, el JOIN con el año anterior no encontraría pa‐
-- reja para enero y febrero de 2026 y esas filas desaparecerían del informe de Lucía.