-- Las líneas con cantidad 0 son líneas anuladas en origen: no representan venta.
select
    cast(pedido_id as integer)                  as pedido_id,
    cast(linea as integer)                      as linea,
    cast(producto_id as integer)                as producto_id,
    cast(cantidad as integer)                   as cantidad,
    cast(precio_unitario as decimal(12, 2))     as precio_unitario,
    cast(descuento_pct as decimal(5, 2))        as descuento_pct
from {{ source('erp', 'lineas_pedido') }}
where cantidad > 0
