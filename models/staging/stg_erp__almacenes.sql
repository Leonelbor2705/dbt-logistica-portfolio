select
    cast(almacen_id as integer)         as almacen_id,
    trim(nombre)                        as almacen,
    trim(ciudad)                        as ciudad,
    cast(capacidad_pallets as integer)  as capacidad_pallets
from {{ source('erp', 'almacenes') }}
