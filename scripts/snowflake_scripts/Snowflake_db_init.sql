CREATE DATABASE IF NOT EXISTS yfinance_db;
CREATE SCHEMA IF NOT EXISTS yfinance_db.bronze;

CREATE OR REPLACE TABLE yfinance_db.bronze.raw_stock_data (
    file_year INT,
    file_month INT,
    file_day INT,
    raw_json VARIANT,  -- Entire array goes here
    filename STRING,
    ingestion_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
-- 3. Create a JSON File Format
CREATE OR REPLACE FILE FORMAT yfinance_db.bronze.json_format
    TYPE = 'JSON'
    STRIP_OUTER_ARRAY = TRUE;

-- 4. Create the Stage (Points to your S3 folder)

CREATE OR REPLACE STAGE yfinance_db.bronze.s3_stock_stage
    URL = 's3://yfinance-stock-data/stock_data/'
    STORAGE_INTEGRATION = s3_int_yfinance; -

-- Create Storage Integration for S3 Access (Run this in Snowflake UI and replace the ARN with your actual role ARN)
CREATE OR REPLACE STORAGE INTEGRATION s3_int_yfinance
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = '--your_role_arn--'
  STORAGE_ALLOWED_LOCATIONS = ('s3://yfinance-stock-data/stock_data/');

DESC INTEGRATION s3_int_yfinance;


-- 5. Create a Pipe to Auto-Ingest Data from S3 to Snowflake
CREATE OR REPLACE PIPE yfinance_db.bronze.stock_pipe
AUTO_INGEST = TRUE
AS
COPY INTO yfinance_db.bronze.raw_stock_data (
    file_year, file_month, file_day, raw_json, filename
)
FROM (
  SELECT 
    REPLACE(SPLIT_PART(metadata$filename, '/', 2), 'year=', '')::INT,
    REPLACE(SPLIT_PART(metadata$filename, '/', 3), 'month=', '')::INT,
    REPLACE(SPLIT_PART(metadata$filename, '/', 4), 'day=', '')::INT,
    $1, -- This takes the whole file and puts it in one cell
    metadata$filename
  FROM @yfinance_db.bronze.s3_stock_stage
)
FILE_FORMAT = (TYPE = JSON);

-- 6. Create a Notification Integration for Error Handling 
CREATE OR REPLACE NOTIFICATION INTEGRATION yfinance_error_notif
  ENABLED = TRUE
  TYPE = QUEUE
  NOTIFICATION_PROVIDER = AWS_SNS
  DIRECTION = OUTBOUND
  AWS_SNS_TOPIC_ARN = '--your_sns_topic_arn--'
  AWS_SNS_ROLE_ARN = '--your_role_arn--';


 ALTER PIPE yfinance_snowpipe 
SET ERROR_INTEGRATION = yfinance_error_notif;