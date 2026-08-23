{% macro parse_rfb_date(column_name) %}
{#
    Os arquivos da Receita Federal trazem datas no formato 'YYYYMMDD' (texto),
    usando '00000000' ou string vazia como sentinela de "sem data". Esta macro
    padroniza esse campo para o tipo DATE nativo, tratando ambos os casos.

    Uso: {{ parse_rfb_date('data_inicio_atividade') }}
#}
    case
        when {{ column_name }} is null
            or trim({{ column_name }}) = ''
            or trim({{ column_name }}) = '00000000'
        then null
        else try_strptime(trim({{ column_name }}), '%Y%m%d')::date
    end
{% endmacro %}
