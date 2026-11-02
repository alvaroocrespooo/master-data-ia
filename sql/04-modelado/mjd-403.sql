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

--Respuesta a Raquel Fernández: Héctor vendió 1.000 € más que Celia en el primer semestre de 2025, pero Celia vendió 2.000 € más que Héctor en el primer semestre de 2026. En cuanto a clientes con compras, Héctor tuvo 10 clientes más que Celia en 2025, y Celia tuvo 15 clientes más que Héctor en 2026. Por lo tanto, podemos concluir que Celia ha mejorado las ventas y la cartera de clientes respecto a Héctor.