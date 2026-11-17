-- Un cliente puede venir repetido (una fila por cada actualización en origen).
-- Nos quedamos con la versión vigente: la de fecha_actualizacion más reciente.
with origen as (

    select * from {{ source('erp', 'clientes') }}

),

normalizado as (

    select
        cast(cliente_id as integer)             as cliente_id,
        trim(razon_social)                      as cliente,
        case {{ normalizar_texto('segmento') }}
            when 'gran cuenta' then 'Gran cuenta'
            when 'mayorista'   then 'Mayorista'
            when 'minorista'   then 'Minorista'
            when 'e-commerce'  then 'E-commerce'
            else 'Sin clasificar'
        end                                     as segmento,
        trim(region)                            as region,
        cast(fecha_alta as date)                as fecha_alta,
        cast(fecha_actualizacion as date)       as fecha_actualizacion
    from origen

)

select *
from normalizado
qualify row_number() over (
    partition by cliente_id
    order by fecha_actualizacion desc
) = 1
