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

-- ============================================================
-- RESULTADO (05/11/2026) · 2025, margen estimado
--   Vinos 1.371.785 € (34,7 %) · Cervezas 804.196 € (25,4 %) · Alimentación 604.726 € (25,5 %)
--   Refrescos 511.936 € (24,4 %) · Desechables 351.532 € (35,6 %) · Licores 334.410 € (35,3 %)
--   Café e infusiones 312.157 € (37,5 %) · Limpieza 214.286 € (32,5 %) · Aguas 185.137 € (30,1 %)
-- Respuesta a Íñigo Sainz: AVISO, es un margen estimado con el coste de compra actual
--   (2026); para 2025 sale algo subestimado. Donde más dinero ganamos en euros es en vinos
--   (1,37 M€, un 34,7 %), y después cervezas (0,80 M€), pero la cerveza deja solo un 25,4 %.
--   Los porcentajes más altos son café (37,5 %), desechables (35,6 %) y licores (35,3 %),
--   con ventas mucho menores. Para el margen real hace falta el historial de costes de Compras.
-- ============================================================
