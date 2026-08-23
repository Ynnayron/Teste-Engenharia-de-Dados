{% macro situacao_cadastral_desc(column_name) %}
{#
    Traduz o código de situação cadastral (tabela de domínio da RFB) para
    uma descrição legível por negócio, evitando que analistas precisem
    decorar/consultar códigos numéricos em toda análise.

    Uso: {{ situacao_cadastral_desc('situacao_cadastral') }}
#}
    case {{ column_name }}
        when '01' then 'NULA'
        when '02' then 'ATIVA'
        when '03' then 'SUSPENSA'
        when '04' then 'INAPTA'
        when '08' then 'BAIXADA'
        else 'NAO_INFORMADO'
    end
{% endmacro %}


{% macro porte_empresa_desc(column_name) %}
{#
    Traduz o código de porte da empresa (tabela de domínio da RFB).
    Uso: {{ porte_empresa_desc('porte_empresa') }}
#}
    case {{ column_name }}
        when '00' then 'NAO_INFORMADO'
        when '01' then 'MICRO_EMPRESA'
        when '03' then 'EMPRESA_PEQUENO_PORTE'
        when '05' then 'DEMAIS'
        else 'NAO_INFORMADO'
    end
{% endmacro %}
