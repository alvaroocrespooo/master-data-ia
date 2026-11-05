-- TICKET MJD-403
-- De: Raquel Fernández · Jefa de ventas Cantabria
-- Celia lleva un año con la cartera de Héctor. ¿Vende esa cartera más o menos que cuando la llevaba él?
-- Compárame el primer semestre de 2025 (Héctor) con el primer semestre de 2026 (Celia).
-------------------------

WITH clientes_de_celia AS (
SELECT cliente_id
FROM gold.dim_cliente
WHERE es_version_actual AND comercial_asignado_id = 13
)
SELECT d.anio,
c.comercial_asignado,
count(DISTINCT c.cliente_id) AS clientes_con_compras,
round(sum(f.importe_neto)) AS ventas_semestre
FROM gold.fact_ventas AS f
JOIN gold.dim_cliente AS c ON c.cliente_key = f.cliente_key
JOIN gold.dim_fecha AS d ON d.fecha_key = f.fecha_key
WHERE c.cliente_id IN (SELECT cliente_id FROM clientes_de_celia)
AND d.mes <= 6 AND d.anio IN (2025, 2026)
GROUP BY d.anio, c.comercial_asignado
ORDER BY d.anio;

--------------------------

SELECT d.anio,
c.comercial_asignado,
count(DISTINCT c.cliente_id) AS clientes_con_compras,
round(sum(f.importe_neto)) AS ventas_semestre
FROM gold.fact_ventas AS f
JOIN gold.dim_cliente AS c ON c.cliente_key = f.cliente_key
JOIN gold.dim_fecha AS d ON d.fecha_key = f.fecha_key
WHERE c.comercial_asignado_id IN (7, 13)
AND d.mes <= 6 AND d.anio IN (2025, 2026)
GROUP BY d.anio, c.comercial_asignado
ORDER BY d.anio;

-- ============================================================
-- RESULTADO (05/11/2026) · las dos consultas dan lo mismo
--   1.er semestre 2025, Héctor Bustamante: 86 clientes con compras, 596.416 €
--   1.er semestre 2026, Celia Gómez:       88 clientes con compras, 622.559 €  (+4,4 %)
-- Respuesta a Raquel Fernández: la cartera vende un 4,4 % más con Celia (622.559 €)
--   que con Héctor el año anterior (596.416 €), con dos clientes más comprando (88 frente
--   a 86). Las dos formas de mirarlo (los mismos clientes, o la cartera de cada uno en su
--   momento) dan exactamente lo mismo, porque toda la cartera de Héctor pasó a Celia.
--   Ojo antes de evaluar a nadie: las ventas de Cantabria crecen bastante más entre esos
--   dos semestres, así que la comparación justa es con las demás carteras de Cantabria
--   Occidental, no con la cifra sola.
-- ============================================================
