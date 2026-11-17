-- Grain: una fila por pedido (incluye cancelados, para poder medir la tasa de cancelación).
-- Calcula el nivel de servicio: un pedido está "a tiempo" si se entregó
-- en la fecha comprometida o antes.
with pedidos as (

    select * from {{ ref('stg_erp__pedidos') }}

),

totales_lineas as (

    select
        pedido_id,
        count(*)            as num_lineas,
        sum(cantidad)       as unidades,
        sum(importe_neto)   as importe_neto,
        sum(peso_total_kg)  as peso_total_kg
    from {{ ref('int_lineas_pedido_valoradas') }}
    group by pedido_id

)

select
    pedidos.pedido_id,
    pedidos.cliente_id,
    pedidos.almacen_id,
    pedidos.fecha_pedido,
    pedidos.fecha_comprometida,
    pedidos.fecha_entrega,
    pedidos.estado,
    coalesce(totales_lineas.num_lineas, 0)          as num_lineas,
    coalesce(totales_lineas.unidades, 0)            as unidades,
    coalesce(totales_lineas.importe_neto, 0)        as importe_neto,
    coalesce(totales_lineas.peso_total_kg, 0)       as peso_total_kg,
    case
        when pedidos.estado = 'Entregado'
            then datediff('day', pedidos.fecha_comprometida, pedidos.fecha_entrega)
    end                                             as dias_retraso,
    case
        when pedidos.estado = 'Entregado'
            then pedidos.fecha_entrega <= pedidos.fecha_comprometida
    end                                             as entregado_a_tiempo
from pedidos
left join totales_lineas
    on pedidos.pedido_id = totales_lineas.pedido_id
