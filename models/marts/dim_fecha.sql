-- Dimensión calendario generada, sin depender de una tabla de origen.
with dias as (

    select
        cast(unnest(generate_series(
            date '{{ var("fecha_desde") }}',
            date '{{ var("fecha_hasta") }}',
            interval 1 day
        )) as date) as fecha

)

select
    fecha,
    cast(strftime(fecha, '%Y%m%d') as integer)     as fecha_id,
    year(fecha)                                     as anio,
    month(fecha)                                    as mes,
    strftime(fecha, '%Y-%m')                        as anio_mes,
    quarter(fecha)                                  as trimestre,
    weekofyear(fecha)                               as semana_iso,
    isodow(fecha)                                   as dia_semana,
    isodow(fecha) <= 5                              as es_laborable,
    month(fecha) in (11, 12)                        as es_temporada_alta
from dias
