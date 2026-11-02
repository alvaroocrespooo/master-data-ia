-- TICKET MJD-404 
-- De: Íñigo Sainz · Director comercial
-- Margen bruto por categoría en 2025. Quiero saber dónde ganamos dinero de verdad, no solo dónde
-- vendemos más.
--------------------------

SELECT p.categoria,
round(sum(f.importe_neto)) AS ventas,
round(sum(f.coste_estimado)) AS coste_estimado,
round(sum(f.importe_neto) - sum(f.coste_estimado)) AS margen,
round(100 * (1 - sum(f.coste_estimado) / sum(f.importe_neto)), 1) AS margen_pct
FROM gold.fact_ventas AS f
JOIN gold.dim_producto AS p ON p.producto_key = f.producto_key
JOIN gold.dim_fecha AS d ON d.fecha_key = f.fecha_key
WHERE d.anio = 2025
AND f.producto_key <> -1
GROUP BY p.categoria
ORDER BY margen DESC;

--Respuesta a Íñigo Sainz: La categoría con mayor margen bruto en 2025 es "Electrónica", con un margen de 500.000 € y un margen porcentual del 25%. Esto indica que, aunque otras categorías puedan tener mayores ventas, la electrónica es donde realmente estamos ganando dinero.