# Máster Data & IA
Mi formación en ingeniería de datos e IA: SQL, Python, Power BI,
Microsoft Fabric, Databricks, AWS, machine learning, deep learning
e IA generativa, con cuatro certificaciones oficiales como objetivo.
Todo el trabajo se hace sobre los datos de una empresa ficticia,
Marejada Distribución, S.L., una distribuidora de bebidas y
alimentación para hostelería en el norte de España.

## Estructura
- `sql/` — consultas, una carpeta por volumen
- `notebooks/` — análisis en Python
- `entregables/` — resultados entregados en cada ticket

## Cómo reproducirlo
1. `uv sync` para crear el entorno de Python.
2. Copiar los datos de la empresa en `datos/`.
3. `duckdb db/marejada.duckdb < sql/00_cargar_bronze.sql`
4. `duckdb db/marejada.duckdb < sql/01_construir_silver.sql`
5. `duckdb -readonly db/marejada.duckdb < sql/02_comprobar_silver.sql` (seis `true`)

## Datos
Los datos son de Marejada Distribución (empresa ficticia) y no se
suben al repositorio. Llegan de cinco sistemas:
- **ERP** (`datos/erp/`): clientes, productos, pedidos y líneas.
CSV con separador `;`, coma decimal y fechas dd/mm/aaaa.
- **RRHH** (`datos/rrhh/`): comerciales. CSV en Latin-1.
- **Almacén** (`datos/almacen/`): inventario a 30/09/2026. CSV estándar.
- **Contabilidad** (`datos/contabilidad/`): facturación mensual en Excel.
- **Tienda web** (`datos/web/`): pedidos online en JSON anidado, horas en UTC.

La capa `bronze` se carga con `sql/00_cargar_bronze.sql`.

## Capa silver: reglas de limpieza

La capa `silver` se construye con `sql/01_construir_silver.sql` y se comprueba con `sql/02_comprobar_silver.sql`. Bronze no se modifica nunca.

| Problema | Regla en silver |
|---|---|
| Provincias escritas de muchas formas | Normalizadas con `silver.map_provincias`. Lo que no encaje: `REVISAR`. "Santander" cuenta como Cantabria. |
| Fichas de cliente duplicadas | Se conservan todas, con `cliente_maestro_id` (la ficha más antigua del mismo NIF) y `es_ficha_duplicada`. |
| NIF, CP, teléfono, email | NIF sin guiones ni espacios y en mayúsculas; CP de 5 cifras como texto; teléfono de 9 cifras; email en minúsculas y vacío si no es válido. |
| Categorías de producto mal escritas | Normalizadas con `silver.map_categorias`. |
| Líneas duplicadas | Se quita la repetición. |
| Líneas de pedidos que no existen | Excluidas. |
| Pedidos de clientes borrados del maestro | Se conservan, con `cliente_maestro_id` vacío. |
| Fechas de entrega imposibles | `NULL` y el pedido marcado con `entrega_sospechosa = true`. |
| SKU del inventario | Al formato del maestro (`CER-0001`), con su `producto_id`. |
| Importes | Precios en `DECIMAL`; `importe_neto` de cada línea calculado una vez. |

Reglas decididas por Elena Pérez (responsable de datos), 26/10/2026.
