{{
    config(
        materialized='view'
    )
}}

-- Deriva a hierarquia do CNAE (Seção > Divisão > Grupo > Classe > Subclasse)
-- a partir da estrutura posicional do código de 7 dígitos, conforme o
-- Manual da Classificação Nacional de Atividades Econômicas do IBGE.

with cnae as (
    select * from {{ ref('stg_cnae') }}
),

hierarquia as (
    select
        codigo as cnae_subclasse,
        descricao as cnae_subclasse_desc,
        lpad(cast(codigo as varchar), 7, '0') as cnae_str,
        cast(substr(lpad(cast(codigo as varchar), 7, '0'), 1, 2) as integer) as cnae_divisao,
        cast(substr(lpad(cast(codigo as varchar), 7, '0'), 1, 3) as integer) as cnae_grupo,
        cast(substr(lpad(cast(codigo as varchar), 7, '0'), 1, 5) as integer) as cnae_classe,
        case
            when cast(substr(lpad(cast(codigo as varchar), 7, '0'), 1, 2) as integer) between 1 and 3 then 'A - AGROPECUARIA'
            when cast(substr(lpad(cast(codigo as varchar), 7, '0'), 1, 2) as integer) between 5 and 9 then 'B - INDUSTRIAS EXTRATIVAS'
            when cast(substr(lpad(cast(codigo as varchar), 7, '0'), 1, 2) as integer) between 10 and 33 then 'C - INDUSTRIAS DE TRANSFORMACAO'
            when cast(substr(lpad(cast(codigo as varchar), 7, '0'), 1, 2) as integer) between 41 and 43 then 'F - CONSTRUCAO'
            when cast(substr(lpad(cast(codigo as varchar), 7, '0'), 1, 2) as integer) between 45 and 47 then 'G - COMERCIO'
            when cast(substr(lpad(cast(codigo as varchar), 7, '0'), 1, 2) as integer) between 55 and 56 then 'I - ALIMENTACAO'
            when cast(substr(lpad(cast(codigo as varchar), 7, '0'), 1, 2) as integer) between 62 and 63 then 'J - INFORMACAO E COMUNICACAO'
            when cast(substr(lpad(cast(codigo as varchar), 7, '0'), 1, 2) as integer) between 86 and 88 then 'Q - SAUDE'
            when cast(substr(lpad(cast(codigo as varchar), 7, '0'), 1, 2) as integer) = 69 then 'M - ATIVIDADES PROFISSIONAIS'
            when cast(substr(lpad(cast(codigo as varchar), 7, '0'), 1, 2) as integer) between 49 and 53 then 'H - TRANSPORTE'
            else 'OUTROS'
        end as cnae_secao_desc
    from cnae
)

select * from hierarquia
