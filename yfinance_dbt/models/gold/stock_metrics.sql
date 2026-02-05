{{
    config(
        materialized='table',
        schema='gold',
        tags=['gold']
    )
}}


select
    ticker,
    trading_at,
    close_price,
    -- 1. Daily Return %
    (close_price - lag(close_price) over (partition by ticker order by trading_at)) 
        / lag(close_price) over (partition by ticker order by trading_at) as daily_return_pct,
    
    -- 2. 50-Day Moving Average
    avg(close_price) over (
        partition by ticker 
        order by trading_at 
        rows between 49 preceding and current row
    ) as moving_avg_50
from {{ ref('silver_stock_prices') }}