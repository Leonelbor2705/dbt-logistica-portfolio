{#
    Usa el schema configurado tal cual (staging, intermediate, marts, referencia)
    en lugar del comportamiento por defecto de dbt (<target_schema>_<schema>).
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
