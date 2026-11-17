{#
    Test genérico: la combinación de columnas indicada es única en el modelo.
    Uso en un .yml:
        data_tests:
          - unique_combinacion:
              columnas: [pedido_id, linea]
#}
{% test unique_combinacion(model, columnas) %}

select
    {{ columnas | join(', ') }},
    count(*) as repeticiones
from {{ model }}
group by {{ columnas | join(', ') }}
having count(*) > 1

{% endtest %}
