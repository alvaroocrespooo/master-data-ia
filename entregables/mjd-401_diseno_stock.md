# Diseño · fact_stock
Proceso: el inventario de los almacenes.
Tipo: foto periódica (periodic snapshot), una foto por día.
## Grano
Una fila es: las unidades de un producto en un almacén al cierre de un día.
## Dimensiones
- dim_fecha (el día de la foto)
- dim_producto
- almacén: dimensión degenerada (Guarnizo, Llanera)
## Medidas
- unidades: SEMIADITIVA. Se suma entre productos y almacenes,
nunca entre días. Para un mes: la del último día (o la media).
- valor_coste = unidades × coste: igual que unidades.
## Decisiones pendientes
- Origen: hoy solo existe el inventario del 30/09/2026. Para tener
una foto diaria hace falta que el programa de almacén la exporte
cada noche.
- SKU sin producto en el ERP (9 OBS-xxxx): producto_key = -1.