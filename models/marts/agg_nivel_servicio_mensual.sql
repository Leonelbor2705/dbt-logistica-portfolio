-- Indicadores mensuales por almacén, listos para consumir desde un dashboard.
-- Nivel de servicio = pedidos entregados a tiempo / pedidos entregados.
with pedidos as (

    select * from {{ ref('fct_pedidos') }}

),

fechas as (

    select fecha, anio_mes from {{ ref('dim_fecha') }}

),

almacenes as (

    select almacen_id, almacen from {{ ref('dim_almacen') }}

)

select
    fechas.anio_mes,
    almacenes.almacen_id,
    almacenes.almacen,
    count(*)                                                        as pedidos,
    count(*) filter (where pedidos.estado = 'Entregado')            as pedidos_entregados,
    count(*) filter (where pedidos.estado = 'Cancelado')            as pedidos_cancelados,
    count(*) filter (where pedidos.entregado_a_tiempo)              as pedidos_a_tiempo,
    round(
        count(*) filter (where pedidos.entregado_a_tiempo)
        / nullif(count(*) filter (where pedidos.estado = 'Entregado'), 0),
        4
    )                                                               as nivel_servicio,
    round(avg(pedidos.dias_retraso) filter (where pedidos.dias_retraso > 0), 2)
                                                                    as dias_retraso_medio,
    sum(pedidos.importe_neto)                                       as importe_neto,
    sum(pedidos.peso_total_kg)                                      as peso_total_kg
from pedidos
inner join fechas
    on pedidos.fecha_pedido = fechas.fecha
inner join almacenes
    on pedidos.almacen_id = almacenes.almacen_id
group by fechas.anio_mes, almacenes.almacen_id, almacenes.almacen
