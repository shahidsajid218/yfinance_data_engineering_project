# yfinance-DE-Project

A comprehensive, event-driven data engineering pipeline for collecting, transforming, and analyzing financial market data using Yahoo Finance, AWS, Snowflake, and dbt, orchestrated by Apache Airflow.

## 📋 Overview

This project orchestrates a complete ETL/ELT pipeline that:
- **Extracts** real-time stock market data via **AWS Lambda** (Python).
- **Streams** data through **AWS S3** and **Amazon SQS** for event-driven ingestion.
- **Loads** raw data into **Snowflake** via **Snowpipe** with automated **SNS** error alerting.
- **Transforms** data through a Medallion Architecture (**Bronze → Silver → Gold**) using **dbt**.
- **Orchestrates** workflows with **Apache Airflow**, specifically tuned to NYSE trading hours.

The pipeline runs during NYSE trading hours (2:30 PM - 9:00 PM GMT, Monday-Friday) to capture intraday market movements with minimal compute waste.

s
## 🚀 Key Engineering Features

### **1. Event-Driven Ingestion**
- Utilizes **Snowpipe** to automatically ingest data as it lands in S3.
- Notifications are managed via **AWS SQS** to ensure no files are missed.
- **SNS Alerting:** Integrated an outbound notification system that sends an alert to a specified SNS topic if a pipe execution fails.

### **2. dbt Transformation Logic**
- Implemented **Medallion Architecture** to maintain a clean data lineage.
- **Hive Partitioning:** Optimized the Silver layer using date-based partitioning to drastically reduce Snowflake credit consumption during query execution.
- Modular SQL development using `ref()` and `source()` functions for maintainability.

### **3. Security & Governance**
- Implemented the **Principle of Least Privilege (PoLP)**.
- Dedicated roles created in Snowflake (`TRANSFORMER`, `LOADER`, `REPORT_USER`) to ensure Airflow and Power BI only have access to required schemas.

## 🏗️ Architecture

[yfinance API] 
      │
      ▼
[AWS Lambda] ───► [AWS CloudWatch Logs]
      │
      ▼
[AWS S3 (Landing)] ───► [AWS SNS/SQS] ───► [Snowpipe]
                                              │
                                              ▼
[Airflow] ───► [dbt Core] ───► [Snowflake (Medallion)]
                                              │
                                              ▼
                                        [Power BI Dashboard]



### Data Layers (Medallion Architecture)
- **Bronze (Landing):** Raw JSON/CSV extracts stored in S3 and mirrored in Snowflake.
- **Silver (Cleansing):** Data cast to correct types, duplicates removed, and organized via **Hive-style Partitioning** (Year/Month/Day).
- **Gold (Analytics):** Aggregated metrics including **RSI (Relative Strength Index)** and **Hourly Moving Averages** for BI consumption.

### Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Orchestration** | Apache Airflow | DAG scheduling & NYSE-aligned workflow management |
| **Transformation** | dbt (Data Build Tool) | Modular SQL modeling and Medallion layer logic |
| **Cloud Storage** | AWS S3 | Scalable landing zone for raw financial extracts |
| **Ingestion** | Snowpipe + SQS | Serverless, real-time data loading into Snowflake |
| **Messaging** | Amazon SNS | Automated outbound alerting for ingestion failures |
| **Data Warehouse**| Snowflake | High-performance cloud compute and storage |
| **Visualization** | Power BI | Dynamic reporting with DAX-driven time intelligence |




## 📁 Project Structure

```
c:\Personal\Finance Data Engineering Project\
├── README.md                          # This file
├── dbt_project.yml                    # dbt project configuration
├── pyproject.toml                     # Python project metadata
│
├── airflow_home/                      # Apache Airflow configuration
│   ├── airflow.cfg                    # Airflow configuration settings
│   ├── webserver_config.py            # Airflow webserver settings
│   ├── dags/
│   │   └── yfinance_orchestrator.py   # Main ETL DAG
│   └── logs/                          # Airflow execution logs
│
├── yfinance_dbt/                      # dbt project root
│   ├── dbt_project.yml                # dbt configuration
│   ├── profiles.yml                   # Snowflake connection profile
│   ├── models/                        # dbt transformation models
│   │   └── example/                   # Sample models
│   ├── macros/                        # dbt macros (e.g., get_custom_schema.sql)
│   ├── tests/                         # dbt data tests
│   ├── seeds/                         # Static data files
│   ├── analyses/                      # Ad-hoc analysis queries
│   └── target/                        # dbt compiled artifacts
│
├── scripts/                           # Python utility scripts
│   ├── get_stock_data.py              # Stock data extraction (AWS Lambda compatible)
│   ├── requirements.txt               # Python dependencies
│   └── python/                        # Vendored Python packages
│       ├── yfinance/                  # Yahoo Finance library
│       ├── pandas/                    # Data manipulation
│       ├── numpy/                     # Numerical computing
│       └── [other dependencies]
│
└── snowflake_scripts/                 # Snowflake initialization scripts
    ├── snowflake_airflow_init.sql     # Airflow integration setup
    ├── Snowflake_db_init.sql          # Database & schema creation
    └── snowflake_dbt_init.sql         # dbt user & role setup
```

