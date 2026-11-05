-- TICKET MJD-405
-- De: Marcos Diego · Logística y almacén
-- Los clientes se quejan de que los pedidos del viernes tardan mucho. ¿Es verdad? Plazo medio por día de
-- la semana en que se hace el pedido, en 2026, y si cambia entre almacenes.
--------------------------

SELECT f.almacen,
d.nombre_dia AS dia_del_pedido,
count(*) AS pedidos,
round(avg(f.dias_entrega), 2) AS dias_medios
FROM gold.fact_pedidos AS f
JOIN gold.dim_fecha AS d ON d.fecha_key = f.fecha_key
WHERE d.anio = 2026
AND f.fecha_entrega_key IS NOT NULL
GROUP BY f.almacen, d.dia_semana, d.nombre_dia
ORDER BY f.almacen, d.dia_semana;

-- ============================================================
-- RESULTADO (05/11/2026) · 2026
--   Guarnizo: lunes 1,64 · martes 1,66 · miércoles 2,02 · jueves 2,50 · viernes 3,00 · sábado 2,18 días
--   Llanera:  lunes 1,66 · martes 1,66 · miércoles 2,01 · jueves 2,53 · viernes 3,00 · sábado 2,15 días
-- Respuesta a Marcos Diego: sí, lo pedido en viernes tarda 3 días de media frente a 1,6 lo
--   del lunes, y pasa igual en los dos almacenes. La causa es que no se reparte el fin de
--   semana: lo del viernes llega el lunes. En días laborables, el viernes tarda como los
--   demás. Hay dos opciones y la decisión es tuya: avisar a los clientes o repartir los
--   sábados. Para decidir: en 2026 entraron 4.263 pedidos en viernes (3.557 en Guarnizo y
--   706 en Llanera).
-- ============================================================
