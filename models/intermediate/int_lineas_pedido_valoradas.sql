-- Valoriza cada línea de pedido (importe bruto, descuento, neto) y calcula su peso.
-- Se excluyen las líneas de pedidos cancelados: no generan venta ni movimiento físico.
with lineas as (

    select * from {{ ref('stg_erp__lineas_pedido') }}

),

pedidos as (

    select pedido_id, estado from {{ ref('stg_erp__pedidos') }}

),

productos as (

    select producto_id, peso_kg from {{ ref('stg_erp__productos') }}

)

select
    lineas.pedido_id,
    lineas.linea,
    lineas.producto_id,
    lineas.cantidad,
    lineas.precio_unitario,
    lineas.descuento_pct,
    lineas.cantidad * lineas.precio_unitario                                as importe_bruto,
    round(lineas.cantidad * lineas.precio_unitario * lineas.descuento_pct / 100, 2)
                                                                            as importe_descuento,
    round(lineas.cantidad * lineas.precio_unitario * (1 - lineas.descuento_pct / 100), 2)
                                                                            as importe_neto,
    lineas.cantidad * productos.peso_kg                                     as peso_total_kg
from lineas
inner join pedidos
    on lineas.pedido_id = pedidos.pedido_id
left join productos
    on lineas.producto_id = productos.producto_id
where pedidos.estado <> 'Cancelado'
