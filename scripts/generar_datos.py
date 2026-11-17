"""
Genera datos sintéticos de una operación logística (pedidos, líneas, clientes,
productos y almacenes) y los escribe como CSV en data/raw/.

Los datos incluyen a propósito algunos problemas típicos de los sistemas de
origen (duplicados, mayúsculas/espacios inconsistentes, cantidades en cero,
fechas faltantes) para que la capa staging de dbt los resuelva.

Uso:
    python scripts/generar_datos.py [--pedidos 20000] [--semilla 42]
"""

from __future__ import annotations

import argparse
import csv
import random
from datetime import date, timedelta
from pathlib import Path

RAW_DIR = Path(__file__).resolve().parent.parent / "data" / "raw"

FECHA_DESDE = date(2024, 1, 1)
FECHA_HASTA = date(2025, 12, 31)

ALMACENES = [
    (1, "Centro Norte", "Zaragoza", 12000),
    (2, "Centro Sur", "Sevilla", 9000),
    (3, "Plataforma Central", "Madrid", 20000),
    (4, "Levante", "Valencia", 8000),
    (5, "Atlántico", "A Coruña", 6000),
]

CATEGORIAS = {
    "Alimentación seca": (2.0, 0.5, 15.0),
    "Bebidas": (8.0, 1.0, 12.0),
    "Congelados": (5.0, 3.0, 25.0),
    "Droguería": (3.0, 1.5, 18.0),
    "Electrónica": (1.5, 25.0, 400.0),
    "Textil": (0.8, 6.0, 60.0),
}

SEGMENTOS = ["Gran cuenta", "Mayorista", "Minorista", "E-commerce"]
REGIONES = ["Norte", "Sur", "Centro", "Este", "Oeste"]


def ensuciar_texto(rng: random.Random, texto: str) -> str:
    """Devuelve el texto con variaciones de mayúsculas o espacios (simula carga manual)."""
    r = rng.random()
    if r < 0.05:
        return texto.upper()
    if r < 0.10:
        return f"  {texto} "
    if r < 0.13:
        return texto.lower()
    return texto


def generar(n_pedidos: int, semilla: int) -> None:
    rng = random.Random(semilla)
    RAW_DIR.mkdir(parents=True, exist_ok=True)

    # --- Almacenes -----------------------------------------------------------
    with open(RAW_DIR / "almacenes.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["almacen_id", "nombre", "ciudad", "capacidad_pallets"])
        w.writerows(ALMACENES)

    # --- Productos -----------------------------------------------------------
    productos = []
    pesos_categoria = [v[0] for v in CATEGORIAS.values()]
    for pid in range(1, 301):
        categoria = rng.choices(list(CATEGORIAS), weights=pesos_categoria)[0]
        _, pmin, pmax = CATEGORIAS[categoria]
        precio = round(rng.uniform(pmin, pmax), 2)
        peso = round(rng.uniform(0.1, 25.0), 2)
        productos.append((pid, f"Producto {pid:04d}", categoria, peso, precio))

    with open(RAW_DIR / "productos.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["producto_id", "nombre", "categoria", "peso_kg", "precio_lista"])
        for pid, nombre, cat, peso, precio in productos:
            w.writerow([pid, nombre, ensuciar_texto(rng, cat), peso, precio])

    # --- Clientes (con versiones duplicadas por actualización) ---------------
    clientes = []
    with open(RAW_DIR / "clientes.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["cliente_id", "razon_social", "segmento", "region", "fecha_alta", "fecha_actualizacion"])
        for cid in range(1, 251):
            segmento = rng.choices(SEGMENTOS, weights=[1, 3, 5, 3])[0]
            region = rng.choice(REGIONES)
            alta = FECHA_DESDE - timedelta(days=rng.randint(0, 1500))
            act = alta + timedelta(days=rng.randint(0, 400))
            clientes.append((cid, segmento))
            w.writerow([cid, f"Cliente {cid:04d} S.L.", ensuciar_texto(rng, segmento), region, alta, act])
            # ~8 % de los clientes tiene una segunda versión más reciente (cambio de región)
            if rng.random() < 0.08:
                w.writerow([cid, f"Cliente {cid:04d} S.L.", segmento, rng.choice(REGIONES), alta,
                            act + timedelta(days=rng.randint(30, 300))])

    # --- Pedidos y líneas ----------------------------------------------------
    dias = (FECHA_HASTA - FECHA_DESDE).days
    estados = ["Entregado", "Pendiente", "Cancelado"]
    pesos_cliente = [{"Gran cuenta": 8, "Mayorista": 4, "Minorista": 1, "E-commerce": 2}[s] for _, s in clientes]

    with open(RAW_DIR / "pedidos.csv", "w", newline="", encoding="utf-8") as fp, \
         open(RAW_DIR / "lineas_pedido.csv", "w", newline="", encoding="utf-8") as fl:
        wp, wl = csv.writer(fp), csv.writer(fl)
        wp.writerow(["pedido_id", "cliente_id", "almacen_id", "fecha_pedido",
                     "fecha_comprometida", "fecha_entrega", "estado"])
        wl.writerow(["pedido_id", "linea", "producto_id", "cantidad", "precio_unitario", "descuento_pct"])

        for pedido_id in range(1, n_pedidos + 1):
            # Estacionalidad simple: más pedidos en noviembre-diciembre
            while True:
                fecha = FECHA_DESDE + timedelta(days=rng.randint(0, dias))
                if fecha.weekday() < 6 and (fecha.month >= 11 or rng.random() < 0.8):
                    break
            cliente_id = rng.choices(clientes, weights=pesos_cliente)[0][0]
            almacen_id = rng.choices([a[0] for a in ALMACENES], weights=[a[3] for a in ALMACENES])[0]
            comprometida = fecha + timedelta(days=rng.choice([1, 2, 2, 3, 5]))

            dias_desde_fin = (FECHA_HASTA - fecha).days
            if dias_desde_fin < 5 and rng.random() < 0.7:
                estado, entrega = "Pendiente", ""
            elif rng.random() < 0.03:
                estado, entrega = "Cancelado", ""
            else:
                # Peor servicio en el almacén 5 y en temporada alta
                retraso_base = 0.25 if almacen_id == 5 else 0.10
                if fecha.month >= 11:
                    retraso_base += 0.10
                retraso = rng.randint(1, 4) if rng.random() < retraso_base else -rng.randint(0, 1)
                estado, entrega = "Entregado", comprometida + timedelta(days=retraso)

            wp.writerow([pedido_id, cliente_id, almacen_id, fecha, comprometida, entrega,
                         ensuciar_texto(rng, estado)])

            for linea in range(1, rng.randint(1, 6) + 1):
                pid, _, _, _, precio = rng.choice(productos)
                cantidad = 0 if rng.random() < 0.01 else rng.randint(1, 120)
                descuento = rng.choice([0, 0, 0, 5, 10, 15])
                precio_venta = round(precio * rng.uniform(0.95, 1.05), 2)
                wl.writerow([pedido_id, linea, pid, cantidad, precio_venta, descuento])

    print(f"Datos generados en {RAW_DIR} ({n_pedidos} pedidos, semilla {semilla})")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--pedidos", type=int, default=20000)
    parser.add_argument("--semilla", type=int, default=42)
    args = parser.parse_args()
    generar(args.pedidos, args.semilla)
