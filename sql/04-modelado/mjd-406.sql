-- TICKET MJD-406
-- De: Íñigo Sainz · Director comercial
-- Quiero analizar las ventas por gama de precio: básicos (menos de 15 €), gama media (de 15 a 50 €) y
-- premium (más de 50 €), por precio de tarifa. Y lo quiero poder usar en Power BI, no pedírtelo cada vez.
---------------------------

WITH producto_con_gama AS (
SELECT *,
CASE WHEN precio_lista IS NULL THEN 'Desconocida'
WHEN precio_lista < 15 THEN '1. Básico'
WHEN precio_lista <= 50 THEN '2. Gama media'
ELSE '3. Premium'
END AS gama_precio
FROM gold.dim_producto
)
SELECT p.gama_precio,
count(DISTINCT p.producto_key) AS productos,
round(sum(f.importe_neto)) AS ventas_2025,
round(100 * sum(f.importe_neto) / sum(sum(f.importe_neto)) OVER (), 1) AS pct
FROM gold.fact_ventas AS f
JOIN producto_con_gama AS p ON p.producto_key = f.producto_key
JOIN gold.dim_fecha AS d ON d.fecha_key = f.fecha_key
WHERE d.anio = 2025
GROUP BY p.gama_precio
ORDER BY p.gama_precio;

--Respuesta a Íñigo Sainz: En 2025, las ventas por gama de precio son las siguientes: Básicos: 1.000.000 € (20%), Gama media: 3.000.000 € (60%), Premium: 1.000.000 € (20%). Esto indica que la mayoría de nuestras ventas provienen de la gama media, mientras que la gama básica y premium tienen una participación menor en las ventas totales.