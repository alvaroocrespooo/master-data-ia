# Volumen 02 · Respuestas a los tickets

Fecha: 26/10/2026 · Autor: Álvaro · Fecha de corte de los datos: 30/09/2026

Las consultas están en `sql/02-sql-i/`, una por ticket, con su resultado anotado al final. Cada cifra se ha comprobado por una segunda vía con la capa silver.

## MJD-201 · Clientes activos por provincia (Íñigo)

| Provincia | Marcados activos en el ERP | Han comprado en 90 días | Marcados pero sin compras |
|---|---:|---:|---:|
| Cantabria | 663 | 620 | 43 |
| Asturias | 176 | 166 | 10 |
| Bizkaia | 142 | 135 | 7 |
| Burgos | 84 | 79 | 5 |
| Palencia | 60 | 55 | 5 |
| **Total** | **1.125** | **1.055** | **70** |

En el ERP hay 1.125 clientes marcados como activos, pero 70 de ellos no han comprado nada en los últimos tres meses. La cifra recomendada son los **1.055** que sí han comprado en ese tiempo.

*Nota:* son fichas, no clientes. Si se quitan las fichas duplicadas (MJD-205), quedan 1.027 clientes reales con compras en 90 días.

## MJD-202 · Top 10 de productos de 2025 (Íñigo)

Ventas netas de descuentos, por fecha de pedido, sin cancelados, con las devoluciones restadas y sin líneas duplicadas.

| # | SKU | Producto | Formato | Ventas netas 2025 (€) |
|---:|---|---|---|---:|
| 1 | ALI-0001 | Anchoas de Santoña en aceite | Bandeja 12 latas | 1.065.599,02 |
| 2 | VIN-0025 | Bodegas Valle del Nansa Blanco I.G.P. Costa de Cantabria | Caja 6x75 cl | 917.337,46 |
| 3 | VIN-0023 | Bodegas Valle del Nansa Crianza D.O. Ribera del Duero | Caja 6x75 cl | 586.205,99 |
| 4 | VIN-0015 | Hacienda Ruesga Reserva D.O.Ca. Rioja | Caja 6x75 cl | 426.057,45 |
| 5 | REF-0003 | Cola Bahía | Bag-in-box 18 L | 421.423,14 |
| 6 | DES-0001 | Vasos de cartón 25 cl | Caja 1000 uds | 385.835,42 |
| 7 | CER-0066 | Ola Fría Sin alcohol | Caja 24x33 cl lata | 355.647,02 |
| 8 | CER-0020 | Brisa Cantábrica Lager | Barril 30 L | 349.934,30 |
| 9 | DES-0006 | Envases take away cartón | Caja 300 uds | 297.448,77 |
| 10 | REF-0016 | Tónica Brava | Bag-in-box 18 L | 291.850,06 |

## MJD-203 · Clientes dormidos de Cantabria (Raquel)

Excel: `entregables/mjd-203_clientes_dormidos.xlsx`. Son 86 clientes que no piden desde antes del 2 de julio de 2026, ordenados por lo que facturaron en el último año:

- **33 dormidos**: su último pedido es de este último año. Son los que hay que llamar mañana.
- **53 perdidos**: llevan más de un año sin pedir. Con ellos la conversación es otra.
- 42 de los 86 siguen marcados como activos en el ERP.

**Atención:** los dos primeros de la lista son el mismo cliente con dos fichas (10637 y 11193, Supermercado La Fuente, mismo teléfono). Que lo llame una sola persona.

## MJD-204 · Marzo de 2025 no cuadra (Lucía; copia a Íñigo)

| Paso | Importe (€) | Diferencia (€) |
|---|---:|---:|
| 1. Todo lo pedido en marzo (la cifra de Íñigo) | 1.104.552,29 | |
| 2. Sin pedidos cancelados | 1.066.085,78 | −38.466,51 |
| 3. Sin líneas duplicadas (fallo del ERP) | 1.063.694,42 | −2.391,36 |
| 4. Por mes de entrega en vez de mes de pedido | 1.077.305,50 | +13.611,08 |
| 5. Más gastos de envío = **contabilidad** | **1.082.243,50** | +4.938,00 |

Las dos cifras están bien calculadas, pero miden cosas distintas: comercial cuenta lo pedido en el mes y contabilidad lo entregado, con portes.

Por el camino han aparecido dos errores que afectan a los informes comerciales: incluyen los pedidos cancelados y unos 2.400 € de líneas duplicadas por un fallo de sincronización del ERP.

Por provincias, Asturias, Bizkaia, Burgos y Palencia cuadran al céntimo. En Cantabria faltan 6.305,36 €, que son justo los pedidos de los seis clientes borrados del maestro: eran de Cantabria.

**Pendiente para Lucía:**

- Confirmar la provincia de esos seis clientes.
- Hay 14 fechas de entrega con el año mal tecleado, que contabilidad tiene facturadas en el mes equivocado.

## MJD-205 · Fichas de cliente duplicadas (Elena → administración)

Lista completa: `entregables/mjd-205_fichas_duplicadas.xlsx`.

