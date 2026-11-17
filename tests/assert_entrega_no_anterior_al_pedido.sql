-- Un pedido no puede entregarse antes de haberse realizado.
-- Devuelve los pedidos que incumplen la regla (el test falla si hay filas).
select
    pedido_id,
    fecha_pedido,
    fecha_entrega
from {{ ref('fct_pedidos') }}
where fecha_entrega < fecha_pedido
