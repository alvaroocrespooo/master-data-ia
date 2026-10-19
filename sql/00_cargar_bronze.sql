-- ============================================================
-- Carga de la capa BRONZE de Marejada Distribución
-- Copia fiel de los ficheros de origen, solo con los tipos
-- bien leídos. Aquí no se corrige ningún dato.
-- Uso: duckdb db/marejada.duckdb < sql/00_cargar_bronze.sql
-- ============================================================
CREATE SCHEMA IF NOT EXISTS bronze;
-- ERP: separador ";" y coma decimal
CREATE OR REPLACE TABLE bronze.clientes AS
SELECT * FROM read_csv('datos/erp/clientes.csv',
delim = ';', decimal_separator = ',');
CREATE OR REPLACE TABLE bronze.productos AS
SELECT * FROM read_csv('datos/erp/productos.csv',
delim = ';', decimal_separator = ',');
-- Los pedidos traen las fechas en formato español
CREATE OR REPLACE TABLE bronze.pedidos AS
SELECT * FROM read_csv('datos/erp/pedidos.csv',
delim = ';', decimal_separator = ',',
timestampformat = '%d/%m/%Y %H:%M', dateformat = '%d/%m/%Y');
CREATE OR REPLACE TABLE bronze.lineas_pedido AS
SELECT * FROM read_csv('datos/erp/lineas_pedido.csv',
delim = ';', decimal_separator = ',');
-- RRHH: programa antiguo, codificación Latin-1
CREATE OR REPLACE TABLE bronze.comerciales AS
SELECT * FROM read_csv('datos/rrhh/comerciales.csv',
encoding = 'latin-1');
-- Almacén: CSV estándar
CREATE OR REPLACE TABLE bronze.inventario AS
SELECT * FROM read_csv('datos/almacen/inventario_2026-09-30.csv');