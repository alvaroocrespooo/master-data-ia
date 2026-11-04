#Resumen de ventas por año desde la capa gold.
#Uso: uv run python scripts/resumen_ventas.py

import duckdb
RUTA_BD = "db/marejada.duckdb"
def ventas_por_anio(con):
	return con.sql("""
	    SELECT d.anio, round(sum(f.importe_neto)) AS ventas
	    FROM gold.fact_ventas AS f
	    JOIN gold.dim_fecha AS d ON d.fecha_key = f.fecha_key
	    GROUP BY d.anio
	    ORDER BY d.anio
	""").fetchall()

def main():
	con = duckdb.connect(RUTA_BD, read_only=True)
	for anio, ventas in ventas_por_anio(con):
		print(f"{anio}: {ventas:>14,.0f} €")
	con.close()
if __name__ == "__main__":
	main()