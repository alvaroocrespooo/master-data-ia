# Inventario de datos · capa bronze

Fecha: 19/10/2026 · Autor: Álvaro

| Tabla          | Filas   | Columnas | Origen                   |
|----------------|---------|----------|--------------------------|
| clientes       | 1.212   | 15       | ERP                      |
| comerciales    | 14      | 9        | RRHH                     |
| inventario     | 381     | 6        | Almacén                  |
| lineas_pedido  | 381.158 | 7        | ERP                      |
| pedidos        | 77.448  | 10       | ERP                      |
| productos      | 235     | 13       | ERP                      |

- Pedidos del ERP: del 01/01/2024 al 30/09/2026.
- Tienda web (JSON, aún sin cargar): 7.956 pedidos,
  del 07/04/2025 al 30/09/2026 (horas en UTC).