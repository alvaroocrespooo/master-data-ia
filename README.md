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

## Datos
Los datos son de Marejada Distribución (empresa ficticia) y no se
suben al repositorio. Llegan de cinco sistemas:
- **ERP** (`datos/erp/`): clientes, productos, pedidos y líneas.
CSV con separador `;`, coma decimal y fechas dd/mm/aaaa.
- **RRHH** (`datos/rrhh/`): comerciales. CSV en Latin-1.
- **Almacén** (`datos/almacen/`): inventario a 30/09/2026. CSV estándar.
- **Contabilidad** (`datos/contabilidad/`): facturación mensual en Excel.
- **Tienda web** (`datos/web/`): pedidos online en JSON anidado, horas en UTC.
La capa `bronze` se carga con `sql/00_cargar_bronze.sql`