select
    almacen_id,
    almacen,
    ciudad,
    capacidad_pallets
from {{ ref('stg_erp__almacenes') }}
