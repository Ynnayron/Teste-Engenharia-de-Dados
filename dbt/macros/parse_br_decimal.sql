{% macro parse_br_decimal(column_name) %}
{#
    Converte um campo textual no formato numérico brasileiro (ex: "1234,56")
    para DECIMAL, tratando também valores vazios/nulos que são comuns nos
    arquivos de dados abertos da Receita Federal.

    Uso: {{ parse_br_decimal('capital_social') }}
#}
    case
        when {{ column_name }} is null or trim({{ column_name }}) = '' then null
        else try_cast(replace(trim({{ column_name }}), ',', '.') as decimal(18,2))
    end
{% endmacro %}
