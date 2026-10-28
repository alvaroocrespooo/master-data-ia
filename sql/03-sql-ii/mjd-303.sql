-- MJD-303 · ¿Qué ha pasado en septiembre?
-- Pide: Carmen Ruiz · Directora General
--He visto en el informe que en septiembre solo hemos crecido un 6,6 % frente al año pasado, cuando
--todo el año vamos por encima del 20 %. ¿Ha pasado algo? Una frase y la cifra que lo demuestre.
-------------------------------------------------------------------------------------------

WITH ventas_mes AS (
SELECT date_trunc('month', p.fecha)::DATE AS mes, sum(l.importe_neto) AS ventas
FROM silver.pedidos AS p
JOIN silver.lineas_pedido AS l ON l.pedido_id = p.pedido_id
WHERE p.estado <> 'Cancelado'
GROUP BY mes
)
SELECT a.mes,
round(a.ventas) AS ventas,
round(100 * (a.ventas / b.ventas - 1), 1) AS vs_anio_anterior_pct,
round(100 * (a.ventas / c.ventas - 1), 1) AS vs_hace_dos_anios_pct
FROM ventas_mes AS a
LEFT JOIN ventas_mes AS b ON b.mes = a.mes - INTERVAL 1 YEAR
LEFT JOIN ventas_mes AS c ON c.mes = a.mes - INTERVAL 2 YEAR
WHERE month(a.mes) IN (7, 8, 9)
ORDER BY a.mes;


--Respuesta a Carmen Ruiz: No ha pasado nada en septiembre de 2026: es que septiembre de 2025 fue excepcional (+35,8 %). 
--Frente a 2024, septiembre crece un 44,8 %, igual que julio y agosto.