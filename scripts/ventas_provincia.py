#Ventas de una provincia en un año, desde gold.
#Uso: uv run python scripts/ventas_provincia.py Cantabria --anio 2025

import argparse

import duckdb

def main():
	parser = argparse.ArgumentParser(description="Ventas de una provincia en un año.")
	parser.add_argument("provincia", help="Provincia, como en dim_cliente (p. ej. Cantabria)")
	parser.add_argument("--anio", type=int, default=2026, help="Año (por defecto, 2026)")
	args = parser.parse_args()
	
	con = duckdb.connect("db/marejada.duckdb", read_only=True)
	ventas, = con.execute("""
SELECT round(sum(f.importe_neto), 2)
FROM gold.fact_ventas AS f
JOIN gold.dim_cliente AS c ON c.cliente_key = f.cliente_key
JOIN gold.dim_fecha AS d ON d.fecha_key = f.fecha_key
WHERE c.provincia = ? AND d.anio = ?
""", [args.provincia, args.anio]).fetchone()
	con.close()
	
	if ventas is None:
		print(f"No hay ventas de {args.provincia} en {args.anio}.")
	else:
		print(f"{args.provincia} {args.anio}: {ventas:,.2f} €")
		
if __name__ == "__main__":
	main()