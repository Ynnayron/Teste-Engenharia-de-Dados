{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ source('raw', 'raw_cnae') }}
),

renamed as (
    select
        try_cast(codigo as integer) as codigo,
        trim(descricao)             as descricao
    from source
    where codigo is not null and trim(codigo) != ''
)

select * from renamed
