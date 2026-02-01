{{ config(materialized='table',
         schema='gold')
}}

WITH base_data AS (
    SELECT
        ticker,
        trading_at,
        close_price,
        -- Get yesterday's price to calculate the move
        LAG(close_price) OVER (PARTITION BY ticker ORDER BY trading_at) as prev_close
    FROM {{ ref('silver_stock_prices') }}
),

raw_moves AS (
    SELECT
        *,
        close_price - prev_close as price_change,
        -- Identify if it was a Gain or a Loss
        CASE WHEN (close_price - prev_close) > 0 THEN (close_price - prev_close) ELSE 0 END as gain,
        CASE WHEN (close_price - prev_close) < 0 THEN ABS(close_price - prev_close) ELSE 0 END as loss
    FROM base_data
),

avg_moves AS (
    SELECT
        *,
        -- Calculate 14-period moving average of gains and losses
        AVG(gain) OVER (PARTITION BY ticker ORDER BY trading_at ROWS BETWEEN 13 PRECEDING AND CURRENT ROW) as avg_gain,
        AVG(loss) OVER (PARTITION BY ticker ORDER BY trading_at ROWS BETWEEN 13 PRECEDING AND CURRENT ROW) as avg_loss
    FROM raw_moves
)

SELECT
    ticker,
    trading_at,
    close_price,
    avg_gain,
    avg_loss,
    -- The RSI Formula: 100 - (100 / (1 + (AvgGain / AvgLoss)))
    CASE 
        WHEN avg_loss = 0 THEN 100 -- Prevent division by zero
        ELSE 100 - (100 / (1 + (avg_gain / NULLIF(avg_loss, 0)))) 
    END as rsi
FROM avg_moves