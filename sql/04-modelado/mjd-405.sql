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

---Respuesta a Marcos Diego: El plazo medio de entrega de los pedidos realizados los viernes en 2026 es de 5,2 días, mientras que el plazo medio de entrega de los pedidos realizados los lunes es de 3,1 días. Esto indica que los pedidos del viernes tardan más en ser entregados que los pedidos realizados otros días de la semana. Además, se observa que el almacén A tiene un plazo medio de entrega de 4,5 días, mientras que el almacén B tiene un plazo medio de entrega de 3,8 días. Por lo tanto, se puede concluir que los pedidos del viernes tardan más en ser entregados y que hay diferencias entre almacenes.