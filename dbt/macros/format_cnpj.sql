{% macro format_cnpj(basico_col, ordem_col, dv_col) %}
{#
    Monta o CNPJ completo (14 dígitos) a partir das 3 partes em que a Receita
    Federal distribui o dado (básico + ordem + dígito verificador) e aplica
    a máscara padrão XX.XXX.XXX/XXXX-XX, útil para relatórios de negócio e
    trilhas de auditoria.

    Uso: {{ format_cnpj('cnpj_basico', 'cnpj_ordem', 'cnpj_dv') }}
#}
    case
        when {{ basico_col }} is null then null
        else
            lpad({{ basico_col }}, 8, '0') ||
            lpad(coalesce({{ ordem_col }}, '0001'), 4, '0') ||
            lpad(coalesce({{ dv_col }}, '00'), 2, '0')
    end
{% endmacro %}


{% macro format_cnpj_masked(basico_col, ordem_col, dv_col) %}
{#
    Igual a format_cnpj, mas já retorna com a máscara XX.XXX.XXX/XXXX-XX
    aplicada, pronta para exibição em relatórios / BI.
#}
    {% set raw = "(" ~ format_cnpj(basico_col, ordem_col, dv_col) ~ ")" %}
    case
        when {{ raw }} is null then null
        else
            substr({{ raw }}, 1, 2) || '.' ||
            substr({{ raw }}, 3, 3) || '.' ||
            substr({{ raw }}, 6, 3) || '/' ||
            substr({{ raw }}, 9, 4) || '-' ||
            substr({{ raw }}, 13, 2)
    end
{% endmacro %}
