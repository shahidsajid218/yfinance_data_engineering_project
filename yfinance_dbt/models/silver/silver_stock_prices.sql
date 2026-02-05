{{ 
    config(
        materialized='incremental',
        unique_key=['ticker', 'trading_at'],
        schema='silver',
        incremental_strategy='merge',
        cluster_by=['trading_at::date'],
        tags=['silver']
    ) 
}}



with raw_source as (
    select 
        raw_json,
        file_year,
        file_month,
        ingestion_timestamp
    from {{ source('bronze_data', 'raw_stock_data') }}
    
    {% if is_incremental() %}
      -- This ensures we only scan NEW data since the last dbt run
      where ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
    {% endif %}
)

select
    -- 1. Extract and Cast JSON fields
    value:Ticker::string as ticker,
    value:Open::float as open_price,
    value:High::float as high_price,
    value:Low::float as low_price,
    value:Close::float as close_price,
    value:Volume::int as volume,
    to_timestamp(value:Datetime::string) as trading_at,
    
    -- 2. Metadata and Partitioning
    file_year,
    file_month,
    ingestion_timestamp
from raw_source,
lateral flatten(input => raw_json)

{% if is_incremental() %}
    -- Double-check to prevent processing empty/null records in incremental loads
    where ticker is not null
{% endif %}