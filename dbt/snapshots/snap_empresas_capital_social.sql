{% snapshot snap_empresas_capital_social %}

{{
    config(
        target_schema='snapshots',
        unique_key='cnpj_basico',
        strategy='check',
        check_cols=['capital_social', 'porte_empresa_desc'],
        invalidate_hard_deletes=True
    )
}}

-- Rastreia o histórico de alterações do Capital Social (campo crítico para
-- análise de risco/crédito) via SCD Type 2. Cada execução do snapshot
-- (rodada pelo Prefect Flow em cadência definida) compara o estado atual
-- de `stg_empresas` com a última versão registrada e abre uma nova linha
-- sempre que capital_social ou porte_empresa mudarem, preservando as
-- colunas dbt_valid_from / dbt_valid_to geradas automaticamente.

select
    cnpj_basico,
    razao_social,
    capital_social,
    porte_empresa_desc
from {{ ref('stg_empresas') }}

{% endsnapshot %}
