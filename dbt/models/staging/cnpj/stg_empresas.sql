{{
    config(
        materialized='view'
    )
}}

-- Padronização básica dos dados brutos de EMPRESAS: tipagem, trim e
-- decodificação de domínios. Sem regra de negócio além de limpeza/tipagem.

with source as (
    select * from {{ source('raw', 'raw_empresas') }}
),

renamed as (
    select
        trim(cnpj_basico)  as cnpj_basico,
        trim(razao_social) as razao_social,
        try_cast(natureza_juridica as integer) as natureza_juridica,
        try_cast(qualificacao_responsavel as integer) as qualificacao_responsavel,
        {{ parse_br_decimal('capital_social') }} as capital_social,
        trim(porte_empresa) as porte_empresa_cod,
        {{ porte_empresa_desc('porte_empresa') }} as porte_empresa_desc,
        nullif(trim(ente_federativo_responsavel), '') as ente_federativo_responsavel
    from source
    where cnpj_basico is not null and trim(cnpj_basico) != ''
)

select * from renamed
