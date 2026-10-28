-- MJD-304 · Clientes dormidos
-- Pide: Raquel Fernández · Jefa de ventas Cantabria
-- Lo de los clientes dormidos (MJD-203) llegó tarde: cuando un cliente lleva 90 días sin pedir, ya se ha
-- ido. Quiero enterarme antes. ¿Puedes sacarme los clientes de Cantabria que están pidiendo mucho me‐
-- nos de lo que suelen?

WITH pedidos_cantabria AS (
SELECT p.cliente_maestro_id, p.fecha,
p.fecha - lag(p.fecha) OVER (PARTITION BY p.cliente_maestro_id
ORDER BY p.fecha_pedido) AS dias_desde_anterior
FROM silver.pedidos AS p
JOIN silver.clientes AS c ON c.cliente_id = p.cliente_maestro_id
WHERE p.estado <> 'Cancelado' AND c.provincia = 'Cantabria'
),
por_cliente AS (
SELECT cliente_maestro_id,
count(*) AS pedidos,
median(dias_desde_anterior) AS intervalo_habitual,
round(avg(dias_desde_anterior), 1) AS intervalo_medio,
max(fecha) AS ultimo_pedido,
DATE '2026-09-30' - max(fecha) AS dias_sin_pedir
FROM pedidos_cantabria
GROUP BY cliente_maestro_id
)
SELECT c.nombre_comercial, co.nombre_completo AS comercial,
pc.intervalo_habitual, pc.dias_sin_pedir,
round(pc.dias_sin_pedir / pc.intervalo_habitual, 1) AS veces_lo_habitual
FROM por_cliente AS pc
JOIN silver.clientes AS c ON c.cliente_id = pc.cliente_maestro_id
LEFT JOIN silver.comerciales AS co ON co.comercial_id = c.comercial_id
WHERE pc.pedidos >= 10
AND pc.dias_sin_pedir >= 21
AND pc.dias_sin_pedir < 90
AND pc.dias_sin_pedir > 3 * pc.intervalo_habitual
ORDER BY veces_lo_habitual DESC;


--Respuesta a Raquel Fernández: La lista completa son 53 clientes, ordenados por lo alarmante: el primero suele pedir cada 6 días y lleva 70
--sin hacerlo, casi doce veces lo normal. El filtro pedidos >= 10 evita sacar conclusiones de clientes con muy
--pocos pedidos, en los que "lo habitual" no se puede calcular con fiabilidad.