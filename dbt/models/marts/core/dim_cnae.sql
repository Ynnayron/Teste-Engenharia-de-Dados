{{
    config(
        materialized='table'
    )
}}

select
    cnae_subclasse,
    cnae_subclasse_desc,
    cnae_divisao,
    cnae_grupo,
    cnae_classe,
    cnae_secao_desc
from {{ ref('int_cnae_hierarquia') }}