## 🚀 Quick Start




### Prerequisites

- **Python** >= 3.9
- **Apache Airflow** (configured in `airflow_home/`)
- **dbt** with Snowflake adapter
- **Snowflake** account with appropriate permissions
- **Yahoo Finance API** access (free tier)

### Installation

1. **Clone/navigate to the project**
   ```bash
   cd "c:\Personal\Finance Data Engineering Project"
   ```

2. **Set up Python environment**
   ```bash
   python -m venv venv
   venv\Scripts\activate
   pip install -r scripts/requirements.txt
   ```

3. **Configure Snowflake connection**
   - Update `yfinance_dbt/profiles.yml` with your Snowflake credentials
   - Run initialization scripts:
     ```bash
     snowflake_scripts/Snowflake_db_init.sql
     snowflake_scripts/snowflake_dbt_init.sql
     snowflake_scripts/snowflake_airflow_init.sql
     ```

4. **Initialize Airflow**
   ```bash
   set AIRFLOW_HOME=airflow_home
   airflow standalone
   ```
   - Access webUI at `http://localhost:8080`
   - Login with credentials from `airflow_home/standalone_admin_password.txt`

5. **Deploy dbt models**
   ```bash
   cd yfinance_dbt
   dbt debug
   dbt run
   ```

## 📊 Data Flow

### Airflow DAG: `yfinance_dbt_transformation`

**Schedule**: Every hour from 2:00 PM - 9:00 PM ET, Monday-Friday

**Tasks**:
1. `dbt_run_silver` - Cleansing & Hive-style partitioning
2. `dbt_run_gold` - Analytics aggregation & enrichment
3. (Optional) Data quality tests

### Data Extraction

The `scripts/get_stock_data.py` script:
- Fetches 1-minute interval data via yfinance
- Processes and enriches stock tickers
- Uploads to S3 or Snowflake staging area
- Compatible with AWS Lambda for serverless execution

## 🔧 Configuration

### Airflow DAG Configuration

Edit `airflow_home/dags/yfinance_orchestrator.py`:
- **DBT_PROJECT_DIR** - Path to dbt project
- **DBT_VENV_EXECUTABLE** - Path to dbt executable
- **schedule_interval** - Cron expression for execution timing
- **default_args.start_date** - Pipeline start date

### dbt Configuration

Edit `yfinance_dbt/dbt_project.yml`:
- **name** - Project identifier
- **version** - Project version
- **profile** - Snowflake connection profile
- **model-paths** - Location of transformation models

### Snowflake Connection

Update `yfinance_dbt/profiles.yml`:
```yaml
yfinance_dbt:
  outputs:
    dev:
      type: snowflake
      account: [your-account-id]
      user: [your-username]
      password: [your-password]
      role: [role-name]
      database: [database-name]
      schema: [schema-name]
      threads: 4
      client_session_keep_alive: false
  target: dev
```

## 📈 Models & Transformations

### Silver Layer Models
- Data cleansing and validation
- Hive-style partitioning by date/ticker
- Removal of duplicates and null handling

### Gold Layer Models
- Time-series aggregations (hourly, daily, etc.)
- Technical indicators (moving averages, volatility)
- Analytics-ready fact and dimension tables

## 🧪 Testing

Run dbt data tests:
```bash
cd yfinance_dbt
dbt test
```

Test includes:
- NOT NULL constraints
- Unique key validation
- Referential integrity
- Custom data quality checks

## 📝 Development Workflow

### Adding a New Model

1. Create SQL file in `yfinance_dbt/models/[layer]/`
2. Define source/ref relationships
3. Add documentation in `schema.yml`
4. Run `dbt run --select [model_name]`
5. Run `dbt test --select [model_name]`

### Debugging

**Check Airflow logs**:
```bash
echo %AIRFLOW_HOME%\logs\dag_id=yfinance_dbt_transformation\
```

**Check dbt artifacts**:
```bash
cd yfinance_dbt
dbt docs generate
dbt docs serve  # View at http://localhost:8000
```

## 🔐 Security & Best Practices

- Store Snowflake credentials in environment variables, not in `profiles.yml`
- Use Airflow connections/secrets management for sensitive data
- Implement IAM roles in Snowflake (separate read/write permissions)
- Version control dbt models but exclude `profiles.yml`

## 📚 Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [Apache Airflow Docs](https://airflow.apache.org/)
- [Snowflake Documentation](https://docs.snowflake.com/)
- [yfinance Documentation](https://github.com/ranaroussi/yfinance)

## 📞 Support & Contribution

For issues or improvements, refer to the specific component documentation or check logs in:
- `airflow_home/logs/` - Airflow execution logs
- `yfinance_dbt/target/` - dbt run artifacts

## 📄 License



---

**Last Updated**: February 5, 2026
