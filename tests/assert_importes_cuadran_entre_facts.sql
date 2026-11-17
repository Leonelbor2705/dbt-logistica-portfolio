-- Control de cuadre: el importe total a nivel pedido debe coincidir con la suma
-- de las líneas. Detecta pérdidas o duplicaciones de filas entre las dos facts.
with total_pedidos as (

    select sum(importe_neto) as importe from {{ ref('fct_pedidos') }}

),

total_lineas as (

    select sum(importe_neto) as importe from {{ ref('fct_lineas_pedido') }}

)

select
    total_pedidos.importe as importe_pedidos,
    total_lineas.importe  as importe_lineas
from total_pedidos
cross join total_lineas
where abs(total_pedidos.importe - total_lineas.importe) > 0.01
