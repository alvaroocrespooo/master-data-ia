------------------------------------------------------
-- Para el comité: los 5 mejores clientes de cada provincia en los últimos 12 meses, 
-- con lo que (pesa)
-- cada uno dentro de su provincia. Si alguno se nos va, quiero saber cuánto nos duele. ($)
-- CRITERIOS DE ACEPTACIÓN:
-- Cinco filas por provincia, con el puesto, el nombre del cliente, sus ventas y su porcentaje sobre las ventas de la provincia.
-- Clientes reales: las fichas duplicadas, sumadas.
-------------------------------------------------------

WITH ventas_cliente AS (
SELECT c.provincia, c.cliente_id, c.nombre_comercial,
sum(l.importe_neto) AS ventas
FROM silver.pedidos AS p
JOIN silver.lineas_pedido AS l ON l.pedido_id = p.pedido_id
JOIN silver.clientes AS c ON c.cliente_id = p.cliente_maestro_id
WHERE p.estado <> 'Cancelado'
AND p.fecha > DATE '2026-09-30' - INTERVAL 1 YEAR
GROUP BY c.provincia, c.cliente_id, c.nombre_comercial
)
SELECT provincia,
rank() OVER (PARTITION BY provincia ORDER BY ventas DESC) AS puesto,
nombre_comercial,
round(ventas) AS ventas,
round(100 * ventas / sum(ventas) OVER (PARTITION BY provincia), 1) AS pct_provincia
FROM ventas_cliente
QUALIFY puesto <= 5
ORDER BY provincia, puesto;

-- ============================================================
│ provincia │ puesto │     nombre_comercial     │  ventas  │ pct_provincia │
│  varchar  │ int64  │         varchar          │  double  │    double     │
├───────────┼────────┼──────────────────────────┼──────────┼───────────────┤
│ Asturias  │      1 │ Supermercado La Sidra    │ 388548.0 │          11.7 │
│ Asturias  │      2 │ Hotel La Judería         │ 195750.0 │           5.9 │
│ Asturias  │      3 │ Supermercado La Rula     │ 157043.0 │           4.7 │
│ Asturias  │      4 │ Supermercado El Mercado  │ 138296.0 │           4.2 │
│ Asturias  │      5 │ Supermercado Bitácora    │ 115784.0 │           3.5 │
│ Bizkaia   │      1 │ Hotel Albatros           │ 143195.0 │           7.3 │
│ Bizkaia   │      2 │ Supermercado La Montaña  │  98620.0 │           5.0 │
│ Bizkaia   │      3 │ Supermercado Los Arcos   │  81705.0 │           4.2 │
│ Bizkaia   │      4 │ Supermercado El Cid      │  81232.0 │           4.2 │
│ Bizkaia   │      5 │ Hotel La Muralla         │  71659.0 │           3.7 │
│ Burgos    │      1 │ Hotel Mareas             │ 130249.0 │           7.8 │
│ Burgos    │      2 │ Supermercado Arena       │ 123428.0 │           7.4 │
│ Burgos    │      3 │ Supermercado Bitácora    │ 115910.0 │           6.9 │
│ Burgos    │      4 │ Supermercado La Montaña  │  88471.0 │           5.3 │
│ Burgos    │      5 │ Supermercado La Taberna  │  73039.0 │           4.4 │
│ Cantabria │      1 │ Supermercado Los Arcos   │ 168611.0 │           1.6 │
│ Cantabria │      2 │ Supermercado Los Pinares │ 163458.0 │           1.6 │
│ Cantabria │      3 │ Supermercado Velero      │ 128407.0 │           1.2 │
│ Cantabria │      4 │ Supermercado El Ancla    │ 116815.0 │           1.1 │
│ Cantabria │      5 │ Supermercado Nautilus    │ 115321.0 │           1.1 │
│ Palencia  │      1 │ Supermercado Duna        │ 133309.0 │          14.3 │
│ Palencia  │      2 │ Supermercado La Ría      │  86077.0 │           9.2 │
│ Palencia  │      3 │ Hotel El Abra            │  62956.0 │           6.7 │
│ Palencia  │      4 │ Hotel Los Pinares II     │  51791.0 │           5.6 │
│ Palencia  │      5 │ Hotel La Estación        │  46575.0 │           5.0 │
└───────────┴────────┴──────────────────────────┴──────────┴───────────────┘
-- ============================================================