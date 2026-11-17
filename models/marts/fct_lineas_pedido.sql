{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'delete+insert',
        unique_key = ['pedido_id', 'linea'],
        on_schema_change = 'fail'
    )
}}

-- Grain: una fila por línea de pedido (pedidos no cancelados).
-- Incremental: en cada corrida se reprocesan los últimos N días de pedidos
-- (var dias_reproceso) para capturar líneas que llegan o cambian con retraso.
with lineas as (

    select * from {{ ref('int_lineas_pedido_valoradas') }}

),

pedidos as (

    select pedido_id, cliente_id, almacen_id, fecha_pedido
    from {{ ref('stg_erp__pedidos') }}

    {% if is_incremental() %}
    where fecha_pedido >= (
        select max(fecha_pedido) - interval {{ var('dias_reproceso') }} day
        from {{ this }}
    )
    {% endif %}

)

select
    lineas.pedido_id,
    lineas.linea,
    pedidos.fecha_pedido,
    pedidos.cliente_id,
    pedidos.almacen_id,
    lineas.producto_id,
    lineas.cantidad,
    lineas.precio_unitario,
    lineas.descuento_pct,
    lineas.importe_bruto,
    lineas.importe_descuento,
    lineas.importe_neto,
    lineas.peso_total_kg
from lineas
inner join pedidos
    on lineas.pedido_id = pedidos.pedido_id
