select
    producto_id,
    producto,
    categoria,
    familia,
    requiere_frio,
    peso_kg,
    precio_lista
from {{ ref('stg_erp__productos') }}
