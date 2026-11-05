# Ventas de una semana por canal, comparadas con la misma semana del año anterior.
# Uso (desde la raíz del repo): uv run python scripts/informe_semana.py 2026-09-21

import argparse
import datetime as dt

import duckdb

CONSULTA = """
SELECT f.canal, round(sum(f.importe_neto), 2) AS ventas
FROM gold.fact_ventas AS f
JOIN gold.dim_fecha AS d ON d.fecha_key = f.fecha_key
WHERE d.fecha BETWEEN ? AND ?
GROUP BY f.canal
"""


def ventas_por_canal(con, lunes):
    domingo = lunes + dt.timedelta(days=6)
    return dict(con.execute(CONSULTA, [lunes, domingo]).fetchall())


def main():
    parser = argparse.ArgumentParser(description="Informe semanal de ventas por canal.")
    parser.add_argument("lunes", help="Lunes de la semana, en formato AAAA-MM-DD")
    args = parser.parse_args()

    lunes = dt.date.fromisoformat(args.lunes)
    if lunes.isoweekday() != 1:
        parser.error(f"{lunes} no es lunes")
    # el lunes de la misma semana ISO del año anterior
    anio, semana, _ = lunes.isocalendar()
    lunes_anterior = dt.date.fromisocalendar(anio - 1, semana, 1)

    con = duckdb.connect("db/marejada.duckdb", read_only=True)
    actual = ventas_por_canal(con, lunes)
    anterior = ventas_por_canal(con, lunes_anterior)
    con.close()

    print(f"Semana {semana} de {anio} (del {lunes:%d/%m} al {lunes + dt.timedelta(days=6):%d/%m})")
    print(f"comparada con la semana {semana} de {anio - 1} (desde el {lunes_anterior:%d/%m/%Y})\n")
    print(f"{'Canal':<12}{'Ventas':>14}{'Año anterior':>16}{'Variación':>12}")

    for canal in sorted(set(actual) | set(anterior)):
        v, a = actual.get(canal, 0), anterior.get(canal, 0)
        variacion = f"{100 * (v / a - 1):+.1f} %" if a else "nuevo"
        print(f"{canal:<12}{v:>14,.2f}{a:>16,.2f}{variacion:>12}")

    v, a = sum(actual.values()), sum(anterior.values())
    print(f"{'Total':<12}{v:>14,.2f}{a:>16,.2f}{100 * (v / a - 1):>+10.1f} %")


if __name__ == "__main__":
    main()
