-- TICKET MJD-408 Prioridad: media
-- De: Carmen Ruiz · Directora general
-- En un informe he visto una fila que pone "Cliente desconocido". ¿Qué es eso, cuánto dinero es y qué va‐
-- mos a hacer?
---------------------------

SELECT d.anio,
count(DISTINCT f.pedido_id) AS pedidos,
round(sum(f.importe_neto), 2) AS ventas
FROM gold.fact_ventas AS f
JOIN gold.dim_fecha AS d ON d.fecha_key = f.fecha_key
WHERE f.cliente_key = -1
GROUP BY d.anio
ORDER BY d.anio;

SELECT round(100 * sum(importe_neto) FILTER (WHERE cliente_key = -1) / sum(importe_neto), 2) AS
pct_ventas_sin_cliente
FROM gold.fact_ventas;

-- La respuesta a Carmen: "Son ventas reales a seis clientes de Cantabria que dejaron de comprar y que al‐
-- guien borró del sistema de clientes. Suman unos 126.000 € desde 2024, el 0,3 % de las ventas, y en 2026 ya
-- no hay ninguna. No se ha perdido dinero: se ha perdido la ficha. Lucía tiene sus datos, y vamos a recuperar‐
-- los."
-- El "vamos a recuperarlos" es un plan concreto: pedir a Lucía los datos de los seis clientes, añadirlos a silver
-- como una tabla de correspondencias (como las de provincias), y reconstruir. Los pedidos dejarán de apuntar
-- a -1 y la fila "Cliente desconocido" desaparecerá de los informes.