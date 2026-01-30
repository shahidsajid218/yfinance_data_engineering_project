import yfinance as yf
import pandas as pd
import json
from datetime import datetime

def fetch_stock_data(tickers):
    data = yf.download(["AAPL", "TSLA", "GOOGL", "MSFT"], period="1d", interval="1m", group_by='ticker')
    #print(data)
    print(data.head())

    records = []
    for ticker in tickers:
            # Get the most recent price row
            latest_row = data[ticker].iloc[-1]
            
            # Construct the payload (similar to the nested JSON we parsed earlier)
            payload = {
                "symbol": ticker,
                "timestamp": datetime.now().isoformat(),
                "price_data": {
                    "open": float(latest_row['Open']),
                    "high": float(latest_row['High']),
                    "low": float(latest_row['Low']),
                    "close": float(latest_row['Close']),
                    "volume": int(latest_row['Volume'])
                },
                "meta": {
                    "source": "yahoo_finance",
                    "interval": "1m"
                }
            }
            records.append(payload)
        
    print(records)

if __name__ == "__main__":
    stocks = ["AAPL", "TSLA", "GOOGL", "MSFT"]
    real_time_data = fetch_stock_data(stocks)
    
    # Print the first record as a formatted JSON string
    print(json.dumps(real_time_data[0], indent=4))