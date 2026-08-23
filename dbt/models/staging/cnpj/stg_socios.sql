{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ source('raw', 'raw_socios') }}
),

renamed as (
    select
        trim(cnpj_basico)                              as cnpj_basico,
        case identificador_socio
            when '1' then 'PESSOA_JURIDICA'
            when '2' then 'PESSOA_FISICA'
            when '3' then 'ESTRANGEIRO'
            else 'NAO_INFORMADO'
        end                                             as tipo_socio,
        trim(nome_socio)                                as nome_socio,
        nullif(trim(cnpj_cpf_socio), '')                as cnpj_cpf_socio,
        try_cast(qualificacao_socio as integer)         as qualificacao_socio,
        {{ parse_rfb_date('data_entrada_sociedade') }}  as data_entrada_sociedade,
        try_cast(faixa_etaria as integer)               as faixa_etaria_cod
    from source
    where cnpj_basico is not null and trim(cnpj_basico) != ''
)

select * from renamed
