{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ source('raw', 'raw_simples') }}
),

renamed as (
    select
        trim(cnpj_basico)  as cnpj_basico,
        case opcao_simples when 'S' then true when 'N' then false else null end as optante_simples,
        {{ parse_rfb_date('data_opcao_simples') }}     as data_opcao_simples,
        {{ parse_rfb_date('data_exclusao_simples') }}  as data_exclusao_simples,
        case opcao_mei when 'S' then true 
                       when 'N' then false 
                       else null 
                       end  as optante_mei,
        {{ parse_rfb_date('data_opcao_mei') }} as data_opcao_mei,
        {{ parse_rfb_date('data_exclusao_mei') }} as data_exclusao_mei
    from source
    where cnpj_basico is not null and trim(cnpj_basico) != ''
)

select * from renamed
