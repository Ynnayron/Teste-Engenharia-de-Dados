{{
    config(
        materialized='view'
    )
}}

-- Agrega o quadro societário no grão de empresa (cnpj_basico), preparando
-- a métrica "quantidade de sócios" consumida pela tabela fato.

with socios as (
    select * from {{ ref('stg_socios') }}
),

agregado as (
    select
        cnpj_basico,
        count(*)                                                        as qtd_socios,
        count(*) filter (where tipo_socio = 'PESSOA_FISICA')             as qtd_socios_pf,
        count(*) filter (where tipo_socio = 'PESSOA_JURIDICA')           as qtd_socios_pj,
        min(data_entrada_sociedade)                                     as data_entrada_socio_mais_antigo
    from socios
    group by cnpj_basico
)

select * from agregado
