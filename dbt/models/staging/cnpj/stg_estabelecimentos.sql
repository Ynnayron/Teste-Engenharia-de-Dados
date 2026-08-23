{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ source('raw', 'raw_estabelecimentos') }}
),

renamed as (
    select
        trim(cnpj_basico)                                          as cnpj_basico,
        trim(cnpj_ordem)                                           as cnpj_ordem,
        trim(cnpj_dv)                                              as cnpj_dv,
        {{ format_cnpj('cnpj_basico', 'cnpj_ordem', 'cnpj_dv') }}  as cnpj_completo,
        case identificador_matriz_filial
            when '1' then 'MATRIZ'
            when '2' then 'FILIAL'
            else 'NAO_INFORMADO'
        end                                                        as tipo_estabelecimento,
        nullif(trim(nome_fantasia), '')                            as nome_fantasia,
        trim(situacao_cadastral)                                   as situacao_cadastral_cod,
        {{ situacao_cadastral_desc('situacao_cadastral') }}        as situacao_cadastral_desc,
        {{ parse_rfb_date('data_situacao_cadastral') }}            as data_situacao_cadastral,
        trim(motivo_situacao_cadastral)                            as motivo_situacao_cadastral,
        nullif(trim(pais), '')                                     as pais_cod,
        {{ parse_rfb_date('data_inicio_atividade') }}              as data_inicio_atividade,
        try_cast(cnae_fiscal_principal as integer)                 as cnae_fiscal_principal,
        nullif(trim(cnae_fiscal_secundaria), '')                   as cnae_fiscal_secundaria,
        nullif(trim(logradouro), '')                                as logradouro,
        nullif(trim(bairro), '')                                    as bairro,
        regexp_replace(coalesce(cep, ''), '[^0-9]', '')             as cep,
        trim(uf)                                                    as uf,
        nullif(trim(correio_eletronico), '')                        as correio_eletronico
    from source
    where cnpj_basico is not null and trim(cnpj_basico) != ''
)

select * from renamed
