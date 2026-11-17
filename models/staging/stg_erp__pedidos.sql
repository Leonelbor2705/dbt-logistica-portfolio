select
    cast(pedido_id as integer)          as pedido_id,
    cast(cliente_id as integer)         as cliente_id,
    cast(almacen_id as integer)         as almacen_id,
    cast(fecha_pedido as date)          as fecha_pedido,
    cast(fecha_comprometida as date)    as fecha_comprometida,
    cast(fecha_entrega as date)         as fecha_entrega,
    case {{ normalizar_texto('estado') }}
        when 'entregado' then 'Entregado'
        when 'pendiente' then 'Pendiente'
        when 'cancelado' then 'Cancelado'
        else 'Desconocido'
    end                                 as estado
from {{ source('erp', 'pedidos') }}
