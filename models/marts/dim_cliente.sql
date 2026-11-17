select
    cliente_id,
    cliente,
    segmento,
    region,
    fecha_alta
from {{ ref('stg_erp__clientes') }}
