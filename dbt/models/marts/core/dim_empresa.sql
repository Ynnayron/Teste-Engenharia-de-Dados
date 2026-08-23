{{
    config(
        materialized='table'
    )
}}

-- Dimensão de empresa no grão do estabelecimento MATRIZ (1:1 com cnpj_basico),
-- reunindo os atributos descritivos usados para fatiar a tabela fato.

with empresas as (
    select * from {{ ref('stg_empresas') }}
),

matriz as (
    select *
    from {{ ref('stg_estabelecimentos') }}
    where tipo_estabelecimento = 'MATRIZ'
    qualify row_number() over (partition by cnpj_basico order by data_inicio_atividade asc) = 1
),

simples as (
    select * from {{ ref('stg_simples_nacional') }}
),

final as (
    select
        e.cnpj_basico,
        m.cnpj_completo,
        e.razao_social,
        m.nome_fantasia,
        e.natureza_juridica,
        e.porte_empresa_desc,
        e.capital_social,
        m.situacao_cadastral_desc,
        m.data_inicio_atividade,
        m.cnae_fiscal_principal,
        m.uf,
        m.bairro,
        coalesce(s.optante_simples, false) as optante_simples,
        coalesce(s.optante_mei, false)     as optante_mei
    from empresas e
    left join matriz m   on e.cnpj_basico = m.cnpj_basico
    left join simples s  on e.cnpj_basico = s.cnpj_basico
)

select * from final
