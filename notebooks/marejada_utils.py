#Utilidades de Marejada: funciones que se usan en varios notebooks.
from decimal import Decimal

FECHA_CORTE = "2026-09-30"

def normalizar_sku(sku: str) -> str:
	#Devuelve el SKU en el formato del maestro: CER-0001.
	limpio = sku.strip().upper().replace("-", "")
	return limpio[:3] + "-" + limpio[3:]

def a_decimal(texto: str) -> Decimal:
	#Convierte un importe del ERP ('41,65') en Decimal."""
	return Decimal(texto.strip().replace(",", "."))
