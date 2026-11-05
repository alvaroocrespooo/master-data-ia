-- TICKET MJD-406
-- De: Íñigo Sainz · Director comercial
-- Quiero analizar las ventas por gama de precio: básicos (menos de 15 €), gama media (de 15 a 50 €) y
-- premium (más de 50 €), por precio de tarifa. Y lo quiero poder usar en Power BI, no pedírtelo cada vez.
---------------------------

-- La regla vive en gold.dim_producto (columna gama_precio, en sql/03_construir_gold.sql),
-- así Power BI la ve como un atributo más del producto y se cambia en un solo sitio.
-- Así se probó primero como consulta, antes de añadirla a la dimensión:
--   CASE WHEN precio_lista IS NULL THEN 'Desconocida'
--        WHEN precio_lista < 15 THEN '1. Básico'
--        WHEN precio_lista <= 50 THEN '2. Gama media'
--        ELSE '3. Premium' END AS gama_precio

SELECT p.gama_precio,
count(DISTINCT p.producto_key) AS productos,
round(sum(f.importe_neto)) AS ventas_2025,
round(100 * sum(f.importe_neto) / sum(sum(f.importe_neto)) OVER (), 1) AS pct
FROM gold.fact_ventas AS f
JOIN gold.dim_producto AS p ON p.producto_key = f.producto_key
JOIN gold.dim_fecha AS d ON d.fecha_key = f.fecha_key
WHERE d.anio = 2025
GROUP BY p.gama_precio
ORDER BY p.gama_precio;

-- ============================================================
-- RESULTADO (05/11/2026) · ventas 2025
--   1. Básico      66 productos  2.569.360 €  16,4 %
--   2. Gama media 112 productos  8.608.251 €  55,1 %
--   3. Premium     49 productos  4.441.607 €  28,4 %
--   Desconocida     1 producto         158 €   0,0 %
-- Respuesta a Íñigo Sainz: en 2025, la gama media (de 15 a 50 €) hace más de la mitad de
--   las ventas (55,1 %); la premium, el 28,4 %, y la básica, el 16,4 %. La gama ya está en
--   el modelo como columna del producto, así que en Power BI la tendrás como cualquier otro
--   filtro. Dos cosas que decides tú: si 15 € y 50 € van en gama media (ahora sí), y que la
--   gama es la del precio de hoy (si sube un precio, el producto cambia de gama).
-- ============================================================
