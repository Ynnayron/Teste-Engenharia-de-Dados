{{
    config(
        materialized='incremental',
        unique_key='cnpj_basico',
        incremental_strategy='delete+insert',
        on_schema_change='sync_all_columns'
    )
}}

-- Tabela fato: consolida métricas de empresas ATIVAS no grão de
-- cnpj_basico (matriz + agregação do quadro societário).
--
-- Estratégia incremental: em produção, a camada de extração (Airbyte)
-- entrega apenas o lote/delta mais recente publicado pela Receita Federal
-- (arquivos são liberados em snapshots mensais). Aqui simulamos esse
-- comportamento filtrando por `data_situacao_cadastral` (última alteração
-- cadastral) maior que o máximo já processado -- isso evita reprocessar
-- o histórico completo (~50M+ registros em produção) a cada execução,
-- processando apenas os estabelecimentos que mudaram desde a última carga.

with estabelecimentos as (
    select * from {{ ref('stg_estabelecimentos') }}
    where tipo_estabelecimento = 'MATRIZ'
      and situacao_cadastral_desc = 'ATIVA'

    {% if is_incremental() %}
    and data_situacao_cadastral > (select max(data_situacao_cadastral) from {{ this }})
    {% endif %}
),

empresas as (
    select * from {{ ref('stg_empresas') }}
),

socios_agg as (
    select * from {{ ref('int_socios_agregado') }}
),

simples as (
    select * from {{ ref('stg_simples_nacional') }}
),

final as (
    select
        est.cnpj_basico,
        est.cnpj_completo,
        emp.razao_social,
        est.nome_fantasia,
        emp.porte_empresa_desc,
        emp.capital_social,
        est.cnae_fiscal_principal,
        est.uf,
        est.data_inicio_atividade,
        est.data_situacao_cadastral,
        coalesce(soc.qtd_socios, 0)     as qtd_socios,
        coalesce(soc.qtd_socios_pf, 0)  as qtd_socios_pf,
        coalesce(soc.qtd_socios_pj, 0)  as qtd_socios_pj,
        coalesce(sim.optante_simples, false) as optante_simples,
        coalesce(sim.optante_mei, false)     as optante_mei,
        current_timestamp                    as _carregado_em
    from estabelecimentos est
    inner join empresas emp     on est.cnpj_basico = emp.cnpj_basico
    left join socios_agg soc    on est.cnpj_basico = soc.cnpj_basico
    left join simples sim       on est.cnpj_basico = sim.cnpj_basico
)

select * from final
