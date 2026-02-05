import json
import logging
import yfinance as yf
import boto3
from datetime import datetime

s3 = boto3.client("s3")
logger = logging.getLogger()
logger.setLevel(logging.INFO)
BUCKET_NAME = "yfinance-stock-data"

def lambda_handler(event, context):
    tickers = event.get('tickers', ["AAPL"]) 
    logger.info(f"Processing tickers: {tickers}")

    try:
        # Fetch data
        data = yf.download(tickers, period="1d", interval="1m")

        if data.empty:
            logger.warning(f"No data found for tickers: {tickers}")
            return {'statusCode': 404, 'body': 'No data found'}

        # Process DataQ
        latest_data = data.tail(1).stack(level=1, future_stack=True).reset_index()
        json_data = latest_data.to_json(orient="records", date_format="iso")

        # 1. NEW HIVE PATH WITH TOP-LEVEL FOLDER
        now = datetime.now()
        year = now.strftime("%Y")
        month = now.strftime("%m")
        day = now.strftime("%d")
        timestamp_str = now.strftime("%H-%M-%S")

        # This places the partitions INSIDE the stock_data folder
        hive_path = f"stock_data/year={year}/month={month}/day={day}/prices_{timestamp_str}.json"

        # 2. Upload to S3
        s3.put_object(
            Bucket=BUCKET_NAME,
            Key=hive_path,
            Body=json_data,
            ContentType='application/json'
        )

        logger.info(f"Successfully landed data to: s3://{BUCKET_NAME}/{hive_path}")

        return {
            'statusCode': 200,
            'body': json_data
        }

    except Exception as e:
        logger.error(f"Error fetching data: {str(e)}", exc_info=True)
        return {'statusCode': 500, 'body': 'Error processing request'}