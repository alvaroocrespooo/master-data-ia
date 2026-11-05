# Máster Data & IA
Mi formación en ingeniería de datos e IA: SQL, Python, Power BI,
Microsoft Fabric, Databricks, AWS, machine learning, deep learning
e IA generativa, con cuatro certificaciones oficiales como objetivo.
Todo el trabajo se hace sobre los datos de una empresa ficticia,
Marejada Distribución, S.L., una distribuidora de bebidas y
alimentación para hostelería en el norte de España.

## Estructura
- `sql/` — consultas, una carpeta por volumen, y los scripts de las capas (`00_` a `04_`)
- `scripts/` — programas de Python y el script de reconstrucción de la base
- `notebooks/` — análisis en Python
- `entregables/` — resultados entregados en cada ticket

## Cómo reproducirlo
1. `uv sync` para crear el entorno de Python (DuckDB 1.5.6, pandas, Jupyter).
2. Copiar los datos de la empresa en `datos/`.
3. `./scripts/reconstruir_bd.sh`: crea `db/marejada.duckdb` desde cero
   (bronze → silver → gold) y pasa las 13 comprobaciones (6 de silver y 7 de gold).

## Versiones
- **Python:** DuckDB 1.5.6, la versión con la que están hechos los volúmenes.
- **Terminal:** Homebrew instala DuckDB 2.0. Lee y escribe sin problema una base creada
  con la 1.5, pero si crea una base nueva la deja en un formato que el Python 1.5.6 no
  puede abrir. Por eso la base se reconstruye siempre con `scripts/reconstruir_bd.sh`,
  nunca con `rm` + `duckdb` a mano.

## Problemas frecuentes
- **`Could not set lock on file`**: la base está abierta en otro programa (otra pestaña
  con DuckDB o un notebook). Sal con `.quit` o reinicia el kernel. Solo para consultar,
  abre en modo lectura: `duckdb -readonly db/marejada.duckdb`.
- **`No files found that match the pattern "datos/..."`**: has abierto DuckDB desde otra
  carpeta. Lánzalo siempre desde la raíz del repo: `cd ~/master-data-ia`.
- **La base sale vacía**: has escrito `duckdb marejada.duckdb` sin `db/` y DuckDB ha creado
  una base nueva vacía. Bórrala y abre `db/marejada.duckdb`.

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
