{#
    Normaliza un texto cargado a mano en origen: quita espacios en los extremos
    y lo pasa a minúsculas, para poder compararlo o cruzarlo con una tabla de mapeo.
#}
{% macro normalizar_texto(columna) -%}
    lower(trim({{ columna }}))
{%- endmacro %}
