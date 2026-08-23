{% test valor_positivo(model, column_name) %}
{#
    Teste genérico customizado: garante que uma coluna numérica é sempre
    > 0. Usado para validar regras de negócio como "quantidade de sócios
    deve ser maior que zero" ou "capital social declarado deve ser positivo".

    Uso (em .yml):
        - dbt_utils... (não usado aqui, macro própria)
        - valor_positivo
#}
select *
from {{ model }}
where {{ column_name }} is not null
  and {{ column_name }} <= 0
{% endtest %}
