with origen as (

    select * from {{ source('erp', 'productos') }}

)

select
    cast(origen.producto_id as integer)         as producto_id,
    trim(origen.nombre)                         as producto,
    mapa.categoria,
    mapa.familia,
    mapa.requiere_frio,
    cast(origen.peso_kg as decimal(10, 2))      as peso_kg,
    cast(origen.precio_lista as decimal(12, 2)) as precio_lista
from origen
left join {{ ref('map_categorias') }} as mapa
    on {{ normalizar_texto('origen.categoria') }} = mapa.categoria_clave
