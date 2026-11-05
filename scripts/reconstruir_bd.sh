#!/bin/zsh
# ============================================================
# Reconstruye db/marejada.duckdb desde cero: bronze → silver → gold,
# con las comprobaciones de silver (6) y de gold (7).
# Uso, desde cualquier carpeta:  ~/master-data-ia/scripts/reconstruir_bd.sh
#
# Por qué existe: la terminal de DuckDB de Homebrew es la 2.0 y crea las bases
# en un formato nuevo que el DuckDB de Python del proyecto (1.5.6, el de los
# volúmenes) no puede abrir. El script crea primero el fichero con Python, en
# el formato 1.5, y después lo rellena con la terminal. Así lo leen los dos.
# ============================================================
set -e
cd "$(dirname "$0")/.."
BD=db/marejada.duckdb

# 1. Nadie puede tener la base abierta (DuckDB en otra pestaña, un notebook...)
if [ -f "$BD" ] && lsof "$BD" >/dev/null 2>&1; then
  echo "La base está abierta en otro programa. Ciérralo antes de reconstruir:"
  lsof "$BD" | awk 'NR>1 {print "  PID " $2 " · " $1}' | sort -u
  echo "(en DuckDB: .quit · en un notebook: Restart del kernel)"
  exit 1
fi

# 2. Borrar la base anterior y crearla vacía en formato 1.5 con el Python del proyecto
mkdir -p db
rm -f "$BD" "$BD.wal"
.venv/bin/python -c "import duckdb; duckdb.connect('$BD').close()"

# 3. Cargar las tres capas y comprobarlas
inicio=$(date +%s)
for s in 00_cargar_bronze 01_construir_silver 02_comprobar_silver 03_construir_gold 04_comprobar_gold; do
  echo "→ sql/$s.sql"
  duckdb "$BD" < "sql/$s.sql"
done
echo "Base reconstruida en $(( $(date +%s) - inicio )) s. Revisa que salgan 13 true (6 de silver y 7 de gold)."