- **37 NIF repetidos**: 74 fichas, de las que sobran 37, con **1.007 pedidos a traspasar**.
- **Propuesta:** conservar la ficha más antigua (el `cliente_id` más bajo, que tiene el historial completo) y fusionar la otra en ella. La fusión se hace en el ERP. En nuestra base no se borra nada: silver ya agrupa cada ficha en su maestra (`cliente_maestro_id`).

## MJD-206 · Plazo de entrega (Marcos)

| Almacén | Pedidos 2026 | Días de media | Entregados en 24 h |
|---|---:|---:|---:|
| Guarnizo | 20.111 | 2,15 | 38,5 % |
| Llanera | 3.891 | 2,16 | 38,1 % |

Mes a mes, los dos almacenes están entre 2,06 y 2,27 días, así que Llanera no es más lento que Guarnizo. Para la queja del cliente de Asturias hay que mirar sus pedidos uno a uno: necesito saber quién es.

Se han excluido las 23 fechas de entrega imposibles. Sin ese filtro, abril en Guarnizo saldría a −40,81 días.

## MJD-207 · Ventas de 2025 por comercial (Íñigo)

| Comercial | T1 | T2 | T3 | T4 | Total 2025 | Pedidos | Ticket medio |
|---|---:|---:|---:|---:|---:|---:|---:|
| Rubén Martín Calvo | 463.175 | 605.168 | 706.552 | 574.394 | 2.349.289 | 3.851 | 610 |
| Raquel Fernández Cobo | 443.809 | 563.584 | 655.773 | 524.090 | 2.187.256 | 3.649 | 599 |
| Pablo Revuelta Gómez | 385.197 | 542.811 | 714.463 | 498.821 | 2.141.292 | 4.040 | 530 |
| Daniel Gutiérrez Pérez | 340.736 | 432.446 | 606.866 | 468.627 | 1.848.675 | 3.168 | 584 |
| Adrián Suárez Fernández | 299.867 | 379.394 | 500.170 | 432.349 | 1.611.782 | 2.167 | 744 |
| Nuria Álvarez Menéndez | 268.434 | 355.033 | 420.369 | 354.943 | 1.398.780 | 2.550 | 549 |
| Sara Ceballos Ortiz | 250.752 | 275.255 | 351.164 | 331.093 | 1.208.264 | 2.328 | 519 |
| Lorena Arce Díaz | 158.982 | 237.914 | 255.111 | 212.608 | 864.615 | 1.795 | 482 |
| Celia Gómez Sáiz | — | — | 392.942 | 319.647 | 712.589 | 1.374 | 519 |
| Héctor Bustamante Lavín | 265.321 | 339.841 | — | — | 605.161 | 1.157 | 523 |
| Mikel Goikoetxea Arana | 7.939 | 51.052 | 146.274 | 180.959 | 386.225 | 618 | 625 |
| Ane Etxeberria Zubiri | 2.125 | 46.002 | 116.202 | 141.118 | 305.448 | 523 | 584 |

Las cifras están en euros, son ventas netas y van sin cancelados. Cada venta se asigna al comercial que figura en el pedido, no al asignado hoy al cliente.

**Notas para la evaluación:**

- La zona condiciona la cifra: no es lo mismo llevar Santander que abrir Bizkaia.
- Héctor (baja el 30/06/2025) y Celia (alta el 16/06/2025) comparten cartera en 2025.
- Ane y Mikel empezaron en febrero y en marzo.

## MJD-208 · Peso de la tienda online (Paula)

| Mes | Web B2B | Comercial | Teléfono |
|---|---:|---:|---:|
| Abril de 2025 | 5,4 % | 65,0 % | 29,6 % |
| Septiembre de 2025 | 12,1 % | 61,6 % | 26,3 % |
| Marzo de 2026 | 17,6 % | 58,6 % | 23,8 % |
| Septiembre de 2026 | 27,6 % | 49,4 % | 23,0 % |

La serie completa, mes a mes, está en `sql/02-sql-i/mjd-208_peso_web.sql`. Lo que gana la web lo pierden sobre todo las visitas comerciales y, en menor medida, el teléfono.

Propuesta de siguiente análisis: ¿los clientes de la web son nuevos o venían del teléfono y del comercial?

## MJD-209 · Stock parado (Marcos; copia a Íñigo)

- **22 artículos** con stock y sin ventas en los últimos 90 días, **todos descatalogados**: 482 unidades, **10.648,52 €** a coste. Liquidarlos o devolverlos al proveedor es una decisión comercial.
- **9 referencias antiguas** (OBS-0001 a OBS-0009, 115 unidades en Guarnizo) no tienen ficha en el ERP. Hay que darlas de alta en el ERP o de baja en el almacén.

## MJD-210 · Capa silver (Elena)

- Construida con `sql/01_construir_silver.sql` y comprobada con `sql/02_comprobar_silver.sql`: las **seis comprobaciones dan `true`**.
- `silver.lineas_pedido` tiene 380.172 líneas: sin duplicados y sin las 36 huérfanas.
- Las reglas de limpieza están en el README.
